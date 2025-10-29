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
 * Product test app
 */

#include <cstdint>
#include <cstring>
#include <iostream>
#include <sstream>
#include <iomanip>
#include <vector>
#include <vxe_regs.hxx>
#include <simple_alloc.hxx>
#include <vec_util.hxx>
#define FAKE_CPU_API_SHORTCUTS
#include "fake_cpu_api.h"

#include "prog/prod.h"


static struct fake_cpu_api *g_cpu_api;
#define FAKE_CPU_API	g_cpu_api

const size_t MAX_VEC_LEN = 522240;	/* Max. Rs and Rt vectors length (do not change) */

// Test params
const size_t MIN_TEST_LEN = 100;
const size_t MAX_TEST_LEN = 15000;
const size_t STEP_TEST_LEN = 1000;


// Program addresses (set after load)
uint64_t pgm_prod;


void load_program(const sw::simple_allocator::allocation& prog_mem);
void run_program(uint64_t addr);
void patch_veclen(void *prog, size_t size, size_t new_veclen);
bool verify_results(const std::string& hint, float *dest, float ref_val);


/**
 * Main entry point
 */
extern "C" int fake_cpu_entry(struct fake_cpu_api *cpu_api)
{
	g_cpu_api = cpu_api;

	struct fake_cpu_dmi dmi;
	get_dmi(&dmi);

	sw::simple_allocator mem(dmi.ptr, dmi.start, dmi.end);

	std::cout << "< Product test program >" << std::endl;

	// Read device Id
	uint32_t id = mmio_rreg32(vxe::rego::REG_ID);

	std::cout << std::endl << "DevID = 0x" << std::hex << id
		<< " " << (id != vxe::VXENGINE_ID ? "(MISMATCH!)" : "" ) << std::endl;

	// Load program
	auto prog_space = mem.allocate(0x2000); // Reserve 8KB
	if(!prog_space.vaddr) {
		std::cout << "No memory" << std::endl;
		return -1;
	}
	load_program(prog_space);


	// Allocate space for test vectors
	auto rs = mem.allocate(MAX_VEC_LEN * sizeof(float));
	auto rt = mem.allocate(MAX_VEC_LEN * sizeof(float));
	auto rd = mem.allocate(0x1000);
	if(!rs.vaddr || !rt.vaddr || !rd.vaddr) {
		std::cout << "No memory" << std::endl;
		return -1;
	}
	float *rs_ptr = static_cast<float*>(rs.vaddr);
	float *rt_ptr = static_cast<float*>(rt.vaddr);
	float *rd_ptr = static_cast<float*>(rd.vaddr);

	std::cout << std::endl << "Data buffers:" << std::endl;
	std::cout << "* Rs addr = 0x" << std::hex << rs.paddr << std::endl;
	std::cout << "* Rt addr = 0x" << std::hex << rt.paddr << std::endl;
	std::cout << "* Rd addr = 0x" << std::hex << rd.paddr << std::endl;


	// Generate input vectors
	for(size_t i = 0; i < MAX_VEC_LEN; ++i) {
		rs_ptr[i] = (float)(i + 1);
		rt_ptr[i] = 1.0 / (float)(i + 1);
	}


	// Run tests
	bool status = false;
	std::cout << std::endl << "Running tests..." << std::endl;
	for(size_t t = MIN_TEST_LEN; t < MAX_TEST_LEN; t += STEP_TEST_LEN) {
		std::stringstream hint;
		hint << "[ Vec.Len: " << std::setw(5) << std::setfill(' ')
			<< t << " ]";

		patch_veclen(prog_space.vaddr, 0x2000, t);
		run_program(pgm_prod);

		// Verify results
		std::cout << "Verifying results..." << std::endl;
		verify_results(hint.str(), rd_ptr, static_cast<float>(t));
	}

	std::cout << std::endl << "All done." << std::endl;

	return status ? -1 : 0;
}


void load_program(const sw::simple_allocator::allocation& prog_mem)
{
	char *vaddr = static_cast<char*>(prog_mem.vaddr);
	uint64_t paddr = prog_mem.paddr;

	pgm_prod = paddr;
	memcpy(vaddr, prog_prod_bin, prog_prod_bin_len);
}


void run_program(uint64_t addr)
{
	std::ios state(nullptr);
	state.copyfmt(std::cout);	// Save current stream state

	std::cout << "Launching program at 0x" << std::setw(8) << std::setfill('0')
		<< std::hex << addr;

	mmio_wreg32(vxe::rego::REG_PGM_ADDR_LO, addr & 0xFFFFFFFF);
	mmio_wreg32(vxe::rego::REG_PGM_ADDR_HI, addr >> 32);

	mmio_wreg32(vxe::rego::REG_START, 0);
	wait_intr();

	// Acknowledge interrupts
	uint32_t intr = mmio_rreg32(vxe::rego::REG_INTR_ACT);
	mmio_wreg32(vxe::rego::REG_INTR_ACT, intr);
	wait_cycles(10);

	std::cout << " ... done!" << std::endl;

	std::cout.copyfmt(state);
}


void patch_veclen(void *prog, size_t size, size_t new_veclen)
{
	uint64_t *instr = static_cast<uint64_t*>(prog);
	size_t ninstr = size / sizeof(uint64_t);

	new_veclen &= 0xFFFFF;	/* 20-bits maximum */

	for(size_t i = 0; i < ninstr; ++i) {
		uint64_t op = instr[i] >> 59;
		if(op == 0x9) {	// 0x9 - setvl opcode
			instr[i] &= ~0xFFFFF;
			instr[i] |= new_veclen;
		}
	}
}


bool verify_results(const std::string& hint, float *dest, float ref_val)
{
	int res_idx = 0;
	bool fail = false;

	for(int vpu = 0; vpu < 2; ++vpu) {
		for(int thread = 0; thread < 8; ++thread) {
			std::cout << hint << " VPU" << vpu
				<< ", Thread" << thread
				<< ": ";
			if(dest[res_idx] != ref_val) {
				std::cout << "FAIL (" << dest[res_idx] << " != "
					<< ref_val << ")" << std::endl;
				fail = true;
			} else {
				std::cout << "PASS" << std::endl;
			}

			++res_idx;
		}
	}

	return fail;
}
