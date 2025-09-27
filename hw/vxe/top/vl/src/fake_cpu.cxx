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
 * Fake CPU model
 */

#include <iostream>
#include <dlfcn.h>
#include "fake_cpu.hxx"


// Private namespace
namespace {

	void cpu_wait(void *cpuid)
	{
		fake_cpu *cpu = reinterpret_cast<fake_cpu*>(cpuid);
		wait(cpu->clk.posedge_event());
	}

	void cpu_wait_cycles(void *cpuid, unsigned cycles)
	{
		fake_cpu *cpu = reinterpret_cast<fake_cpu*>(cpuid);
		while(cycles) {
			wait(cpu->clk.posedge_event());
			--cycles;
		}
	}

	void cpu_wait_intr(void *cpuid)
	{
		fake_cpu *cpu = reinterpret_cast<fake_cpu*>(cpuid);
		while(!cpu->i_intr.read())
			wait(cpu->clk.posedge_event());
	}

	uint32_t cpu_mmio_rreg32(void *cpuid, uint64_t addr)
	{
		fake_cpu *cpu = reinterpret_cast<fake_cpu*>(cpuid);

		// Send request
		axi4::areq32 rrq;
		rrq.id = fake_cpu::ID;
		rrq.addr = addr;
		cpu->m_ar_fifo_out.write(rrq);

		// Get response
		axi4::rresp32 rrs = cpu->m_r_fifo_in.read();
		if(rrs.id != fake_cpu::ID)
			std::cerr << __func__ << ": id mismatch ("
				<< rrs.id << " != " << fake_cpu::ID << ")"
				<< std::endl;
		if(rrs.resp != 0)
			std::cerr << __func__ << ": non-zero response ("
				<< rrs.resp << ")"
				<< std::endl;
		return rrs.data;
	}

	void cpu_mmio_wreg32(void *cpuid, uint64_t addr, uint32_t value)
	{
		fake_cpu *cpu = reinterpret_cast<fake_cpu*>(cpuid);

		// Send request
		axi4::areq32 wrqa;
		wrqa.id = fake_cpu::ID;
		wrqa.addr = addr;
		cpu->m_aw_fifo_out.write(wrqa);
		axi4::wreq32 wrqd;
		wrqd.strb = 0xF;
		wrqd.data = value;
		cpu->m_w_fifo_out.write(wrqd);

		// Get response
		axi4::bresp32 brs = cpu->m_b_fifo_in.read();
		if(brs.id != fake_cpu::ID)
			std::cerr << __func__ << ": id mismatch ("
				<< brs.id << " != " << fake_cpu::ID << ")"
				<< std::endl;
		if(brs.resp != 0)
			std::cerr << __func__ << ": non-zero response ("
				<< brs.resp << ")"
				<< std::endl;
	}

	void cpu_get_dmi(void *cpuid, struct fake_cpu_dmi *dmi)
	{
		fake_cpu *cpu = reinterpret_cast<fake_cpu*>(cpuid);
		*dmi = cpu->get_dmi();
	}

} // Private namespace


fake_cpu::fake_cpu(::sc_core::sc_module_name name, bool allow_stop)
	: ::sc_core::sc_module(name)
	, clk("clk")
	, nrst("nrst")
	, i_intr("i_intr")
	, m_aw_fifo_out("m_aw_fifo_out")
	, m_w_fifo_out("m_w_fifo_out")
	, m_b_fifo_in("m_b_fifo_in")
	, m_ar_fifo_out("m_ar_fifo_out")
	, m_r_fifo_in("m_r_fifo_in")
	, m_allow_stop(allow_stop)
	, retval(0)
{
	SC_THREAD(cpu_thread);
		sensitive << clk.pos();

	// Set CPU/SW interface
	cpu_api.cpuid = this;
	cpu_api.wait = cpu_wait;
	cpu_api.wait_cycles = cpu_wait_cycles;
	cpu_api.wait_intr = cpu_wait_intr;
	cpu_api.mmio_rreg32 = cpu_mmio_rreg32;
	cpu_api.mmio_wreg32 = cpu_mmio_wreg32;
	cpu_api.get_dmi = cpu_get_dmi;
}

void fake_cpu::set_mem(void *ptr, uint64_t size)
{
	dmi.ptr = ptr;
	dmi.start = 0;
	dmi.end = size - 1;
}

void fake_cpu::set_so_file(const std::string& so)
{
	so_file = so;
}

struct fake_cpu_dmi fake_cpu::get_dmi() const
{
	return dmi;
}

int fake_cpu::get_retval() const
{
	return retval;
}

void fake_cpu::cpu_thread()
{
	void *lh = nullptr;
	fake_cpu_entry_t entry = nullptr;

	// Wait for reset completion
	while(nrst.read() == false)
		wait();

	wait();

	// Load application shared object
	if(!so_file.empty()) {
		lh = dlopen(so_file.c_str(), RTLD_LAZY);
		if(lh)
			entry = reinterpret_cast<fake_cpu_entry_t>(dlsym(lh, FAKE_CPU_ENTRY_NAME));
		else
			std::cerr << name() << ": failed to load: " << so_file << std::endl;
	} else {
		std::cerr << name() << ": no shared object provided!" << std::endl;
	}

	// Call application
	if(entry) {
		retval = entry(&cpu_api);
		std::cout << name() << ": app terminated, exit code " << retval << "." << std::endl;
	}

	if(lh)
		dlclose(lh);

	if(m_allow_stop) {
		// Stop simulation
		sc_stop();
	}
}
