/*
 * Copyright (c) 2020-2025 The VxEngine Project. All rights reserved.
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
#include "fake_cpu.hxx"
#include "memory.hxx"
#include "vxe_top_wrapper.hxx"
#pragma once


// System top module
SC_MODULE(sys_top) {
	sc_in<bool> clk;
	sc_in<bool> nrst;

	// VxEngine wrapper
	vxe_top_wrapper vxe_wrapper;

	// Memory
	memory mem;

	// CPU
	fake_cpu cpu;

	SC_CTOR(sys_top)
		: clk("clk"), nrst("nrst")
		, vxe_wrapper("vxe_wrapper")
		, mem("mem"), cpu("cpu")
	{
		// Connect VxEngine signals
		vxe_wrapper.clk(clk);
		vxe_wrapper.nrst(nrst);
		vxe_wrapper.o_intr(intr);
		vxe_wrapper.s0_aw_fifo_in(io_aw_fifo);
		vxe_wrapper.s0_w_fifo_in(io_w_fifo);
		vxe_wrapper.s0_b_fifo_out(io_b_fifo);
		vxe_wrapper.s0_ar_fifo_in(io_ar_fifo);
		vxe_wrapper.s0_r_fifo_out(io_r_fifo);
		vxe_wrapper.m0_aw_fifo_out(mem0_aw_fifo);
		vxe_wrapper.m0_w_fifo_out(mem0_w_fifo);
		vxe_wrapper.m0_b_fifo_in(mem0_b_fifo);
		vxe_wrapper.m0_ar_fifo_out(mem0_ar_fifo);
		vxe_wrapper.m0_r_fifo_in(mem0_r_fifo);
		vxe_wrapper.m1_aw_fifo_out(mem1_aw_fifo);
		vxe_wrapper.m1_w_fifo_out(mem1_w_fifo);
		vxe_wrapper.m1_b_fifo_in(mem1_b_fifo);
		vxe_wrapper.m1_ar_fifo_out(mem1_ar_fifo);
		vxe_wrapper.m1_r_fifo_in(mem1_r_fifo);

		// Connect memory signals
		mem.clk(clk);
		mem.nrst(nrst);
		mem.s0_aw_fifo_in(mem0_aw_fifo);
		mem.s0_w_fifo_in(mem0_w_fifo);
		mem.s0_b_fifo_out(mem0_b_fifo);
		mem.s0_ar_fifo_in(mem0_ar_fifo);
		mem.s0_r_fifo_out(mem0_r_fifo);
		mem.s1_aw_fifo_in(mem1_aw_fifo);
		mem.s1_w_fifo_in(mem1_w_fifo);
		mem.s1_b_fifo_out(mem1_b_fifo);
		mem.s1_ar_fifo_in(mem1_ar_fifo);
		mem.s1_r_fifo_out(mem1_r_fifo);

		// Connect CPU signals
		cpu.clk(clk);
		cpu.nrst(nrst);
		cpu.i_intr(intr);
		cpu.m_aw_fifo_out(io_aw_fifo);
		cpu.m_w_fifo_out(io_w_fifo);
		cpu.m_b_fifo_in(io_b_fifo);
		cpu.m_ar_fifo_out(io_ar_fifo);
		cpu.m_r_fifo_in(io_r_fifo);
	}

private:
	// Interrupt line
	sc_signal<bool> intr;

	// Slave I/O port
	sc_fifo<axi4::areq32> io_aw_fifo;
	sc_fifo<axi4::wreq32> io_w_fifo;
	sc_fifo<axi4::bresp32> io_b_fifo;
	sc_fifo<axi4::areq32> io_ar_fifo;
	sc_fifo<axi4::rresp32> io_r_fifo;

	// Master mem port 0
	sc_fifo<axi4::areq64> mem0_aw_fifo;
	sc_fifo<axi4::wreq64> mem0_w_fifo;
	sc_fifo<axi4::bresp64> mem0_b_fifo;
	sc_fifo<axi4::areq64> mem0_ar_fifo;
	sc_fifo<axi4::rresp64> mem0_r_fifo;

	// Master mem port 1
	sc_fifo<axi4::areq64> mem1_aw_fifo;
	sc_fifo<axi4::wreq64> mem1_w_fifo;
	sc_fifo<axi4::bresp64> mem1_b_fifo;
	sc_fifo<axi4::areq64> mem1_ar_fifo;
	sc_fifo<axi4::rresp64> mem1_r_fifo;
};
