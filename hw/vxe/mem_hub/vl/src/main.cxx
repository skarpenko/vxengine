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
 * Main function. Testbench top-level instantiation.
 */

#include <iostream>
#include <iomanip>
#include <cstring>
#include <systemc.h>
#include <verilated.h>
#include <verilated_vcd_sc.h>
#include <tb_top.hxx>
#include <trace.hxx>


void setup_tests(tb_top& top);
void dump_memory(const std::vector<uint8_t>& mem);


// MAIN
int sc_main(int argc, char *argv[])
{
	constexpr unsigned SZ_KB = 1024;
	sc_trace_file *sys_trace = nullptr;	// trace file
	VerilatedVcdSc *vl_trace = nullptr;	// Verilator SC trace
	size_t ram_size = 0;
	size_t region_size = 8*SZ_KB;	// Two pages by default
	bool do_trace = false;
	bool do_vtrace = false;
	bool do_memdump = false;
	unsigned ardelay0 = 0;
	unsigned awdelay0 = 0;
	unsigned wdelay0 = 0;
	unsigned ardelay1 = 0;
	unsigned awdelay1 = 0;
	unsigned wdelay1 = 0;

	// Hint for help
	if(argc < 2)
		std::cout << std::endl << "Use -h for help." << std::endl;

	// Parse command-line arguments
	for(int i=1; i<argc; ++i) {
		if(!strcmp(argv[i], "-h")) {
			std::cout << std::endl << "Command line arguments:" << std::endl
				<< "\t-h                   - this help screen;" << std::endl
				<< "\t-trace               - dump trace;" << std::endl
				<< "\t-vtrace              - dump Verilator trace;" << std::endl
				<< "\t-memdump             - dump memory contents;" << std::endl
				<< "\t-ardelay0 <cycles>   - Delay in AXI AR channel for port 0;"
				<< "\t-awdelay0 <cycles>   - Delay in AXI AW channel for port 0;"
				<< "\t-wdelay0 <cycles>    - Delay in AXI W channel for port 0;"
				<< "\t-ardelay1 <cycles>   - Delay in AXI AR channel for port 1;"
				<< "\t-awdelay1 <cycles>   - Delay in AXI AW channel for port 1;"
				<< "\t-wdelay1 <cycles>    - Delay in AXI W channel for port 1;"
				<< "\t-regsz <size KB>     - test region size (default: 8KB)." << std::endl
				<< std::endl;
			return 0;
		} else if(!strcmp(argv[i], "-trace")) {
			do_trace = true;
		} else if(!strcmp(argv[i], "-vtrace")) {
			do_vtrace = true;
		} else if(!strcmp(argv[i], "-memdump")) {
			do_memdump = true;
		} else if(!strcmp(argv[i], "-ardelay0")) {
			++i;
			if(i<argc) {
				try {
					ardelay0 = std::stoi(argv[i]);
				}
				catch(const std::exception& e)
				{
					std::cerr << e.what() << std::endl;
				}
			} else {
				std::cerr << "-ardelay0: missing delay." << std::endl;
			}
		} else if(!strcmp(argv[i], "-awdelay0")) {
			++i;
			if(i<argc) {
				try {
					awdelay0 = std::stoi(argv[i]);
				}
				catch(const std::exception& e)
				{
					std::cerr << e.what() << std::endl;
				}
			} else {
				std::cerr << "-awdelay0: missing delay." << std::endl;
			}
		} else if(!strcmp(argv[i], "-wdelay0")) {
			++i;
			if(i<argc) {
				try {
					wdelay0 = std::stoi(argv[i]);
				}
				catch(const std::exception& e)
				{
					std::cerr << e.what() << std::endl;
				}
			} else {
				std::cerr << "-wdelay0: missing delay." << std::endl;
			}
		} else if(!strcmp(argv[i], "-ardelay1")) {
			++i;
			if(i<argc) {
				try {
					ardelay1 = std::stoi(argv[i]);
				}
				catch(const std::exception& e)
				{
					std::cerr << e.what() << std::endl;
				}
			} else {
				std::cerr << "-ardelay1: missing delay." << std::endl;
			}
		} else if(!strcmp(argv[i], "-awdelay1")) {
			++i;
			if(i<argc) {
				try {
					awdelay1 = std::stoi(argv[i]);
				}
				catch(const std::exception& e)
				{
					std::cerr << e.what() << std::endl;
				}
			} else {
				std::cerr << "-awdelay1: missing delay." << std::endl;
			}
		} else if(!strcmp(argv[i], "-wdelay1")) {
			++i;
			if(i<argc) {
				try {
					wdelay1 = std::stoi(argv[i]);
				}
				catch(const std::exception& e)
				{
					std::cerr << e.what() << std::endl;
				}
			} else {
				std::cerr << "-wdelay1: missing delay." << std::endl;
			}
		} else if(!strcmp(argv[i], "-regsz")) {
			++i;
			if(i<argc) {
				unsigned size = 0;
				try {
					size = std::stoi(argv[i]);
				}
				catch(const std::exception& e)
				{
					std::cerr << e.what() << std::endl;
				}
				size *= SZ_KB;
				region_size = size ? size : region_size;
			} else {
				std::cerr << "-regsz: missing size." << std::endl;
			}
		} else {
			std::cerr << "Unknown argument: " << argv[i] << std::endl;
		}
	}

	// Setup tests memory map
	ram_size = stimul::init_test_regions(region_size);

	// Print simulation summary
	std::cout << std::endl;
	std::cout << std::setfill('=') << std::setw(80) << "=" << std::endl;
	std::cout << "Simulation parameters:" << std::endl;
	std::cout << "> Tracing          : " << (do_trace ? "ON" : "OFF") << std::endl;
	std::cout << "> Verilator Tracing: " << (do_vtrace ? "ON" : "OFF") << std::endl;
	std::cout << "> Memory dump      : " << (do_memdump ? "ON" : "OFF") << std::endl;
	std::cout << "> Region size      : " << region_size << std::endl;
	std::cout << "> RAM size         : " << ram_size << std::endl;
	std::cout << "> Port 0 delays    : "
		<< "AR=" << ardelay0 << "/" << "AW=" << awdelay0 << "/" << "W=" << wdelay0 << std::endl;
	std::cout << "> Port 1 delays    : "
		<< "AR=" << ardelay1 << "/" << "AW=" << awdelay1 << "/" << "W=" << wdelay1 << std::endl;
	std::cout << std::setfill('=') << std::setw(80) << "=" << std::endl;

	// System clock and reset
	sc_clock sys_clk("sys_clk", 10, SC_NS);
	sc_signal<bool> nrst;

	// Top-level
	tb_top top("tb_top");

	// Set memory size
	top.memory.mem.resize(ram_size);
	// Set port delays
	top.memory.S0.set_delays(ardelay0, awdelay0, wdelay0);
	top.memory.S1.set_delays(ardelay1, awdelay1, wdelay1);

	// Setup tests to run
	setup_tests(top);

	// Bind signals
	top.clk(sys_clk);
	top.nrst(nrst);

	// Setup Verilator trace
	if(do_vtrace) {
		Verilated::traceEverOn(true);
		vl_trace = new VerilatedVcdSc();
		if(vl_trace) {
			top.mem_hub.trace(vl_trace, 99);
			vl_trace->open("vltrace.vcd");
		}
	}

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

	top.mem_hub.final();	// Done simulating

	// Close Verilator trace
	if(vl_trace) {
		vl_trace->close();
		delete vl_trace;
		vl_trace = nullptr;
	}

	// Close trace file
	if(sys_trace)
		sc_close_vcd_trace_file(sys_trace);

	// Dump memory contents
	if(do_memdump)
		dump_memory(top.memory.mem);

	// Return error code if some tests failed
	return top.stimul.get_failed() ? -1 : 0;
}

