/*
 * Copyright (c) 2020-2025 The VxEngine Project. All rights reserved.
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
#include <sys_top.hxx>
#include <trace.hxx>


// MAIN
int sc_main(int argc, char *argv[])
{
	constexpr unsigned SZ_KB = 1024;
	sc_trace_file *sys_trace = nullptr;	// trace file
	VerilatedVcdSc *vl_trace = nullptr;	// Verilator SC trace
	size_t ram_size_kb = 4096;
	size_t ram_size = 0;
	const char *test_so_path = nullptr;
	bool do_trace = false;
	bool do_vtrace = false;

	// Hint for help
	if(argc < 2)
		std::cout << std::endl << "Use -h for help." << std::endl;

	// Parse Verilator command-line arguments
	Verilated::commandArgs(argc, argv);

	// Parse command-line arguments
	for(int i=1; i<argc; ++i) {
		if(!strcmp(argv[i], "-h")) {
			std::cout << std::endl << "Command line arguments:" << std::endl
				<< "\t-h                   - this help screen;" << std::endl
				<< "\t-memsz <size>        - memory size, KB (default: "
					<< ram_size_kb << ");" << std::endl
				<< "\t-test <file>         - test shared library file;" << std::endl
				<< "\t-trace               - dump trace;" << std::endl
				<< "\t-vtrace              - dump Verilator trace;" << std::endl
				<< std::endl;
			return 0;
		} else if(!strcmp(argv[i], "-trace")) {
			do_trace = true;
		} else if(!strcmp(argv[i], "-vtrace")) {
			do_vtrace = true;
		} else if(!strcmp(argv[i], "-memsz")) {
			++i;
			if(i<argc) {
				unsigned size = 0;
				try {
					size = std::stoi(argv[i]);
					if(size == 0)
						std::cerr << "-memsz: size cannot be 0." << std::endl;
				}
				catch(const std::exception& e)
				{
					std::cerr << e.what() << std::endl;
				}
				ram_size_kb = (size == 0 ? ram_size_kb : size);
			} else {
				std::cerr << "-memsz: missing size." << std::endl;
			}
		} else if(!strcmp(argv[i], "-test")) {
			++i;
			if(i<argc) {
				test_so_path = argv[i];
			} else {
				std::cerr << "-test: missing application shared library." << std::endl;
			}
		} else if(argv[i][0] == '+') {
			// skip Verilator arguments
		} else {
			std::cerr << "Unknown argument: " << argv[i] << std::endl;
		}
	}

	// Memory size in bytes
	ram_size = ram_size_kb * SZ_KB;

	// Print simulation summary
	std::cout << std::endl;
	std::cout << std::setfill('=') << std::setw(80) << "=" << std::endl;
	std::cout << "Simulation parameters:" << std::endl;
	std::cout << "> Tracing          : " << (do_trace ? "ON" : "OFF") << std::endl;
	std::cout << "> Verilator Tracing: " << (do_vtrace ? "ON" : "OFF") << std::endl;
	std::cout << "> RAM size, KB     : " << ram_size_kb << std::endl;
	std::cout << "> Test library     : " << (test_so_path ? test_so_path : "N/A") << std::endl;

	// System clock and reset
	sc_clock sys_clk("sys_clk", 10, SC_NS);
	sc_signal<bool> nrst;

	// Top-level
	sys_top top("sys_top");

	// Set memory size
	top.mem.mem.resize(ram_size);
	top.cpu.set_mem(top.mem.mem.data(), ram_size);
	if(test_so_path)
		top.cpu.set_so_file(test_so_path);

	// Bind signals
	top.clk(sys_clk);
	top.nrst(nrst);

	// Setup Verilator trace
	if(do_vtrace) {
		Verilated::traceEverOn(true);
		vl_trace = new VerilatedVcdSc();
		if(vl_trace) {
			top.vxe_wrapper.vxe_top.trace(vl_trace, 99);
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
		// VxE top-level RTL interface signals
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.clk);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.nrst);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.o_intr);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_AWID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_AWADDR);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_AWLEN);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_AWSIZE);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_AWBURST);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_AWLOCK);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_AWCACHE);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_AWPROT);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_AWVALID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_AWREADY);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_WDATA);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_WSTRB);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_WLAST);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_WVALID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_WREADY);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_BID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_BRESP);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_BVALID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_BREADY);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_ARID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_ARADDR);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_ARLEN);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_ARSIZE);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_ARBURST);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_ARLOCK);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_ARCACHE);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_ARPROT);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_ARVALID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_ARREADY);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_RID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_RDATA);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_RRESP);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_RLAST);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_RVALID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.S0_AXI4_RREADY);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_AWID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_AWADDR);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_AWLEN);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_AWSIZE);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_AWBURST);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_AWLOCK);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_AWCACHE);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_AWPROT);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_AWVALID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_AWREADY);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_WDATA);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_WSTRB);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_WLAST);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_WVALID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_WREADY);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_BID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_BRESP);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_BVALID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_BREADY);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_ARID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_ARADDR);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_ARLEN);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_ARSIZE);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_ARBURST);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_ARLOCK);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_ARCACHE);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_ARPROT);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_ARVALID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_ARREADY);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_RID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_RDATA);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_RRESP);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_RLAST);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_RVALID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M0_AXI4_RREADY);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_AWID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_AWADDR);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_AWLEN);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_AWSIZE);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_AWBURST);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_AWLOCK);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_AWCACHE);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_AWPROT);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_AWVALID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_AWREADY);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_WDATA);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_WSTRB);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_WLAST);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_WVALID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_WREADY);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_BID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_BRESP);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_BVALID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_BREADY);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_ARID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_ARADDR);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_ARLEN);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_ARSIZE);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_ARBURST);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_ARLOCK);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_ARCACHE);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_ARPROT);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_ARVALID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_ARREADY);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_RID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_RDATA);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_RRESP);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_RLAST);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_RVALID);
		sc_trace_x(sys_trace, top.vxe_wrapper.vxe_top.M1_AXI4_RREADY);
	}

	// Start simulation
	sc_start(0, SC_NS);
	nrst = 0;
	sc_start(100, SC_NS);
	nrst = 1;
	sc_start();

	top.vxe_wrapper.vxe_top.final();	// Done simulating

	// Close Verilator trace
	if(vl_trace) {
		vl_trace->close();
		delete vl_trace;
		vl_trace = nullptr;
	}

	// Close trace file
	if(sys_trace)
		sc_close_vcd_trace_file(sys_trace);

	// Return error code from the test
	return top.cpu.get_retval();
}
