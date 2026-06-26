/*
 * Copyright (c) 2020-2026 The VxEngine Project. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <linux/slab.h>
#include <linux/uaccess.h>
#include "vxe.h"


/* Command opcodes */
#define VXE_OPCODE_AF		0x12	/* Activation function */
#define VXE_OPCODE_NOP		0x00	/* No operation */
#define VXE_OPCODE_SETACC	0x08	/* Set Accumulator */
#define VXE_OPCODE_SETVL	0x09	/* Set Vector Length */
#define VXE_OPCODE_SETRS	0x0C	/* Set First Operand */
#define VXE_OPCODE_SETRT	0x0D	/* Set Second Operand */
#define VXE_OPCODE_SETRD	0x0E	/* Set Destination */
#define VXE_OPCODE_SETEN	0x0A	/* Set Thread Enable */
#define VXE_OPCODE_PROD		0x10	/* Vector Product */
#define VXE_OPCODE_STORE	0x11	/* Store Result */
#define VXE_OPCODE_SYNC		0x01	/* Synchronize */

#define VESZ	4	/* Vector element size (float) */


/* Generic command format */
union i_generic {
	struct {
		u64 ctl	: 59;	/* Other bits */
		u64 op	: 5;	/* Opcode */
	};
	u64 raw;
};


/* Generic VPU command format */
union i_generic_vpu {
	struct {
		u64 pl	: 48;	/* Payload passed to VPU */
		u64 _z0	: 3;	/* Must be zero */
		u64 dst	: 8;	/* Destination */
		u64 op	: 5;	/* Opcode */
	};
	u64 raw;
};


/* SETVL command */
union i_setvl {
	struct {
		u64 len	: 20;	/* Vector length */
		u64 _z0	: 31;	/* Must be zero */
		u64 dst	: 8;	/* Destination */
		u64 op	: 5;	/* Opcode */
	};
	u64 raw;
};


/* SETRS / SETRT / SETRD commands */
union i_setrx {
	struct {
		u64 addr: 38;	/* Upper 38-bits of 32-bit aligned address */
		u64 _z0	: 13;	/* Must be zero */
		u64 dst	: 8;	/* Destination */
		u64 op	: 5;	/* Opcode */
	};
	u64 raw;
};


/* SETEN command */
union i_seten {
	struct {
		u64 en	: 1;	/* Enable/disable bit */
		u64 _z0	: 50;	/* Must be zero */
		u64 dst	: 8;	/* Destination */
		u64 op	: 5;	/* Opcode */
	};
	u64 raw;
};


/* SYNC command */
union i_sync {
	struct {
		u64 stop: 1;	/* Stop program execution */
		u64 intr: 1;	/* Send interrupt */
		u64 _z0	: 57;	/* Must be zero */
		u64 op	: 5;	/* Opcode */
	};
	u64 raw;
};


/* Get device struct from program state */
static struct device *ps_dev(struct vxe_prog_state *state)
{
	return state->ctx->vxdev->dev;
}


/* Get device struct from command buffer */
static struct device *cb_dev(struct vxe_cmd_buffer *cbuf)
{
	return cbuf->buf.ctx->vxdev->dev;
}


/* Parse destination field of the command */
static void prog_parse_dst(unsigned dst, unsigned *vpu, unsigned *th)
{
	*th = dst & (VXE_NR_THR - 1);
	*vpu = (dst >> 3) & (VXE_NR_VPU - 1);
}


/* Index of the next resource / buffer */
static size_t prog_next_res(struct vxe_prog_state *state)
{
	return state->curres < state->res->nres ? state->curres++ : state->res->nres;
}


/* Check if resource index is valid */
static bool prog_valid_res(struct vxe_prog_state *state, size_t ri)
{
	return ri < state->res->nres;
}


/* Handle SETACC command */
static int prog_prep_setacc(struct vxe_prog_state *state, size_t pc)
{
	union i_generic_vpu *u = (union i_generic_vpu*)(&state->prog[pc]);
	unsigned vpu, th;

	prog_parse_dst(u->dst, &vpu, &th);

	state->ts[vpu][th].a_set = 1;

	return 0;
}


