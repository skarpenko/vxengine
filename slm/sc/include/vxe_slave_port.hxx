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
 * VxEngine slave port
 */

#include <systemc.h>
#include <tlm.h>
#include "vxe_port_util.hxx"
#pragma once


// VxEngine slave port model template
template<unsigned WIDTH>
SC_MODULE(vxe_slave_port), public virtual tlm::tlm_fw_transport_if<> {
	SC_CTOR(vxe_slave_port)
	{}

	template<class Callable>
	void set_handler(Callable&& c)
	{
		m_handler = std::make_shared<vxe_port_callback<Callable>>(std::forward<Callable>(c));
	}


	tlm::tlm_sync_enum nb_transport_fw(tlm::tlm_generic_payload& trans, tlm::tlm_phase& phase, sc_time& t) override
	{
		return m_handler->handle(trans, phase, t);
	}

	void b_transport(tlm::tlm_generic_payload& trans,sc_time& t) override
	{
		tlm::tlm_phase phase = tlm::BEGIN_REQ;	// Not used for blocking transactions
		m_handler->handle(trans, phase, t);
	}

	bool get_direct_mem_ptr(tlm::tlm_generic_payload& trans, tlm::tlm_dmi& dmi_data) override
	{
		return false;
	}

	unsigned int transport_dbg(tlm::tlm_generic_payload& trans) override
	{
		return 0;
	}

public:
	std::shared_ptr<vxe_port_callback_base> m_handler;
};
