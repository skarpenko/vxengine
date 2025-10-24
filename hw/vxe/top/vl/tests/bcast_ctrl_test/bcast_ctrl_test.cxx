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
 * Broadcast control test app
 */

#include <cstdint>
#include <cstring>
#include <iostream>
#include <iomanip>
#include <vxe_regs.hxx>
#include <simple_alloc.hxx>
#include <vec_util.hxx>
#define FAKE_CPU_API_SHORTCUTS
#include "fake_cpu_api.h"

#include "prog/lrelu_vpu0.h"
#include "prog/lrelu_vpu1.h"
#include "prog/prod_vpu0.h"
#include "prog/prod_vpu1.h"
#include "prog/store_vpu0.h"
#include "prog/store_vpu1.h"


static struct fake_cpu_api *g_cpu_api;
#define FAKE_CPU_API	g_cpu_api


// Program addresses (set after load)
uint64_t pgm_lrelu_vpu0;
uint64_t pgm_lrelu_vpu1;
uint64_t pgm_prod_vpu0;
uint64_t pgm_prod_vpu1;
uint64_t pgm_store_vpu0;
uint64_t pgm_store_vpu1;


// Reference values
float ref_lrelu_vpu0[16] = { -4096.0, -2048.0, -1024.0, -512.0, -256.0, -128.0,
	-64.0, -32.0, -256.0, -128.0, -64.0, -32.0, -16.0, -8.0, -4.0, -2.0 };
float ref_lrelu_vpu1[16] = { -65536.0, -32768.0, -16384.0, -8192.0, -4096.0,
	-2048.0, -1024.0, -512.0, -16.0, -8.0, -4.0, -2.0, -1.0, -0.5, -0.25,
	-0.125 };
float ref_prod_vpu0[16] = { 10.0, 40.0, 90.0, 160.0, 250.0, 360.0, 490.0, 640.0,
	-1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0 };
float ref_prod_vpu1[16] = { -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0,
	810.0, 1000.0, 1210.0, 1440.0, 1690.0, 1960.0, 2250.0, 2560.0 };
float ref_store_vpu0[16] = { 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, -1.0, -1.0,
	-1.0, -1.0, -1.0, -1.0, -1.0, -1.0 };
float ref_store_vpu1[16] = { -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0,
	9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0 };


void load_programs(const sw::simple_allocator::allocation& prog_mem);
void run_program(uint64_t addr);
bool verify_results(const std::string& hint, float *dest, float *ref);
void init_mem(float *mem, size_t count, float start_val, float incr = 0.0);


/**
 * Main entry point
 */
extern "C" int fake_cpu_entry(struct fake_cpu_api *cpu_api)
{
	g_cpu_api = cpu_api;

	struct fake_cpu_dmi dmi;
	get_dmi(&dmi);

	sw::simple_allocator mem(dmi.ptr, dmi.start, dmi.end);

	std::cout << "< Broadcast control test program >" << std::endl;

	// Read device Id
	uint32_t id = mmio_rreg32(vxe::rego::REG_ID);

	std::cout << std::endl << "DevID = 0x" << std::hex << id
		<< " " << (id != vxe::VXENGINE_ID ? "(MISMATCH!)" : "" ) << std::endl;

	// Load programs 
	auto prog_space = mem.allocate(0x2000); // Reserve 8KB
	load_programs(prog_space);

	// Allocate space for test results
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


	// Run tests
	std::cout << std::endl << "Running tests..." << std::endl;
	bool fail = false;

	// ReLU broadcast tests
	run_program(pgm_lrelu_vpu0);
	fail |= verify_results("[ L.ReLU (VPU0) ]", rd_ptr, ref_lrelu_vpu0);

	run_program(pgm_lrelu_vpu1);
	fail |= verify_results("[ L.ReLU (VPU1) ]", rd_ptr, ref_lrelu_vpu1);

	// Product operation broadcast tests
	init_mem(rs_ptr, 16, 1.0, 1.0);
	init_mem(rt_ptr, 16, 10.0, 10.0);

	run_program(pgm_prod_vpu0);
	fail |= verify_results("[ Prod (VPU0)   ]", rd_ptr, ref_prod_vpu0);

	run_program(pgm_prod_vpu1);
	fail |= verify_results("[ Prod (VPU1)   ]", rd_ptr, ref_prod_vpu1);

	// Store operation broadcast tests
	init_mem(rd_ptr, 16, -1.0);
	run_program(pgm_store_vpu0);
	fail |= verify_results("[ Store (VPU0)  ]", rd_ptr, ref_store_vpu0);

	init_mem(rd_ptr, 16, -1.0);
	run_program(pgm_store_vpu1);
	fail |= verify_results("[ Store (VPU1)  ]", rd_ptr, ref_store_vpu1);


	std::cout << std::endl << "All done." << std::endl;

	return fail ? -1 : 0;
}


void load_programs(const sw::simple_allocator::allocation& prog_mem)
{
	const unsigned pg_size = 1024;
	char *vaddr = static_cast<char*>(prog_mem.vaddr);
	uint64_t paddr = prog_mem.paddr;

	pgm_lrelu_vpu0 = paddr;
	memcpy(vaddr, prog_lrelu_vpu0_bin, prog_lrelu_vpu0_bin_len);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_lrelu_vpu1 = paddr;
	memcpy(vaddr, prog_lrelu_vpu1_bin, prog_lrelu_vpu1_bin_len);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_prod_vpu0 = paddr;
	memcpy(vaddr, prog_prod_vpu0_bin, prog_prod_vpu0_bin_len);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_prod_vpu1 = paddr;
	memcpy(vaddr, prog_prod_vpu1_bin, prog_prod_vpu1_bin_len);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_store_vpu0 = paddr;
	memcpy(vaddr, prog_store_vpu0_bin, prog_store_vpu0_bin_len);

	vaddr += pg_size;
	paddr += pg_size;
	pgm_store_vpu1 = paddr;
	memcpy(vaddr, prog_store_vpu1_bin, prog_store_vpu1_bin_len);
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


void init_mem(float *mem, size_t count, float start_val, float incr)
{
	for(size_t i = 0; i < count; ++i) {
		mem[i] = start_val;
		start_val += incr;
	}
}
