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
 * VxEngine Vector Processing Unit
 */

#include <iostream>
#include <systemc.h>
#include "vxe_internal.hxx"


// VxEngine Vector Processing Unit
SC_MODULE(vxe_vector_unit) {
	sc_in<bool> clk;
	sc_in<bool> nrst;

	// Memory interface
	sc_fifo_in<vxe::vxe_mem_rq> mem_fifo_in;
	sc_fifo_out<vxe::vxe_mem_rq> mem_fifo_out;

	// Control signals
	sc_out<bool> o_busy;

	// Command bus
	sc_in<bool> i_cmd_select;
	sc_out<bool> o_cmd_ack;
	sc_out<bool> o_cmd_err;
	sc_in<uint8_t> i_cmd_op;
	sc_in<uint8_t> i_cmd_thread;
	sc_in<uint64_t> i_cmd_wdata;

	SC_HAS_PROCESS(vxe_vector_unit);

	vxe_vector_unit(::sc_core::sc_module_name name, unsigned client_id)
		: ::sc_core::sc_module(name), clk("clk"), nrst("nrst")
		, mem_fifo_in("mem_fifo_in"), mem_fifo_out("mem_fifo_out")
		, o_busy("o_busy")
		, i_cmd_select("i_cmd_select"), o_cmd_ack("o_cmd_ack"), o_cmd_err("o_cmd_err")
		, i_cmd_op("i_cmd_op"), i_cmd_thread("i_cmd_thread"), i_cmd_wdata("i_cmd_wdata")
		, m_client_id(client_id)
	{
		SC_THREAD(cmd_exec_thread);
			sensitive << clk.pos();
	}

private:
	[[noreturn]] void cmd_exec_thread()
	{
		uint8_t cmd_op;
		uint8_t cmd_thread;
		uint64_t cmd_wdata;

		// Reset state
		o_cmd_ack.write(false);
		o_cmd_err.write(false);

		while(true) {
			wait(); // Wait for positive edge

			o_cmd_ack.write(false);
			o_cmd_err.write(false);

			if(!i_cmd_select.read())
				continue;

			cmd_op = i_cmd_op.read();
			cmd_thread = i_cmd_thread.read();
			cmd_wdata = i_cmd_wdata.read();

			while(o_busy.read())
				wait();

			std::cout << name() << ": wdata = " << cmd_wdata << std::endl;
			//TODO:
			(void)cmd_op;
			(void)cmd_thread;

			//TODO: define commands in vxe_internal.hxx, might correlate with instructions

			//if(name() == std::string("sys_top.vxe.vpu1"))
			o_cmd_ack.write(true);
		}
	}

private:
	const unsigned m_client_id;
};
