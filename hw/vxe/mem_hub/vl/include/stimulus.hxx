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
 * Testbench stimulus module
 */

#include <cstdint>
#include <systemc.h>
#include <list>
#include "stimulus_common.hxx"
#include "stimulus_cu.hxx"
#include "stimulus_vpu.hxx"
#include "stimulus_test.hxx"
#pragma once


// Stimulus
SC_MODULE(stimulus) {
	sc_in<bool>		clk;
	sc_in<bool>		nrst;
	// CU
	// Master port select
	sc_out<bool>		o_cu_m_sel;
	// Request channel
	sc_in<bool>		i_cu_rqa_rdy;
	sc_out<uint64_t>	o_cu_rqa;
	sc_out<bool>		o_cu_rqa_wr;
	// Response channel
	sc_in<bool>		i_cu_rss_vld;
	sc_in<uint32_t>		i_cu_rss;
	sc_out<bool>		o_cu_rss_rd;
	sc_in<bool>		i_cu_rsd_vld;
	sc_in<uint64_t>		i_cu_rsd;
	sc_out<bool>		o_cu_rsd_rd;
	// VPU0
	// Request channel
	sc_in<bool>		i_vpu0_rqa_rdy;
	sc_out<uint64_t>	o_vpu0_rqa;
	sc_out<bool>		o_vpu0_rqa_wr;
	sc_in<bool>		i_vpu0_rqd_rdy;
	sc_out<sc_bv<72>>	o_vpu0_rqd;
	sc_out<bool>		o_vpu0_rqd_wr;
	// Response channel
	sc_in<bool>		i_vpu0_rss_vld;
	sc_in<uint32_t>		i_vpu0_rss;
	sc_out<bool>		o_vpu0_rss_rd;
	sc_in<bool>		i_vpu0_rsd_vld;
	sc_in<uint64_t>		i_vpu0_rsd;
	sc_out<bool>		o_vpu0_rsd_rd;
	// VPU1
	// Request channel
	sc_in<bool>		i_vpu1_rqa_rdy;
	sc_out<uint64_t>	o_vpu1_rqa;
	sc_out<bool>		o_vpu1_rqa_wr;
	sc_in<bool>		i_vpu1_rqd_rdy;
	sc_out<sc_bv<72>>	o_vpu1_rqd;
	sc_out<bool>		o_vpu1_rqd_wr;
	// Response channel
	sc_in<bool>		i_vpu1_rss_vld;
	sc_in<uint32_t>		i_vpu1_rss;
	sc_out<bool>		o_vpu1_rss_rd;
	sc_in<bool>		i_vpu1_rsd_vld;
	sc_in<uint64_t>		i_vpu1_rsd;
	sc_out<bool>		o_vpu1_rsd_rd;

	// Instances of internal blocks
	stimulus_cu	cu;
	stimulus_vpu	vpu0;
	stimulus_vpu	vpu1;

	SC_CTOR(stimulus)
		: clk("clk"), nrst("nrst")
		, o_cu_m_sel("o_cu_m_sel")
		, i_cu_rqa_rdy("i_cu_rqa_rdy"), o_cu_rqa("o_cu_rqa"), o_cu_rqa_wr("o_cu_rqa_wr")
		, i_cu_rss_vld("i_cu_rss_vld"), i_cu_rss("i_cu_rss"), o_cu_rss_rd("o_cu_rss_rd")
		, i_cu_rsd_vld("i_cu_rsd_vld"), i_cu_rsd("i_cu_rsd"), o_cu_rsd_rd("o_cu_rsd_rd")
		, i_vpu0_rqa_rdy("i_vpu0_rqa_rdy"), o_vpu0_rqa("o_vpu0_rqa"), o_vpu0_rqa_wr("o_vpu0_rqa_wr")
		, i_vpu0_rqd_rdy("i_vpu0_rqd_rdy"), o_vpu0_rqd("o_vpu0_rqd"), o_vpu0_rqd_wr("o_vpu0_rqd_wr")
		, i_vpu0_rss_vld("i_vpu0_rss_vld"), i_vpu0_rss("i_vpu0_rss"), o_vpu0_rss_rd("o_vpu0_rss_rd")
		, i_vpu0_rsd_vld("i_vpu0_rsd_vld"), i_vpu0_rsd("i_vpu0_rsd"), o_vpu0_rsd_rd("o_vpu0_rsd_rd")
		, i_vpu1_rqa_rdy("i_vpu1_rqa_rdy"), o_vpu1_rqa("o_vpu1_rqa"), o_vpu1_rqa_wr("o_vpu1_rqa_wr")
		, i_vpu1_rqd_rdy("i_vpu1_rqd_rdy"), o_vpu1_rqd("o_vpu1_rqd"), o_vpu1_rqd_wr("o_vpu1_rqd_wr")
		, i_vpu1_rss_vld("i_vpu1_rss_vld"), i_vpu1_rss("i_vpu1_rss"), o_vpu1_rss_rd("o_vpu1_rss_rd")
		, i_vpu1_rsd_vld("i_vpu1_rsd_vld"), i_vpu1_rsd("i_vpu1_rsd"), o_vpu1_rsd_rd("o_vpu1_rsd_rd")
		, cu("cu", stimul::mhc::CU), vpu0("vpu0", stimul::mhc::VPU0), vpu1("vpu1", stimul::mhc::VPU1)
	{
		SC_THREAD(test_issue_thread)
			sensitive << clk.pos();

		// Connect CU signals
		cu.clk(clk);
		cu.nrst(nrst);
		cu.o_cu_m_sel(o_cu_m_sel);
		cu.i_cu_rqa_rdy(i_cu_rqa_rdy);
		cu.o_cu_rqa(o_cu_rqa);
		cu.o_cu_rqa_wr(o_cu_rqa_wr);
		cu.i_cu_rss_vld(i_cu_rss_vld);
		cu.i_cu_rss(i_cu_rss);
		cu.o_cu_rss_rd(o_cu_rss_rd);
		cu.i_cu_rsd_vld(i_cu_rsd_vld);
		cu.i_cu_rsd(i_cu_rsd);
		cu.o_cu_rsd_rd(o_cu_rsd_rd);

		// Connect VPU0 signals
		vpu0.clk(clk);
		vpu0.nrst(nrst);
		vpu0.i_vpu_rqa_rdy(i_vpu0_rqa_rdy);
		vpu0.o_vpu_rqa(o_vpu0_rqa);
		vpu0.o_vpu_rqa_wr(o_vpu0_rqa_wr);
		vpu0.i_vpu_rqd_rdy(i_vpu0_rqd_rdy);
		vpu0.o_vpu_rqd(o_vpu0_rqd);
		vpu0.o_vpu_rqd_wr(o_vpu0_rqd_wr);
		vpu0.i_vpu_rss_vld(i_vpu0_rss_vld);
		vpu0.i_vpu_rss(i_vpu0_rss);
		vpu0.o_vpu_rss_rd(o_vpu0_rss_rd);
		vpu0.i_vpu_rsd_vld(i_vpu0_rsd_vld);
		vpu0.i_vpu_rsd(i_vpu0_rsd);
		vpu0.o_vpu_rsd_rd(o_vpu0_rsd_rd);

		// Connect VPU1 signals
		vpu1.clk(clk);
		vpu1.nrst(nrst);
		vpu1.i_vpu_rqa_rdy(i_vpu1_rqa_rdy);
		vpu1.o_vpu_rqa(o_vpu1_rqa);
		vpu1.o_vpu_rqa_wr(o_vpu1_rqa_wr);
		vpu1.i_vpu_rqd_rdy(i_vpu1_rqd_rdy);
		vpu1.o_vpu_rqd(o_vpu1_rqd);
		vpu1.o_vpu_rqd_wr(o_vpu1_rqd_wr);
		vpu1.i_vpu_rss_vld(i_vpu1_rss_vld);
		vpu1.i_vpu_rss(i_vpu1_rss);
		vpu1.o_vpu_rss_rd(o_vpu1_rss_rd);
		vpu1.i_vpu_rsd_vld(i_vpu1_rsd_vld);
		vpu1.i_vpu_rsd(i_vpu1_rsd);
		vpu1.o_vpu_rsd_rd(o_vpu1_rsd_rd);
	}

	void add_test(std::shared_ptr<stimul::test_base> t)
	{
		m_tests.push_back(t);
	}

private:
	[[noreturn]] void test_issue_thread()
	{
		auto it = m_tests.begin();
		while(true) {
			if(it == m_tests.end()) {
				sc_stop();
				while(true)
					wait();
			}

			// Issue tests
			cu.assign_trace((*it)->get_cu_trace());
			vpu0.assign_trace((*it)->get_vpu0_trace());
			vpu1.assign_trace((*it)->get_vpu1_trace());

			// Set CU master port select
			o_cu_m_sel.write((*it)->cu_mas() == 1);

			std::cout << "Running... " << (*it)->name() << std::endl;

			while(!(*it)->done())
				wait();

			wait();

			++it;
		}
	}

private:
	std::list<std::shared_ptr<stimul::test_base>> m_tests;	// Tests list
};
