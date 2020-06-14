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
 * Simple CPU model
 */

#include <dlfcn.h>
#include "util.hxx"
#include "simple_cpu.hxx"


// Private namespace
namespace {
	void cpu_wait(void *cpuid)
	{
		simple_cpu *cpu = reinterpret_cast<simple_cpu*>(cpuid);
		wait(cpu->clk.posedge_event());
	}

	void cpu_wait_cycles(void *cpuid, unsigned cycles)
	{
		simple_cpu *cpu = reinterpret_cast<simple_cpu*>(cpuid);
		while(cycles) {
			wait(cpu->clk.posedge_event());
			--cycles;
		}
	}

	uint32_t cpu_mmio_rreg32(void *cpuid, uint64_t addr)
	{
		simple_cpu *cpu = reinterpret_cast<simple_cpu*>(cpuid);
		(void)cpu; //TODO:
		return 0;
	}

	void cpu_mmio_wreg32(void *cpuid, uint64_t addr, uint32_t value)
	{
		simple_cpu *cpu = reinterpret_cast<simple_cpu*>(cpuid);
		(void)cpu; //TODO:
	}

	int cpu_get_dmi(void *cpuid, struct simple_cpu_dmi *dmi)
	{
		simple_cpu *cpu = reinterpret_cast<simple_cpu*>(cpuid);
		*dmi = cpu->dmi;
		return cpu->dmi.ptr != nullptr;
	}
} // Private namespace


simple_cpu::simple_cpu(::sc_core::sc_module_name name)
	: ::sc_core::sc_module(name)
	, clk("clk")
	, nrst("nrst")
{
	SC_CTHREAD(cpu_thread, clk.pos());

	io_initiator(*this);
	mem_initiator(*this);

	// Set CPU/SW interface
	cpu_if.cpuid = this;
	cpu_if.wait = cpu_wait;
	cpu_if.wait_cycles = cpu_wait_cycles;
	cpu_if.mmio_rreg32 = cpu_mmio_rreg32;
	cpu_if.mmio_wreg32 = cpu_mmio_wreg32;
	cpu_if.get_dmi = cpu_get_dmi;
}


void simple_cpu::cpu_thread()
{
	void *lh = nullptr;
	simple_cpu_entry_t entry = nullptr;
	const ut::scope_guard guard([&lh]{ if(lh) dlclose(lh); });

	// Request DMI
	tlm::tlm_generic_payload pl;
	tlm::tlm_dmi dmi_data;
	if(mem_initiator->get_direct_mem_ptr(pl, dmi_data)) {
		dmi.ptr = dmi_data.get_dmi_ptr();
		dmi.start = dmi_data.get_start_address();
		dmi.end = dmi_data.get_end_address();
	} else {
		std::cerr << name() << ": DMI is not supported!" << std::endl;
	}

	// Load application shared object
	if(!so_file.empty()) {
		lh = dlopen(so_file.c_str(), RTLD_LAZY);
		if(lh)
			entry = reinterpret_cast<simple_cpu_entry_t>(dlsym(lh, SIMPLE_CPU_ENTRY_NAME));
		else
			std::cerr << name() << ": failed to load: " << so_file << std::endl;
	} else {
		std::cerr << name() << ": no shared object provided!" << std::endl;
	}

	// Call application
	if(entry) {
		int r = entry(&cpu_if);
		std::cout << name() << ": app terminated, exit code " << r << "." << std::endl;
	}
}


tlm::tlm_sync_enum simple_cpu::nb_transport_bw(tlm::tlm_generic_payload& trans, tlm::tlm_phase& phase, sc_time& t)
{
	//TODO:
	return tlm::TLM_COMPLETED;
}


void simple_cpu::invalidate_direct_mem_ptr(sc_dt::uint64 start_range, sc_dt::uint64 end_range)
{
}
