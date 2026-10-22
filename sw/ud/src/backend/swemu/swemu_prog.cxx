/*
 * Copyright (c) 2020-2026 The VxEngine Project. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/*
 * Program verification and assembly
 */

#define DEBUG_PREFIX	"[asm] "

#include <errno.h>
#include <algorithm>
#include "../../debug.hxx"
#include "swemu_impl.hxx"
#include "swemu_prog.hxx"


namespace cmd {

#include <vxe_instr.hxx>

}


void ProgramAssembler::parseDst(unsigned dst, unsigned *vpu, unsigned *th)
{
	*th = dst & (VXE_NR_THR - 1);
	*vpu = (dst >> 3) & (VXE_NR_VPU - 1);
}


uint32_t ProgramAssembler::nextRes()
{
	return m_currentRes < m_cmdBuf->resLength() ? m_currentRes++ : m_cmdBuf->resLength();
}


bool ProgramAssembler::isValidRes(uint32_t ri)
{
	return ri < m_cmdBuf->resLength();
}


int ProgramAssembler::verifPROD(unsigned vpu)
{
	for(unsigned th = 0; th < VXE_NR_THR; ++th) {
		if(m_threads[vpu][th].en_st < 0) {
			debug_printf("Error: <prod> vpu%u, th%u: not enabled or disabled.\n", vpu, th);
			return EINVAL;
		} else if(m_threads[vpu][th].en_st == 0)
			continue;

		if(m_threads[vpu][th].a_set == 0) {
			debug_printf("Error: <prod> vpu%u, th%u: accumulator is not set.\n", vpu, th);
			return EINVAL;
		}

		if(m_threads[vpu][th].rs_idx < 0) {
			debug_printf("Error: <prod> vpu%u, th%u: rs is not set.\n", vpu, th);
			return EINVAL;
		}

		if(m_threads[vpu][th].rt_idx < 0) {
			debug_printf("Error: <prod> vpu%u, th%u: rt is not set.\n", vpu, th);
			return EINVAL;
		}

		if(m_threads[vpu][th].vlen < 0) {
			debug_printf("Error: <prod> vpu%u, th%u: vector length is not set.\n", vpu, th);
			return EINVAL;
		}

		if(std::min(m_threads[vpu][th].rs_len, m_threads[vpu][th].rt_len) < m_threads[vpu][th].vlen) {
			debug_printf("Error: <prod> vpu%u, th%u: invalid operand vector length.\n", vpu, th);
			return EINVAL;
		}

		// Store configured vector length
		m_cmdBuf->resData()[m_threads[vpu][th].rs_idx].vlen = m_threads[vpu][th].vlen;
		m_cmdBuf->resData()[m_threads[vpu][th].rt_idx].vlen = m_threads[vpu][th].vlen;
	}

	return 0;
}


int ProgramAssembler::verifSTORE(unsigned vpu)
{
	for(unsigned th = 0; th < VXE_NR_THR; ++th) {
		if(m_threads[vpu][th].en_st < 0) {
			debug_printf("Error: <store> vpu%u, th%u: not enabled or disabled.\n", vpu, th);
			return EINVAL;
		} else if(m_threads[vpu][th].en_st == 0)
			continue;

		if(m_threads[vpu][th].a_set == 0) {
			debug_printf("Error: <store> vpu%u, th%u: accumulator is not set.\n", vpu, th);
			return EINVAL;
		}

		if(m_threads[vpu][th].rd_idx < 0) {
			debug_printf("Error: <store> vpu%u, th%u: rd is not set.\n", vpu, th);
			return EINVAL;
		}

		if(m_threads[vpu][th].rd_len == 0) {
			debug_printf("Error: <store> vpu%u, th%u: invalid destination length.\n", vpu, th);
			return EINVAL;
		}

		// Rd destination length is always 1
		m_cmdBuf->resData()[m_threads[vpu][th].rd_idx].vlen = 1;
	}

	return 0;
}


