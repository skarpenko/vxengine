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
#include "vxe_ioctl.h"


long vxe_ioctl_device_getinfo(struct vxe_context *ctx, void __user *arg)
{
	struct vxe_device_info di;

	di.hwid = vxe_device_rdreg(ctx->vxdev, VXE_DEVICE_REG_ID);

	if(copy_to_user(arg, &di, sizeof(di)))
		return -EFAULT;

	return 0;
}


long vxe_ioctl_buffer_create(struct vxe_context *ctx, void __user *arg)
{
	union vxe_buffer_create bc;
	struct vxe_buffer *buf;
	s32 buf_id;
	int err;

	err = copy_from_user(&bc, arg, sizeof(bc));
	if(err)
		return -EFAULT;

	/* Create new buffer */
	buf = vxe_buffer_create(ctx, bc.in.size, false);
	if(IS_ERR(buf)) {
		return PTR_ERR(buf);
	}

	bc.out.buf.id = buf_id = buf->id;

	/* Map if requested */
	if(bc.in.flags & VXE_BUFFER_CREATE_FLAG_MAP) {
		err = vxe_buffer_mmap(ctx, buf->id, NULL);
		if(err)
			goto err_destroy_buf;
		bc.out.va.vaddr = (void*)buf->user_addr;
	}

	err = copy_to_user(arg, &bc, sizeof(bc));
	if(err) {
		err = -EFAULT;
		goto err_destroy_buf;
	}

	/* Unbind buffer before return */
	vxe_buffer_ctx_lock(ctx);
	vxe_buffer_unbind_unlocked(&buf, 1);
	vxe_buffer_ctx_unlock(ctx);

	return 0;

err_destroy_buf:
	vxe_buffer_ctx_lock(ctx);
	vxe_buffer_unbind_unlocked(&buf, 1);
	vxe_buffer_ctx_unlock(ctx);

	vxe_buffer_destroy(ctx, buf_id);

	return err;
}


long vxe_ioctl_buffer_destroy(struct vxe_context *ctx, void __user *arg)
{
	struct vxe_buffer_id bi;

	if(copy_from_user(&bi, arg, sizeof(bi)))
		return -EFAULT;

	return vxe_buffer_destroy(ctx, bi.id);
}


long vxe_ioctl_buffer_map(struct vxe_context *ctx, void __user *arg)
{
	union vxe_buffer_map bm;
	int err;

	err = copy_from_user(&bm, arg, sizeof(bm));
	if(err)
		return -EFAULT;

	err = vxe_buffer_mmap(ctx, bm.in.id, &bm.out.vaddr);
	if(err)
		return err;

	err = copy_to_user(arg, &bm, sizeof(bm));
	if(err)
		return -EFAULT;

	return 0;
}


long vxe_ioctl_buffer_unmap(struct vxe_context *ctx, void __user *arg)
{
	struct vxe_buffer_id bi;

	if(copy_from_user(&bi, arg, sizeof(bi)))
		return -EFAULT;

	return vxe_buffer_munmap(ctx, bi.id);
}


