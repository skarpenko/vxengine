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
 * APB FMAC block test for FPGA
 */

#include <cstdint>
#include <ctime>
#include <cstdlib>
#include <iostream>
#include <iomanip>

// Floating point reference model
#include <hwfmac.hxx>
#include <common.hxx>

// APB FMAC device driver
#include "device.hxx"


#define SRAND_SEED()	std::time(NULL)

constexpr uint64_t NITER = 10000000000;
constexpr uint64_t NPRIN = 100000;


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
uint32_t mac_ref(uint32_t a, uint32_t b, uint32_t c)
{
	uint32_t r;

	hwfmac::mac<uint32_t, uint64_t, 8, 23, 23>(a, b, c, r);

	return r;
}


// MAIN
int main(int argc, char **argv)
{
	//
	// Default MMIO base address of APB FMAC device.
	// The value is a base address of FPGA bridges region
	// on Atlas-SoC (DE0-Nano-SoC) board.
	//
	unsigned long mmio_base = 0xFF201000;

	std::cout << "APB FMAC device test" << std::endl;

	if(argc > 1) {
		mmio_base = std::strtol(argv[1], nullptr, 0);
		if(!mmio_base) {
			std::cerr << "wrong argument value: " << argv[1]
				<< std::endl;
			return -1;
		}
	}

	std::cout << "MMIO = 0x" << std::hex << mmio_base << std::dec
		<< std::endl;

	srand(SRAND_SEED());

	// Create device instance
	fmac_mmio fmac_dev(mmio_base);
	if(!fmac_dev.is_opened()) {
		std::cerr << "failed to setup device mappings." << std::endl;
		return -1;
	}

	std::cout << "DEV_ID = 0x" << std::hex << fmac_dev.id_reg() << std::dec
		<< std::endl;


	aux::float_t a;
	aux::float_t b;
	aux::float_t c;
	aux::float_t rm, rh;

	std::cout << "NITER = " << NITER << std::endl;

	// Main loop
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
		// Randomized inputs
		a.f = static_cast<float>(r1) / static_cast<float>(r2);
		b.f = static_cast<float>(r3) / static_cast<float>(r4);
		c.f = static_cast<float>(r5) / static_cast<float>(r6);
		a.s.sign = s1;
		b.s.sign = s2;
		c.s.sign = s3;

		rm.v = mac_ref(a.v, b.v, c.v);		// Reference model result
		rh.v = fmac_dev.fmac(a.v, b.v, c.v);	// APB FMAC device

		check_result(rm, rh);			// Check result

		// Print progress
		if(!(i % NPRIN))
			std::cout << i << " / " << NITER << "\r";
	}

	std::cout << std::endl << "Done." << std::endl;

	return 0;
}
