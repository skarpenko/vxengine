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
 * Store test app
 */

#include <cstdint>
#include <cstring>
#include <iostream>
#include <iomanip>
#include <vector>
#include <vxe_regs.hxx>
#include <simple_alloc.hxx>
#include <vec_util.hxx>
#define FAKE_CPU_API_SHORTCUTS
#include "fake_cpu_api.h"

#include "prog/aligned.h"
#include "prog/unaligned.h"
#include "prog/scattered.h"


static struct fake_cpu_api *g_cpu_api;
#define FAKE_CPU_API	g_cpu_api


// Program addresses (set after load)
uint64_t pgm_aligned;
uint64_t pgm_unaligned;
uint64_t pgm_scattered;

std::vector<uint64_t> all_tests;


void load_programs(const sw::simple_allocator::allocation& prog_mem);
void run_program(uint64_t addr);
bool verify_results(const std::string& hint, float *dest, int incr);


/**
 * Main entry point
 */
extern "C" int fake_cpu_entry(struct fake_cpu_api *cpu_api)
{
	g_cpu_api = cpu_api;

	struct fake_cpu_dmi dmi;
	get_dmi(&dmi);

	sw::simple_allocator mem(dmi.ptr, dmi.start, dmi.end);

	std::cout << "< Store test program >" << std::endl;

	// Read device Id
	uint32_t id = mmio_rreg32(vxe::rego::REG_ID);

	std::cout << std::endl << "DevID = 0x" << std::hex << id
		<< " " << (id != vxe::VXENGINE_ID ? "(MISMATCH!)" : "" ) << std::endl;

	// Load programs 
	auto prog_space = mem.allocate(0x2000); // Reserve 8KB
	if(!prog_space.vaddr) {
		std::cout << "No memory" << std::endl;
		return -1;
	}
	load_programs(prog_space);


	// Allocate space for test results
	auto rd1 = mem.allocate(0x1000);
	auto rd2 = mem.allocate(0x1000);
	auto rd3 = mem.allocate(0x1000);
	if(!rd1.vaddr || !rd2.vaddr || !rd3.vaddr) {
		std::cout << "No memory" << std::endl;
		return -1;
	}
	float *rd1_ptr = static_cast<float*>(rd1.vaddr);
	float *rd2_ptr = static_cast<float*>(rd2.vaddr);
	float *rd3_ptr = static_cast<float*>(rd3.vaddr);

	std::cout << std::endl << "Data buffers:" << std::endl;
	std::cout << "* Rd1 addr = 0x" << std::hex << rd1.paddr << std::endl;
	std::cout << "* Rd2 addr = 0x" << std::hex << rd2.paddr << std::endl;
	std::cout << "* Rd3 addr = 0x" << std::hex << rd3.paddr << std::endl;

	// Run tests
	std::cout << std::endl << "Running tests..." << std::endl;
	for(uint64_t pgm_address : all_tests) {
		run_program(pgm_address);
	}

	// Verify results
	std::cout << std::endl << "Verifying results..." << std::endl;
	bool fail = false;
	fail |= verify_results("[ Aligned store   ]", &rd1_ptr[0], 1);
	fail |= verify_results("[ Unaligned store ]", &rd2_ptr[1], 1);
	fail |= verify_results("[ Scattered store ]", &rd3_ptr[0], 4);

	std::cout << std::endl << "All done." << std::endl;

	return fail ? -1 : 0;
}


void load_programs(const sw::simple_allocator::allocation& prog_mem)
{
	const unsigned pg_size = 1024;
	char *vaddr = static_cast<char*>(prog_mem.vaddr);
	uint64_t paddr = prog_mem.paddr;

	pgm_aligned = paddr;
	memcpy(vaddr, prog_aligned_bin, prog_aligned_bin_len);
	all_tests.push_back(paddr);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_unaligned = paddr;
	memcpy(vaddr, prog_unaligned_bin, prog_unaligned_bin_len);
	all_tests.push_back(paddr);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_scattered = paddr;
	memcpy(vaddr, prog_scattered_bin, prog_scattered_bin_len);
	all_tests.push_back(paddr);
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


bool verify_results(const std::string& hint, float *dest, int incr)
{
	int res_idx = 0;
	bool fail = false;
	float ref_val = 1.0;

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

			res_idx += incr;
			ref_val += 1.0;
		}
	}

	return fail;
}
