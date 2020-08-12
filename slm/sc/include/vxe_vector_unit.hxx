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
#include "obj_dir/Vflp32_mac_5stg.h"


// VxEngine Vector Processing Unit
SC_MODULE(vxe_vector_unit) {
	static constexpr unsigned NT = 8;	// Number of threads per VPU

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

	// FMAC32 unit
	Vflp32_mac_5stg fmac32;

	SC_HAS_PROCESS(vxe_vector_unit);

	vxe_vector_unit(::sc_core::sc_module_name name, unsigned client_id)
		: ::sc_core::sc_module(name), clk("clk"), nrst("nrst")
		, mem_fifo_in("mem_fifo_in"), mem_fifo_out("mem_fifo_out")
		, o_busy("o_busy")
		, i_cmd_select("i_cmd_select"), o_cmd_ack("o_cmd_ack"), o_cmd_err("o_cmd_err")
		, i_cmd_op("i_cmd_op"), i_cmd_thread("i_cmd_thread"), i_cmd_wdata("i_cmd_wdata")
		, fmac32("fmac32")
		, m_client_id(client_id)
	{
		SC_THREAD(cmd_exec_thread);
			sensitive << clk.pos();

		// Connect FMAC32 signals
		fmac32.clk(clk);
		fmac32.nrst(nrst);
		fmac32.i_valid(s_fmac32_i_valid);
		fmac32.o_sign(s_fmac32_o_sign);
		fmac32.o_zero(s_fmac32_o_zero);
		fmac32.o_nan(s_fmac32_o_nan);
		fmac32.o_inf(s_fmac32_o_inf);
		fmac32.o_valid(s_fmac32_o_valid);
		fmac32.i_a(s_fmac32_i_a);
		fmac32.i_b(s_fmac32_i_b);
		fmac32.i_c(s_fmac32_i_c);
		fmac32.o_p(s_fmac32_o_p);
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

			// Get operands
			cmd_op = i_cmd_op.read();
			cmd_thread = i_cmd_thread.read();
			cmd_wdata = i_cmd_wdata.read();

			// Wait while unit is busy
			while(o_busy.read())
				wait();

			switch(cmd_op) {
				case vxe::vpc::SETACC:
					reg_acc[cmd_thread] = cmd_wdata;
					break;
				case vxe::vpc::SETVL:
					reg_len[cmd_thread] = cmd_wdata;
					break;
				case vxe::vpc::SETRS:
					reg_rsa[cmd_thread] = cmd_wdata;
					break;
				case vxe::vpc::SETRT:
					reg_rst[cmd_thread] = cmd_wdata;
					break;
				case vxe::vpc::SETRD:
					reg_rsd[cmd_thread] = cmd_wdata;
					break;
				case vxe::vpc::SETEN:
					reg_thr_en[cmd_thread] = (cmd_wdata & 1u) != 0;
					break;
				case vxe::vpc::PROD:
				case vxe::vpc::STORE:
					break;
				default:
					o_cmd_err.write(true);
					break;
			}

			o_cmd_ack.write(true);
		}
	}

private:
	const unsigned m_client_id;
	// Internal registers
	uint32_t reg_acc[NT];	// Accumulators
	uint32_t reg_len[NT];	// Vector lengths
	uint64_t reg_rsa[NT];	// Rs addresses
	uint64_t reg_rst[NT];	// Rt addresses
	uint64_t reg_rsd[NT];	// Rd addresses
	bool reg_thr_en[NT];	// Thread enables
	// FMAC32 signals
	sc_signal<bool> s_fmac32_i_valid;
	sc_signal<bool> s_fmac32_o_sign;
	sc_signal<bool> s_fmac32_o_zero;
	sc_signal<bool> s_fmac32_o_nan;
	sc_signal<bool> s_fmac32_o_inf;
	sc_signal<bool> s_fmac32_o_valid;
	sc_signal<uint32_t> s_fmac32_i_a;
	sc_signal<uint32_t> s_fmac32_i_b;
	sc_signal<uint32_t> s_fmac32_i_c;
	sc_signal<uint32_t> s_fmac32_o_p;
};