long vxe_ioctl_cmd_buffer_create(struct vxe_context *ctx, void __user *arg)
{
	union vxe_cmd_buffer_create cbc;
	struct vxe_prog_state *state;
	struct vxe_binding *bindings;
	struct vxe_buffer *buf;
	struct vxe_cmd_buffer *cmd_buf;
	s32 buf_id;
	size_t i;
	int err;

	err = copy_from_user(&cbc, arg, sizeof(cbc));
	if(err)
		return -EFAULT;

	/* Verify lengths */
	if(cbc.in.program_len > VXE_IOCTL_MAX_COMMANDS)
		return -EINVAL;
	if(cbc.in.bindings_len > VXE_IOCTL_MAX_BINDINGS)
		return -EINVAL;

	/* Creater program state */
	state = vxe_prog_state_create(ctx, cbc.in.program_len, cbc.in.bindings_len);
	if(IS_ERR(state))
		return -ENOMEM;

	/* Copy program from user */
	err = copy_from_user(state->prog, cbc.in.program, cbc.in.program_len * sizeof(u64));
	if(err) {
		vxe_prog_state_destroy(state);
		return -EFAULT;
	}

	/* Allocate space for bindings data */
	bindings = kmalloc(cbc.in.bindings_len * sizeof(struct vxe_binding), GFP_KERNEL);
	if(!bindings) {
		vxe_prog_state_destroy(state);
		return -ENOMEM;
	}

	/* Copy bindings data */
	err = copy_from_user(bindings, cbc.in.bindings, cbc.in.bindings_len * sizeof(struct vxe_binding));
	if(err) {
		kfree(bindings);
		vxe_prog_state_destroy(state);
		return -EFAULT;
	}

	/* Populate program resources */
	vxe_buffer_ctx_lock(ctx);	/* lock */

	for(i = 0; i < state->res->nres; ++i) {
		struct vxe_buffer *b = vxe_buffer_find_unlocked(ctx, bindings[i].buf.id);
		if(!b) {
			err = -ENOENT;
			break;
		} else if(vxe_buf_cmdbuf(b)) {
			err = -EINVAL;
			break;
		}

		state->res->bufs[i] = b;
		state->indexes[i] = bindings[i].index;
	}

	kfree(bindings);

	if(err) {
		vxe_buffer_ctx_unlock(ctx);	/* unlock */
		vxe_prog_state_destroy(state);
		return err;
	}

	/* Bind buffers */
	vxe_buffer_bind_unlocked(state->res->bufs, state->res->nres);

	vxe_buffer_ctx_unlock(ctx);	/* unlock */


	/* Verify and assemble program */
	err = vxe_prog_assemble(state);
	if(err) {
		vxe_buffer_ctx_lock(ctx);
		vxe_buffer_unbind_unlocked(state->res->bufs, state->res->nres);
		vxe_buffer_ctx_unlock(ctx);
		vxe_prog_state_destroy(state);
		return err;
	}

	/* Create command buffer */
	buf = vxe_buffer_create(ctx, vxe_prog_len(state)*sizeof(u64), true);
	if(IS_ERR(buf)) {
		vxe_buffer_ctx_lock(ctx);
		vxe_buffer_unbind_unlocked(state->res->bufs, state->res->nres);
		vxe_buffer_ctx_unlock(ctx);
		vxe_prog_state_destroy(state);
		return PTR_ERR(buf);
	}

	cbc.out.cmd_buf.id = buf_id = buf->id;

	cmd_buf = vxe_buf2cbuf(buf);

	/* Copy program and move resources to command buffer */
	vxe_prog_move_to_cbuf(state, cmd_buf);

	vxe_prog_state_destroy(state);

	/* Copy command buffer data to user */
	err = copy_to_user(arg, &cbc, sizeof(cbc));

	/* Unbind buffer before exit */
	vxe_buffer_ctx_lock(ctx);
	vxe_buffer_unbind_unlocked(&buf, 1);
	vxe_buffer_ctx_unlock(ctx);

	if(err) {
		vxe_buffer_destroy(ctx, buf_id);
		return -EFAULT;
	}

	return 0;
}


long vxe_ioctl_cmd_buffer_runpgm(struct vxe_context *ctx, void __user *arg)
{
	union vxe_cmd_buffer_runpgm rp;
	struct vxe_buffer *buf;
	struct vxe_job *job;
	unsigned long flags;
	int err;

	/* Check the number of already submitted jobs */
	if(atomic_inc_return(&ctx->num_jobs) > ctx->max_jobs) {
		atomic_dec(&ctx->num_jobs);
		return -EAGAIN;
	}

	err = copy_from_user(&rp, arg, sizeof(rp));
	if(err) {
		atomic_dec(&ctx->num_jobs);
		return -EFAULT;
	}

	/* Allocate new job object */
	job = kzalloc(sizeof(struct vxe_job), GFP_KERNEL);
	if(!job) {
		atomic_dec(&ctx->num_jobs);
		return -ENOMEM;
	}

	/* Get command buffer */
	vxe_buffer_ctx_lock(ctx);
	buf = vxe_buffer_find_unlocked(ctx, rp.in.id);
	if(buf) {
		if(!vxe_buf_cmdbuf(buf)) {
			err = -EINVAL;
		} else if(vxe_buf_locked(buf)) {
			err = -EPERM;
		} else {
			buf->bind_count = 1;
			buf->flags |= VXE_BUF_F_LOCKED;
			err = 0;
		}
	}
	vxe_buffer_ctx_unlock(ctx);

	if(err) {
		kfree(job);
		atomic_dec(&ctx->num_jobs);
		return err;
	}

	job->ctx = ctx;
	job->cbuf = vxe_buf2cbuf(buf);

	/* Add job to queue */
	spin_lock_irqsave(&ctx->vxdev->job_queue_lock, flags);
	rp.out.seq = job->seq = atomic64_inc_return(&ctx->vxdev->active_seq);
	list_add_tail(&job->list_node, &ctx->vxdev->job_queue);
	spin_unlock_irqrestore(&ctx->vxdev->job_queue_lock, flags);

	/* Wake up jobs scheduler */
	wake_up_interruptible(&ctx->vxdev->sched_wq);

	err = copy_to_user(arg, &rp, sizeof(rp));
	if(err)
		return -EFAULT;

	return 0;
}


