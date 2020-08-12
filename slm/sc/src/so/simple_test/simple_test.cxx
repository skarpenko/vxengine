/*
 * Copyright (c) 2020 The VxEngine Project. All rights reserved.
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
 * Simple test application for simple CPU model
 */

#include <cstdint>
#include <iostream>
#include "vxe_common.hxx"
#define SIMPLE_CPU_IF_SHORTCUTS
#include "simple_cpu_if.h"

struct simple_cpu_if *g_cpu_if;
#define SIMPLE_CPU_IF	g_cpu_if


simple_cpu_dmi dmi;
uint8_t *mem;

extern "C" int simple_cpu_entry(struct simple_cpu_if *cpu_if)
{
	g_cpu_if = cpu_if;

	std::cout << "Started on CPU: " << cpu_if->cpuid << std::endl;

	cpu_if->get_dmi(cpu_if->cpuid, &dmi);
	mem = reinterpret_cast<uint8_t*>(dmi.ptr);

	uint32_t v = mmio_rreg32(0);
	printf("0x%08x\n", v);

	mmio_wreg32(0, 13123);
	v = mmio_rreg32(0);
	printf("0x%08x\n", v);

	v = mmio_rreg32(4);
	printf("0x%08x\n", v);

	mmio_wreg32(4, 13123);
	v = mmio_rreg32(4);
	printf("0x%08x\n", v);

	{
		uint64_t *instr = reinterpret_cast<uint64_t*>(mem + 1024);
		uint64_t addr = dmi.start + 1024;

		printf("addr = %0lx\n", addr);

		mmio_wreg32(vxe::rego::REG_PGM_ADDR_LO, addr & 0xFFFFFFFF);
		mmio_wreg32(vxe::rego::REG_PGM_ADDR_HI, addr >> 32u);

		printf("addr_lo = %08x\n", mmio_rreg32(vxe::rego::REG_PGM_ADDR_LO));
		printf("addr_hi = %08x\n", mmio_rreg32(vxe::rego::REG_PGM_ADDR_HI));

		int pc = 0;	// Program counter
//		instr[pc++] = 0xDEADBEEFBEEFDEAD;
//		instr[pc++] = 0xCAFEBABECAFEBABE;
		instr[pc++] = vxe::instr::nop();
		instr[pc++] = vxe::instr::nop();
		instr[pc++] = vxe::instr::setacc(9, 0xAABBCCDD);
		instr[pc++] = vxe::instr::setacc(7, 0xAABBCCDD);
		instr[pc++] = vxe::instr::setrs(9, 0xAABBCCDD);
		instr[pc++] = vxe::instr::setrt(7, 0xAABBCCDD);
//		instr[pc++] = 0xDEADBEEFBEEFDEAD;
		instr[pc++] = vxe::instr::sync(true, true);

		mmio_wreg32(vxe::rego::REG_START, 0);

		printf("status = %08x\n", mmio_rreg32(vxe::rego::REG_STATUS));
	}

	wait_intr();

	printf("act_int = %08x\n", mmio_rreg32(vxe::rego::REG_INTR_ACT));
	printf("status = %08x\n", mmio_rreg32(vxe::rego::REG_STATUS));

	mmio_wreg32(vxe::rego::REG_INTR_ACT, mmio_rreg32(vxe::rego::REG_INTR_ACT));
	printf("(ack) act_int = %08x\n", mmio_rreg32(vxe::rego::REG_INTR_ACT));

	wait_cycles(50);

	return 0;
}
