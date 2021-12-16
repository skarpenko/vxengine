/*
 * Copyright (c) 2020-2021 The VxEngine Project. All rights reserved.
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
	}

private:
	[[noreturn]] void upstream_thread()
	{
		while(true) {
			//TODO:
			wait();
		}
	}

	[[noreturn]] void downstream_thread()
	{
		while(true) {
			//TODO:
			wait();
		}
	}

private:
	unsigned		m_cid;
};