long vxe_ioctl_cmd_buffer_update(struct vxe_context *ctx, void __user *arg)
{
	struct vxe_cmd_buffer_update cbu;
	size_t i;
	struct vxe_buffer *buf;
	struct vxe_cmd_buffer *cbuf;
	struct vxe_buffer **old_buffers;
	struct vxe_binding *bindings = NULL;
	struct vxe_buffer **buffers = NULL;
	u32 *indexes = NULL;
	int err = 0;

	if(copy_from_user(&cbu, arg, sizeof(cbu)))
		return -EFAULT;

	/* Get command buffer */
	vxe_buffer_ctx_lock(ctx);
	buf = vxe_buffer_find_unlocked(ctx, cbu.cmd_buf.id);
	if(buf) {
		if(!vxe_buf_cmdbuf(buf)) {
			err = -EINVAL;
		} else if(vxe_buf_locked(buf)) {
			err = -EPERM;
		} else {
			buf->bind_count = 1;
			buf->flags |= VXE_BUF_F_LOCKED;
			err = 0;
		}
	}
	vxe_buffer_ctx_unlock(ctx);

	if(err)
		return err;

	cbuf = vxe_buf2cbuf(buf);

	/* Number of provided resources must match existing set size */
	if(cbuf->res->nres != cbu.bindings_len) {
		err = -EINVAL;
		goto exit_unlock_cbuf;
	}

	bindings = kmalloc(cbu.bindings_len * sizeof(struct vxe_binding), GFP_KERNEL);
	buffers = kzalloc(cbu.bindings_len * sizeof(struct vxe_buffer*), GFP_KERNEL);
	indexes = kzalloc(cbu.bindings_len * sizeof(u32), GFP_KERNEL);
	if(!bindings || !buffers || !indexes) {
		err = -ENOMEM;
		goto exit_free_inputs;
	}

	/* Copy bindings data */
	err = copy_from_user(bindings, cbu.bindings, cbu.bindings_len * sizeof(struct vxe_binding));
	if(err) {
		err = -EFAULT;
		goto exit_free_inputs;
	}

	/* Populate program resources */
	vxe_buffer_ctx_lock(ctx);	/* lock */
	for(i = 0; i < cbu.bindings_len; ++i) {
		struct vxe_buffer *b = vxe_buffer_find_unlocked(ctx, bindings[i].buf.id);
		if(!b) {
			err = -ENOENT;
			break;
		} else if(vxe_buf_cmdbuf(b)) {
			err = -EINVAL;
			break;
		}

		buffers[i] = b;
		indexes[i] = bindings[i].index;
	}

	if(err) {
		vxe_buffer_ctx_unlock(ctx);	/* Unlock */
		goto exit_free_inputs;
	}

	vxe_buffer_bind_unlocked(buffers, cbu.bindings_len);

	vxe_buffer_ctx_unlock(ctx);	/* Unlock */

	/* Swap old and new resources and update program */
	old_buffers = vxe_prog_swap_res(cbuf, buffers, indexes);
	if(IS_ERR(old_buffers)) {
		err = PTR_ERR(old_buffers);
		goto exit_free_inputs;
	}

	/* Unbind old resources */
	vxe_buffer_ctx_lock(ctx);
	vxe_buffer_unbind_unlocked(old_buffers, cbu.bindings_len);
	vxe_buffer_ctx_unlock(ctx);

	kfree(old_buffers);

	buffers = NULL;	/* Now "buffers" is owned by command buffer */

exit_free_inputs:
	kfree(bindings);
	kfree(buffers);
	kfree(indexes);

exit_unlock_cbuf:
	/* Unbind buffer before exit */
	vxe_buffer_ctx_lock(ctx);
	vxe_buffer_unbind_unlocked(&buf, 1);
	vxe_buffer_ctx_unlock(ctx);

	return err;
}


long vxe_ioctl_fence_wait(struct vxe_context *ctx, void __user *arg)
{
	struct vxe_fence f;

	if(copy_from_user(&f, arg, sizeof(f)))
		return -EFAULT;

	/* Check if the value represents completed/active job */
	if(f.seq > atomic64_read(&ctx->vxdev->active_seq))
		return -EINVAL;

	/* Wait for job completion */
	return wait_event_interruptible(ctx->vxdev->user_wq,
		atomic64_read(&ctx->vxdev->finished_seq) >= f.seq);
}