/* Handle SETVL command */
static int prog_prep_setvl(struct vxe_prog_state *state, size_t pc)
{
	union i_setvl *u = (union i_setvl*)(&state->prog[pc]);
	unsigned vpu, th;

	prog_parse_dst(u->dst, &vpu, &th);

	state->ts[vpu][th].vlen = u->len;

	return 0;
}


/* Handle SETRS command */
static int prog_prep_setrs(struct vxe_prog_state *state, size_t pc)
{
	union i_setrx *u = (union i_setrx*)(&state->prog[pc]);
	size_t ri = prog_next_res(state);
	unsigned vpu, th;
	struct vxe_buffer *buf;
	u32 idx;
	size_t blen;

	if(!prog_valid_res(state, ri)) {
		dev_err(ps_dev(state), "<setrs> out of resources.\n");
		return -EINVAL;
	}

	buf = state->res->bufs[ri];	/* Buffer */
	blen = buf->size / VESZ;	/* Buffer length */
	idx = state->indexes[ri];	/* User provided index to the buffer */

	if(idx > blen) {
		dev_err(ps_dev(state), "<setrs> index out of range (res: %zu).\n", ri);
		return -EINVAL;
	}

	prog_parse_dst(u->dst, &vpu, &th);

	/* Store buffer state */
	state->ts[vpu][th].rs_idx = ri;
	state->ts[vpu][th].rs_len = blen - state->indexes[ri];

	/* Patch command with address */
	u->addr = (buf->dma_addr / VESZ) + idx;
	u->_z0 = 0;

	/* Store current PC */
	state->res->cmdixs[ri] = pc;

	return 0;
}


/* Handle SETRT command */
static int prog_prep_setrt(struct vxe_prog_state *state, size_t pc)
{
	union i_setrx *u = (union i_setrx*)(&state->prog[pc]);
	size_t ri = prog_next_res(state);
	unsigned vpu, th;
	struct vxe_buffer *buf;
	u32 idx;
	size_t blen;

	if(!prog_valid_res(state, ri)) {
		dev_err(ps_dev(state), "<setrt> out of resources.\n");
		return -EINVAL;
	}

	buf = state->res->bufs[ri];	/* Buffer */
	blen = buf->size / VESZ;	/* Buffer length */
	idx = state->indexes[ri];	/* User provided index to the buffer */

	if(idx > blen) {
		dev_err(ps_dev(state), "<setrt> index out of range (res: %zu).\n", ri);
		return -EINVAL;
	}

	prog_parse_dst(u->dst, &vpu, &th);

	/* Store buffer state */
	state->ts[vpu][th].rt_idx = ri;
	state->ts[vpu][th].rt_len = blen - state->indexes[ri];

	/* Patch command with address */
	u->addr = (buf->dma_addr / VESZ) + idx;
	u->_z0 = 0;

	/* Store current PC */
	state->res->cmdixs[ri] = pc;

	return 0;
}


/* Handle SETRD command */
static int prog_prep_setrd(struct vxe_prog_state *state, size_t pc)
{
	union i_setrx *u = (union i_setrx*)(&state->prog[pc]);
	size_t ri = prog_next_res(state);
	unsigned vpu, th;
	struct vxe_buffer *buf;
	u32 idx;
	size_t blen;

	if(!prog_valid_res(state, ri)) {
		dev_err(ps_dev(state), "<setrd> out of resources.\n");
		return -EINVAL;
	}

	buf = state->res->bufs[ri];	/* Buffer */
	blen = buf->size / VESZ;	/* Buffer length */
	idx = state->indexes[ri];	/* User provided index to the buffer */

	if(idx > blen) {
		dev_err(ps_dev(state), "<setrd> index out of range (res: %zu).\n", ri);
		return -EINVAL;
	}

	prog_parse_dst(u->dst, &vpu, &th);

	/* Store buffer state */
	state->ts[vpu][th].rd_idx = ri;
	state->ts[vpu][th].rd_len = blen - state->indexes[ri];

	/* Patch command with address */
	u->addr = (buf->dma_addr / VESZ) + idx;
	u->_z0 = 0;

	/* Store current PC */
	state->res->cmdixs[ri] = pc;

	return 0;
}


