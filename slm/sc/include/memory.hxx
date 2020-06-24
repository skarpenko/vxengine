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
 * Memory model
 */

#include "memory_port.hxx"
#pragma once


// Memory model template
template<unsigned MEM_WIDTH>
SC_MODULE(memory) {
	sc_in<bool> clk;
	sc_in<bool> nrst;

	tlm::tlm_target_socket<MEM_WIDTH> cpu_target;
	tlm::tlm_target_socket<MEM_WIDTH> vxe_target0;
	tlm::tlm_target_socket<MEM_WIDTH> vxe_target1;

	SC_CTOR(memory)
		: clk("clk"), nrst("nrst")
		, cpu_port("cpu_port", mem, cpu_target)
		, vxe_port0("vxe_port0", mem, vxe_target0)
		, vxe_port1("vxe_port1", mem, vxe_target1)
	{
		// Connect clock and reset signals
		cpu_port.clk(clk);
		cpu_port.nrst(nrst);
		vxe_port0.clk(clk);
		vxe_port0.nrst(nrst);
		vxe_port1.clk(clk);
		vxe_port1.nrst(nrst);

		// Init ports
		cpu_target(cpu_port);
		vxe_target0(vxe_port0);
		vxe_target1(vxe_port1);

		mem.resize(0x1000); // default size
	}

public:
	// Storage
	std::vector<uint8_t> mem;

private:
	// Ports
	memory_port<MEM_WIDTH> cpu_port;
	memory_port<MEM_WIDTH> vxe_port0;
	memory_port<MEM_WIDTH> vxe_port1;
};
