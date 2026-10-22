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
 * Program executor
 */

#define DEBUG_PREFIX	"[exec] "

#include <cmath>
#include <new>
#include "../../debug.hxx"
#include "swemu_impl.hxx"
#include "swemu_exec.hxx"


namespace cmd {

#include <vxe_instr.hxx>

}


bool ProgramExecutor::isEnabledVPU(unsigned vpu)
{
	vpu = vpu & (VXE_NR_VPU - 1);
	return ((1 << vpu) & m_vpuMask) != 0;
}


void ProgramExecutor::parseDst(unsigned dst, unsigned *vpu, unsigned *th)
{
	*th = dst & (VXE_NR_THR - 1);
	*vpu = (dst >> 3) & (VXE_NR_VPU - 1);
}


void ProgramExecutor::execSETACC(uint32_t pc)
{
	cmd::setacc *u = reinterpret_cast<cmd::setacc*>(&m_cmdBuf->progData()[pc]);
	unsigned vpu, th;

	parseDst(u->dst, &vpu, &th);
	if(!isEnabledVPU(vpu))
		return;

	// to avoid strict-aliasing rule violation
	union cvt {
		float a;
		uint32_t b;
	};
	uint32_t fp32 = u->acc;
	cvt c = { .b = fp32 };

	m_threads[vpu][th].acc = c.a;
}


void ProgramExecutor::execSETVL(uint32_t pc)
{
	cmd::setvl *u = reinterpret_cast<cmd::setvl*>(&m_cmdBuf->progData()[pc]);
	unsigned vpu, th;

	parseDst(u->dst, &vpu, &th);
	if(!isEnabledVPU(vpu))
		return;

	m_threads[vpu][th].vlen = u->len;
}


void ProgramExecutor::execSETRS(uint32_t pc)
{
	cmd::setrs *u = reinterpret_cast<cmd::setrs*>(&m_cmdBuf->progData()[pc]);
	uint32_t ri;
	unsigned vpu, th;
	SwEmuDataBuffer *buf;
	uint32_t idx;

	parseDst(u->dst, &vpu, &th);
	if(!isEnabledVPU(vpu))
		return;

	// Extract resource index from the command
	ri = static_cast<uint32_t>(u->addr);

	buf = m_cmdBuf->resData()[ri].data;	// Buffer
	idx = m_cmdBuf->resData()[ri].index;	// User provided index to the buffer

	// Set vector address
	m_threads[vpu][th].rs = &buf->floatData()[idx];
}


void ProgramExecutor::execSETRT(uint32_t pc)
{
	cmd::setrt *u = reinterpret_cast<cmd::setrt*>(&m_cmdBuf->progData()[pc]);
	uint32_t ri;
	unsigned vpu, th;
	SwEmuDataBuffer *buf;
	uint32_t idx;

	parseDst(u->dst, &vpu, &th);
	if(!isEnabledVPU(vpu))
		return;

	// Extract resource index from the command
	ri = static_cast<uint32_t>(u->addr);

	buf = m_cmdBuf->resData()[ri].data;	// Buffer
	idx = m_cmdBuf->resData()[ri].index;	// User provided index to the buffer

	// Set vector address
	m_threads[vpu][th].rt = &buf->floatData()[idx];
}


void ProgramExecutor::execSETRD(uint32_t pc)
{
	cmd::setrd *u = reinterpret_cast<cmd::setrd*>(&m_cmdBuf->progData()[pc]);
	uint32_t ri;
	unsigned vpu, th;
	SwEmuDataBuffer *buf;
	uint32_t idx;

	parseDst(u->dst, &vpu, &th);
	if(!isEnabledVPU(vpu))
		return;

	// Extract resource index from the command
	ri = static_cast<uint32_t>(u->addr);

	buf = m_cmdBuf->resData()[ri].data;	// Buffer
	idx = m_cmdBuf->resData()[ri].index;	// User provided index to the buffer

	// Set vector address
	m_threads[vpu][th].rd = &buf->floatData()[idx];
}


