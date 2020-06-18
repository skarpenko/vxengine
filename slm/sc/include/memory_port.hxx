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
 * Memory port model
 */

#include <cstdint>
#include <vector>
#include <systemc.h>
#include <tlm.h>
#pragma once


// Memory port model template
template<unsigned MEM_WIDTH>
SC_MODULE(memory_port), public virtual tlm::tlm_fw_transport_if<> {
	sc_in<bool> clk;
	sc_in<bool> nrst;

	SC_HAS_PROCESS(memory_port);

	memory_port(::sc_core::sc_module_name name, std::vector<uint8_t>& m)
		: ::sc_core::sc_module(name), clk("clk"), nrst("nrst"), mem(m)
	{
	}

	tlm::tlm_sync_enum nb_transport_fw(tlm::tlm_generic_payload& trans, tlm::tlm_phase& phase, sc_time& t) override
	{
		//TODO:
		return tlm::TLM_ACCEPTED;
	}

	void b_transport(tlm::tlm_generic_payload& trans,sc_time& t) override
	{
		//TODO:
	}

	bool get_direct_mem_ptr(tlm::tlm_generic_payload& trans, tlm::tlm_dmi& dmi_data) override
	{
		// Fill direct memory interface data
		dmi_data.set_dmi_ptr(mem.data());
		dmi_data.set_start_address(0);
		dmi_data.set_end_address(mem.size()-1);
		dmi_data.allow_read_write();
		return true;
	}

	unsigned int transport_dbg(tlm::tlm_generic_payload& trans) override
	{
		return 0;
	}

public:
	std::vector<uint8_t>& mem;
};
