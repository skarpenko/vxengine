/*
 * Copyright (c) 2020-2022 The VxEngine Project. All rights reserved.
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
 * Unicast mode test for broadcast subclass of instructions
 */

#include <cstdint>
#include <iostream>
#include "vxe_common.hxx"
#include "simple_alloc.hxx"
#include "vec_util.hxx"
#include "flp/hwfmac.hxx"
#include "flp/common.hxx"
#define SIMPLE_CPU_IF_SHORTCUTS
#include "simple_cpu_if.h"

static struct simple_cpu_if *g_cpu_if;
#define SIMPLE_CPU_IF	g_cpu_if

constexpr size_t VEC_LEN		= 129;	// Vectors length to use
constexpr size_t VEC_PAIRS		= 16;	// Number of vector pairs (16 max.)
constexpr size_t THREADS_PER_VPU	= 8;	// Threads per VPU
constexpr size_t VPUS_NR		= 2;	// Number of VPUs


namespace {
	simple_cpu_dmi dmi;		// Direct memory interface information
	uint8_t *mem;			// Pointer to memory
	sw::simple_allocator mem_alloc;	// Memory allocator
}


/**
 * Compute vector product using reference FMAC model
 * @param acc accumulator value
 * @param rs operand vector 1
 * @param rt operand vector 2
 * @param len vectors len
 * @return result
 */
static float vector_prod(float acc, float *rs, float *rt, size_t len)
{
	aux::float_t a;

	a.f = acc;
	for(size_t i = 0; i < len; ++i) {
		aux::float_t b, c, r;
		b.f = rs[i];
		c.f = rt[i];
		hwfmac::mac<uint32_t, uint64_t, 8, 23, 23>(a.v, b.v, c.v, r.v);
		a.v = r.v;
	}

	return a.f;
}

/**
 * Pair of vector operands
 */
struct vector_pair {
	float *rs;
	uint64_t rs_pa;
	float *rt;
	uint64_t rt_pa;
};

/**
 * Main entry point
 */
