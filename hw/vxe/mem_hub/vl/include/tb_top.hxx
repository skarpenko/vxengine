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
 * Testbench top
 */

#include <cstdint>
#include <systemc.h>
#include "obj_dir/Vvl_axi4_mem_hub.h"
#include "axi4_2port_mem.hxx"
#include "stimulus.hxx"
#pragma once


// Testbench top module
SC_MODULE(tb_top) {
	sc_in<bool> clk;
	sc_in<bool> nrst;

	// Memory hub unit
	Vvl_axi4_mem_hub mem_hub;
	// Memory
	axi4_2port_mem memory;
	// Stimulus unit
	stimulus stimul;

	SC_CTOR(tb_top)
		: clk("clk"), nrst("nrst")
		, mem_hub("mem_hub"), memory("memory"), stimul("stimul")
	{
		// Connect memory hub signals
		mem_hub.clk(clk);
		mem_hub.nrst(nrst);
		mem_hub.M0_AXI4_AWID(s_M0_AXI4_AWID);
		mem_hub.M0_AXI4_AWADDR(s_M0_AXI4_AWADDR);
		mem_hub.M0_AXI4_AWLEN(s_M0_AXI4_AWLEN);
		mem_hub.M0_AXI4_AWSIZE(s_M0_AXI4_AWSIZE);
		mem_hub.M0_AXI4_AWBURST(s_M0_AXI4_AWBURST);
		mem_hub.M0_AXI4_AWLOCK(s_M0_AXI4_AWLOCK);
		mem_hub.M0_AXI4_AWCACHE(s_M0_AXI4_AWCACHE);
		mem_hub.M0_AXI4_AWPROT(s_M0_AXI4_AWPROT);
		mem_hub.M0_AXI4_AWVALID(s_M0_AXI4_AWVALID);
		mem_hub.M0_AXI4_AWREADY(s_M0_AXI4_AWREADY);
		mem_hub.M0_AXI4_WDATA(s_M0_AXI4_WDATA);
		mem_hub.M0_AXI4_WSTRB(s_M0_AXI4_WSTRB);
		mem_hub.M0_AXI4_WLAST(s_M0_AXI4_WLAST);
		mem_hub.M0_AXI4_WVALID(s_M0_AXI4_WVALID);
		mem_hub.M0_AXI4_WREADY(s_M0_AXI4_WREADY);
		mem_hub.M0_AXI4_BID(s_M0_AXI4_BID);
		mem_hub.M0_AXI4_BRESP(s_M0_AXI4_BRESP);
		mem_hub.M0_AXI4_BVALID(s_M0_AXI4_BVALID);
		mem_hub.M0_AXI4_BREADY(s_M0_AXI4_BREADY);
		mem_hub.M0_AXI4_ARID(s_M0_AXI4_ARID);
		mem_hub.M0_AXI4_ARADDR(s_M0_AXI4_ARADDR);
		mem_hub.M0_AXI4_ARLEN(s_M0_AXI4_ARLEN);
		mem_hub.M0_AXI4_ARSIZE(s_M0_AXI4_ARSIZE);
		mem_hub.M0_AXI4_ARBURST(s_M0_AXI4_ARBURST);
		mem_hub.M0_AXI4_ARLOCK(s_M0_AXI4_ARLOCK);
		mem_hub.M0_AXI4_ARCACHE(s_M0_AXI4_ARCACHE);
		mem_hub.M0_AXI4_ARPROT(s_M0_AXI4_ARPROT);
		mem_hub.M0_AXI4_ARVALID(s_M0_AXI4_ARVALID);
		mem_hub.M0_AXI4_ARREADY(s_M0_AXI4_ARREADY);
		mem_hub.M0_AXI4_RID(s_M0_AXI4_RID);
		mem_hub.M0_AXI4_RDATA(s_M0_AXI4_RDATA);
		mem_hub.M0_AXI4_RRESP(s_M0_AXI4_RRESP);
		mem_hub.M0_AXI4_RLAST(s_M0_AXI4_RLAST);
		mem_hub.M0_AXI4_RVALID(s_M0_AXI4_RVALID);
		mem_hub.M0_AXI4_RREADY(s_M0_AXI4_RREADY);
		mem_hub.M1_AXI4_AWID(s_M1_AXI4_AWID);
		mem_hub.M1_AXI4_AWADDR(s_M1_AXI4_AWADDR);
		mem_hub.M1_AXI4_AWLEN(s_M1_AXI4_AWLEN);
		mem_hub.M1_AXI4_AWSIZE(s_M1_AXI4_AWSIZE);
		mem_hub.M1_AXI4_AWBURST(s_M1_AXI4_AWBURST);
		mem_hub.M1_AXI4_AWLOCK(s_M1_AXI4_AWLOCK);
		mem_hub.M1_AXI4_AWCACHE(s_M1_AXI4_AWCACHE);
		mem_hub.M1_AXI4_AWPROT(s_M1_AXI4_AWPROT);
		mem_hub.M1_AXI4_AWVALID(s_M1_AXI4_AWVALID);
		mem_hub.M1_AXI4_AWREADY(s_M1_AXI4_AWREADY);
		mem_hub.M1_AXI4_WDATA(s_M1_AXI4_WDATA);
		mem_hub.M1_AXI4_WSTRB(s_M1_AXI4_WSTRB);
		mem_hub.M1_AXI4_WLAST(s_M1_AXI4_WLAST);
		mem_hub.M1_AXI4_WVALID(s_M1_AXI4_WVALID);
		mem_hub.M1_AXI4_WREADY(s_M1_AXI4_WREADY);
		mem_hub.M1_AXI4_BID(s_M1_AXI4_BID);
		mem_hub.M1_AXI4_BRESP(s_M1_AXI4_BRESP);
		mem_hub.M1_AXI4_BVALID(s_M1_AXI4_BVALID);
		mem_hub.M1_AXI4_BREADY(s_M1_AXI4_BREADY);
		mem_hub.M1_AXI4_ARID(s_M1_AXI4_ARID);
		mem_hub.M1_AXI4_ARADDR(s_M1_AXI4_ARADDR);
		mem_hub.M1_AXI4_ARLEN(s_M1_AXI4_ARLEN);
		mem_hub.M1_AXI4_ARSIZE(s_M1_AXI4_ARSIZE);
		mem_hub.M1_AXI4_ARBURST(s_M1_AXI4_ARBURST);
		mem_hub.M1_AXI4_ARLOCK(s_M1_AXI4_ARLOCK);
		mem_hub.M1_AXI4_ARCACHE(s_M1_AXI4_ARCACHE);
		mem_hub.M1_AXI4_ARPROT(s_M1_AXI4_ARPROT);
		mem_hub.M1_AXI4_ARVALID(s_M1_AXI4_ARVALID);
		mem_hub.M1_AXI4_ARREADY(s_M1_AXI4_ARREADY);
		mem_hub.M1_AXI4_RID(s_M1_AXI4_RID);
		mem_hub.M1_AXI4_RDATA(s_M1_AXI4_RDATA);
		mem_hub.M1_AXI4_RRESP(s_M1_AXI4_RRESP);
		mem_hub.M1_AXI4_RLAST(s_M1_AXI4_RLAST);
		mem_hub.M1_AXI4_RVALID(s_M1_AXI4_RVALID);
		mem_hub.M1_AXI4_RREADY(s_M1_AXI4_RREADY);
		mem_hub.i_cu_m_sel(s_cu_m_sel);
		mem_hub.o_cu_rqa_rdy(s_cu_rqa_rdy);
		mem_hub.i_cu_rqa(s_cu_rqa);
		mem_hub.i_cu_rqa_wr(s_cu_rqa_wr);
		mem_hub.o_cu_rss_vld(s_cu_rss_vld);
		mem_hub.o_cu_rss(s_cu_rss);
		mem_hub.i_cu_rss_rd(s_cu_rss_rd);
		mem_hub.o_cu_rsd_vld(s_cu_rsd_vld);
		mem_hub.o_cu_rsd(s_cu_rsd);
		mem_hub.i_cu_rsd_rd(s_cu_rsd_rd);
		mem_hub.o_vpu0_rqa_rdy(s_vpu0_rqa_rdy);
		mem_hub.i_vpu0_rqa(s_vpu0_rqa);
		mem_hub.i_vpu0_rqa_wr(s_vpu0_rqa_wr);
		mem_hub.o_vpu0_rqd_rdy(s_vpu0_rqd_rdy);
		mem_hub.i_vpu0_rqd(s_vpu0_rqd);
		mem_hub.i_vpu0_rqd_wr(s_vpu0_rqd_wr);
		mem_hub.o_vpu0_rss_vld(s_vpu0_rss_vld);
		mem_hub.o_vpu0_rss(s_vpu0_rss);
		mem_hub.i_vpu0_rss_rd(s_vpu0_rss_rd);
		mem_hub.o_vpu0_rsd_vld(s_vpu0_rsd_vld);
		mem_hub.o_vpu0_rsd(s_vpu0_rsd);
		mem_hub.i_vpu0_rsd_rd(s_vpu0_rsd_rd);
		mem_hub.o_vpu1_rqa_rdy(s_vpu1_rqa_rdy);
		mem_hub.i_vpu1_rqa(s_vpu1_rqa);
		mem_hub.i_vpu1_rqa_wr(s_vpu1_rqa_wr);
		mem_hub.o_vpu1_rqd_rdy(s_vpu1_rqd_rdy);
		mem_hub.i_vpu1_rqd(s_vpu1_rqd);
		mem_hub.i_vpu1_rqd_wr(s_vpu1_rqd_wr);
		mem_hub.o_vpu1_rss_vld(s_vpu1_rss_vld);
		mem_hub.o_vpu1_rss(s_vpu1_rss);
		mem_hub.i_vpu1_rss_rd(s_vpu1_rss_rd);
		mem_hub.o_vpu1_rsd_vld(s_vpu1_rsd_vld);
		mem_hub.o_vpu1_rsd(s_vpu1_rsd);
		mem_hub.i_vpu1_rsd_rd(s_vpu1_rsd_rd);

		// Connect memory signals
		memory.clk(clk);
		memory.nrst(nrst);
		memory.S0.AWID(s_M0_AXI4_AWID);
		memory.S0.AWADDR(s_M0_AXI4_AWADDR);
		memory.S0.AWLEN(s_M0_AXI4_AWLEN);
		memory.S0.AWSIZE(s_M0_AXI4_AWSIZE);
		memory.S0.AWBURST(s_M0_AXI4_AWBURST);
		memory.S0.AWLOCK(s_M0_AXI4_AWLOCK);
		memory.S0.AWCACHE(s_M0_AXI4_AWCACHE);
		memory.S0.AWPROT(s_M0_AXI4_AWPROT);
		memory.S0.AWVALID(s_M0_AXI4_AWVALID);
		memory.S0.AWREADY(s_M0_AXI4_AWREADY);
		memory.S0.WDATA(s_M0_AXI4_WDATA);
		memory.S0.WSTRB(s_M0_AXI4_WSTRB);
		memory.S0.WLAST(s_M0_AXI4_WLAST);
		memory.S0.WVALID(s_M0_AXI4_WVALID);
		memory.S0.WREADY(s_M0_AXI4_WREADY);
		memory.S0.BID(s_M0_AXI4_BID);
		memory.S0.BRESP(s_M0_AXI4_BRESP);
		memory.S0.BVALID(s_M0_AXI4_BVALID);
		memory.S0.BREADY(s_M0_AXI4_BREADY);
		memory.S0.ARID(s_M0_AXI4_ARID);
		memory.S0.ARADDR(s_M0_AXI4_ARADDR);
		memory.S0.ARLEN(s_M0_AXI4_ARLEN);
		memory.S0.ARSIZE(s_M0_AXI4_ARSIZE);
		memory.S0.ARBURST(s_M0_AXI4_ARBURST);
		memory.S0.ARLOCK(s_M0_AXI4_ARLOCK);
		memory.S0.ARCACHE(s_M0_AXI4_ARCACHE);
		memory.S0.ARPROT(s_M0_AXI4_ARPROT);
		memory.S0.ARVALID(s_M0_AXI4_ARVALID);
		memory.S0.ARREADY(s_M0_AXI4_ARREADY);
		memory.S0.RID(s_M0_AXI4_RID);
		memory.S0.RDATA(s_M0_AXI4_RDATA);
		memory.S0.RRESP(s_M0_AXI4_RRESP);
		memory.S0.RLAST(s_M0_AXI4_RLAST);
		memory.S0.RVALID(s_M0_AXI4_RVALID);
		memory.S0.RREADY(s_M0_AXI4_RREADY);
		memory.S1.AWID(s_M1_AXI4_AWID);
		memory.S1.AWADDR(s_M1_AXI4_AWADDR);
		memory.S1.AWLEN(s_M1_AXI4_AWLEN);
		memory.S1.AWSIZE(s_M1_AXI4_AWSIZE);
		memory.S1.AWBURST(s_M1_AXI4_AWBURST);
		memory.S1.AWLOCK(s_M1_AXI4_AWLOCK);
		memory.S1.AWCACHE(s_M1_AXI4_AWCACHE);
		memory.S1.AWPROT(s_M1_AXI4_AWPROT);
		memory.S1.AWVALID(s_M1_AXI4_AWVALID);
		memory.S1.AWREADY(s_M1_AXI4_AWREADY);
		memory.S1.WDATA(s_M1_AXI4_WDATA);
		memory.S1.WSTRB(s_M1_AXI4_WSTRB);
		memory.S1.WLAST(s_M1_AXI4_WLAST);
		memory.S1.WVALID(s_M1_AXI4_WVALID);
		memory.S1.WREADY(s_M1_AXI4_WREADY);
		memory.S1.BID(s_M1_AXI4_BID);
		memory.S1.BRESP(s_M1_AXI4_BRESP);
		memory.S1.BVALID(s_M1_AXI4_BVALID);
		memory.S1.BREADY(s_M1_AXI4_BREADY);
		memory.S1.ARID(s_M1_AXI4_ARID);
		memory.S1.ARADDR(s_M1_AXI4_ARADDR);
		memory.S1.ARLEN(s_M1_AXI4_ARLEN);
		memory.S1.ARSIZE(s_M1_AXI4_ARSIZE);
		memory.S1.ARBURST(s_M1_AXI4_ARBURST);
		memory.S1.ARLOCK(s_M1_AXI4_ARLOCK);
		memory.S1.ARCACHE(s_M1_AXI4_ARCACHE);
		memory.S1.ARPROT(s_M1_AXI4_ARPROT);
		memory.S1.ARVALID(s_M1_AXI4_ARVALID);
		memory.S1.ARREADY(s_M1_AXI4_ARREADY);
		memory.S1.RID(s_M1_AXI4_RID);
		memory.S1.RDATA(s_M1_AXI4_RDATA);
		memory.S1.RRESP(s_M1_AXI4_RRESP);
		memory.S1.RLAST(s_M1_AXI4_RLAST);
		memory.S1.RVALID(s_M1_AXI4_RVALID);
		memory.S1.RREADY(s_M1_AXI4_RREADY);

		// Connect stimulus signals
		stimul.clk(clk);
		stimul.nrst(nrst);
		stimul.o_cu_m_sel(s_cu_m_sel);
		stimul.i_cu_rqa_rdy(s_cu_rqa_rdy);
		stimul.o_cu_rqa(s_cu_rqa);
		stimul.o_cu_rqa_wr(s_cu_rqa_wr);
		stimul.i_cu_rss_vld(s_cu_rss_vld);
		stimul.i_cu_rss(s_cu_rss);
		stimul.o_cu_rss_rd(s_cu_rss_rd);
		stimul.i_cu_rsd_vld(s_cu_rsd_vld);
		stimul.i_cu_rsd(s_cu_rsd);
		stimul.o_cu_rsd_rd(s_cu_rsd_rd);
		stimul.i_vpu0_rqa_rdy(s_vpu0_rqa_rdy);
		stimul.o_vpu0_rqa(s_vpu0_rqa);
		stimul.o_vpu0_rqa_wr(s_vpu0_rqa_wr);
		stimul.i_vpu0_rqd_rdy(s_vpu0_rqd_rdy);
		stimul.o_vpu0_rqd(s_vpu0_rqd);
		stimul.o_vpu0_rqd_wr(s_vpu0_rqd_wr);
		stimul.i_vpu0_rss_vld(s_vpu0_rss_vld);
		stimul.i_vpu0_rss(s_vpu0_rss);
		stimul.o_vpu0_rss_rd(s_vpu0_rss_rd);
		stimul.i_vpu0_rsd_vld(s_vpu0_rsd_vld);
		stimul.i_vpu0_rsd(s_vpu0_rsd);
		stimul.o_vpu0_rsd_rd(s_vpu0_rsd_rd);
		stimul.i_vpu1_rqa_rdy(s_vpu1_rqa_rdy);
		stimul.o_vpu1_rqa(s_vpu1_rqa);
		stimul.o_vpu1_rqa_wr(s_vpu1_rqa_wr);
		stimul.i_vpu1_rqd_rdy(s_vpu1_rqd_rdy);
		stimul.o_vpu1_rqd(s_vpu1_rqd);
		stimul.o_vpu1_rqd_wr(s_vpu1_rqd_wr);
		stimul.i_vpu1_rss_vld(s_vpu1_rss_vld);
		stimul.i_vpu1_rss(s_vpu1_rss);
		stimul.o_vpu1_rss_rd(s_vpu1_rss_rd);
		stimul.i_vpu1_rsd_vld(s_vpu1_rsd_vld);
		stimul.i_vpu1_rsd(s_vpu1_rsd);
		stimul.o_vpu1_rsd_rd(s_vpu1_rsd_rd);
	}

private:
	// Memory hub signals
	// AXI4 Master 0
	sc_signal<uint32_t>	s_M0_AXI4_AWID;
	sc_signal<uint64_t>	s_M0_AXI4_AWADDR;
	sc_signal<uint32_t>	s_M0_AXI4_AWLEN;
	sc_signal<uint32_t>	s_M0_AXI4_AWSIZE;
	sc_signal<uint32_t>	s_M0_AXI4_AWBURST;
	sc_signal<bool>		s_M0_AXI4_AWLOCK;
	sc_signal<uint32_t>	s_M0_AXI4_AWCACHE;
	sc_signal<uint32_t>	s_M0_AXI4_AWPROT;
	sc_signal<bool>		s_M0_AXI4_AWVALID;
	sc_signal<bool>		s_M0_AXI4_AWREADY;
	sc_signal<uint64_t>	s_M0_AXI4_WDATA;
	sc_signal<uint32_t>	s_M0_AXI4_WSTRB;
	sc_signal<bool>		s_M0_AXI4_WLAST;
	sc_signal<bool>		s_M0_AXI4_WVALID;
	sc_signal<bool>		s_M0_AXI4_WREADY;
	sc_signal<uint32_t>	s_M0_AXI4_BID;
	sc_signal<uint32_t>	s_M0_AXI4_BRESP;
	sc_signal<bool>		s_M0_AXI4_BVALID;
	sc_signal<bool>		s_M0_AXI4_BREADY;
	sc_signal<uint32_t>	s_M0_AXI4_ARID;
	sc_signal<uint64_t>	s_M0_AXI4_ARADDR;
	sc_signal<uint32_t>	s_M0_AXI4_ARLEN;
	sc_signal<uint32_t>	s_M0_AXI4_ARSIZE;
	sc_signal<uint32_t>	s_M0_AXI4_ARBURST;
	sc_signal<bool>		s_M0_AXI4_ARLOCK;
	sc_signal<uint32_t>	s_M0_AXI4_ARCACHE;
	sc_signal<uint32_t>	s_M0_AXI4_ARPROT;
	sc_signal<bool>		s_M0_AXI4_ARVALID;
	sc_signal<bool>		s_M0_AXI4_ARREADY;
	sc_signal<uint32_t>	s_M0_AXI4_RID;
	sc_signal<uint64_t>	s_M0_AXI4_RDATA;
	sc_signal<uint32_t>	s_M0_AXI4_RRESP;
	sc_signal<bool>		s_M0_AXI4_RLAST;
	sc_signal<bool>		s_M0_AXI4_RVALID;
	sc_signal<bool>		s_M0_AXI4_RREADY;
	// AXI4 Master 1
	sc_signal<uint32_t>	s_M1_AXI4_AWID;
	sc_signal<uint64_t>	s_M1_AXI4_AWADDR;
	sc_signal<uint32_t>	s_M1_AXI4_AWLEN;
	sc_signal<uint32_t>	s_M1_AXI4_AWSIZE;
	sc_signal<uint32_t>	s_M1_AXI4_AWBURST;
	sc_signal<bool>		s_M1_AXI4_AWLOCK;
	sc_signal<uint32_t>	s_M1_AXI4_AWCACHE;
	sc_signal<uint32_t>	s_M1_AXI4_AWPROT;
	sc_signal<bool>		s_M1_AXI4_AWVALID;
	sc_signal<bool>		s_M1_AXI4_AWREADY;
	sc_signal<uint64_t>	s_M1_AXI4_WDATA;
	sc_signal<uint32_t>	s_M1_AXI4_WSTRB;
	sc_signal<bool>		s_M1_AXI4_WLAST;
	sc_signal<bool>		s_M1_AXI4_WVALID;
	sc_signal<bool>		s_M1_AXI4_WREADY;
	sc_signal<uint32_t>	s_M1_AXI4_BID;
	sc_signal<uint32_t>	s_M1_AXI4_BRESP;
	sc_signal<bool>		s_M1_AXI4_BVALID;
	sc_signal<bool>		s_M1_AXI4_BREADY;
	sc_signal<uint32_t>	s_M1_AXI4_ARID;
	sc_signal<uint64_t>	s_M1_AXI4_ARADDR;
	sc_signal<uint32_t>	s_M1_AXI4_ARLEN;
	sc_signal<uint32_t>	s_M1_AXI4_ARSIZE;
	sc_signal<uint32_t>	s_M1_AXI4_ARBURST;
	sc_signal<bool>		s_M1_AXI4_ARLOCK;
	sc_signal<uint32_t>	s_M1_AXI4_ARCACHE;
	sc_signal<uint32_t>	s_M1_AXI4_ARPROT;
	sc_signal<bool>		s_M1_AXI4_ARVALID;
	sc_signal<bool>		s_M1_AXI4_ARREADY;
	sc_signal<uint32_t>	s_M1_AXI4_RID;
	sc_signal<uint64_t>	s_M1_AXI4_RDATA;
	sc_signal<uint32_t>	s_M1_AXI4_RRESP;
	sc_signal<bool>		s_M1_AXI4_RLAST;
	sc_signal<bool>		s_M1_AXI4_RVALID;
	sc_signal<bool>		s_M1_AXI4_RREADY;
	// CU
	// Master port select
	sc_signal<bool>		s_cu_m_sel;
	// Request channel
	sc_signal<bool>		s_cu_rqa_rdy;
	sc_signal<uint64_t>	s_cu_rqa;
	sc_signal<bool>		s_cu_rqa_wr;
	// Response channel
	sc_signal<bool>		s_cu_rss_vld;
	sc_signal<uint32_t>	s_cu_rss;
	sc_signal<bool>		s_cu_rss_rd;
	sc_signal<bool>		s_cu_rsd_vld;
	sc_signal<uint64_t>	s_cu_rsd;
	sc_signal<bool>		s_cu_rsd_rd;
	// VPU0
	// Request channel
	sc_signal<bool>		s_vpu0_rqa_rdy;
	sc_signal<uint64_t>	s_vpu0_rqa;
	sc_signal<bool>		s_vpu0_rqa_wr;
	sc_signal<bool>		s_vpu0_rqd_rdy;
	sc_signal<sc_bv<72>>	s_vpu0_rqd;
	sc_signal<bool>		s_vpu0_rqd_wr;
	// Response channel
	sc_signal<bool>		s_vpu0_rss_vld;
	sc_signal<uint32_t>	s_vpu0_rss;
	sc_signal<bool>		s_vpu0_rss_rd;
	sc_signal<bool>		s_vpu0_rsd_vld;
	sc_signal<uint64_t>	s_vpu0_rsd;
	sc_signal<bool>		s_vpu0_rsd_rd;
	// VPU1
	// Request channel
	sc_signal<bool>		s_vpu1_rqa_rdy;
	sc_signal<uint64_t>	s_vpu1_rqa;
	sc_signal<bool>		s_vpu1_rqa_wr;
	sc_signal<bool>		s_vpu1_rqd_rdy;
	sc_signal<sc_bv<72>>	s_vpu1_rqd;
	sc_signal<bool>		s_vpu1_rqd_wr;
	// Response channel
	sc_signal<bool>		s_vpu1_rss_vld;
	sc_signal<uint32_t>	s_vpu1_rss;
	sc_signal<bool>		s_vpu1_rss_rd;
	sc_signal<bool>		s_vpu1_rsd_vld;
	sc_signal<uint64_t>	s_vpu1_rsd;
	sc_signal<bool>		s_vpu1_rsd_rd;
};
