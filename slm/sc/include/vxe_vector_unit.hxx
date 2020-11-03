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
#include "vxe_fifo64x32.hxx"
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

		SC_THREAD(mem_req_thread);
			sensitive << clk.pos();

		SC_THREAD(mem_resp_thread);
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
		s_dpcmd_valid.write(false);

		while(true) {
			wait(); // Wait for positive edge

			o_cmd_ack.write(false);
			o_cmd_err.write(false);
			s_dpcmd_valid.write(false);

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
					reg_rsl[cmd_thread] = cmd_wdata;
					reg_rtl[cmd_thread] = cmd_wdata;
					break;
				case vxe::vpc::SETRS:
					reg_rsa[cmd_thread] = cmd_wdata;
					break;
				case vxe::vpc::SETRT:
					reg_rta[cmd_thread] = cmd_wdata;
					break;
				case vxe::vpc::SETRD:
					reg_rda[cmd_thread] = cmd_wdata;
					break;
				case vxe::vpc::SETEN:
					reg_thr_en[cmd_thread] = (cmd_wdata & 1u) != 0;
					break;
				case vxe::vpc::PROD:
					s_dpcmd_op.write(vxe::vpc::PROD);
					s_dpcmd_valid.write(true);
					wait();
					s_dpcmd_valid.write(false);
					while(s_dpcmd_done.read() == false)
						wait();
				case vxe::vpc::STORE:
					break;
				default:
					o_cmd_err.write(true);
					break;
			}

			o_cmd_ack.write(true);
		}
	}

	void set_load_addr(vxe::vxe_mem_rq& rq, uint64_t& addr, uint32_t& len)
	{
		if(addr & 1) {		// Address is not word aligned. Load only one word.
			rq.addr = addr & (~1);
			rq.set_ben_mask(0xF0);
			addr += 1;
			len -= 1;
		} else if(len == 1) {	// Only one word remaining.
			rq.addr = addr;
			rq.set_ben_mask(0x0F);
			addr += 1;
			len -= 1;
		} else {		// Can load two words at a time.
			rq.addr = addr;
			rq.set_ben_mask(0xFF);
			addr += 2;
			len -= 2;
		}

		// Convert addr to byte offset
		rq.addr <<= 2;
	}

	void data_load()
	{
		unsigned done_mask = 0;	// Mask of completed threads

		while(done_mask != NT-1) {
			for (unsigned th = 0; th < NT; ++th) {
				// Skip not enabled threads
				if (!reg_thr_en[th]) {
					done_mask |= 1 << th;
					wait();
					continue;
				}

				// Prepare request for Rs operand
				if(reg_rsl[th] != 0) {
					vxe::vxe_mem_rq rq;
					rq.set_client_id(m_client_id);
					rq.req = vxe::vxe_mem_rq::rqtype::REQ_RD;
					rq.set_thread_id(th);
					set_load_addr(rq, reg_rsa[th], reg_rsl[th]);
					// Send request
					mem_fifo_out.write(rq);
					// Push to outstanding requests FIFO
					out_rqs_fifo.write(true);
				}

				wait();	// Can issue second load only on next clock cycle.

				// Prepare request for Rt operand
				if(reg_rtl[th] != 0) {
					vxe::vxe_mem_rq rq;
					rq.set_client_id(m_client_id);
					rq.req = vxe::vxe_mem_rq::rqtype::REQ_RD;
					rq.set_thread_id(th);
					set_load_addr(rq, reg_rta[th], reg_rtl[th]);
					// Send request
					mem_fifo_out.write(rq);
					// Push to outstanding requests FIFO
					out_rqs_fifo.write(true);
				}

				// Check completion status
				if((reg_rsl[th] == 0) && (reg_rtl[th] == 0))
					done_mask |= 1 << th;
			}
		}
	}

	void data_store()
	{
		//TODO:
	}

	[[noreturn]] void mem_req_thread()
	{
		while(true) {
			wait(); // Wait for positive edge

			bool dpcmd_valid = s_dpcmd_valid.read();

			if(!dpcmd_valid)
				continue;

			uint8_t dpcmd_op = s_dpcmd_op.read();

			switch(dpcmd_op) {
				case vxe::vpc::PROD:
					data_load();
					break;
				case vxe::vpc::STORE:
					data_store();
					break;
				default:
					std::cerr << name() << ": invalid dpcmd_op!"
						  << std::endl;
					continue;
			}
		}
	}

	[[noreturn]] void mem_resp_thread()
	{
		// Reset state
		s_dpcmd_done.write(false);
		//TODO: done condition is No mem transactions and FMAC is idle. Set probably not here.

		while(true) {
			vxe::vxe_mem_rq rq;
			// Read incoming data FIFO
			rq = mem_fifo_in.read();
			// Drop outstanding request
			out_rqs_fifo.read();

			//TBD:
			std::cout << rq << endl;
		}
	}

private:
	const unsigned m_client_id;
	// Internal registers
	uint32_t reg_acc[NT];	// Accumulators
	uint64_t reg_rsa[NT];	// Rs addresses
	uint32_t reg_rsl[NT];	// Rs lengths
	uint64_t reg_rta[NT];	// Rt addresses
	uint32_t reg_rtl[NT];	// Rt lengths
	uint64_t reg_rda[NT];	// Rd addresses
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
	// Internal control FIFOs
	sc_fifo<bool> out_rqs_fifo;
	// Internal control signals
	sc_signal<uint8_t> s_dpcmd_op;	// Data processing command operation
	sc_signal<bool> s_dpcmd_valid;	// Data processing command valid
	sc_signal<bool> s_dpcmd_done;	// Data processing command done
};