/* Handle SETEN command */
static int prog_prep_seten(struct vxe_prog_state *state, size_t pc)
{
	union i_seten *u = (union i_seten*)(&state->prog[pc]);
	unsigned vpu, th;

	prog_parse_dst(u->dst, &vpu, &th);

	state->ts[vpu][th].en_st = u->en;

	return 0;
}


/* Verify state for PROD command */
static int prog_verif_prod(struct vxe_prog_state *state, unsigned vpu)
{
	int th;

	for(th = 0; th < VXE_NR_THR; ++th) {
		if(state->ts[vpu][th].en_st < 0) {
			dev_err(ps_dev(state), "<prod> vpu%u, th%u: not enabled or disabled.\n", vpu, th);
			return -EINVAL;
		} else if(state->ts[vpu][th].en_st == 0)
			continue;

		if(state->ts[vpu][th].a_set == 0) {
			dev_err(ps_dev(state), "<prod> vpu%u, th%u: accumulator is not set.\n", vpu, th);
			return -EINVAL;
		}

		if(state->ts[vpu][th].rs_idx < 0) {
			dev_err(ps_dev(state), "<prod> vpu%u, th%u: rs is not set.\n", vpu, th);
			return -EINVAL;
		}

		if(state->ts[vpu][th].rt_idx < 0) {
			dev_err(ps_dev(state), "<prod> vpu%u, th%u: rt is not set.\n", vpu, th);
			return -EINVAL;
		}

		if(state->ts[vpu][th].vlen < 0) {
			dev_err(ps_dev(state), "<prod> vpu%u, th%u: vector length is not set.\n", vpu, th);
			return -EINVAL;
		}

		if(min(state->ts[vpu][th].rs_len, state->ts[vpu][th].rs_len) < state->ts[vpu][th].vlen) {
			dev_err(ps_dev(state), "<prod> vpu%u, th%u: invalid operand vector length.\n", vpu, th);
			return -EINVAL;
		}

		/* Store configured vector length */
		state->res->vlens[state->ts[vpu][th].rs_idx] = state->ts[vpu][th].vlen;
		state->res->vlens[state->ts[vpu][th].rt_idx] = state->ts[vpu][th].vlen;
	}

	return 0;
}


/* Handle PROD command */
static int prog_prep_prod(struct vxe_prog_state *state, size_t pc)
{
	union i_generic_vpu *u = (union i_generic_vpu*)(&state->prog[pc]);
	unsigned vpu, uc;
	int err = 0;

	prog_parse_dst(u->dst, &vpu, &uc);

	if(!uc) {	/* If broadcast to all VPUs */
		unsigned i;
		for(i = 0; i < VXE_NR_VPU; ++i) {
			err = prog_verif_prod(state, i);
			if(err)
				break;
		}
	} else
		err = prog_verif_prod(state, vpu);

	return err;
}


/* Verify state for STORE command */
static int prog_verif_store(struct vxe_prog_state *state, unsigned vpu)
{
	int th;

	for(th = 0; th < VXE_NR_THR; ++th) {
		if(state->ts[vpu][th].en_st < 0) {
			dev_err(ps_dev(state), "<store> vpu%u, th%u: not enabled or disabled.\n", vpu, th);
			return -EINVAL;
		} else if(state->ts[vpu][th].en_st == 0)
			continue;

		if(state->ts[vpu][th].a_set == 0) {
			dev_err(ps_dev(state), "<store> vpu%u, th%u: accumulator is not set.\n", vpu, th);
			return -EINVAL;
		}

		if(state->ts[vpu][th].rd_idx < 0) {
			dev_err(ps_dev(state), "<store> vpu%u, th%u: rd is not set.\n", vpu, th);
			return -EINVAL;
		}

		if(state->ts[vpu][th].rd_len == 0) {
			dev_err(ps_dev(state), "<store> vpu%u, th%u: invalid destination length.\n", vpu, th);
			return -EINVAL;
		}

		/* Rd destination length is always 1 */
		state->res->vlens[state->ts[vpu][th].rd_idx] = 1;
	}

	return 0;
}


