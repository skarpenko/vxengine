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
 * MLP inference test
 */

#include <cstdint>
#include <cstring>
#include <iostream>
#include "vxe_common.hxx"
#include "simple_alloc.hxx"
#define SIMPLE_CPU_IF_SHORTCUTS
#include "simple_cpu_if.h"


static struct simple_cpu_if *g_cpu_if;
#define SIMPLE_CPU_IF	g_cpu_if

typedef sw::simple_allocator::allocation alloc_t;

namespace {
	simple_cpu_dmi dmi;		// Direct memory interface information
	uint8_t *mem;			// Pointer to memory
	sw::simple_allocator mem_alloc;	// Memory allocator
}

namespace mdl {
	constexpr size_t NH = 800;	// Number of neurons in hidden layer
	constexpr size_t NO = 10;	// Number of neurons in output layer
#	include "mnist_train/mdl/mlp_weights1.h"
#	include "mnist_train/mdl/mlp_weights2.h"
/*#	include "mnist_train/mdl/mnist_train_images.h"*/
/*#	include "mnist_train/mdl/mnist_train_labels.h"*/
#	include "mnist_train/mdl/mnist_test_images.h"
#	include "mnist_train/mdl/mnist_test_labels.h"
#	include "mnist_train/mdl/test_matches.h"
	constexpr size_t NIMG = sizeof(mnist_test_labels) / sizeof(mnist_test_labels[10]);
	constexpr size_t IMW = 28;
	constexpr size_t IMH = 28;
	constexpr int LRELU_EXP_REDUCE = -4;
} // namespace mdl


/* MLP configuration data */
struct configuration {
	alloc_t in_buf;
	alloc_t layer_w1;
	alloc_t tmp_buf;
	alloc_t layer_w2;
	alloc_t out_buf;
	alloc_t program;
};


/**
 * Setup inference stage (called once per MLP layer)
 * @param prog program location
 * @param pc starting PC
 * @param pc_lim PC limit
 * @param in input vector
 * @param ni number of inputs
 * @param w weights and biases
 * @param nn number of neurons
 * @param out inference output destination
 * @return new PC value
 */
size_t set_infer_stage(uint64_t *prog, size_t pc, size_t pc_lim, alloc_t in, size_t ni, alloc_t w, size_t nn, alloc_t out);


/**
 * Run inference
 * @param input input vector
 * @param cfg program configuration
 */
void run_inference(const float *input, configuration& cfg);


/**
 * Check if result matches MNIST label
 * @param res resulting vector
 * @param label MNIST label vector
 * @return true if result match reference
 */
bool label_match(const float *res, const float *label);


/**
 * Main entry point
 */