void ProgramExecutor::execSETEN(uint32_t pc)
{
	cmd::seten *u = reinterpret_cast<cmd::seten*>(&m_cmdBuf->progData()[pc]);
	unsigned vpu, th;

	parseDst(u->dst, &vpu, &th);
	if(!isEnabledVPU(vpu))
		return;

	m_threads[vpu][th].en = (u->en != 0);
}


void ProgramExecutor::execPROD_ST(uint32_t pc)
{
	cmd::generic_vpu *u = reinterpret_cast<cmd::generic_vpu*>(&m_cmdBuf->progData()[pc]);
	unsigned vpu, uc;

	parseDst(u->dst, &vpu, &uc);

	if(!uc) {	// If broadcast to all VPUs
		for(unsigned vpu = 0; vpu < VXE_NR_VPU; ++vpu) {
			if(!isEnabledVPU(vpu))
				continue;
			for(unsigned th = 0; th < VXE_NR_THR; ++th) {
				compVecProd(vpu, th);
			}
		}
	} else if(isEnabledVPU(vpu)) {
		for(unsigned th = 0; th < VXE_NR_THR; ++th) {
			compVecProd(vpu, th);
		}
	}
}


void ProgramExecutor::execPROD_MT(uint32_t pc)
{
	cmd::generic_vpu *u = reinterpret_cast<cmd::generic_vpu*>(&m_cmdBuf->progData()[pc]);
	unsigned vpu, uc;

	parseDst(u->dst, &vpu, &uc);

	if(!uc) {	// If broadcast to all VPUs
		// Start work
		for(unsigned vpu = 0; vpu < VXE_NR_VPU; ++vpu) {
			if(!isEnabledVPU(vpu))
				continue;
			for(unsigned th = 0; th < VXE_NR_THR; ++th) {
				m_MT[vpu * VXE_NR_THR + th].ready.signal();
			}
		}
		// Wait for completion
		for(unsigned vpu = 0; vpu < VXE_NR_VPU; ++vpu) {
			if(!isEnabledVPU(vpu))
				continue;
			for(unsigned th = 0; th < VXE_NR_THR; ++th) {
				m_MT[vpu * VXE_NR_THR + th].done.wait();
			}
		}
	} else if(isEnabledVPU(vpu)) {
		// Start work
		for(unsigned th = 0; th < VXE_NR_THR; ++th) {
			m_MT[vpu * VXE_NR_THR + th].ready.signal();
		}
		// Wait for completion
		for(unsigned th = 0; th < VXE_NR_THR; ++th) {
			m_MT[vpu * VXE_NR_THR + th].done.wait();
		}
	}
}


void ProgramExecutor::execSTORE(uint32_t pc)
{
	cmd::generic_vpu *u = reinterpret_cast<cmd::generic_vpu*>(&m_cmdBuf->progData()[pc]);
	unsigned vpu, uc;

	parseDst(u->dst, &vpu, &uc);

	if(!uc) {	// If broadcast to all VPUs
		for(unsigned vpu = 0; vpu < VXE_NR_VPU; ++vpu) {
			if(!isEnabledVPU(vpu))
				continue;
			for(unsigned th = 0; th < VXE_NR_THR; ++th)
				if(m_threads[vpu][th].en)
					m_threads[vpu][th].rd[0] = m_threads[vpu][th].acc;
		}
	} else if(isEnabledVPU(vpu)) {
		for(unsigned th = 0; th < VXE_NR_THR; ++th)
			if(m_threads[vpu][th].en)
				m_threads[vpu][th].rd[0] = m_threads[vpu][th].acc;
	}
}


