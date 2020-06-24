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
#include <iostream>
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

	memory_port(::sc_core::sc_module_name name, std::vector<uint8_t>& m, tlm::tlm_target_socket<MEM_WIDTH>& s)
		: ::sc_core::sc_module(name), clk("clk"), nrst("nrst"), mem(m), socket(s)
	{
		SC_THREAD(mem_req_pipe_thread);
			sensitive << clk.pos();
	}

	tlm::tlm_sync_enum nb_transport_fw(tlm::tlm_generic_payload& trans, tlm::tlm_phase& phase, sc_time& t) override
	{
		// Make sure that correct transaction phase started
		if(phase != tlm::BEGIN_REQ) {
			std::cerr << name() << ": invalid transaction phase!" << std::endl;
			return tlm::TLM_COMPLETED;
		}

		// Handle memory access
		handle_access(trans);

		// Acquire transaction object and put to requests pipe
		trans.acquire();
		m_mem_req_pipe.write(&trans);

		return tlm::TLM_ACCEPTED;
	}

	void b_transport(tlm::tlm_generic_payload& trans, sc_time& t) override
	{
		handle_access(trans);
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

private:
	void handle_access(tlm::tlm_generic_payload& trans)
	{
		// Check that target address range is valid
		sc_dt::uint64 end_addr = trans.get_address() + trans.get_data_length();
		if(end_addr > mem.size()) {
			std::cerr << name() << ": invalid address range!" << std::endl;
			trans.set_response_status(tlm::TLM_ADDRESS_ERROR_RESPONSE);
			return;
		}

		// Handle read/write transactions
		if(trans.is_read()) {
			handle_read(trans);
		} else if(trans.is_write()) {
			handle_write(trans);
		} else {
			std::cerr << name() << ": invalid transaction type!" << std::endl;
		}
	}

	void handle_read(tlm::tlm_generic_payload& trans)
	{
		memcpy(trans.get_data_ptr(), &mem[trans.get_address()], trans.get_data_length());
		trans.set_response_status(tlm::TLM_OK_RESPONSE);
	}

	void handle_write(tlm::tlm_generic_payload& trans)
	{
		uint8_t *dst_mem = &mem[trans.get_address()];
		unsigned char *data_ptr = trans.get_data_ptr();
		unsigned int data_len = trans.get_data_length();
		unsigned char *be_ptr = trans.get_byte_enable_ptr();
		unsigned int be_len = trans.get_byte_enable_length();

		// Handle byte enables if valid
		if(be_ptr && be_len) {
			unsigned int i;
			unsigned int be_idx;
			for(i = 0; i < data_len; ++i) {
				be_idx = i % be_len;
				dst_mem[i] = (be_ptr[be_idx] == TLM_BYTE_ENABLED ? data_ptr[i] : dst_mem[i]);
			}
		} else {
			memcpy(dst_mem, data_ptr, data_len);
		}

		trans.set_response_status(tlm::TLM_OK_RESPONSE);
	}

private:
	void mem_req_pipe_thread()
	{
		tlm::tlm_generic_payload *trans;

		while(true) {
			wait();
			// Handle response
			trans = m_mem_req_pipe.read();
			tlm::tlm_phase phase = tlm::BEGIN_RESP;
			sc_time t;
			tlm::tlm_sync_enum r= socket->nb_transport_bw(*trans, phase, t);
			if(r != tlm::TLM_COMPLETED)
				std::cerr << name() << ": unexpected result returned!" << std::endl;
			wait(t);
		}
	}

private:
	std::vector<uint8_t>& mem;				// Memory reference
	tlm::tlm_target_socket<MEM_WIDTH>& socket;		// Socket reference
	sc_fifo<tlm::tlm_generic_payload*> m_mem_req_pipe;	// Requests pipe
};