extern "C" int simple_cpu_entry(struct simple_cpu_if *cpu_if)
{
	g_cpu_if = cpu_if;

	std::cout << "MLP inference test" << std::endl;
	std::cout << "Started on CPU: " << cpu_if->cpuid << std::endl;
	std::cout << "Hidden neurons: " << mdl::NH << std::endl;
	std::cout << "Output neurons: " << mdl::NO << std::endl;
	std::cout << "Test set size: " << mdl::NIMG << std::endl;

	std::cout << "Requesting DMI data." << std::endl;
	cpu_if->get_dmi(cpu_if->cpuid, &dmi);
	if(dmi.ptr == nullptr) {
		std::cerr << "Error: DMI is not available!" << std::endl;
		return -1;
	}
	mem = reinterpret_cast<uint8_t*>(dmi.ptr);

	std::cout << "Setting up memory allocator." << std::endl;
	mem_alloc = sw::simple_allocator(dmi.ptr, dmi.start, dmi.end);

	constexpr size_t alignment = sizeof(float);
	constexpr size_t PC_LIMIT = 8192;
	configuration cfg = {};
	uint64_t *instr;

	// Allocate input buffer
	std::cout << "Allocating input buffer." << std::endl;
	cfg.in_buf = mem_alloc.allocate(mdl::IMW * mdl::IMH * sizeof(float), alignment);
	if(cfg.in_buf.vaddr == nullptr) {
		std::cerr << "Error: failed to allocate space for input buffer." << std::endl;
		return -1;
	}

	// Allocate space for hidden layer weights
	std::cout << "Allocating hidden layer weights storage." << std::endl;
	cfg.layer_w1 = mem_alloc.allocate(sizeof(mdl::mlp_weights_layer1), alignment);
	if(cfg.layer_w1.vaddr == nullptr) {
		std::cerr << "Error: failed to allocate space for hidden layer weights." << std::endl;
		return -1;
	}
	std::memcpy(cfg.layer_w1.vaddr, mdl::mlp_weights_layer1, sizeof(mdl::mlp_weights_layer1));

	// Allocate intermediate result buffer
	std::cout << "Allocating intermediate result buffer." << std::endl;
	cfg.tmp_buf = mem_alloc.allocate(mdl::NH * sizeof(float), alignment);
	if(cfg.tmp_buf.vaddr == nullptr) {
		std::cerr << "Error: failed to allocate space for intermediate result buffer." << std::endl;
		return -1;
	}

	// Allocate space for output layer weights
	std::cout << "Allocating output layer weights storage." << std::endl;
	cfg.layer_w2 = mem_alloc.allocate(sizeof(mdl::mlp_weights_layer2), alignment);
	if(cfg.layer_w2.vaddr == nullptr) {
		std::cerr << "Error: failed to allocate space for output layer weights." << std::endl;
		return -1;
	}
	std::memcpy(cfg.layer_w2.vaddr, mdl::mlp_weights_layer2, sizeof(mdl::mlp_weights_layer2));

	// Allocate output buffer
	std::cout << "Allocating output buffer." << std::endl;
	cfg.out_buf = mem_alloc.allocate(mdl::NO * sizeof(float), alignment);
	if(cfg.out_buf.vaddr == nullptr) {
		std::cerr << "Error: failed to allocate space for output buffer." << std::endl;
		return -1;
	}

	// Allocate space for program
	std::cout << "Allocating program space." << std::endl;
	cfg.program = mem_alloc.allocate(PC_LIMIT * sizeof(uint64_t), sizeof(uint64_t));
	if(cfg.program.vaddr == nullptr) {
		std::cerr << "Error: failed to allocate space for program." << std::endl;
		return -1;
	}
	instr = reinterpret_cast<uint64_t*>(cfg.program.vaddr);

	std::cout << "Creating VxE program." << std::endl;
	size_t pc = 0;
	pc = set_infer_stage(instr, pc, PC_LIMIT, cfg.in_buf, mdl::IMW * mdl::IMH, cfg.layer_w1, mdl::NH, cfg.tmp_buf);
	pc = set_infer_stage(instr, pc, PC_LIMIT, cfg.tmp_buf, mdl::NH, cfg.layer_w2, mdl::NO, cfg.out_buf);
	instr[pc++] = vxe::instr::sync(true, true);
	std::cout << "Program created." << " (" << pc << " instr.)" << std::endl;

	std::cout << "Executing inference test..." << std::endl;
	size_t pass_count = 0;
	for(size_t i = 0; i < mdl::NIMG; ++i) {
		float *res = reinterpret_cast<float*>(cfg.out_buf.vaddr);
		float *label = &mdl::mnist_test_labels[i][0];
		bool pass;
		std::cout << "Imag " << i << ": ";
		run_inference(&mdl::mnist_test_images[i][0], cfg);
		pass = (label_match(res, label) == (mdl::test_matches[i] == 1));
		std::cout << "(" << label_match(res, label) << " : " << mdl::test_matches[i] << ") ";
		std::cout << (pass ? "PASS" : "FAIL") << std::endl;
		pass_count += (pass ? 1 : 0);
	}
	std::cout << "Pass rate: " << pass_count << " / " << mdl::NIMG << std::endl;

	wait_cycles(50);

	std::cout << "All done." << std::endl;

	return 0;
}

