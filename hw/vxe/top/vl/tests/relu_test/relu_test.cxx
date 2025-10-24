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
 * ReLU and Leaky ReLU test app
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

#include "prog/lrelu_neg.h"
#include "prog/lrelu_pos.h"
#include "prog/relu_neg.h"
#include "prog/relu_pos.h"


static struct fake_cpu_api *g_cpu_api;
#define FAKE_CPU_API	g_cpu_api


// Program addresses (set after load)
uint64_t pgm_lrelu_neg;
uint64_t pgm_lrelu_pos;
uint64_t pgm_relu_neg;
uint64_t pgm_relu_pos;

std::vector<uint64_t> all_tests;

// Reference values
float ref_lrelu_neg[16] = { -4096.0, -2048.0, -1024.0, -512.0, -256.0, -128.0,
	-64.0, -32.0, -16.0, -8.0, -4.0, -2.0, -1.0, -0.5, -0.25, -0.125 };
float ref_lrelu_pos[16] = { 65536.0, 32768.0, 16384.0, 8192.0, 4096.0, 2048.0,
	1024.0, 512.0, 256.0, 128.0, 64.0, 32.0, 16.0, 8.0, 4.0, 2.0 };
float ref_relu_neg[16] = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
	0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
float ref_relu_pos[16] = { 65536.0, 32768.0, 16384.0, 8192.0, 4096.0, 2048.0,
	1024.0, 512.0, 256.0, 128.0, 64.0, 32.0, 16.0, 8.0, 4.0, 2.0 };


void load_programs(const sw::simple_allocator::allocation& prog_mem);
void run_program(uint64_t addr);
bool verify_results(const std::string& hint, float *dest, float *ref);


/**
 * Main entry point
 */
extern "C" int fake_cpu_entry(struct fake_cpu_api *cpu_api)
{
	g_cpu_api = cpu_api;

	struct fake_cpu_dmi dmi;
	get_dmi(&dmi);

	sw::simple_allocator mem(dmi.ptr, dmi.start, dmi.end);

	std::cout << "< ReLU test program >" << std::endl;

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
	auto rd4 = mem.allocate(0x1000);
	if(!rd1.vaddr || !rd2.vaddr || !rd3.vaddr || !rd4.vaddr) {
		std::cout << "No memory" << std::endl;
		return -1;
	}
	float *rd1_ptr = static_cast<float*>(rd1.vaddr);
	float *rd2_ptr = static_cast<float*>(rd2.vaddr);
	float *rd3_ptr = static_cast<float*>(rd3.vaddr);
	float *rd4_ptr = static_cast<float*>(rd4.vaddr);
	// Init destination memory
	for(size_t i = 0; i < 0x1000 / sizeof(float); ++i) {
		rd1_ptr[i] = 1E6;
		rd2_ptr[i] = 1E6;
		rd3_ptr[i] = 1E6;
		rd4_ptr[i] = 1E6;
	}

	std::cout << std::endl << "Data buffers:" << std::endl;
	std::cout << "* Rd1 addr = 0x" << std::hex << rd1.paddr << std::endl;
	std::cout << "* Rd2 addr = 0x" << std::hex << rd2.paddr << std::endl;
	std::cout << "* Rd3 addr = 0x" << std::hex << rd3.paddr << std::endl;
	std::cout << "* Rd4 addr = 0x" << std::hex << rd4.paddr << std::endl;

	// Run tests
	std::cout << std::endl << "Running tests..." << std::endl;
	for(uint64_t pgm_address : all_tests) {
		run_program(pgm_address);
	}

	// Verify results
	std::cout << std::endl << "Verifying results..." << std::endl;
	bool fail = false;
	fail |= verify_results("[ L.ReLU (neg range) ]", &rd1_ptr[0], ref_lrelu_neg);
	fail |= verify_results("[ L.ReLU (pos range) ]", &rd2_ptr[0], ref_lrelu_pos);
	fail |= verify_results("[ ReLU (neg range)   ]", &rd3_ptr[0], ref_relu_neg);
	fail |= verify_results("[ ReLU (pos range)   ]", &rd4_ptr[0], ref_relu_pos);

	std::cout << std::endl << "All done." << std::endl;

	return fail ? -1 : 0;
}


void load_programs(const sw::simple_allocator::allocation& prog_mem)
{
	const unsigned pg_size = 1024;
	char *vaddr = static_cast<char*>(prog_mem.vaddr);
	uint64_t paddr = prog_mem.paddr;

	pgm_lrelu_neg = paddr;
	memcpy(vaddr, prog_lrelu_neg_bin, prog_lrelu_neg_bin_len);
	all_tests.push_back(paddr);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_lrelu_pos = paddr;
	memcpy(vaddr, prog_lrelu_pos_bin, prog_lrelu_pos_bin_len);
	all_tests.push_back(paddr);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_relu_neg = paddr;
	memcpy(vaddr, prog_relu_neg_bin, prog_relu_neg_bin_len);
	all_tests.push_back(paddr);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_relu_pos = paddr;
	memcpy(vaddr, prog_relu_pos_bin, prog_relu_pos_bin_len);
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


bool verify_results(const std::string& hint, float *dest, float *ref)
{
	int res_idx = 0;
	bool fail = false;

	for(int vpu = 0; vpu < 2; ++vpu) {
		for(int thread = 0; thread < 8; ++thread) {
			std::cout << hint << " VPU" << vpu
				<< ", Thread" << thread
				<< ": ";
			if(dest[res_idx] != ref[res_idx]) {
				std::cout << "FAIL (" << dest[res_idx] << " != "
					<< ref[res_idx] << ")" << std::endl;
				fail = true;
			} else {
				std::cout << "PASS" << std::endl;
			}

			++res_idx;
		}
	}

	return fail;
}