void setup_tests(tb_top& top)
{
	// Filling regions with patterns
	top.stimul.add_test(std::make_shared<stimul::test_write_region>("Write: Region 0, VPU0", 0, 0,
		0xFEFEFAFABEBE0000));
	top.stimul.add_test(std::make_shared<stimul::test_write_region>("Write: Region 1, VPU1", 1, 1,
		0xDADABEBEAEAE0000));
	top.stimul.add_test(std::make_shared<stimul::test_write_region>("Write: Region 2, VPU0", 2, 0,
		0xAEAEBEBEFEFE0000));

	// CU read tests
	top.stimul.add_test(std::make_shared<stimul::test_read_regions>("Read: Region 0, CU M0",
		true, false, 0, 0xFEFEFAFABEBE0000, true,
		false, false, 0, 0, false,
		false, false, 0, 0, false));

	top.stimul.add_test(std::make_shared<stimul::test_read_regions>("Read: Region 0, CU M1",
		true, true, 0, 0xFEFEFAFABEBE0000, true,
		false, false, 0, 0, false,
		false, false, 0, 0, false));

	// CU and VPU0 read tests
	top.stimul.add_test(std::make_shared<stimul::test_read_regions>("Read: Region 0, CU M0 | Region 1, VPU0 Rs arg",
		true, false, 0, 0xFEFEFAFABEBE0000, true,
		true, false, 1, 0xDADABEBEAEAE0000, true,
		false, false, 0, 0, false));

	top.stimul.add_test(std::make_shared<stimul::test_read_regions>("Read: Region 0, CU M0 | Region 1, VPU0 Rt arg",
		true, false, 0, 0xFEFEFAFABEBE0000, true,
		true, true, 1, 0xDADABEBEAEAE0000, true,
		false, false, 0, 0, false));

	top.stimul.add_test(std::make_shared<stimul::test_read_regions>("Read: Region 0, CU M1 | Region 1, VPU0 Rt arg",
		true, true, 0, 0xFEFEFAFABEBE0000, true,
		true, true, 1, 0xDADABEBEAEAE0000, true,
		false, false, 0, 0, false));

	top.stimul.add_test(std::make_shared<stimul::test_read_regions>("Read: Region 0, CU M1 | Region 1, VPU0 Rs arg",
		true, true, 0, 0xFEFEFAFABEBE0000, true,
		true, false, 1, 0xDADABEBEAEAE0000, true,
		false, false, 0, 0, false));

	// CU and VPU1 read tests
	top.stimul.add_test(std::make_shared<stimul::test_read_regions>("Read: Region 0, CU M0 | Region 2, VPU1 Rs arg",
		true, false, 0, 0xFEFEFAFABEBE0000, true,
		false, false, 0, 0, false,
		true, false, 2, 0xAEAEBEBEFEFE0000, true));

	top.stimul.add_test(std::make_shared<stimul::test_read_regions>("Read: Region 0, CU M0 | Region 2, VPU1 Rt arg",
		true, false, 0, 0xFEFEFAFABEBE0000, true,
		false, false, 0, 0, false,
		true, true, 2, 0xAEAEBEBEFEFE0000, true));

	top.stimul.add_test(std::make_shared<stimul::test_read_regions>("Read: Region 0, CU M1 | Region 2, VPU1 Rt arg",
		true, true, 0, 0xFEFEFAFABEBE0000, true,
		false, false, 0, 0, false,
		true, true, 2, 0xAEAEBEBEFEFE0000, true));

	top.stimul.add_test(std::make_shared<stimul::test_read_regions>("Read: Region 0, CU M1 | Region 2, VPU1 Rs arg",
		true, true, 0, 0xFEFEFAFABEBE0000, true,
		false, false, 0, 0, false,
		true, false, 2, 0xAEAEBEBEFEFE0000, true));

	// CU, VPU0 and VPU1 read tests
	top.stimul.add_test(std::make_shared<stimul::test_read_regions>(
		"Read: Region 0, CU M0 | Region 1, VPU0 Rs arg | Region 2, VPU1 Rs arg",
		true, false, 0, 0xFEFEFAFABEBE0000, true,
		true, false, 1, 0xDADABEBEAEAE0000, true,
		true, false, 2, 0xAEAEBEBEFEFE0000, true));

	top.stimul.add_test(std::make_shared<stimul::test_read_regions>(
		"Read: Region 0, CU M1 | Region 1, VPU0 Rs arg | Region 2, VPU1 Rs arg",
		true, true, 0, 0xFEFEFAFABEBE0000, true,
		true, false, 1, 0xDADABEBEAEAE0000, true,
		true, false, 2, 0xAEAEBEBEFEFE0000, true));

	top.stimul.add_test(std::make_shared<stimul::test_read_regions>(
		"Read: Region 0, CU M0 | Region 1, VPU0 Rt arg | Region 2, VPU1 Rs arg",
		true, false, 0, 0xFEFEFAFABEBE0000, true,
		true, true, 1, 0xDADABEBEAEAE0000, true,
		true, false, 2, 0xAEAEBEBEFEFE0000, true));

	top.stimul.add_test(std::make_shared<stimul::test_read_regions>(
		"Read: Region 0, CU M1 | Region 1, VPU0 Rt arg | Region 2, VPU1 Rs arg",
		true, true, 0, 0xFEFEFAFABEBE0000, true,
		true, true, 1, 0xDADABEBEAEAE0000, true,
		true, false, 2, 0xAEAEBEBEFEFE0000, true));

	top.stimul.add_test(std::make_shared<stimul::test_read_regions>(
		"Read: Region 0, CU M0 | Region 1, VPU0 Rs arg | Region 2, VPU1 Rt arg",
		true, false, 0, 0xFEFEFAFABEBE0000, true,
		true, false, 1, 0xDADABEBEAEAE0000, true,
		true, true, 2, 0xAEAEBEBEFEFE0000, true));

	top.stimul.add_test(std::make_shared<stimul::test_read_regions>(
		"Read: Region 0, CU M1 | Region 1, VPU0 Rs arg | Region 2, VPU1 Rt arg",
		true, true, 0, 0xFEFEFAFABEBE0000, true,
		true, false, 1, 0xDADABEBEAEAE0000, true,
		true, true, 2, 0xAEAEBEBEFEFE0000, true));

	top.stimul.add_test(std::make_shared<stimul::test_read_regions>(
		"Read: Region 0, CU M0 | Region 1, VPU0 Rt arg | Region 2, VPU1 Rt arg",
		true, false, 0, 0xFEFEFAFABEBE0000, true,
		true, true, 1, 0xDADABEBEAEAE0000, true,
		true, true, 2, 0xAEAEBEBEFEFE0000, true));

	top.stimul.add_test(std::make_shared<stimul::test_read_regions>(
		"Read: Region 0, CU M1 | Region 1, VPU0 Rt arg | Region 2, VPU1 Rt arg",
		true, true, 0, 0xFEFEFAFABEBE0000, true,
		true, true, 1, 0xDADABEBEAEAE0000, true,
		true, true, 2, 0xAEAEBEBEFEFE0000, true));

	// CU, VPU0, VPU1 read and write tests
	top.stimul.add_test(std::make_shared<stimul::test_rdwr_regions>(
		"Read/write: Region 0, CU M0 Rd | Region 3, VPU0 Wr | Region 2, VPU1 Rd",
		false, 0, 0xFEFEFAFABEBE0000,
		false, false, 3, 0x1212121212120000, 0xFF, true,
		true, false, 2, 0xAEAEBEBEFEFE0000, 0xFF, true));

	top.stimul.add_test(std::make_shared<stimul::test_rdwr_regions>(
		"Read/write: Region 0, CU M1 Rd | Region 4, VPU0 Wr | Region 2, VPU1 Rd",
		true, 0, 0xFEFEFAFABEBE0000,
		false, false, 4, 0x2323232323230000, 0xFF, true,
		true, false, 2, 0xAEAEBEBEFEFE0000, 0xFF, true));

	top.stimul.add_test(std::make_shared<stimul::test_rdwr_regions>(
		"Read/write: Region 0, CU M0 Rd | Region 1, VPU0 Rd | Region 5, VPU1 Wr",
		false, 0, 0xFEFEFAFABEBE0000,
		true, false, 1, 0xDADABEBEAEAE0000, 0xFF, true,
		false, false, 5, 0x3434343434340000, 0xFF, true));

	top.stimul.add_test(std::make_shared<stimul::test_rdwr_regions>(
		"Read/write: Region 0, CU M1 Rd | Region 1, VPU0 Rd | Region 6, VPU1 Wr",
		true, 0, 0xFEFEFAFABEBE0000,
		true, false, 1, 0xDADABEBEAEAE0000, 0xFF, true,
		false, false, 6, 0x4545454545450000, 0xFF, true));

	top.stimul.add_test(std::make_shared<stimul::test_rdwr_regions>(
		"Read/write: Region 0, CU M0 Rd | Region 7, VPU0 Wr | Region 8, VPU1 Wr",
		false, 0, 0xFEFEFAFABEBE0000,
		false, false, 7, 0x5656565656560000, 0xFF, true,
		false, false, 8, 0x6767676767670000, 0xFF, true));

	top.stimul.add_test(std::make_shared<stimul::test_rdwr_regions>(
		"Read/write: Region 0, CU M1 Rd | Region 9, VPU0 Wr | Region 10, VPU1 Wr",
		true, 0, 0xFEFEFAFABEBE0000,
		false, false, 9, 0x7878787878780000, 0xFF, true,
		false, false, 10, 0x8989898989890000, 0xFF, true));

	// Verify written data
	top.stimul.add_test(std::make_shared<stimul::test_read_regions>(
		"Read/write: Region 3, CU M0 Rd | Region 4, VPU0 Rd | Region 5, VPU1 Rd",
		true, false, 3, 0x1212121212120000, true,
		true, false, 4, 0x2323232323230000, true,
		true, false, 5, 0x3434343434340000, true));

	top.stimul.add_test(std::make_shared<stimul::test_read_regions>(
		"Read/write: Region 6, CU M0 Rd | Region 7, VPU0 Rd | Region 8, VPU1 Rd",
		true, false, 6, 0x4545454545450000, true,
		true, false, 7, 0x5656565656560000, true,
		true, true, 8, 0x6767676767670000, true));

	top.stimul.add_test(std::make_shared<stimul::test_read_regions>(
		"Read/write: Region 9, VPU0 Rd | Region 10, VPU1 Rd",
		false, false, 0, 0, false,
		true, true, 9, 0x7878787878780000, true,
		true, false, 10, 0x8989898989890000, true));

	// CU reads, VPU0, VPU1 use byte enabled writes
	top.stimul.add_test(std::make_shared<stimul::test_rdwr_regions>(
		"Read/write: Region 0, CU M0 Rd | Region 11, VPU0 Wr(BEn=0x55) | Region 12, VPU1 Wr(BEn=0x55)",
		false, 0, 0xFEFEFAFABEBE0000,
		false, false, 11, 0xF7F6F5F4F3F2F1F0, 0x55, false,
		false, false, 12, 0xE7E6E5E4E3E2E1E0, 0x55, false));

	top.stimul.add_test(std::make_shared<stimul::test_rdwr_regions>(
		"Read/write: Region 0, CU M1 Rd | Region 11, VPU0 Wr(BEn=0xAA) | Region 12, VPU1 Wr(BEn=0xAA)",
		true, 0, 0xFEFEFAFABEBE0000,
		false, false, 11, 0xA7A6A5A4A3A2A1A0, 0xAA, false,
		false, false, 12, 0xB7B6B5B4B3B2B1B0, 0xAA, false));

	// Verify written data
	top.stimul.add_test(std::make_shared<stimul::test_read_regions>(
		"Read/write: Region 11, VPU0 Rd | Region 12, VPU1 Rd",
		false, false, 0, 0, false,
		true, false, 11, 0xA7F6A5F4A3F2A1F0, false,
		true, true, 12, 0xB7E6B5E4B3E2B1E0, false));
}

void dump_memory(const std::vector<uint8_t>& mem)
{
	std::cout << "Dumping memory..." << std::endl;

	std::ofstream of("memdump.txt");

	bool print = true;
	uint64_t paddr, addr = 0;
	const uint64_t *data;
	unsigned len = mem.size() / sizeof(uint64_t);

	for(unsigned i = 0; i < len; ++i) {
		data = reinterpret_cast<const uint64_t*>(&mem[addr]);
		paddr = addr;
		addr += sizeof(uint64_t);

		if(*data == 0 && print) {
			of << std::string(16, ' ') << "..." << std::endl;
			print = false;
			continue;
		} else if(*data == 0)
			continue;

		print = true;

		of << std::setw(16) << std::setfill('0') << std::hex << paddr << ": "
			<< std::setw(16) << std::setfill('0') << std::hex << *data << std::endl;
	}
}
