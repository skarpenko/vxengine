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
 * ReLU tests
 */

#include <iostream>
#include <iomanip>
#include <fstream>
#include <stdexcept>
#include <vector>
#include <cstdint>
#include "hwrelu.hxx"
#include "common.hxx"


#define EXP_REDUCE	(-4)		/* Exponent adjustment value for leaky ReLU */
#define PLOT_MIN	(-16.0)		/* Plot X axis minimum */
#define PLOT_MAX	(16.0)		/* Plot X axis maximum */
#define PLOT_STEP	(0.1)		/* Plot step */


struct fmt_float_s { float f; };


inline fmt_float_s fmt_float(float f)
{
	return { f };
}


inline std::ostream& operator<<(std::ostream& os, fmt_float_s s)
{
	std::ios state(nullptr);
	state.copyfmt(os);
	os << std::setprecision(20) << std::fixed << s.f;
	os.copyfmt(state);
	return os;
}


bool is_nan(uint32_t v)
{
	aux::float_t vv = { .v = v };
	return vv.s.exp == 0xff && vv.s.man != 0;
}


bool nan_cond(uint32_t a, uint32_t b)
{
	return is_nan(a) && is_nan(b);
}


float relu_float(float v, bool l, int e)
{
	aux::float_t n = { .f = v };

	if(is_nan(n.v))
		return v;

	if(l && e >= 0)
		throw std::runtime_error(std::string(__FUNCTION__) +
			": Wrong argument, 'e' must be negative!");

	if(l) {
		float scale = 1.0 / static_cast<float>(1 << -e);
		return (v > 0.0 ? v : v * scale);
	} else
		return (v > 0.0 ? v : 0.0);
}


uint32_t relu_test(uint32_t v, bool l, int e)
{
	uint32_t r;

	hwrelu::relu<uint32_t, 8, 23>(v, r, l, e);

	aux::float_t vf, rf, sf;
	vf.v = v;
	rf.v = r;

	sf.f = relu_float(vf.f, l, e);

	float d = rf.f - sf.f;
	if(rf.v != sf.v && !nan_cond(rf.v, sf.v)) {
		std::ios state(nullptr);
		state.copyfmt(std::cout);
		std::cout << (l ? "Leaky_ReLU" : "ReLU") << "("
			<< fmt_float(vf.f) << ")"
			<< " = " << fmt_float(rf.f)
			<< " (" << fmt_float(sf.f) << ") d = "
			<< fmt_float(d) << " v = "
			<< std::setw(8) << std::setfill('0') << std::hex
			<< rf.v << " ("
			<< std::setw(8) << std::setfill('0') << std::hex
			<< sf.v << ")" << std::endl;
		std::cout.copyfmt(state);
	}

	return r;
}


void corner_case();	// Corner cases test

int main()
{
	std::cout << "ReLU test" << std::endl;

	corner_case();

	std::ofstream relu_out("relu_values.txt");
	std::ofstream lrelu_out("lrelu_values.txt");

	std::cout << "Plotting..." << std::endl;

	for(float i = PLOT_MIN; i <= PLOT_MAX; i += PLOT_STEP) {
		aux::float_t v;
		aux::float_t r;

		v.f = i;
		r.v = relu_test(v.v, false, EXP_REDUCE);
		relu_out << i << " " << r.f << std::endl;
		r.v = relu_test(v.v, true, EXP_REDUCE);
		lrelu_out << i << " " << r.f << std::endl;
	}

	return 0;
}


void corner_case()
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

	for(const uint32_t v : a) {
		relu_test(v, false, EXP_REDUCE);
		relu_test(v, true, EXP_REDUCE);
	}
}
