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
 * Single precision 5-stage floating point multiply-accumulate test (C++ main)
 */

#include <cstdint>
#include <ctime>
#include <iostream>
#include <iomanip>
#include <vector>
#include <algorithm>
#include <verilated.h>		// Defines common routines
#if VM_TRACE
# include <verilated_vcd_c.h>	// Trace file format header
#endif
#include "Vvl_flp32_mac_5stg.h"	// From Verilating "vl_flp32_mac_5stg.v"
#include "vl_common.hxx"	// Common Verilator types

// Floating point reference model
#include "hwfmac.hxx"
#include "common.hxx"


#define SRAND_SEED()	std::time(NULL)

constexpr uint64_t NITER = 10000000000;
constexpr uint64_t NPRIN = 100000;

constexpr int rst_cycles = 10;	// Reset cycles

vluint64_t main_time = 0;	// Current simulation time

#if VM_TRACE
VerilatedVcdC* tfp = 0;		// Trace file
#endif


// Called by $time in Verilog
double sc_time_stamp()
{
	return main_time;
}


// Check result
bool check_result(const aux::float_t& rm, const aux::float_t& rh)
{
	bool res = true;

	if(rm.v != rh.v) {
		std::ios state(nullptr);
		state.copyfmt(std::cout);
		std::cout << "[!] "
			<< std::setfill('0') << std::hex
			<< std::setw(8) << rm.v << " != "
			<< std::setw(8) << rh.v
			<< "\t"
			<< rm.f << " != " << rh.f
			<< std::endl;
		std::cout.copyfmt(state);
		res = false;
	}

	return res;
}


// Floating point multiply-accumulate reference model
uint32_t mac_test(uint32_t a, uint32_t b, uint32_t c)
{
	uint32_t r;

	hwfmac::mac<uint32_t, uint64_t, 8, 23, 23>(a, b, c, r);

	return r;
}


// MAIN
int main(int argc, char **argv)
{
	std::cout << "FP32 5-stage multiply-accumulate test" << std::endl;

	srand(SRAND_SEED());

	Verilated::commandArgs(argc, argv);	// Pass args to Verilator

	// Create top-level instance
	model_top<Vvl_flp32_mac_5stg> top;

#if VM_TRACE
	Verilated::traceEverOn(true);	// Enable traces
	tfp = new VerilatedVcdC;
	top->trace(tfp, 99);		// Trace 99 levels of hierarchy
	tfp->open("vlt_dump.vcd");	// Open the dump file
#endif


	// Set initial clock and reset
	top->nrst = 0;
	top->clk = 0;

	// Reset logic
	for(int i = 0; i <= rst_cycles; ++i) {
		top->nrst = (i == rst_cycles ? 1 : 0);	// De-assert reset
		for(int h = 0; h < 2 && !Verilated::gotFinish(); ++h) {
			top->clk = !top->clk;		// Toggle clock
			top->eval();			// Evaluate model
#if VM_TRACE
			if(tfp) tfp->dump(main_time);	// Dump waveforms
#endif
			++main_time;			// Time passes...
		}
	}


	aux::float_t a;
	aux::float_t b;
	aux::float_t c;
	aux::float_t rm, rh;

	std::cout << "NITER = " << NITER << std::endl;

	// Main simulation loop
	for(uint64_t i = 0; i < NITER && !Verilated::gotFinish(); ++i) {
		int r1 = rand();
		int r2 = rand();
		int r3 = rand();
		int r4 = rand();
		int r5 = rand();
		int r6 = rand();
		int s1 = rand() & 1;
		int s2 = rand() & 1;
		int s3 = rand() & 1;
		// Randomized inputs
		a.f = static_cast<float>(r1) / static_cast<float>(r2);
		b.f = static_cast<float>(r3) / static_cast<float>(r4);
		c.f = static_cast<float>(r5) / static_cast<float>(r6);
		a.s.sign = s1;
		b.s.sign = s2;
		c.s.sign = s3;

		// Set mac inputs
		top->i_a = a.v;
		top->i_b = b.v;
		top->i_c = c.v;
		top->i_valid = 1;

		// Simulate five stages
		for(int j = 0; j < 5; ++j) {
			for(int h = 0; h < 2 && !Verilated::gotFinish(); ++h) {
				top->clk = !top->clk;		// Toggle clock
				top->eval();			// Evaluate RTL model
#if VM_TRACE
				if(tfp) tfp->dump(main_time);	// Dump waveforms
#endif
				++main_time;			// Time passes...
			}
			top->i_valid = 0;			// Disable inputs
		}

		// Check valid output signal
		if(!top->o_valid) {
			std::cerr << "[!] top->o_valid is not '1'." << std::endl;
			break;
		}

		rh.v = top->o_p;		// RTL model result

		rm.v = mac_test(a.v, b.v, c.v);	// Reference model result

		check_result(rm, rh);		// Check result

		// Print progress
		if(!(i % NPRIN))
			std::cout << i << " / " << NITER << "\r";

	}

	std::cout << std::endl << "Done." << std::endl;

	top->final();	// Done simulating

#if VM_TRACE
	if(tfp) tfp->close();
#endif

	return 0;
}
