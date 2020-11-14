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
#include "vxe_pipe.hxx"
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
	vxe_pipe<uint8_t, 5> thr_id_pipe;

	// 64-to-32 FIFOs
	sc_vector<vxe_fifo64x32<16>> f64x32_rs_fifo;
	sc_vector<vxe_fifo64x32<16>> f64x32_rt_fifo;

	SC_HAS_PROCESS(vxe_vector_unit);

	vxe_vector_unit(::sc_core::sc_module_name name, unsigned client_id)
		: ::sc_core::sc_module(name), clk("clk"), nrst("nrst")
		, mem_fifo_in("mem_fifo_in"), mem_fifo_out("mem_fifo_out")
		, o_busy("o_busy")
		, i_cmd_select("i_cmd_select"), o_cmd_ack("o_cmd_ack"), o_cmd_err("o_cmd_err")
		, i_cmd_op("i_cmd_op"), i_cmd_thread("i_cmd_thread"), i_cmd_wdata("i_cmd_wdata")
		, fmac32("fmac32"), thr_id_pipe("thr_id_pipe")
		, f64x32_rs_fifo("f64x32_rs_fifo", NT), f64x32_rt_fifo("f64x32_rt_fifo", NT)
		, m_client_id(client_id)
	{
		SC_THREAD(cmd_exec_thread);
			sensitive << clk.pos();

		SC_THREAD(mem_req_thread);
			sensitive << clk.pos();

		SC_THREAD(mem_resp_thread);
			sensitive << clk.pos();

		SC_THREAD(op_issue_thread);
			sensitive << clk.pos();

		SC_THREAD(writeback_thread);
			sensitive << clk.pos();

		SC_METHOD(busy_logic_method);
			sensitive << s_load_store_busy << s_exec_pipe_busy;

		SC_METHOD(load_store_busy_logic_method);
			sensitive << out_rqrs_fifo.data_written_event() << out_rqrs_fifo.data_read_event()
				<< out_rqrt_fifo.data_written_event() << out_rqrt_fifo.data_read_event()
				<< out_rqst_fifo.data_written_event() << out_rqst_fifo.data_read_event()
				<< s_load_store_active;

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
		// Connect thread Id pipe signals
		thr_id_pipe.clk(clk);
		thr_id_pipe.nrst(nrst);
		thr_id_pipe.in(thr_id_pipe_in);
		thr_id_pipe.out(thr_id_pipe_out);
		// Connect 64-to-32 FIFOs signals
		for(unsigned i = 0; i < NT; ++i) {
			// Rs
			f64x32_rs_fifo[i].clk(clk);
			f64x32_rs_fifo[i].nrst(nrst);
			f64x32_rs_fifo[i].i_data(f64x32_rs_fifo_wdata[i]);
			f64x32_rs_fifo[i].i_write(f64x32_rs_fifo_write[i]);
			f64x32_rs_fifo[i].i_valid(f64x32_rs_fifo_wvalid[i]);
			f64x32_rs_fifo[i].o_full(f64x32_rs_fifo_full[i]);
			f64x32_rs_fifo[i].i_read(f64x32_rs_fifo_read[i]);
			f64x32_rs_fifo[i].o_empty(f64x32_rs_fifo_empty[i]);
			f64x32_rs_fifo[i].o_data(f64x32_rs_fifo_rdata[i]);
			// Rt
			f64x32_rt_fifo[i].clk(clk);
			f64x32_rt_fifo[i].nrst(nrst);
			f64x32_rt_fifo[i].i_data(f64x32_rt_fifo_wdata[i]);
			f64x32_rt_fifo[i].i_write(f64x32_rt_fifo_write[i]);
			f64x32_rt_fifo[i].i_valid(f64x32_rt_fifo_wvalid[i]);
			f64x32_rt_fifo[i].o_full(f64x32_rt_fifo_full[i]);
			f64x32_rt_fifo[i].i_read(f64x32_rt_fifo_read[i]);
			f64x32_rt_fifo[i].o_empty(f64x32_rt_fifo_empty[i]);
			f64x32_rt_fifo[i].o_data(f64x32_rt_fifo_rdata[i]);
		}
	}

