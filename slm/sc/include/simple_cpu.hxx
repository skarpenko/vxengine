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

#include <string>
#include <systemc.h>
#include <tlm.h>
#include "simple_cpu_if.h"
#pragma once


// Simple CPU
SC_MODULE(simple_cpu), public virtual tlm::tlm_bw_transport_if<> {
	static constexpr unsigned IO_WIDTH = 32;
	static constexpr unsigned MEM_WIDTH = 64;

	sc_in<bool> clk;
	sc_in<bool> nrst;
	sc_in<bool> i_intr;

	tlm::tlm_initiator_socket<IO_WIDTH> io_initiator;
	tlm::tlm_initiator_socket<MEM_WIDTH> mem_initiator;

	SC_HAS_PROCESS(simple_cpu);

	simple_cpu(::sc_core::sc_module_name name, bool allow_stop=true);

	void cpu_thread();

	tlm::tlm_sync_enum nb_transport_bw(tlm::tlm_generic_payload& trans, tlm::tlm_phase& phase, sc_time& t) override;
	void invalidate_direct_mem_ptr(sc_dt::uint64 start_range, sc_dt::uint64 end_range) override;

public:
	bool m_allow_stop;		// If =true simulation will end when program returns
	std::string so_file;		// App. shared object
	struct simple_cpu_dmi dmi;	// Direct memory interface info
	struct simple_cpu_if cpu_if;	// CPU/App interface
};
