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
 * Main function. Top-level instantiation.
 */

#include <iostream>
#include <iomanip>
#include <cstring>
#include <systemc.h>
#include <sys_top.hxx>
#include <trace.hxx>


// MAIN
int sc_main(int argc, char *argv[])
{
	constexpr unsigned SZ_MB = 1024*1024;
	sc_trace_file *sys_trace = 0;	// trace file
	unsigned ram_size = 4*SZ_MB;
	const char *so_file = nullptr;
	bool do_trace = false;

	// Hint for help
	if(argc < 2)
		std::cout << std::endl << "Use -h for help." << std::endl;

	// Parse command-line arguments
	for(int i=1; i<argc; ++i) {
		if(!strcmp(argv[i], "-h")) {
			std::cout << std::endl << "Command line arguments:" << std::endl
				<< "\t-h                   - this help screen;" << std::endl
				<< "\t-trace               - dump trace;" << std::endl
				<< "\t-ram <size MB>       - RAM size to use;" << std::endl
				<< "\t-so <so_file >       - app library to run." << std::endl
				<< std::endl;
			return 0;
		} else if(!strcmp(argv[i], "-trace")) {
			do_trace = true;
		} else if(!strcmp(argv[i], "-ram")) {
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
				size *= SZ_MB;
				ram_size = size ? size : ram_size;
			} else {
				std::cerr << "-ram: missing size." << std::endl;
			}
		} else if(!strcmp(argv[i], "-so")) {
			++i;
			if(i<argc) {
				so_file = argv[i];
			} else {
				std::cerr << "-so: missing file name." << std::endl;
			}
		} else {
			std::cerr << "Unknown argument: " << argv[i] << std::endl;
		}
	}

	// Print simulation summary
	std::cout << std::endl;
	std::cout << std::setfill('=') << std::setw(80) << "=" << std::endl;
	std::cout << "Simulation parameters:" << std::endl;
	std::cout << "> Tracing: " << (do_trace ? "ON" : "OFF") << std::endl;
	std::cout << "> RAM size: " << (ram_size/SZ_MB) << "MB" << std::endl;
	std::cout << "> Shared object: " << (so_file ? so_file : "N/A") << std::endl;
	std::cout << std::setfill('=') << std::setw(80) << "=" << std::endl;

	// System clock and reset
	sc_clock sys_clk("sys_clk", 10, SC_NS);
	sc_signal<bool> nrst;

	// Top-level
	sys_top top("sys_top");

	// Bind signals
	top.clk(sys_clk);
	top.nrst(nrst);

	// Set model parameters
	top.cpu.so_file = so_file ? so_file : "";
	top.ram.mem.resize(ram_size);

	// Setup tracing
	sys_trace = (do_trace ? sc_create_vcd_trace_file("trace") : 0);
	if(sys_trace) {
		// Clock and reset
		sc_trace_x(sys_trace, sys_clk);
		sc_trace_x(sys_trace, nrst);

		//TODO:
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