void ProgramExecutor::execACTF(uint32_t pc)
{
	cmd::generic_af *u = reinterpret_cast<cmd::generic_af*>(&m_cmdBuf->progData()[pc]);
	cmd::lrelu *lr = reinterpret_cast<cmd::lrelu*>(&m_cmdBuf->progData()[pc]);
	bool islr = (u->af == cmd::lrelu::AF);
	struct { signed int x:7; } s;
	int e = s.x = lr->ed;
	unsigned vpu, uc;

	auto relu = [&](unsigned v, unsigned t) -> float {
		if(std::isnan(m_threads[v][t].acc) || std::isinf(m_threads[v][t].acc))
			return m_threads[v][t].acc;
		return (m_threads[v][t].acc > 0.0f ? m_threads[v][t].acc : 0.0f);
	};

	auto lrelu = [&](unsigned v, unsigned t) -> float {
		if(std::isnan(m_threads[v][t].acc) || std::isinf(m_threads[v][t].acc))
			return m_threads[v][t].acc;
		float scale = 1.0f / static_cast<float>(1 << -e);
		return (m_threads[v][t].acc > 0.0f ? m_threads[v][t].acc : m_threads[v][t].acc * scale);
	};

	parseDst(u->dst, &vpu, &uc);

	if(!uc) {	// If broadcast to all VPUs
		for(unsigned vpu = 0; vpu < VXE_NR_VPU; ++vpu) {
			if(!isEnabledVPU(vpu))
				continue;
			for(unsigned th = 0; th < VXE_NR_THR; ++th)
				if(m_threads[vpu][th].en)
					m_threads[vpu][th].acc = islr ? lrelu(vpu, th) : relu(vpu, th);
		}
	} else if(isEnabledVPU(vpu)) {
		for(unsigned th = 0; th < VXE_NR_THR; ++th)
			if(m_threads[vpu][th].en)
				m_threads[vpu][th].acc = islr ? lrelu(vpu, th) : relu(vpu, th);
	}
}


void ProgramExecutor::compVecProd(unsigned vpu, unsigned th)
{
	if(!m_threads[vpu][th].en)
		return;

	for(uint32_t i = 0; i < m_threads[vpu][th].vlen; ++i)
		m_threads[vpu][th].acc += m_threads[vpu][th].rs[i] * m_threads[vpu][th].rt[i];
}


ProgramExecutor::ProgramExecutor(uint32_t vpuMask, bool mt)
	: m_MT(nullptr), m_vpuMask(vpuMask)
{
	if(!mt)
		return;

	m_MT = new(std::nothrow) MTSupport[VXE_NR_VPU * VXE_NR_THR];
	if(m_MT == nullptr)
		return;

	try {
		size_t mti = 0;
		for(unsigned vpu = 0; vpu < VXE_NR_VPU; ++vpu) {
			for(unsigned th = 0; th < VXE_NR_THR; ++th) {
				m_MT[mti].thrd = std::thread([this](MTSupport *mt, unsigned vpu, unsigned th) {
					while(!mt->stop.load()) {
						mt->ready.wait();
						if(mt->stop.load())
							break;
						compVecProd(vpu, th);
						mt->done.signal();
					}
				}, &m_MT[mti], vpu, th);
				++mti;
			}
		}
	}
	catch(...)
	{
		delete[] m_MT;
		m_MT = nullptr;
	}
}


ProgramExecutor::~ProgramExecutor()
{
	delete[] m_MT;
}


void ProgramExecutor::execute(SwEmuCmdBuffer *cmdBuf)
{
	uint32_t i;

	m_cmdBuf = cmdBuf;

	for(i = 0; i < m_cmdBuf->progLength(); ++i) {
		cmd::generic *g = reinterpret_cast<cmd::generic *>(&m_cmdBuf->progData()[i]);
		switch (g->op) {
			case cmd::setacc::OP:
				execSETACC(i);
				break;
			case cmd::setvl::OP:
				execSETVL(i);
				break;
			case cmd::setrs::OP:
				execSETRS(i);
				break;
			case cmd::setrt::OP:
				execSETRT(i);
				break;
			case cmd::setrd::OP:
				execSETRD(i);
				break;
			case cmd::seten::OP:
				execSETEN(i);
				break;
			case cmd::prod::OP:
				if(isMT())
					execPROD_MT(i);
				else
					execPROD_ST(i);
				break;
			case cmd::store::OP:
				execSTORE(i);
				break;
			case cmd::generic_af::OP:
				execACTF(i);
				break;
			case cmd::sync::OP:
			case cmd::nop::OP:
				break;
			default:
				debug_printf("Error: invalid opcode.\n");
				break;
		}
	}
}
