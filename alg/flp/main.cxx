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
 * Floating point tests
 */

#include <iostream>
#include <iomanip>
#include <vector>
#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <ctime>
#include <cmath>
#include "hwfmac.hxx"
#include "common.hxx"

#define SRAND_SEED()	std::time(NULL)

constexpr uint64_t NITER = 10000000000;
constexpr bool ignore_nan_mismatch = true;
constexpr float mac_tolerance = 1E-12;


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


bool nan_cond(uint32_t a, uint32_t b)
{
	aux::float_t aa = { .v = a };
	aux::float_t bb = { .v = b };
	bool nan = aa.s.exp == 0xff && bb.s.exp == 0xff && aa.s.man && bb.s.man;
	return nan && ignore_nan_mismatch;
}


uint32_t mul_test(uint32_t a, uint32_t b)
{
	uint32_t r;

	hwfmac::mul<uint32_t, uint64_t, 8, 23, 2>(a, b, r);

	aux::float_t af, bf, rf;
	af.v = a;
	bf.v = b;
	rf.v = r;

	aux::float_t m;
	m.f = af.f * bf.f;
	float d = rf.f - m.f;
	if(rf.v != m.v && !nan_cond(rf.v, m.v)) {
		std::ios state(nullptr);
		state.copyfmt(std::cout);
		std::cout << "M: "
			<< fmt_float(af.f) << " * " << fmt_float(bf.f)
			<< " = " << fmt_float(rf.f)
			<< " (" << fmt_float(m.f) << ") d = "
			<< fmt_float(d) << " v = "
			<< std::setw(8) << std::setfill('0') << std::hex
			<< rf.v << " ("
			<< std::setw(8) << std::setfill('0') << std::hex
			<< m.v << ")" << std::endl;
		std::cout.copyfmt(state);
	}

	return r;
}


uint32_t add_test(uint32_t a, uint32_t b)
{
	uint32_t r;

	hwfmac::add<uint32_t, uint64_t, 8, 23, 3>(a, b, r);

	aux::float_t af, bf, rf;
	af.v = a;
	bf.v = b;
	rf.v = r;

	aux::float_t s;
	s.f = af.f + bf.f;
	float d = rf.f - s.f;
	if(rf.v != s.v && !nan_cond(rf.v, s.v)) {
		std::ios state(nullptr);
		state.copyfmt(std::cout);
		std::cout << "A: "
			<< fmt_float(af.f) << " + " << fmt_float(bf.f)
			<< " = " << fmt_float(rf.f)
			<< " (" << fmt_float(s.f) << ") d = "
			<< fmt_float(d) << " v = "
			<< std::setw(8) << std::setfill('0') << std::hex
			<< rf.v << " ("
			<< std::setw(8) << std::setfill('0') << std::hex
			<< s.v << ")" << std::endl;
		std::cout.copyfmt(state);
	}

	return r;
}


uint32_t mac_test(uint32_t a, uint32_t b, uint32_t c)
{
	uint32_t r;

	hwfmac::mac<uint32_t, uint64_t, 8, 23, 23>(a, b, c, r);

	aux::float_t af, bf, cf, rf;
	af.v = a;
	bf.v = b;
	cf.v = c;
	rf.v = r;

	aux::float_t s;
	s.f = std::fmaf(bf.f, cf.f, af.f);
	float d = rf.f - s.f;
	if(rf.v != s.v && !nan_cond(rf.v, s.v) && std::fabs(d) > mac_tolerance) {
		std::ios state(nullptr);
		state.copyfmt(std::cout);
		std::cout << "MA: "
			<< fmt_float(af.f) << " + " << fmt_float(bf.f) << " * "
			<< fmt_float(cf.f) << " = " << fmt_float(rf.f)
			<< " (" << fmt_float(s.f) << ") d = "
			<< fmt_float(d) << " v = "
			<< std::setw(8) << std::setfill('0') << std::hex
			<< rf.v << " ("
			<< std::setw(8) << std::setfill('0') << std::hex
			<< s.v << ")" << std::endl;
		std::cout.copyfmt(state);
	}

	return r;
}


void corner_case();	// Corner cases test

int main()
{
	aux::float_t a;
	aux::float_t b;
	aux::float_t c;

	srand(SRAND_SEED());

	std::cout << "Floating point test" << std::endl;

	corner_case();

	std::cout << "NITER = " << NITER << std::endl;

	for(uint64_t i = 0; i < NITER; ++i) {
		int r1 = rand();
		int r2 = rand();
		int r3 = rand();
		int r4 = rand();
		int r5 = rand();
		int r6 = rand();
		int s1 = rand() & 1;
		int s2 = rand() & 1;
		int s3 = rand() & 1;
		a.f = static_cast<float>(r1) / static_cast<float>(r2);
		b.f = static_cast<float>(r3) / static_cast<float>(r4);
		c.f = static_cast<float>(r5) / static_cast<float>(r6);
		a.s.sign = s1;
		b.s.sign = s2;
		c.s.sign = s3;

		mul_test(a.v, b.v);
		add_test(a.v, b.v);
		mac_test(a.v, b.v, c.v);
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
	// These two cause significand overflow while rounding after add
	const aux::float_t rof_val1 = { .v = 0x40efffff };
	const aux::float_t rof_val2 = { .v = 0x3f000007 };
	// Positive and negative values
	const aux::float_t pos_val1 = { .v = 0x4087ae14 };
	const aux::float_t pos_val2 = { .v = 0x3fd9999a };
	const aux::float_t pos_val3 = { .v = 0x3d8f5c29 };
	const aux::float_t neg_val1 = { .v = 0xc087ae14 };
	const aux::float_t neg_val2 = { .v = 0xbfd9999a };
	const aux::float_t neg_val3 = { .v = 0xbd8f5c29 };

	std::vector<uint32_t> a, b, c;

	a.push_back(pos_zero.v);
	a.push_back(neg_zero.v);
	a.push_back(pos_inf.v);
	a.push_back(neg_inf.v);
	a.push_back(pos_nan.v);
	a.push_back(neg_nan.v);
	a.push_back(rof_val1.v);
	a.push_back(rof_val2.v);

	c.push_back(pos_val1.v);
	c.push_back(pos_val2.v);
	c.push_back(pos_val3.v);
	c.push_back(neg_val1.v);
	c.push_back(neg_val2.v);
	c.push_back(neg_val3.v);

	while(!c.empty()) {
		// Push values from 'c' one by one to reduce permutations number
		a.push_back(c.back());
		c.pop_back();

		b = a;

		do {
			for (size_t i = 0; i < a.size(); ++i) {
				mul_test(a[i], b[i]);
				add_test(a[i], b[i]);
			}
		} while (std::next_permutation(b.begin(), b.end()));

		a.pop_back();
	}
}
