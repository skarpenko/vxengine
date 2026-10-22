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
 * Code generator
 */

#include "codegen.hxx"

namespace cmd {

#include <vxe_instr.hxx>

}


unsigned CodeGenerator::makeDst(uint16_t vpu, uint16_t th)
{
	th = th & 7;
	return vpu << 3 | th;
}


CodeGenerator::CodeGenerator(uint32_t vpus, uint32_t vpuMask)
{
	uint32_t disVpus = vpus & ~vpuMask;
	uint32_t enVpus = vpus & vpuMask;
	uint16_t vpu;

	// Disabled VPUs
	vpu = 0;
	while(disVpus) {
		if(disVpus & 1) {
			for(uint16_t t = 0; t < 8; ++t)
				m_inactive.push_back(Thread(vpu, t));
		}
		disVpus >>= 1;
		++vpu;
	}

	// Enabled VPUs
	vpu = 0;
	while(enVpus) {
		if(enVpus & 1) {
			for(uint16_t t = 0; t < 8; ++t)
				m_threads.push_back(Thread(vpu, t));
		}
		enVpus >>= 1;
		++vpu;
	}

	reset();
}


void CodeGenerator::reset()
{
	m_curThread = 0;
	program.clear();
	bindings.clear();

	for(size_t i = 0; i < m_threads.size(); ++i)
		m_threads[i].en = -1;
}


void CodeGenerator::prepare()
{
	// Unused threads must be explicitly disabled
	for(const Thread& t : m_inactive)
		program.push_back(cmd::seten(makeDst(t.vpu, t.thr), false));
}


bool CodeGenerator::allocThread(float accum, VxeBinding rs, VxeBinding rt, VxeBinding rd, size_t length)
{
	if(availThreads() == 0)
		return false;

	Thread& t = m_threads[m_curThread++];

	// Enable thread
	if(t.en != 1) {
		t.en = 1;
		program.push_back(cmd::seten(makeDst(t.vpu, t.thr), true));
	}

	// Set accumulator
	program.push_back(cmd::setacc(makeDst(t.vpu, t.thr), accum));

	// Set Rs
	program.push_back(cmd::setrs(makeDst(t.vpu, t.thr), bindings.size() << 4));
	bindings.push_back(rs);

	// Set Rt
	program.push_back(cmd::setrt(makeDst(t.vpu, t.thr), bindings.size() << 4));
	bindings.push_back(rt);

	// Set Rd
	program.push_back(cmd::setrd(makeDst(t.vpu, t.thr), bindings.size() << 4));
	bindings.push_back(rd);

	// Set vector length
	program.push_back(cmd::setvl(makeDst(t.vpu, t.thr), length));

	return true;
}


void CodeGenerator::finalize()
{
	// Disable unallocated threads
	for(size_t i = m_curThread; i < m_threads.size(); ++i) {
		if(m_threads[i].en == 0)
			continue;
		m_threads[i].en = 0;
		program.push_back(cmd::seten(makeDst(m_threads[i].vpu, m_threads[i].thr), false));
	}

	m_curThread = 0;
}


void CodeGenerator::execProd()
{
	program.push_back(cmd::prod());
}


void CodeGenerator::execStore()
{
	program.push_back(cmd::store());
}


void CodeGenerator::execRELU()
{
	program.push_back(cmd::relu());
}


void CodeGenerator::execLRELU(int ed)
{
	program.push_back(cmd::lrelu(ed));
}


void CodeGenerator::execSync()
{
	program.push_back(cmd::sync());
}
