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
 * Floating point ReLU module test (C++ main)
 */

#include <cstdint>
#include <iostream>
#include <iomanip>
#include <vector>
#include <algorithm>
#include <verilated.h>		// Defines common routines
#if VM_TRACE
# include <verilated_vcd_c.h>	// Trace file format header
#endif
#include "Vvl_flp_relu_test.h"	// From Verilating "vl_flp_relu_test.v"
#include "vl_common.hxx"	// Common Verilator types

// Floating point ReLU reference model
#include "flp/common.hxx"
#include "relu/hwrelu.hxx"


#define EXP_REDUCE	(-4)		// Exponent adjustment for leaky ReLU
#define PLOT_MIN	(-16.0)		// Plot X axis minimum
#define PLOT_MAX	(16.0)		// Plot X axis maximum
#define PLOT_STEP	(0.000001)	// Plot step


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
bool check_result(const char *msg, const aux::float_t& rm, const aux::float_t& rh)
{
	bool res = true;

	if(rm.v != rh.v) {
		std::ios state(nullptr);
		state.copyfmt(std::cout);
		std::cout << "[!] " << msg << " "
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


// Floating point ReLU reference model
uint32_t relu_test(uint32_t v, bool l, int e)
{
	uint32_t r;

	hwrelu::relu<uint32_t, 8, 23>(v, r, l, e);

	return r;
}


void corner_case(model_top<Vvl_flp_relu_test>& top);	// Corner cases test

// MAIN
int main(int argc, char **argv)
{
	std::cout << "FP ReLU logic test" << std::endl;


	Verilated::commandArgs(argc, argv);	// Pass args to Verilator

	// Create top-level instance
	model_top<Vvl_flp_relu_test> top;

#if VM_TRACE
	Verilated::traceEverOn(true);	// Enable traces
	tfp = new VerilatedVcdC;
	top->trace (tfp, 99);		// Trace 99 levels of hierarchy
	tfp->open("vlt_dump.vcd");	// Open the dump file
#endif

	aux::float_t v, rm, rh;

	corner_case(top);

	// Plot loop
	std::cout << "Plot loop..." << std::endl;
	for(float i = PLOT_MIN; i <= PLOT_MAX && !Verilated::gotFinish();
		i += PLOT_STEP)
	{
		v.f = i;

		// ReLU

		rm.v = relu_test(v.v, false, EXP_REDUCE);	// Reference model result

		top->i_v = v.v;
		top->i_l = false;
		top->i_e = EXP_REDUCE;
		top->eval();			// Evaluate model
		rh.v = top->o_r;		// RTL model result

#if VM_TRACE
		if(tfp) tfp->dump(main_time);	// Dump waveforms
#endif

		check_result("ReLU", rm, rh);		// Check result


		++main_time;			// Time passes...


		// Leaky ReLU

		rm.v = relu_test(v.v, true, EXP_REDUCE);	// Reference model result

		top->i_v = v.v;
		top->i_l = true;
		top->i_e = EXP_REDUCE;
		top->eval();			// Evaluate model
		rh.v = top->o_r;		// RTL model result

#if VM_TRACE
		if(tfp) tfp->dump(main_time);	// Dump waveforms
#endif

		check_result("lReLU", rm, rh);		// Check result


		++main_time;			// Time passes...
	}

	std::cout << "Done." << std::endl;

	top->final();	// Done simulating

#if VM_TRACE
	if(tfp) tfp->close();
#endif

	return 0;
}


void corner_case(model_top<Vvl_flp_relu_test>& top)
{
	std::cout << "Corner cases..." << std::endl;

	const aux::float_t pos_zero = { .v = 0x00000000 };
	const aux::float_t neg_zero = { .v = 0x80000000 };
	const aux::float_t pos_inf = { .v = 0x7f800000 };
	const aux::float_t neg_inf = { .v = 0xff800000 };
	const aux::float_t pos_nan = { .v = 0x7fffffff };
	const aux::float_t neg_nan = { .v = 0xffffffff };

	std::vector<uint32_t> a;

	a.push_back(pos_zero.v);
	a.push_back(neg_zero.v);
	a.push_back(pos_inf.v);
	a.push_back(neg_inf.v);
	a.push_back(pos_nan.v);
	a.push_back(neg_nan.v);

	aux::float_t rm, rh;

	for(const uint32_t v : a) {
		// ReLU
		rm.v = relu_test(v, false, EXP_REDUCE);

		top->i_v = v;
		top->i_l = false;
		top->i_e = EXP_REDUCE;
		top->eval();			// Evaluate model
		rh.v = top->o_r;		// RTL model result

#if VM_TRACE
		if(tfp) tfp->dump(main_time);	// Dump waveforms
#endif

		check_result("ReLU", rm, rh);		// Check result

		++main_time;			// Time passes...


		// Leaky ReLU
		rm.v = relu_test(v, true, EXP_REDUCE);

		top->i_v = v;
		top->i_l = true;
		top->i_e = EXP_REDUCE;
		top->eval();			// Evaluate model
		rh.v = top->o_r;		// RTL model result

#if VM_TRACE
		if(tfp) tfp->dump(main_time);	// Dump waveforms
#endif

		check_result("lReLU", rm, rh);		// Check result

		++main_time;			// Time passes...
	}
}