/* Handle STORE command */
static int prog_prep_store(struct vxe_prog_state *state, size_t pc)
{
	union i_generic_vpu *u = (union i_generic_vpu*)(&state->prog[pc]);
	unsigned vpu, uc;
	int err = 0;

	prog_parse_dst(u->dst, &vpu, &uc);

	if(!uc) {	/* If broadcast to all VPUs */
		unsigned i;
		for(i = 0; i < VXE_NR_VPU; ++i) {
			err = prog_verif_store(state, i);
			if(err)
				break;
		}
	} else
		err = prog_verif_store(state, vpu);

	return err;
}


/* Handle SYNC command */
static int prog_prep_sync(struct vxe_prog_state *state, size_t pc)
{
	union i_sync *u = (union i_sync*)(&state->prog[pc]);

	if(u->stop || u->intr) {
		dev_err(ps_dev(state), "<sync> 'stop' and 'intr' flags are not allowed.\n");
		return -EINVAL;
	}

	return 0;
}


/* Validate and prepare program */
static int prog_prepare(struct vxe_prog_state *state)
{
	size_t i;
	int err;

	for(i = 0; i < state->prog_len; ++i) {
		union i_generic *g = (union i_generic *)(&state->prog[i]);
		err = 0;
		switch(g->op) {
			case VXE_OPCODE_SETACC:
				err = prog_prep_setacc(state, i);
				break;
			case VXE_OPCODE_SETVL:
				err = prog_prep_setvl(state, i);
				break;
			case VXE_OPCODE_SETRS:
				err = prog_prep_setrs(state, i);
				break;
			case VXE_OPCODE_SETRT:
				err = prog_prep_setrt(state, i);
				break;
			case VXE_OPCODE_SETRD:
				err = prog_prep_setrd(state, i);
				break;
			case VXE_OPCODE_SETEN:
				err = prog_prep_seten(state, i);
				break;
			case VXE_OPCODE_PROD:
				err = prog_prep_prod(state, i);
				break;
			case VXE_OPCODE_STORE:
				err = prog_prep_store(state, i);
				break;
			case VXE_OPCODE_SYNC:
				err = prog_prep_sync(state, i);
				break;
			case VXE_OPCODE_AF:
			case VXE_OPCODE_NOP:
				break;
			default:
				dev_err(ps_dev(state), "invalid opcode.");
				err = -EINVAL;
				break;
		}

		if(err)
			break;
	}

	return err;
}


struct vxe_prog_state* vxe_prog_state_create(struct vxe_context *ctx, size_t proglen, size_t nres)
{
	struct vxe_prog_state *state;
	size_t i, j;
 
	state = kzalloc(sizeof(struct vxe_prog_state), GFP_KERNEL);
	if(!state)
		return ERR_PTR(-ENOMEM);

	state->ctx = ctx;
	state->prog_len = proglen;

	state->res = vxe_prog_res_create(nres);
	if(IS_ERR(state->res))
		goto err_nomem;

	state->indexes = kmalloc(nres * sizeof(int), GFP_KERNEL);
	if(!state->indexes)
		goto err_nomem;

	state->prog = kmalloc(proglen * sizeof(u64), GFP_KERNEL);
	if(!state->prog)
		goto err_nomem;

	/* Populate initial thread states */
	for(j = 0; j < VXE_NR_VPU; ++j) {
		for(i = 0; i < VXE_NR_THR; ++i) {
			state->ts[j][i].en_st = -1;
			state->ts[j][i].a_set = 0;
			state->ts[j][i].rs_idx = -1;
			state->ts[j][i].rs_len = 0;
			state->ts[j][i].rt_idx = -1;
			state->ts[j][i].rt_len = 0;
			state->ts[j][i].rd_idx = -1;
			state->ts[j][i].rd_len = 0;
			state->ts[j][i].vlen = -1;
		}
	}

	return state;

err_nomem:
	vxe_prog_res_destroy(state->res);
	kfree(state->indexes);
	kfree(state->prog);
	kfree(state);

	return ERR_PTR(-ENOMEM);
}


