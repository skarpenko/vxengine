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
#include <cstdint>
#include <cstdlib>
#include <ctime>
#include "hwfmac.hxx"
#include "common.hxx"

#define SRAND_SEED	time(NULL)
#define NITER		10000000000


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


uint32_t mul_test(uint32_t a, uint32_t b)
{
	uint32_t r;

	hwfmac::mul<uint32_t, uint64_t, 8, 23, 2>(a, b, r);

	float_t af, bf, rf;
	af.v = a;
	bf.v = b;
	rf.v = r;

	float m = af.f * bf.f;
	float d = rf.f - m;
	if (d != 0.0) {
		std::ios state(nullptr);
		state.copyfmt(std::cout);
		std::cout << "M: "
			<< fmt_float(af.f) << " * " << fmt_float(bf.f)
			<< " = " << fmt_float(rf.f)
			<< " (" << fmt_float(m) << ") d = "
			<< fmt_float(d) << ") (v = "
			<< std::setw(8) << std::setfill('0') << std::hex
			<< rf.v << ")" << std::endl;
		std::cout.copyfmt(state);
	}

	return r;
}


uint32_t add_test(uint32_t a, uint32_t b)
{
	uint32_t r;

	hwfmac::add<uint32_t, uint64_t, 8, 23, 3>(a, b, r);

	float_t af, bf, rf;
	af.v = a;
	bf.v = b;
	rf.v = r;

	float s = af.f + bf.f;
	float d = rf.f - s;
	if (d != 0.0) {
		std::ios state(nullptr);
		state.copyfmt(std::cout);
		std::cout << "A: "
			<< fmt_float(af.f) << " + " << fmt_float(bf.f)
			<< " = " << fmt_float(rf.f)
			<< " (" << fmt_float(s) << ") d = "
			<< fmt_float(d) << ") (v = "
			<< std::setw(8) << std::setfill('0') << std::hex
			<< rf.v << ")" << std::endl;
		std::cout.copyfmt(state);
	}

	return r;
}


int main()
{
	float_t a;
	float_t b;

	srand(SRAND_SEED);

	std::cout << "Floating point test" << std::endl;
	std::cout << "NITER = " << NITER << std::endl;

	for (long long i = 0; i < NITER; ++i) {
		int r1 = rand();
		int r2 = rand();
		int r3 = rand();
		int r4 = rand();
		int s1 = rand() & 1;
		int s2 = rand() & 1;
		a.f = (float) r1 / (float) r2;
		b.f = (float) r3 / (float) r4;
		a.s.sign = s1;
		b.s.sign = s2;

		mul_test(a.v, b.v);
		add_test(a.v, b.v);
	}

	return 0;
}
