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
 * VxEngine Control Unit
 */

#include <iostream>
#include <systemc.h>
#include "register_set.hxx"
#include "vxe_common.hxx"
#include "vxe_internal.hxx"


// VxEngine Control Unit
SC_MODULE(vxe_ctrl_unit) {
	sc_in<bool> clk;
	sc_in<bool> nrst;

	// Memory interface
	sc_fifo_in<vxe::vxe_mem_rq> mem_fifo_in;
	sc_fifo_out<vxe::vxe_mem_rq> mem_fifo_out;

	// Control signals
	sc_in<bool> i_start;
	sc_out<bool> o_busy;

	SC_HAS_PROCESS(vxe_ctrl_unit);

	vxe_ctrl_unit(::sc_core::sc_module_name name, unsigned client_id, register_set_if<uint32_t>& regs)
		: ::sc_core::sc_module(name), clk("clk"), nrst("nrst")
		, mem_fifo_in("mem_fifo_in"), mem_fifo_out("mem_fifo_out")
		, i_start("i_start"), o_busy("o_busy")
		, m_client_id(client_id), m_regs(regs)
	{
		SC_THREAD(instr_fetch_thread);
			sensitive << clk.pos();

		SC_THREAD(instr_exec_thread);
			sensitive << clk.pos();

		SC_METHOD(busy_logic_method);
			sensitive << ifetch_busy;
	}

private:

	[[noreturn]] void instr_fetch_thread()
	{
		ifetch_busy.write(false);

		while(1) {
			// Wait for start trigger
			wait();

			if(!i_start.read())
				continue;

			// Check for logic error
			if(o_busy.read())
				std::cerr << name() << ": start signal asserted while in busy state!"
					<< std::endl;

			// Start instruction requests
			ifetch_busy.write(true);

			// Form a program counter
			uint64_t pgm_lo = m_regs.get_reg(vxe::regi::REG_PGM_ADDR_LO);
			uint64_t pgm_hi = m_regs.get_reg(vxe::regi::REG_PGM_ADDR_HI);
			m_pgm_counter = (pgm_hi << 32u) | pgm_lo;

			while(!ifetch_stop.read()) {
				// Prepare request
				vxe::vxe_mem_rq rq;
				rq.set_client_id(m_client_id);
				rq.type = vxe::vxe_mem_rq::rtype::CMD_RD;
				rq.addr = m_pgm_counter;
				rq.set_ben_mask(0xFF);
				// Send request
				mem_fifo_out.write(rq);
				// Increment program counter
				m_pgm_counter += sizeof(vxe::instr::generic);
			}
		}
	}

	[[noreturn]] void instr_exec_thread()
	{
		ifetch_stop.write(false);

		//TODO: implementation needed
		while(1) {
			vxe::vxe_mem_rq rq;
			rq = mem_fifo_in.read();

			std::cout << rq << std::endl;

			vxe::instr::generic g(rq.data_u64[0]);

			if(g.op == vxe::instr::sync::OP) {
				ifetch_stop.write(true);
				while (1) {
					wait();
					sc_stop();
				}
			}
		}
	}

	void busy_logic_method()
	{
		if(ifetch_busy)
			o_busy.write(true);
		else
			o_busy.write(false);
	}

private:
	const unsigned m_client_id;
	// VxE register file
	register_set_if<uint32_t>& m_regs;
	// Internal control signals
	sc_signal<bool> ifetch_busy;
	sc_signal<bool> ifetch_stop;
	// Internal registers
	uint64_t m_pgm_counter;
};