void vxe_prog_state_destroy(struct vxe_prog_state *state)
{
	vxe_prog_res_destroy(state->res);
	kfree(state->indexes);
	kfree(state->prog);
	kfree(state);
}


struct vxe_prog_res* vxe_prog_res_create(size_t nres)
{
	size_t i;
	struct vxe_prog_res *res = kzalloc(sizeof(struct vxe_prog_res), GFP_KERNEL);
	if(!res)
		return ERR_PTR(-ENOMEM);

	res->nres = nres;

	res->bufs = kzalloc(nres * sizeof(struct vxe_buffer*), GFP_KERNEL);
	if(!res->bufs)
		goto err_nomem;

	res->vlens = kmalloc(nres * sizeof(int), GFP_KERNEL);
	if(!res->vlens)
		goto err_nomem;

	res->cmdixs = kmalloc(nres * sizeof(size_t), GFP_KERNEL);
	if(!res->cmdixs)
		goto err_nomem;

	/* Populate vector lengths and command indexes */
	for(i = 0; i < nres; ++i) {
		res->vlens[i] = -1;
		res->cmdixs[i] = -1;
	}

	return res;

err_nomem:
	kfree(res->bufs);
	kfree(res->vlens);
	kfree(res->cmdixs);
	kfree(res);

	return ERR_PTR(-ENOMEM);
}


void vxe_prog_res_destroy(struct vxe_prog_res *res)
{
	if(res) {
		kfree(res->bufs);
		kfree(res->vlens);
		kfree(res->cmdixs);
		kfree(res);
	}
}


int vxe_prog_assemble(struct vxe_prog_state *state)
{
	union i_sync *sync = (union i_sync*)(&state->postamble[0]);

	int err;

	err = prog_prepare(state);
	if(err)
		return err;

	/* Place "sync stop, intr" command to postamble */
	state->npost = 1;
	sync->raw = 0;
	sync->op = VXE_OPCODE_SYNC;
	sync->stop = 1;
	sync->intr = 1;

	return 0;
}


void vxe_prog_move_to_cbuf(struct vxe_prog_state *state, struct vxe_cmd_buffer *cbuf)
{
	size_t i;
	u64 *dst = (u64*)cbuf->buf.cpu_addr;

	for(i = 0; i < state->prog_len; ++i)
		dst[i] = cpu_to_le64(state->prog[i]);
	dst[i] = cpu_to_le64(state->postamble[0]);

	cbuf->res = state->res;
	state->res = NULL;
}


struct vxe_buffer** vxe_prog_swap_res(struct vxe_cmd_buffer *cbuf, struct vxe_buffer **buffers,
	u32 *indexes)
{
	union i_setrx u;
	size_t i;
	u32 idx;
	size_t blen;
	struct vxe_buffer **old_buffers;
	u64 *prog = (u64*)cbuf->buf.cpu_addr;

	/* Verify indexes and sizes first */
	for(i = 0; i < cbuf->res->nres; ++i) {
		if(cbuf->res->vlens[i] < 0)
			continue;

		blen = buffers[i]->size / VESZ;
		idx = indexes[i];

		if(idx > blen) {
			dev_err(cb_dev(cbuf), "Index out of range (res: %zu).\n", i);
			return ERR_PTR(-EINVAL);
		}

		if((blen - idx) < cbuf->res->vlens[i]) {
			dev_err(cb_dev(cbuf), "Invalid storage length (res: %zu).\n", i);
			return ERR_PTR(-EINVAL);
		}
	}

	/* Patch program */
	for(i = 0; i < cbuf->res->nres; ++i) {
		if(cbuf->res->vlens[i] < 0)
			continue;

		/* Get command */
		u.raw = le64_to_cpu(prog[cbuf->res->cmdixs[i]]);

		/* Patch command with new address */
		u.addr = (buffers[i]->dma_addr / VESZ) + indexes[i];

		/* Put updated command back */
		prog[cbuf->res->cmdixs[i]] = cpu_to_le64(u.raw);
	}

	old_buffers = cbuf->res->bufs;
	cbuf->res->bufs = buffers;

	return old_buffers;
}