private:
	/**
	 * Commands execution thread
	 * Receives commands from CU
	 */
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
					wait();
					while(s_load_store_busy.read() || s_exec_pipe_busy.read())
						wait();
					break;
				case vxe::vpc::STORE:
					s_dpcmd_op.write(vxe::vpc::STORE);
					s_dpcmd_valid.write(true);
					wait();
					s_dpcmd_valid.write(false);
					wait();
					while(s_load_store_busy.read())
						wait();
					break;
				default:
					o_cmd_err.write(true);
					break;
			}

			o_cmd_ack.write(true);
		}
	}

	/**
	 * Set load address and byte enable mask
	 * @param rq request structure
	 * @param addr load address
	 * @param len current vector length
	 */
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

	/**
	 * Data loads handler
	 */
	void data_load()
	{
		unsigned done_mask = 0;	// Mask of completed threads

		while(done_mask != (1 << NT) - 1) {
			for (unsigned th = 0; th < NT; ++th) {
				// Skip not enabled threads
				if(!reg_thr_en[th]) {
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
					rq.set_thread_arg(0);
					set_load_addr(rq, reg_rsa[th], reg_rsl[th]);
					// Push to outstanding requests FIFO
					out_rqrs_fifo.write(vxe::word_enable<2>({ !!rq.ben[0], !!rq.ben[4] }));
					// Send request
					mem_fifo_out.write(rq);
				}

				wait();	// Can issue second load only on the next clock cycle.

				// Prepare request for Rt operand
				if(reg_rtl[th] != 0) {
					vxe::vxe_mem_rq rq;
					rq.set_client_id(m_client_id);
					rq.req = vxe::vxe_mem_rq::rqtype::REQ_RD;
					rq.set_thread_id(th);
					rq.set_thread_arg(1);
					set_load_addr(rq, reg_rta[th], reg_rtl[th]);
					// Push to outstanding requests FIFO
					out_rqrt_fifo.write(vxe::word_enable<2>({ !!rq.ben[0], !!rq.ben[4] }));
					// Send request
					mem_fifo_out.write(rq);
				}

				// Check completion status
				if((reg_rsl[th] == 0) && (reg_rtl[th] == 0))
					done_mask |= 1 << th;

				wait();
			}
		}
	}

	/**
	 * Data stores handler
	 */
	void data_store()
	{
		for (unsigned th = 0; th < NT; th += 2) {
			// Skip not enabled pairs of threads
			if(!reg_thr_en[th] && !reg_thr_en[th + 1]) {
				wait();
				continue;
			}

			// Check if we can merge store for neighbour threads
			if(reg_thr_en[th] && reg_thr_en[th + 1] && ((reg_rda[th] & ~1) == (reg_rda[th + 1] & ~1))) {
				vxe::vxe_mem_rq rq;
				rq.set_client_id(m_client_id);
				rq.req = vxe::vxe_mem_rq::rqtype::REQ_WR;
				rq.set_thread_id(th);
				rq.addr = (reg_rda[th] & ~1) << 2;
				rq.set_ben_mask(0xFF);
				// Note: stores to the same address have undefined behavior
				rq.data_u32[0] = ((reg_rda[th] & 1) == 0 ? reg_acc[th] : reg_acc[th + 1]);
				rq.data_u32[1] = ((reg_rda[th] & 1) != 0 ? reg_acc[th] : reg_acc[th + 1]);
				// Push to outstanding requests FIFO
				out_rqst_fifo.write(true);
				// Send request
				mem_fifo_out.write(rq);

				wait();
				continue;
			}

			// If we cannot merge then send one by one
			if(reg_thr_en[th]) {
				vxe::vxe_mem_rq rq;
				rq.set_client_id(m_client_id);
				rq.req = vxe::vxe_mem_rq::rqtype::REQ_WR;
				rq.set_thread_id(th);
				rq.addr = (reg_rda[th] & ~1) << 2;
				rq.set_ben_mask((reg_rda[th] & 1) == 0 ? 0x0F : 0xF0);
				rq.data_u32[0] = ((reg_rda[th] & 1) == 0 ? reg_acc[th] : 0xDEADBEEF);
				rq.data_u32[1] = ((reg_rda[th] & 1) != 0 ? reg_acc[th] : 0xDEADBEEF);
				// Push to outstanding requests FIFO
				out_rqst_fifo.write(true);
				// Send request
				mem_fifo_out.write(rq);

				wait();
				continue;
			}

			if(reg_thr_en[th + 1]) {
				vxe::vxe_mem_rq rq;
				rq.set_client_id(m_client_id);
				rq.req = vxe::vxe_mem_rq::rqtype::REQ_WR;
				rq.set_thread_id(th + 1);
				rq.addr = (reg_rda[th + 1] & ~1) << 2;
				rq.set_ben_mask((reg_rda[th + 1] & 1) == 0 ? 0x0F : 0xF0);
				rq.data_u32[0] = ((reg_rda[th + 1] & 1) == 0 ? reg_acc[th + 1] : 0xDEADBEEF);
				rq.data_u32[1] = ((reg_rda[th + 1] & 1) != 0 ? reg_acc[th + 1] : 0xDEADBEEF);
				// Push to outstanding requests FIFO
				out_rqst_fifo.write(true);
				// Send request
				mem_fifo_out.write(rq);

				wait();
				continue;
			}
		}
	}

	/**
	 * Memory requests thread
	 * Handle loads and stores
	 */
	[[noreturn]] void mem_req_thread()
	{
		while(true) {
			s_load_store_active.write(false);
			wait(); // Wait for positive edge

			// Check if command to start is valid
			bool dpcmd_valid = s_dpcmd_valid.read();
			if(!dpcmd_valid)
				continue;

			s_load_store_active.write(true);

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

	/**
	 * Memory response thread
	 * Handles responses from memory
	 */
	[[noreturn]] void mem_resp_thread()
	{
		// Reset state
		for(unsigned i = 0; i < NT; ++i) {
			f64x32_rs_fifo_write[i].write(false);
			f64x32_rt_fifo_write[i].write(false);
		}

		while(true) {
			vxe::vxe_mem_rq rq;
			vxe::word_enable<2> we;
			unsigned thread;
			unsigned arg;

			// Read incoming data FIFO
			rq = mem_fifo_in.read();

			// Thread and argument id
			thread = rq.get_thread_id();
			arg = rq.get_thread_arg();

			// Drop outstanding request item
			if(rq.req == vxe::vxe_mem_rq::rqtype::REQ_RD)
				we = (arg == 0 ? out_rqrs_fifo.read() : out_rqrt_fifo.read());
			else
				out_rqst_fifo.read();

			//TODO: errors check
//			cout << rq << endl;

			if(rq.req != vxe::vxe_mem_rq::rqtype::REQ_RD)
				continue;

			// Store data to 64x32b FIFOs
			if(arg == 0) {
				while(f64x32_rs_fifo_full[thread].read())
					wait();
				f64x32_rs_fifo_wdata[thread].write(rq.data_u64[0]);
				f64x32_rs_fifo_wvalid[thread].write(we.bits<unsigned>());
				f64x32_rs_fifo_write[thread].write(true);
				wait();
				f64x32_rs_fifo_write[thread].write(false);
			} else {
				while(f64x32_rt_fifo_full[thread].read())
					wait();
				f64x32_rt_fifo_wdata[thread].write(rq.data_u64[0]);
				f64x32_rt_fifo_wvalid[thread].write(we.bits<unsigned>());
				f64x32_rt_fifo_write[thread].write(true);
				wait();
				f64x32_rt_fifo_write[thread].write(false);
			}
		}
	}

	/**
	 * FMAC operation issue thread
	 */
	[[noreturn]] void op_issue_thread()
	{
		// Reset state
		for(unsigned thread = 0; thread < NT; ++thread) {
			f64x32_rs_fifo_read[thread].write(false);
			f64x32_rt_fifo_read[thread].write(false);
		}

		while(true) {
			s_exec_pipe_busy.write(false);
			s_fmac32_i_valid.write(false);
			if(!nrst.read()) {
				wait();
				continue;
			}

			for(unsigned thread = 0; thread < NT; ++thread) {
				// Evaluate execute pipe busy state
				bool fmac_busy = (fmac_slots_fifo.num_available() != 0);
				bool issue_busy = false;
				for(unsigned i = 0; i < NT; ++i) {
					if(!f64x32_rs_fifo_empty[i].read() || !f64x32_rt_fifo_empty[i].read()) {
						issue_busy = true;
						break;
					}
				}
				s_exec_pipe_busy.write(fmac_busy || issue_busy);

				wait();

				s_fmac32_i_valid.write(false);

				// Ignore disabled threads and threads with no data available
				if(!reg_thr_en[thread] || f64x32_rs_fifo_empty[thread].read() ||
					f64x32_rt_fifo_empty[thread].read()) {
					continue;
				}

				uint32_t rs, rt;

				// Read FMAC operands
				f64x32_rs_fifo_read[thread].write(true);
				f64x32_rt_fifo_read[thread].write(true);
				wait();
				f64x32_rs_fifo_read[thread].write(false);
				f64x32_rt_fifo_read[thread].write(false);

				rs = f64x32_rs_fifo_rdata[thread].read();
				rt = f64x32_rt_fifo_rdata[thread].read();

				// Send to FMAC pipeline
				s_fmac32_i_a.write(reg_acc[thread]);
				s_fmac32_i_b.write(rs);
				s_fmac32_i_c.write(rt);
				s_fmac32_i_valid.write(true);
				thr_id_pipe_in.write(thread);
				fmac_slots_fifo.write(true);
			}
		}
	}

	/**
	 * Writeback thread
	 * Writes results back to accumulator registers
	 */
	[[noreturn]] void writeback_thread()
	{
		while(true) {
			wait();

			if(!s_fmac32_o_valid.read())
				continue;

			unsigned thread = thr_id_pipe_out.read();
			reg_acc[thread] = s_fmac32_o_p.read();
			fmac_slots_fifo.read();
		}
	}

	/**
	 * VPU busy logic method
	 */
	void busy_logic_method()
	{
		o_busy.write(s_load_store_busy.read() || s_exec_pipe_busy.read());
	}

	/**
	 * Load/Store busy logic method
	 */
	void load_store_busy_logic_method()
	{
		bool out_ld1 = (out_rqrs_fifo.num_available() != 0);
		bool out_ld2 = (out_rqrt_fifo.num_available() != 0);
		bool out_st = (out_rqst_fifo.num_available() != 0);
		s_load_store_busy.write(out_ld1 || out_ld2 || out_st || s_load_store_active.read());
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
	// Thread Id pipe signals
	sc_signal<uint8_t> thr_id_pipe_in;
	sc_signal<uint8_t> thr_id_pipe_out;
	// Internal control FIFOs
	sc_fifo<vxe::word_enable<2>> out_rqrs_fifo;
	sc_fifo<vxe::word_enable<2>> out_rqrt_fifo;
	sc_fifo<bool> out_rqst_fifo;
	// 64-to-32 Rs FIFOs signals
	sc_signal<uint64_t> f64x32_rs_fifo_wdata[NT];
	sc_signal<sc_uint<2>> f64x32_rs_fifo_wvalid[NT];
	sc_signal<bool> f64x32_rs_fifo_write[NT];
	sc_signal<bool> f64x32_rs_fifo_read[NT];
	sc_signal<uint32_t> f64x32_rs_fifo_rdata[NT];
	sc_signal<bool> f64x32_rs_fifo_empty[NT];
	sc_signal<bool> f64x32_rs_fifo_full[NT];
	// 64-to-32 Rt FIFOs signals
	sc_signal<uint64_t> f64x32_rt_fifo_wdata[NT];
	sc_signal<sc_uint<2>> f64x32_rt_fifo_wvalid[NT];
	sc_signal<bool> f64x32_rt_fifo_write[NT];
	sc_signal<bool> f64x32_rt_fifo_read[NT];
	sc_signal<uint32_t> f64x32_rt_fifo_rdata[NT];
	sc_signal<bool> f64x32_rt_fifo_empty[NT];
	sc_signal<bool> f64x32_rt_fifo_full[NT];
	// Occupied FMAC slots FIFO
	sc_fifo<bool> fmac_slots_fifo;
	// Busy signals
	sc_signal<bool> s_load_store_busy;
	sc_signal<bool> s_exec_pipe_busy;
	// Internal control signals
	sc_signal<uint8_t> s_dpcmd_op;	// Data processing command operation
	sc_signal<bool> s_dpcmd_valid;	// Data processing command valid
	sc_signal<bool> s_load_store_active;
};
