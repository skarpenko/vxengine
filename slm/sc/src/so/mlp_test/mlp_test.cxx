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
#include <iostream>
#include "vxe_common.hxx"
#include "simple_alloc.hxx"
#define SIMPLE_CPU_IF_SHORTCUTS
#include "simple_cpu_if.h"


static struct simple_cpu_if *g_cpu_if;
#define SIMPLE_CPU_IF	g_cpu_if


namespace {
	simple_cpu_dmi dmi;		// Direct memory interface information
	uint8_t *mem;			// Pointer to memory
	sw::simple_allocator mem_alloc;	// Memory allocator
}


/**
 * Main entry point
 */
extern "C" int simple_cpu_entry(struct simple_cpu_if *cpu_if)
{
	g_cpu_if = cpu_if;

	std::cout << "MLP inference test" << std::endl;
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

	// TODO:

	wait_cycles(50);

	std::cout << "All done." << std::endl;

	return 0;
}
