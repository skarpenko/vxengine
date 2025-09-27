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
 * Basic test app
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

#include "prog/disable.h"
#include "prog/test_00.h"
#include "prog/test_01.h"
#include "prog/test_02.h"
#include "prog/test_03.h"
#include "prog/test_04.h"
#include "prog/test_05.h"
#include "prog/test_06.h"
#include "prog/test_07.h"
#include "prog/test_10.h"
#include "prog/test_11.h"
#include "prog/test_12.h"
#include "prog/test_13.h"
#include "prog/test_14.h"
#include "prog/test_15.h"
#include "prog/test_16.h"
#include "prog/test_17.h"


static struct fake_cpu_api *g_cpu_api;
#define FAKE_CPU_API	g_cpu_api


// Program addresses (set after load)
uint64_t pgm_disable;
uint64_t pgm_test_00;
uint64_t pgm_test_01;
uint64_t pgm_test_02;
uint64_t pgm_test_03;
uint64_t pgm_test_04;
uint64_t pgm_test_05;
uint64_t pgm_test_06;
uint64_t pgm_test_07;
uint64_t pgm_test_10;
uint64_t pgm_test_11;
uint64_t pgm_test_12;
uint64_t pgm_test_13;
uint64_t pgm_test_14;
uint64_t pgm_test_15;
uint64_t pgm_test_16;
uint64_t pgm_test_17;

std::vector<uint64_t> all_tests;


void load_programs(const sw::simple_allocator::allocation& prog_mem);
void run_program(uint64_t addr);


/**
 * Main entry point
 */
extern "C" int fake_cpu_entry(struct fake_cpu_api *cpu_api)
{
	g_cpu_api = cpu_api;

	struct fake_cpu_dmi dmi;
	get_dmi(&dmi);

	sw::simple_allocator mem(dmi.ptr, dmi.start, dmi.end);

	std::cout << "< Basic test program >" << std::endl;

	// Read device Id
	uint32_t id = mmio_rreg32(vxe::rego::REG_ID);

	std::cout << std::endl << "DevID = 0x" << std::hex << id
		<< " " << (id != vxe::VXENGINE_ID ? "(MISMATCH!)" : "" ) << std::endl;

	// Load programs 
	auto prog_space = mem.allocate(0x2000); // Reserve 8KB
	load_programs(prog_space);


	// Allocate space for test vectors
	auto rs = mem.allocate(0x1000);
	auto rt = mem.allocate(0x1000);
	auto rd = mem.allocate(0x1000);
	float *rs_ptr = static_cast<float*>(rs.vaddr);
	float *rt_ptr = static_cast<float*>(rt.vaddr);
	float *rd_ptr = static_cast<float*>(rd.vaddr);

	std::cout << std::endl << "Data buffers:" << std::endl;
	std::cout << "* Rs addr = 0x" << std::hex << rs.paddr << std::endl;
	std::cout << "* Rt addr = 0x" << std::hex << rt.paddr << std::endl;
	std::cout << "* Rd addr = 0x" << std::hex << rd.paddr << std::endl;

	// Generate test vectors
	sw::gen_vector_linear(1.0f, 1.0f, static_cast<float*>(rs.vaddr), 16);
	sw::gen_vector_linear(1.0f, 1.0f, static_cast<float*>(rt.vaddr), 16);

	// Calculate reference value
	float ref_sum = 0.0;
	for(int i = 0; i < 16; ++i)
		ref_sum += rs_ptr[i] * rt_ptr[i];

	// Run tests
	std::cout << std::endl << "Running tests..." << std::endl;
	for(uint64_t pgm_address : all_tests) {
		run_program(pgm_address);
		run_program(pgm_disable);
	}

	// Verify results
	std::cout << std::endl << "Verifying results..." << std::endl;
	int res_idx = 0;
	int status = 0;
	for(int vpu = 0; vpu < 2; ++vpu) {
		for(int thread = 0; thread < 8; ++thread) {
			std::cout << "VPU" << vpu
				<< ", Thread" << thread
				<< ": ";
			if(rd_ptr[res_idx] != ref_sum) {
				std::cout << "FAIL (" << rd_ptr[res_idx] << " != "
					<< ref_sum << ")" << std::endl;
				status = -1;
			} else {
				std::cout << "PASS" << std::endl;
			}

			++res_idx;
		}
	}

	std::cout << std::endl << "All done." << std::endl;

	return status;
}


void load_programs(const sw::simple_allocator::allocation& prog_mem)
{
	const unsigned pg_size = 256;
	char *vaddr = static_cast<char*>(prog_mem.vaddr);
	uint64_t paddr = prog_mem.paddr;

	pgm_disable = paddr;
	memcpy(vaddr, prog_disable_bin, prog_disable_bin_len);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_test_00 = paddr;
	memcpy(vaddr, prog_test_00_bin, prog_test_00_bin_len);
	all_tests.push_back(paddr);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_test_01 = paddr;
	memcpy(vaddr, prog_test_01_bin, prog_test_01_bin_len);
	all_tests.push_back(paddr);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_test_02 = paddr;
	memcpy(vaddr, prog_test_02_bin, prog_test_02_bin_len);
	all_tests.push_back(paddr);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_test_03 = paddr;
	memcpy(vaddr, prog_test_03_bin, prog_test_03_bin_len);
	all_tests.push_back(paddr);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_test_04 = paddr;
	memcpy(vaddr, prog_test_04_bin, prog_test_04_bin_len);
	all_tests.push_back(paddr);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_test_05 = paddr;
	memcpy(vaddr, prog_test_05_bin, prog_test_05_bin_len);
	all_tests.push_back(paddr);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_test_06 = paddr;
	memcpy(vaddr, prog_test_06_bin, prog_test_06_bin_len);
	all_tests.push_back(paddr);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_test_07 = paddr;
	memcpy(vaddr, prog_test_07_bin, prog_test_07_bin_len);
	all_tests.push_back(paddr);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_test_10 = paddr;
	memcpy(vaddr, prog_test_10_bin, prog_test_10_bin_len);
	all_tests.push_back(paddr);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_test_11 = paddr;
	memcpy(vaddr, prog_test_11_bin, prog_test_11_bin_len);
	all_tests.push_back(paddr);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_test_12 = paddr;
	memcpy(vaddr, prog_test_12_bin, prog_test_12_bin_len);
	all_tests.push_back(paddr);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_test_13 = paddr;
	memcpy(vaddr, prog_test_13_bin, prog_test_13_bin_len);
	all_tests.push_back(paddr);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_test_14 = paddr;
	memcpy(vaddr, prog_test_14_bin, prog_test_14_bin_len);
	all_tests.push_back(paddr);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_test_15 = paddr;
	memcpy(vaddr, prog_test_15_bin, prog_test_15_bin_len);
	all_tests.push_back(paddr);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_test_16 = paddr;
	memcpy(vaddr, prog_test_16_bin, prog_test_16_bin_len);
	all_tests.push_back(paddr);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_test_17 = paddr;
	memcpy(vaddr, prog_test_17_bin, prog_test_17_bin_len);
	all_tests.push_back(paddr);
}


void run_program(uint64_t addr)
{
	std::ios state(nullptr);
	state.copyfmt(std::cout);	// Save current stream state

	std::cout << "Launching program at 0x" << std::setw(8) << std::setfill('0') << std::hex << addr;

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
