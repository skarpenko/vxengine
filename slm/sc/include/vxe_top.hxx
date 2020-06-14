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
 * VxEngine top
 */

#include <systemc.h>
#include <tlm.h>
#pragma once


// VxEngine top module
SC_MODULE(vxe_top), public virtual tlm::tlm_bw_transport_if<>, public virtual tlm::tlm_fw_transport_if<> {
	static constexpr unsigned IO_WIDTH = 32;
	static constexpr unsigned MEM_WIDTH = 64;

	sc_in<bool> clk;
	sc_in<bool> nrst;

	tlm::tlm_target_socket<IO_WIDTH> io_target;
	tlm::tlm_initiator_socket<MEM_WIDTH> mem_initiator0;
	tlm::tlm_initiator_socket<MEM_WIDTH> mem_initiator1;

	SC_CTOR(vxe_top)
		: clk("clk"), nrst("nrst")
	{
		io_target(*this);
		mem_initiator0(*this);
		mem_initiator1(*this);
	}

	tlm::tlm_sync_enum nb_transport_bw(tlm::tlm_generic_payload& trans, tlm::tlm_phase& phase, sc_time& t) override
	{
		//TODO:
		return tlm::TLM_COMPLETED;
	}

	void invalidate_direct_mem_ptr(sc_dt::uint64 start_range, sc_dt::uint64 end_range) override
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
		return false;
	}

	unsigned int transport_dbg(tlm::tlm_generic_payload& trans) override
	{
		return 0;
	}
};
