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
 * System top
 */

#include <cstdint>
#include <systemc.h>
#include "simple_cpu.hxx"
#include "memory.hxx"
#include "vxe_top.hxx"
#pragma once


// System top module
SC_MODULE(sys_top) {
	static constexpr unsigned MEM_WIDTH = 64;

	sc_in<bool> clk;
	sc_in<bool> nrst;

	simple_cpu cpu;		// CPU
	memory<MEM_WIDTH> ram;	// RAM
	vxe_top vxe;		// VxEngine

	SC_CTOR(sys_top)
		: clk("clk"), nrst("nrst")
		, cpu("cpu"), ram("ram"), vxe("vxe")
	{
		// Connect clock and reset signals
		cpu.clk(clk);
		cpu.nrst(nrst);
		ram.clk(clk);
		ram.nrst(nrst);
		vxe.clk(clk);
		vxe.nrst(nrst);

		// Connect RAM to CPU
		ram.cpu_target(cpu.mem_initiator);

		// Connect VxEngine to CPU and RAM
		vxe.io_target(cpu.io_initiator);
		ram.vxe_target0(vxe.mem_initiator0);
		ram.vxe_target1(vxe.mem_initiator1);
	}
};