size_t set_infer_stage(uint64_t *prog, size_t pc, size_t pc_lim, alloc_t in, size_t ni, alloc_t w, size_t nn, alloc_t out)
{
	constexpr size_t MAX_THREADS = 16;
	size_t nr, th;
	uint64_t rs, rt, rd;

	rs = in.paddr;
	rd = out.paddr;
	nr = 0;
	while(nr < nn) {
		for(th = 0; th < MAX_THREADS; ++th) {
			if(nr < nn) {
				float bias = reinterpret_cast<float*>(w.vaddr)[nr * (ni + 1)];
				rt = w.paddr + (nr * (ni + 1)) * sizeof(float) + sizeof(float);

				prog[pc++] = vxe::instr::seten(th, true);
				if(pc >= pc_lim) goto err;
				prog[pc++] = vxe::instr::setacc(th, bias);
				if(pc >= pc_lim) goto err;
				prog[pc++] = vxe::instr::setrs(th, rs);
				if(pc >= pc_lim) goto err;
				prog[pc++] = vxe::instr::setrt(th, rt);
				if(pc >= pc_lim) goto err;
				prog[pc++] = vxe::instr::setrd(th, rd);
				if(pc >= pc_lim) goto err;
				prog[pc++] = vxe::instr::setvl(th, ni);
				if(pc >= pc_lim) goto err;

				rd += sizeof(float);
			} else {
				prog[pc++] = vxe::instr::seten(th, false);
				if(pc >= pc_lim) goto err;
			}
			++nr;
		}
		prog[pc++] = vxe::instr::prod();
		if(pc >= pc_lim) goto err;
		prog[pc++] = vxe::instr::lrelu(mdl::LRELU_EXP_REDUCE);
		if(pc >= pc_lim) goto err;
		prog[pc++] = vxe::instr::store();
		if(pc >= pc_lim) goto err;
	}

	return pc;
err:
	std::cerr << "ERROR: Insufficient space for storing a program!" << std::endl;
	return pc;
}

void run_inference(const float *input, configuration& cfg)
{
	constexpr bool make_debug_noise = false;	// Verbosity level

	std::memcpy(cfg.in_buf.vaddr, input, mdl::IMW * mdl::IMH * sizeof(float));

	// Start processing
	if(make_debug_noise) std::cout << "Preparing VxE for start." << std::endl;

	// Set program address
	mmio_wreg32(vxe::rego::REG_PGM_ADDR_LO, cfg.program.paddr & 0xFFFFFFFF);
	mmio_wreg32(vxe::rego::REG_PGM_ADDR_HI, cfg.program.paddr >> 32u);

	if(make_debug_noise) std::cout << "Start..." << std::endl;
	mmio_wreg32(vxe::rego::REG_START, 0);

	// Status register
	if(make_debug_noise) {
		uint32_t status_reg = mmio_rreg32(vxe::rego::REG_STATUS);
		std::ios state(nullptr);
		state.copyfmt(std::cout);
		std::cout << "Status reg = 0x" << std::hex << status_reg << std::endl;
		std::cout.copyfmt(state);
	}

	// Wait for interrupt
	wait_intr();

	if(make_debug_noise) std::cout << "Interrupt has arrived." << std::endl;

	// Status register and active interrupts register
	if(make_debug_noise) {
		uint32_t status_reg = mmio_rreg32(vxe::rego::REG_STATUS);
		uint32_t act_intr = mmio_rreg32(vxe::rego::REG_INTR_ACT);
		std::ios state(nullptr);
		state.copyfmt(std::cout);
		std::cout << "Status reg = 0x" << std::hex << status_reg << std::endl;
		std::cout << "Active intr. = 0x" << std::hex << act_intr << std::endl;
		std::cout.copyfmt(state);
	}

	// Acknowledge interrupt
	if(make_debug_noise) std::cout << "Acknowledging interrupt" << std::endl;
	mmio_wreg32(vxe::rego::REG_INTR_ACT, mmio_rreg32(vxe::rego::REG_INTR_ACT));

	// Status register and active interrupts register
	if(make_debug_noise) {
		uint32_t status_reg = mmio_rreg32(vxe::rego::REG_STATUS);
		uint32_t act_intr = mmio_rreg32(vxe::rego::REG_INTR_ACT);
		std::ios state(nullptr);
		state.copyfmt(std::cout);
		std::cout << "Status reg = 0x" << std::hex << status_reg << std::endl;
		std::cout << "(ack.) Active intr. = 0x" << std::hex << act_intr << std::endl;
		std::cout.copyfmt(state);
	}
}

bool label_match(const float *res, const float *label)
{
	size_t p = 0;

	for(size_t i = 1; i < mdl::NO; ++i)
		if(res[i] > res[p])
			p = i;

	return label[p] != 0.0;
}