int ProgramAssembler::prepSETACC(uint32_t pc)
{
	cmd::generic_vpu *u = reinterpret_cast<cmd::generic_vpu*>(&m_cmdBuf->progData()[pc]);
	unsigned vpu, th;

	parseDst(u->dst, &vpu, &th);

	m_threads[vpu][th].a_set = 1;

	return 0;
}


int ProgramAssembler::prepSETVL(uint32_t pc)
{
	cmd::setvl *u = reinterpret_cast<cmd::setvl*>(&m_cmdBuf->progData()[pc]);
	unsigned vpu, th;

	parseDst(u->dst, &vpu, &th);

	m_threads[vpu][th].vlen = u->len;

	return 0;
}


int ProgramAssembler::prepSETRS(uint32_t pc)
{
	cmd::setrs *u = reinterpret_cast<cmd::setrs*>(&m_cmdBuf->progData()[pc]);
	uint32_t ri = nextRes();
	unsigned vpu, th;
	SwEmuDataBuffer *buf;
	uint32_t idx;
	uint32_t blen;

	if(!isValidRes(ri)) {
		debug_printf("Error: <setrs> out of resources.\n");
		return EINVAL;
	}

	buf = m_cmdBuf->resData()[ri].data;	// Buffer
	blen = buf->length();			// Buffer length
	idx = m_cmdBuf->resData()[ri].index;	// User provided index to the buffer

	if(idx > blen) {
		debug_printf("Error: <setrs> index out of range (res: %u).\n", ri);
		return EINVAL;
	}

	parseDst(u->dst, &vpu, &th);

	// Store buffer state
	m_threads[vpu][th].rs_idx = ri;
	m_threads[vpu][th].rs_len = blen - idx;

	// Patch command with resource index
	u->addr = ri;
	u->_z0 = 0;

	// Store current PC
	m_cmdBuf->resData()[ri].cmdpc = pc;

	return 0;
}


int ProgramAssembler::prepSETRT(uint32_t pc)
{
	cmd::setrt *u = reinterpret_cast<cmd::setrt*>(&m_cmdBuf->progData()[pc]);
	uint32_t ri = nextRes();
	unsigned vpu, th;
	SwEmuDataBuffer *buf;
	uint32_t idx;
	uint32_t blen;

	if(!isValidRes(ri)) {
		debug_printf("Error: <setrt> out of resources.\n");
		return EINVAL;
	}

	buf = m_cmdBuf->resData()[ri].data;	// Buffer
	blen = buf->length();			// Buffer length
	idx = m_cmdBuf->resData()[ri].index;	// User provided index to the buffer

	if(idx > blen) {
		debug_printf("Error: <setrt> index out of range (res: %u).\n", ri);
		return EINVAL;
	}

	parseDst(u->dst, &vpu, &th);

	// Store buffer state
	m_threads[vpu][th].rt_idx = ri;
	m_threads[vpu][th].rt_len = blen - idx;

	// Patch command with resource index
	u->addr = ri;
	u->_z0 = 0;

	// Store current PC
	m_cmdBuf->resData()[ri].cmdpc = pc;

	return 0;
}


int ProgramAssembler::prepSETRD(uint32_t pc)
{
	cmd::setrd *u = reinterpret_cast<cmd::setrd*>(&m_cmdBuf->progData()[pc]);
	uint32_t ri = nextRes();
	unsigned vpu, th;
	SwEmuDataBuffer *buf;
	uint32_t idx;
	uint32_t blen;

	if(!isValidRes(ri)) {
		debug_printf("Error: <setrd> out of resources.\n");
		return EINVAL;
	}

	buf = m_cmdBuf->resData()[ri].data;	// Buffer
	blen = buf->length();			// Buffer length
	idx = m_cmdBuf->resData()[ri].index;	// User provided index to the buffer

	if(idx > blen) {
		debug_printf("Error: <setrd> index out of range (res: %u).\n", ri);
		return EINVAL;
	}

	parseDst(u->dst, &vpu, &th);

	// Store buffer state
	m_threads[vpu][th].rd_idx = ri;
	m_threads[vpu][th].rd_len = blen - idx;

	// Patch command with resource index
	u->addr = ri;
	u->_z0 = 0;

	// Store current PC
	m_cmdBuf->resData()[ri].cmdpc = pc;

	return 0;
}


