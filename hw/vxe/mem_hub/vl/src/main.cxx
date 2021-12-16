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
 * Main function. Testbench top-level instantiation.
 */

#include <iostream>
#include <iomanip>
#include <cstring>
#include <systemc.h>
#include <tb_top.hxx>
#include <trace.hxx>


// MAIN
int sc_main(int argc, char *argv[])
{
	constexpr unsigned SZ_MB = 1024*1024;
	sc_trace_file *sys_trace = nullptr;	// trace file
	unsigned ram_size = 4*SZ_MB;
	bool do_trace = false;

	// Hint for help
	if(argc < 2)
		std::cout << std::endl << "Use -h for help." << std::endl;

	// Parse command-line arguments
	for(int i=1; i<argc; ++i) {
		if(!strcmp(argv[i], "-h")) {
			std::cout << std::endl << "Command line arguments:" << std::endl
				  << "\t-h                   - this help screen;" << std::endl
				  << "\t-trace               - dump trace." << std::endl
				  << std::endl;
			return 0;
		} else if(!strcmp(argv[i], "-trace")) {
			do_trace = true;
		} else {
			std::cerr << "Unknown argument: " << argv[i] << std::endl;
		}
	}

	// Print simulation summary
	std::cout << std::endl;
	std::cout << std::setfill('=') << std::setw(80) << "=" << std::endl;
	std::cout << "Simulation parameters:" << std::endl;
	std::cout << "> Tracing: " << (do_trace ? "ON" : "OFF") << std::endl;
	std::cout << std::setfill('=') << std::setw(80) << "=" << std::endl;

	// System clock and reset
	sc_clock sys_clk("sys_clk", 10, SC_NS);
	sc_signal<bool> nrst;

	// Top-level
	tb_top top("tb_top");

	// Set memory size
	top.memory.mem.resize(ram_size);

	// Bind signals
	top.clk(sys_clk);
	top.nrst(nrst);

	// Setup tracing
	sys_trace = (do_trace ? sc_create_vcd_trace_file("trace") : nullptr);
	if(sys_trace) {
		// Clock and reset
		sc_trace_x(sys_trace, sys_clk);
		sc_trace_x(sys_trace, nrst);
		// Top-level signals
		sc_trace_x(sys_trace, top.clk);
		sc_trace_x(sys_trace, top.nrst);
		// Memory hub signals
		sc_trace_x(sys_trace, top.mem_hub.clk);
		sc_trace_x(sys_trace, top.mem_hub.nrst);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_AWID);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_AWADDR);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_AWLEN);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_AWSIZE);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_AWBURST);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_AWLOCK);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_AWCACHE);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_AWPROT);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_AWVALID);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_AWREADY);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_WDATA);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_WSTRB);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_WLAST);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_WVALID);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_WREADY);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_BID);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_BRESP);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_BVALID);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_BREADY);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_ARID);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_ARADDR);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_ARLEN);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_ARSIZE);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_ARBURST);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_ARLOCK);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_ARCACHE);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_ARPROT);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_ARVALID);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_ARREADY);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_RID);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_RDATA);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_RRESP);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_RLAST);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_RVALID);
		sc_trace_x(sys_trace, top.mem_hub.M0_AXI4_RREADY);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_AWID);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_AWADDR);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_AWLEN);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_AWSIZE);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_AWBURST);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_AWLOCK);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_AWCACHE);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_AWPROT);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_AWVALID);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_AWREADY);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_WDATA);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_WSTRB);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_WLAST);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_WVALID);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_WREADY);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_BID);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_BRESP);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_BVALID);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_BREADY);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_ARID);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_ARADDR);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_ARLEN);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_ARSIZE);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_ARBURST);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_ARLOCK);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_ARCACHE);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_ARPROT);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_ARVALID);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_ARREADY);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_RID);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_RDATA);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_RRESP);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_RLAST);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_RVALID);
		sc_trace_x(sys_trace, top.mem_hub.M1_AXI4_RREADY);
		sc_trace_x(sys_trace, top.mem_hub.i_cu_m_sel);
		sc_trace_x(sys_trace, top.mem_hub.o_cu_rqa_rdy);
		sc_trace_x(sys_trace, top.mem_hub.i_cu_rqa);
		sc_trace_x(sys_trace, top.mem_hub.i_cu_rqa_wr);
		sc_trace_x(sys_trace, top.mem_hub.o_cu_rss_vld);
		sc_trace_x(sys_trace, top.mem_hub.o_cu_rss);
		sc_trace_x(sys_trace, top.mem_hub.i_cu_rss_rd);
		sc_trace_x(sys_trace, top.mem_hub.o_cu_rsd_vld);
		sc_trace_x(sys_trace, top.mem_hub.o_cu_rsd);
		sc_trace_x(sys_trace, top.mem_hub.i_cu_rsd_rd);
		sc_trace_x(sys_trace, top.mem_hub.o_vpu0_rqa_rdy);
		sc_trace_x(sys_trace, top.mem_hub.i_vpu0_rqa);
		sc_trace_x(sys_trace, top.mem_hub.i_vpu0_rqa_wr);
		sc_trace_x(sys_trace, top.mem_hub.o_vpu0_rqd_rdy);
		sc_trace_x(sys_trace, top.mem_hub.i_vpu0_rqd);
		sc_trace_x(sys_trace, top.mem_hub.i_vpu0_rqd_wr);
		sc_trace_x(sys_trace, top.mem_hub.o_vpu0_rss_vld);
		sc_trace_x(sys_trace, top.mem_hub.o_vpu0_rss);
		sc_trace_x(sys_trace, top.mem_hub.i_vpu0_rss_rd);
		sc_trace_x(sys_trace, top.mem_hub.o_vpu0_rsd_vld);
		sc_trace_x(sys_trace, top.mem_hub.o_vpu0_rsd);
		sc_trace_x(sys_trace, top.mem_hub.i_vpu0_rsd_rd);
		sc_trace_x(sys_trace, top.mem_hub.o_vpu1_rqa_rdy);
		sc_trace_x(sys_trace, top.mem_hub.i_vpu1_rqa);
		sc_trace_x(sys_trace, top.mem_hub.i_vpu1_rqa_wr);
		sc_trace_x(sys_trace, top.mem_hub.o_vpu1_rqd_rdy);
		sc_trace_x(sys_trace, top.mem_hub.i_vpu1_rqd);
		sc_trace_x(sys_trace, top.mem_hub.i_vpu1_rqd_wr);
		sc_trace_x(sys_trace, top.mem_hub.o_vpu1_rss_vld);
		sc_trace_x(sys_trace, top.mem_hub.o_vpu1_rss);
		sc_trace_x(sys_trace, top.mem_hub.i_vpu1_rss_rd);
		sc_trace_x(sys_trace, top.mem_hub.o_vpu1_rsd_vld);
		sc_trace_x(sys_trace, top.mem_hub.o_vpu1_rsd);
		sc_trace_x(sys_trace, top.mem_hub.i_vpu1_rsd_rd);
	}

	// Start simulation
	sc_start(0, SC_NS);
	nrst = 0;
	sc_start(100, SC_NS);
	nrst = 1;
	sc_start();

	// Close trace file
	if(sys_trace)
		sc_close_vcd_trace_file(sys_trace);

	return 0;
}