extern "C" int simple_cpu_entry(struct simple_cpu_if *cpu_if)
{
	g_cpu_if = cpu_if;

	std::cout << "Unicast test test" << std::endl;
	std::cout << "Started on CPU: " << cpu_if->cpuid << std::endl;

	std::cout << "Requesting DMI data." << std::endl;
	cpu_if->get_dmi(cpu_if->cpuid, &dmi);
	if(dmi.ptr == nullptr) {
		std::cerr << "Error: DMI is not available!" << std::endl;
		return -1;
	}
	mem = reinterpret_cast<uint8_t*>(dmi.ptr);

	std::cout << "Setting up memory allocator." << std::endl;
	mem_alloc = sw::simple_allocator(dmi.ptr, dmi.start, dmi.end);

	// Check ID register
	uint32_t vxe_id, vxe_id_tmp;
	vxe_id = mmio_rreg32(vxe::rego::REG_ID);
	mmio_wreg32(vxe::rego::REG_ID, 0xDEADBEEF);
	vxe_id_tmp = mmio_rreg32(vxe::rego::REG_ID);
	if(vxe_id == vxe_id_tmp) {
		std::ios state(nullptr);
		state.copyfmt(std::cout);
		std::cout << "VxE ID: 0x" << std::hex << vxe_id << std::endl;
		std::cout.copyfmt(state);
	} else
		std::cerr << "VxE ID mismatch!" << std::endl;

	// Status register
	{
		uint32_t status_reg = mmio_rreg32(vxe::rego::REG_STATUS);
		std::ios state(nullptr);
		state.copyfmt(std::cout);
		std::cout << "Status reg = 0x" << std::hex << status_reg << std::endl;
		std::cout.copyfmt(state);
	}

	// Allocate vector operands
	std::cout << "Preparing vector operands." << std::endl;
	vector_pair vpairs[VEC_PAIRS];
	{
		float vgen_n0 = 0.0;
		float vgen_n1 = 0.5;
		float vgen_n2 = 1.0;
		float vgen_n3 = 2.0;
		for(size_t i = 0; i < VEC_PAIRS; ++i) {
			auto rs = mem_alloc.allocate(VEC_LEN * sizeof(float), sizeof(float));
			auto rt = mem_alloc.allocate(VEC_LEN * sizeof(float), sizeof(float));
			if (rs.vaddr == nullptr || rt.vaddr == nullptr) {
				std::cerr << "Error: failed to allocate vector pair: " << i << std::endl;
				return -1;
			}
			vpairs[i].rs = reinterpret_cast<float*>(rs.vaddr);
			vpairs[i].rs_pa = rs.paddr;
			vpairs[i].rt = reinterpret_cast<float*>(rt.vaddr);
			vpairs[i].rt_pa = rt.paddr;
			// Generate pair
			std::cout << "Generating pair No." << i << std::endl;
			sw::gen_vector2(vgen_n0, vgen_n1, vgen_n2, vgen_n3, vpairs[i].rs, VEC_LEN);
			vgen_n2 += 0.2;
			vgen_n3 += 0.4;
			sw::gen_vector2(vgen_n0, vgen_n1, vgen_n2, vgen_n3, vpairs[i].rt, VEC_LEN);
		}
	}

	// Allocate result storage
	std::cout << "Allocating result storage." << std::endl;
	float *ref_result;
	float *vxe_result;
	uint64_t vxe_result_base;
	{
		auto r1 = mem_alloc.allocate(VEC_PAIRS * sizeof(float), sizeof(float));
		auto r2 = mem_alloc.allocate(VEC_PAIRS * sizeof(float), sizeof(float));
		if(r1.vaddr == nullptr || r2.vaddr == nullptr) {
			std::cerr << "Error: failed to allocate space for results." << std::endl;
			return -1;
		}
		ref_result = reinterpret_cast<float*>(r1.vaddr);
		vxe_result = reinterpret_cast<float*>(r2.vaddr);
		vxe_result_base = r2.paddr;
	}

	std::cout << "Computing reference result." << std::endl;
	for(size_t i = 0; i < VEC_PAIRS; ++i) {
		ref_result[i] = vector_prod(0.0, vpairs[i].rs, vpairs[i].rt, VEC_LEN);
	}

	std::cout << "Setting up VxE program." << std::endl;
	uint64_t prog_addr;
	{
		constexpr size_t prog_len = 256;
		size_t pc = 0;
		uint64_t *instr;
		auto prog = mem_alloc.allocate(prog_len * sizeof(uint64_t), sizeof(uint64_t));
		if(prog.vaddr == nullptr) {
			std::cerr << "Error: failed to allocate space for program." << std::endl;
			return -1;
		}
		instr = reinterpret_cast<uint64_t*>(prog.vaddr);
		prog_addr = prog.paddr;

		uint64_t rd_addr = vxe_result_base;
		for (size_t i = 0; i < VEC_PAIRS / VPUS_NR; ++i) {
			// Overlapped VPU0 and VPU1 instructions
			instr[pc++] = vxe::instr::setacc(i, 0.0f);
			instr[pc++] = vxe::instr::setacc(i + THREADS_PER_VPU, 0.0f);
			instr[pc++] = vxe::instr::setrs(i, vpairs[i].rs_pa);
			instr[pc++] = vxe::instr::setrs(i + THREADS_PER_VPU, vpairs[i + THREADS_PER_VPU].rs_pa);
			instr[pc++] = vxe::instr::setrt(i, vpairs[i].rt_pa);
			instr[pc++] = vxe::instr::setrt(i + THREADS_PER_VPU, vpairs[i + THREADS_PER_VPU].rt_pa);
			instr[pc++] = vxe::instr::setrd(i, rd_addr);
			instr[pc++] = vxe::instr::setrd(i + THREADS_PER_VPU, rd_addr +
					THREADS_PER_VPU * sizeof(float));
			instr[pc++] = vxe::instr::setvl(i, VEC_LEN);
			instr[pc++] = vxe::instr::setvl(i + THREADS_PER_VPU, VEC_LEN);
			instr[pc++] = vxe::instr::seten(i, true);
			instr[pc++] = vxe::instr::seten(i + THREADS_PER_VPU, true);
			rd_addr += sizeof(float);
		}
		instr[pc++] = vxe::instr::prod(0);	// Start PROD on VPU0
		instr[pc++] = vxe::instr::prod(1);	// Start PROD on VPU1
		instr[pc++] = vxe::instr::store(0);	// Store result of VPU0
		instr[pc++] = vxe::instr::store(1);	// Store result of VPU1
		instr[pc++] = vxe::instr::sync(true, true);

		std::ios state(nullptr);
		state.copyfmt(std::cout);
		std::cout << "Program address: 0x" << std::hex << prog_addr
			<< " (" << std::dec << pc << " instr.)" << std::endl;
		std::cout.copyfmt(state);
	}

	// Start processing
	std::cout << "Preparing VxE for start." << std::endl;

	// Set program address
	mmio_wreg32(vxe::rego::REG_PGM_ADDR_LO, prog_addr & 0xFFFFFFFF);
	mmio_wreg32(vxe::rego::REG_PGM_ADDR_HI, prog_addr >> 32u);

	std::cout << "Start..." << std::endl;
	mmio_wreg32(vxe::rego::REG_START, 0);

	// Status register
	{
		uint32_t status_reg = mmio_rreg32(vxe::rego::REG_STATUS);
		std::ios state(nullptr);
		state.copyfmt(std::cout);
		std::cout << "Status reg = 0x" << std::hex << status_reg << std::endl;
		std::cout.copyfmt(state);
	}

	// Wait for interrupt
	wait_intr();

	std::cout << "Interrupt has arrived." << std::endl;

	// Status register and active interrupts register
	{
		uint32_t status_reg = mmio_rreg32(vxe::rego::REG_STATUS);
		uint32_t act_intr = mmio_rreg32(vxe::rego::REG_INTR_ACT);
		std::ios state(nullptr);
		state.copyfmt(std::cout);
		std::cout << "Status reg = 0x" << std::hex << status_reg << std::endl;
		std::cout << "Active intr. = 0x" << std::hex << act_intr << std::endl;
		std::cout.copyfmt(state);
	}

	// Acknowledge interrupt
	std::cout << "Acknowledging interrupt" << std::endl;
	mmio_wreg32(vxe::rego::REG_INTR_ACT, mmio_rreg32(vxe::rego::REG_INTR_ACT));

	// Status register and active interrupts register
	{
		uint32_t status_reg = mmio_rreg32(vxe::rego::REG_STATUS);
		uint32_t act_intr = mmio_rreg32(vxe::rego::REG_INTR_ACT);
		std::ios state(nullptr);
		state.copyfmt(std::cout);
		std::cout << "Status reg = 0x" << std::hex << status_reg << std::endl;
		std::cout << "(ack.) Active intr. = 0x" << std::hex << act_intr << std::endl;
		std::cout.copyfmt(state);
	}

	// Verify result
	std::cout << "Verifying result." << std::endl;
	bool verif_failed = false;
	for(size_t i = 0; i < VEC_PAIRS; ++i) {
		if(ref_result[i] != vxe_result[i]) {
			std::cerr << "Thread" << i << ": " << ref_result[i] << " != "
				<< vxe_result[i] << " mismatch!" << std::endl;
			verif_failed = true;
		}
	}
	std::cout << (!verif_failed ? "PASS!" : "FAILED!") << std::endl;

	wait_cycles(50);

	std::cout << "All done." << std::endl;

	return 0;
}