int ProgramAssembler::prepSETEN(uint32_t pc)
{
	cmd::seten *u = reinterpret_cast<cmd::seten*>(&m_cmdBuf->progData()[pc]);
	unsigned vpu, th;

	parseDst(u->dst, &vpu, &th);

	m_threads[vpu][th].en_st = u->en;

	return 0;
}


int ProgramAssembler::prepPROD(uint32_t pc)
{
	cmd::generic_vpu *u = reinterpret_cast<cmd::generic_vpu*>(&m_cmdBuf->progData()[pc]);
	unsigned vpu, uc;
	int err = 0;

	parseDst(u->dst, &vpu, &uc);

	if(!uc) {	// If broadcast to all VPUs
		for(unsigned i = 0; i < VXE_NR_VPU; ++i) {
			err = verifPROD(i);
			if(err)
				break;
		}
	} else
		err = verifPROD(vpu);

	return err;
}


int ProgramAssembler::prepSTORE(uint32_t pc)
{
	cmd::generic_vpu *u = reinterpret_cast<cmd::generic_vpu*>(&m_cmdBuf->progData()[pc]);
	unsigned vpu, uc;
	int err = 0;

	parseDst(u->dst, &vpu, &uc);

	if(!uc) {	// If broadcast to all VPUs
		for(unsigned i = 0; i < VXE_NR_VPU; ++i) {
			err = verifSTORE(i);
			if(err)
				break;
		}
	} else
		err = verifSTORE(vpu);

	return err;
}


int ProgramAssembler::prepSYNC(uint32_t pc)
{
	cmd::sync *u = reinterpret_cast<cmd::sync*>(&m_cmdBuf->progData()[pc]);

	if(u->stop || u->intr) {
		debug_printf("Error: <sync> 'stop' and 'intr' flags are not allowed.\n");
		return EINVAL;
	}

	return 0;
}


ProgramAssembler::ProgramAssembler(SwEmuCmdBuffer *cmdBuf)
{
	reset(cmdBuf);
}


int ProgramAssembler::prepareProg()
{
	int err;
	uint32_t i;

	for(i = 0; i < m_cmdBuf->progLength() - NRSVD; ++i) {
		cmd::generic *g = reinterpret_cast<cmd::generic*>(&m_cmdBuf->progData()[i]);
		switch(g->op) {
			case cmd::setacc::OP:
				err = prepSETACC(i);
				break;
			case cmd::setvl::OP:
				err = prepSETVL(i);
				break;
			case cmd::setrs::OP:
				err = prepSETRS(i);
				break;
			case cmd::setrt::OP:
				err = prepSETRT(i);
				break;
			case cmd::setrd::OP:
				err = prepSETRD(i);
				break;
			case cmd::seten::OP:
				err = prepSETEN(i);
				break;
			case cmd::prod::OP:
				err = prepPROD(i);
				break;
			case cmd::store::OP:
				err = prepSTORE(i);
				break;
			case cmd::sync::OP:
				err = prepSYNC(i);
				break;
			case cmd::generic_af::OP:
			case cmd::nop::OP:
				break;
			default:
				debug_printf("Error: invalid opcode.");
				err = EINVAL;
				break;
		}

		if(err)
			break;
	}

	if(err)
		return err;

	cmd::sync *sync = reinterpret_cast<cmd::sync*>(&m_cmdBuf->progData()[i]);


	// Place "sync stop, intr" command to the end of the program
	sync->u64 = 0;
	sync->op = cmd::sync::OP;
	sync->stop = 1;
	sync->intr = 1;

	return 0;
}


void ProgramAssembler::reset(SwEmuCmdBuffer *cmdBuf)
{
	m_cmdBuf = cmdBuf;
	m_currentRes = 0;
	for(unsigned j = 0; j < VXE_NR_VPU; ++j)
		for(unsigned i = 0; i < VXE_NR_THR; ++i)
			m_threads[j][i].reset();
}
