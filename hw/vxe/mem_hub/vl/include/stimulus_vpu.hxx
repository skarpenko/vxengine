/*
 * Copyright (c) 2020-2022 The VxEngine Project. All rights reserved.
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
 * VPU stimulus module
 */

#include <cstdint>
#include <systemc.h>
#include "stimulus_common.hxx"
#pragma once


// VPU stimulus
SC_MODULE(stimulus_vpu) {
	sc_in<bool>		clk;
	sc_in<bool>		nrst;
	// Request channel
	sc_in<bool>		i_vpu_rqa_rdy;
	sc_out<uint64_t>	o_vpu_rqa;
	sc_out<bool>		o_vpu_rqa_wr;
	sc_in<bool>		i_vpu_rqd_rdy;
	sc_out<sc_bv<72>>	o_vpu_rqd;
	sc_out<bool>		o_vpu_rqd_wr;
	// Response channel
	sc_in<bool>		i_vpu_rss_vld;
	sc_in<uint32_t>		i_vpu_rss;
	sc_out<bool>		o_vpu_rss_rd;
	sc_in<bool>		i_vpu_rsd_vld;
	sc_in<uint64_t>		i_vpu_rsd;
	sc_out<bool>		o_vpu_rsd_rd;

	SC_HAS_PROCESS(stimulus_vpu);

	stimulus_vpu(::sc_core::sc_module_name name, unsigned client_id)
		: ::sc_core::sc_module(name), clk("clk"), nrst("nrst")
		, i_vpu_rqa_rdy("i_vpu_rqa_rdy"), o_vpu_rqa("o_vpu_rqa"), o_vpu_rqa_wr("o_vpu_rqa_wr")
		, i_vpu_rqd_rdy("i_vpu_rqd_rdy"), o_vpu_rqd("o_vpu_rqd"), o_vpu_rqd_wr("o_vpu_rqd_wr")
		, i_vpu_rss_vld("i_vpu_rss_vld"), i_vpu_rss("i_vpu_rss"), o_vpu_rss_rd("o_vpu_rss_rd")
		, i_vpu_rsd_vld("i_vpu_rsd_vld"), i_vpu_rsd("i_vpu_rsd"), o_vpu_rsd_rd("o_vpu_rsd_rd")
		, m_cid(client_id)
	{
		SC_THREAD(upstream_thread)
		sensitive << clk.pos();

		SC_THREAD(downstream_thread)
		sensitive << clk.pos();

		SC_THREAD(trace_play_thread)
		sensitive << clk.pos();

		SC_THREAD(trace_verif_thread)
		sensitive << clk.pos();
	}

	void assign_trace(std::shared_ptr<stimul::trace_gen_base> trace)
	{
		m_trace = trace;
	}

private:
	[[noreturn]] void upstream_thread()
	{
		o_vpu_rqa_wr.write(false);
		o_vpu_rqd_wr.write(false);

		// Wait for reset release
		while(!nrst) wait();

		while(true) {
			if(fifo_rqa.num_available() && i_vpu_rqa_rdy.read()) {
				stimul::req_addr rqa = fifo_rqa.read();
				o_vpu_rqa_wr.write(true);
				o_vpu_rqa.write(rqa.pack());
				if(!rqa.rnw) {
					stimul::req_data rqd = fifo_rqd.read();
					o_vpu_rqd_wr.write(true);
					o_vpu_rqd.write(rqd.pack());
				}
			} else {
				o_vpu_rqa_wr.write(false);
				o_vpu_rqd_wr.write(false);
			}

			wait();
		}
	}

	[[noreturn]] void downstream_thread()
	{
		o_vpu_rss_rd.write(false);
		o_vpu_rsd_rd.write(false);

		// Wait for reset release
		while(!nrst) wait();

		while(true) {
			bool rds;	// Response status is available
			bool rdd;	// Response data is available

			// Read status
			if(fifo_rss.num_free() && i_vpu_rss_vld) {
				o_vpu_rss_rd.write(true);
				rds = true;
			} else {
				o_vpu_rss_rd.write(false);
				rds = false;
			}

			// Read data
			if(fifo_rsd.num_free() && i_vpu_rsd_vld) {
				o_vpu_rsd_rd.write(true);
				rdd = true;
			} else {
				o_vpu_rsd_rd.write(false);
				rdd = false;
			}

			wait();

			// Status
			if(rds) {
				stimul::res_stat rss;
				rss.unpack(i_vpu_rss.read());
				fifo_rss.write(rss);
			}

			// Data
			if(rdd) {
				stimul::res_data rsd;
				rsd.unpack(i_vpu_rsd.read());
				fifo_rsd.write(rsd);
			}
		}
	}

	[[noreturn]] void trace_play_thread()
	{
		// Wait for reset release
		while(!nrst) wait();

		while(true) {
			if(m_trace == nullptr || m_trace->done()) {
				wait();
				continue;
			}

			while(!m_trace->done()) {
				stimul::trace_req *rq = m_trace->next_req();

				if(rq == nullptr) {
					wait();
					continue;
				}

				stimul::req_addr rqa;
				rqa.txnid = stimul::mktxnid(m_cid, rq->tid, rq->arg);
				rqa.rnw = rq->rnw;
				rqa.addr = rq->addr;
				fifo_rqa.write(rqa);

				if(!rq->rnw) {
					stimul::req_data rqd;
					rqd.ben = rq->ben;
					rqd.data = rq->data;
					fifo_rqd.write(rqd);
				}
			}

			wait();
		}
	}

	[[noreturn]] void trace_verif_thread()
	{
		while(true) {
			if(m_trace == nullptr || m_trace->done()) {
				wait();
				continue;
			}

			while(!m_trace->done()) {
				stimul::trace_res *ref_rs = m_trace->next_res();
				stimul::trace_res rs;
				stimul::res_stat rss;
				stimul::res_data rsd;

				if(ref_rs == nullptr) {
					wait();
					continue;
				}

				rss = fifo_rss.read();
				if(rss.rnw)
					rsd = fifo_rsd.read();

				rs = stimul::trace_res(rss.rnw, rss.err, rsd.data,
						stimul::txnid_thread_id(rss.txnid),
						stimul::txnid_argument(rss.txnid));

				if(rs != *ref_rs) {
					std::cout << "\tMismatch(" << name()
						<< "): [" << rs << "] != [" << *ref_rs << "]" << std::endl;
				}
			}

			wait();
		}
	}

private:
	unsigned				m_cid;
	sc_fifo<stimul::req_addr>		fifo_rqa;
	sc_fifo<stimul::req_data>		fifo_rqd;
	sc_fifo<stimul::res_stat>		fifo_rss;
	sc_fifo<stimul::res_data>		fifo_rsd;
	// Test trace
	std::shared_ptr<stimul::trace_gen_base>	m_trace;
};
