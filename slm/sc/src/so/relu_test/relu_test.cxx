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
 * Test of ReLU support
 */

#include <cstdint>
#include <iostream>
#include "vxe_common.hxx"
#include "simple_alloc.hxx"
#define SIMPLE_CPU_IF_SHORTCUTS
#include "simple_cpu_if.h"
// Floating point ReLU reference model
#include "flp/common.hxx"
#include "relu/hwrelu.hxx"


static struct simple_cpu_if *g_cpu_if;
#define SIMPLE_CPU_IF	g_cpu_if

#define EXP_REDUCE	(-4)		// Exponent adjustment for leaky ReLU
#define PLOT_MIN	(-16.0)		// Plot X axis minimum
#define PLOT_MAX	(16.0)		// Plot X axis maximum
#define PLOT_STEP	(0.1)		// Plot step
#define PLOT_POINTS	((PLOT_MAX - PLOT_MIN) / PLOT_STEP + 1)
#define MAX_THREADS	(16)		// Max. number of threads supported


namespace {
	simple_cpu_dmi dmi;		// Direct memory interface information
	uint8_t *mem;			// Pointer to memory
	sw::simple_allocator mem_alloc;	// Memory allocator
}

// Floating point ReLU reference model
float relu_ref(float v, bool l, int e)
{
	aux::float_t r;
	aux::float_t a;
	a.f = v;
	r.v = 0;
	hwrelu::relu<uint32_t, 8, 23>(a.v, r.v, l, e);
	return r.f;
}


/**
 * Main entry point
 */
extern "C" int simple_cpu_entry(struct simple_cpu_if *cpu_if)
{
	g_cpu_if = cpu_if;

	std::cout << "ReLU test" << std::endl;
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

	// Allocate result storage
	std::cout << "Allocating result storage." << std::endl;
	float *ref_result;
	float *vxe_result;
	uint64_t vxe_result_base;
	{
		auto r1 = mem_alloc.allocate(PLOT_POINTS * sizeof(float), sizeof(float));
		auto r2 = mem_alloc.allocate(PLOT_POINTS * sizeof(float), sizeof(float));
		if(r1.vaddr == nullptr || r2.vaddr == nullptr) {
			std::cerr << "Error: failed to allocate space for results." << std::endl;
			return -1;
		}
		ref_result = reinterpret_cast<float*>(r1.vaddr);
		vxe_result = reinterpret_cast<float*>(r2.vaddr);
		vxe_result_base = r2.paddr;
	}

	std::cout << "Computing reference result." << std::endl;
	{
		float v = PLOT_MIN;
		for(size_t i = 0; i < PLOT_POINTS; ++i) {
			ref_result[i] = relu_ref(v, true, EXP_REDUCE);
			v += PLOT_STEP;
		}
	}

	std::cout << "Setting up VxE program." << std::endl;
	uint64_t prog_addr;
	{
		constexpr size_t prog_len = PLOT_POINTS * 4;
		size_t pc, pnt, th;
		float pv;
		uint64_t *instr;
		auto prog = mem_alloc.allocate(prog_len * sizeof(uint64_t), sizeof(uint64_t));
		if(prog.vaddr == nullptr) {
			std::cerr << "Error: failed to allocate space for program." << std::endl;
			return -1;
		}
		instr = reinterpret_cast<uint64_t*>(prog.vaddr);
		prog_addr = prog.paddr;

		pc = pnt = 0;
		pv = PLOT_MIN;
		uint64_t rd_addr = vxe_result_base;
		while(pnt < PLOT_POINTS) {
			for(th = 0; th < MAX_THREADS; ++th) {
				if(pnt < PLOT_POINTS) {
					instr[pc++] = vxe::instr::setacc(th, pv);
					instr[pc++] = vxe::instr::setrd(th, rd_addr);
					instr[pc++] = vxe::instr::seten(th, true);
					rd_addr += sizeof(float);
				} else {
					instr[pc++] = vxe::instr::seten(th, false);
				}
				++pnt;
				pv = pv + PLOT_STEP;
			}
			instr[pc++] = vxe::instr::lrelu(EXP_REDUCE);
			instr[pc++] = vxe::instr::store();
			if(pc >= prog_len)
				std::cerr << "Warning PC overflow!" << std::endl;
		}
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
	for(size_t i = 0; i < PLOT_POINTS; ++i) {
		if(ref_result[i] != vxe_result[i]) {
			std::cerr << "Index " << i << ": " << ref_result[i] << " != "
				<< vxe_result[i] << " mismatch!" << std::endl;
			verif_failed = true;
		}
	}
	std::cout << (!verif_failed ? "PASS!" : "FAILED!") << std::endl;

	wait_cycles(50);

	std::cout << "All done." << std::endl;

	return 0;
}
