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

#include <iostream>
#include <systemc.h>
#include <tlm.h>
#include "register_set.hxx"
#include "vxe_common.hxx"
#include "vxe_slave_port.hxx"
#include "vxe_master_port.hxx"
#pragma once


// VxEngine top module
SC_MODULE(vxe_top) {
	// Data sizes
	static constexpr unsigned IO_WIDTH	= 32;
	static constexpr unsigned MEM_WIDTH	= 64;

	sc_in<bool> clk;
	sc_in<bool> nrst;

	tlm::tlm_target_socket<IO_WIDTH> io_target;
	tlm::tlm_initiator_socket<MEM_WIDTH> mem_initiator0;
	tlm::tlm_initiator_socket<MEM_WIDTH> mem_initiator1;

	SC_CTOR(vxe_top)
		: clk("clk"), nrst("nrst")
		, m_io_slave("m_io_slave"), m_mem_master0("m_mem_master0"), m_mem_master1("m_mem_master1")
	{
		// Init TLM sockets
		io_target(m_io_slave);
		mem_initiator0(m_mem_master0);
		mem_initiator1(m_mem_master1);

		// Set registers
		m_regs.set_reg(vxe::regi::REG_ID, vxe::VXENGINE_ID);
		m_regs.set_reg(vxe::regi::REG_CTRL, 0);
		m_regs.set_reg(vxe::regi::REG_STATUS, 0);
		m_regs.set_reg(vxe::regi::REG_INTR_ACT, 0);
		m_regs.set_reg(vxe::regi::REG_INTR_MSK, 0);
		m_regs.set_reg(vxe::regi::REG_INTR_RAW, 0);
		m_regs.set_reg(vxe::regi::REG_PGM_ADDR_LO, 0);
		m_regs.set_reg(vxe::regi::REG_PGM_ADDR_HI, 0);
		m_regs.set_reg(vxe::regi::REG_FAULT_INSTR_ADDR_LO, 0);
		m_regs.set_reg(vxe::regi::REG_FAULT_INSTR_ADDR_HI, 0);
		m_regs.set_reg(vxe::regi::REG_FAULT_INSTR_LO, 0);
		m_regs.set_reg(vxe::regi::REG_FAULT_INSTR_HI, 0);

		// Set slave port handler
		m_io_slave.set_handler(
			[&](tlm::tlm_generic_payload& trans, tlm::tlm_phase& phase, sc_time& t) -> tlm::tlm_sync_enum
			{
				handle_mmio(trans, t);
				return tlm::TLM_COMPLETED;
			}
		);

		// Set master ports handlers
		m_mem_master0.set_handler(
			[&](tlm::tlm_generic_payload& trans, tlm::tlm_phase& phase, sc_time& t) -> tlm::tlm_sync_enum
			{
				return tlm::TLM_COMPLETED;
			}
		);
		m_mem_master1.set_handler(
			[&](tlm::tlm_generic_payload& trans, tlm::tlm_phase& phase, sc_time& t) -> tlm::tlm_sync_enum
			{
				return tlm::TLM_COMPLETED;
			}
		);
	}

public:
	void handle_mmio(tlm::tlm_generic_payload& trans, sc_time& t)
	{
		uint32_t v = 0;
		unsigned regi = trans.get_address() / (IO_WIDTH/8);

		// Check that transaction addresses a valid register
		if(regi >= m_regs.size()) {
			std::cerr << name() << ": invalid register address!" << std::endl;
			trans.set_response_status(tlm::TLM_ADDRESS_ERROR_RESPONSE);
			return;
		}

		// Check data length
		if(trans.get_data_length() != (IO_WIDTH/8)) {
			std::cerr << name() << ": invalid data length!" << std::endl;
			trans.set_response_status(tlm::TLM_GENERIC_ERROR_RESPONSE);
			return;
		}

		if(trans.is_write())
			v = *reinterpret_cast<const uint32_t*>(trans.get_data_ptr());

		// Process request
		switch(regi) {
			case vxe::regi::REG_ID:
				if(trans.is_read())
					v = m_regs.get_reg(vxe::regi::REG_ID);
				break;
			case vxe::regi::REG_CTRL:
				if(trans.is_read())
					v = m_regs.get_reg(vxe::regi::REG_CTRL);
				else
					m_regs.set_reg(vxe::regi::REG_CTRL, v & vxe::regm::REG_CTRL);
				break;
			case vxe::regi::REG_STATUS:
				if(trans.is_read())
					v = m_regs.get_reg(vxe::regi::REG_STATUS);
				break;
			case vxe::regi::REG_INTR_ACT:
				if(trans.is_read())
					v = m_regs.get_reg(vxe::regi::REG_INTR_ACT);
				else
					m_regs.set_reg(vxe::regi::REG_INTR_ACT, v & vxe::regm::REG_INTR_ACT);
				break;
			case vxe::regi::REG_INTR_MSK:
				if(trans.is_read())
					v = m_regs.get_reg(vxe::regi::REG_INTR_MSK);
				else
					m_regs.set_reg(vxe::regi::REG_INTR_MSK, v & vxe::regm::REG_INTR_MSK);
				break;
			case vxe::regi::REG_INTR_RAW:
				if(trans.is_read())
					v = m_regs.get_reg(vxe::regi::REG_INTR_RAW);
				break;
			case vxe::regi::REG_PGM_ADDR_LO:
				if(trans.is_read())
					v = m_regs.get_reg(vxe::regi::REG_PGM_ADDR_LO);
				else
					m_regs.set_reg(vxe::regi::REG_PGM_ADDR_LO, v & vxe::regm::REG_PGM_ADDR_LO);
				break;
			case vxe::regi::REG_PGM_ADDR_HI:
				if(trans.is_read())
					v = m_regs.get_reg(vxe::regi::REG_PGM_ADDR_HI);
				else
					m_regs.set_reg(vxe::regi::REG_PGM_ADDR_HI, v & vxe::regm::REG_PGM_ADDR_HI);
				break;
			case vxe::regi::REG_FAULT_INSTR_ADDR_LO:
				if(trans.is_read())
					v = m_regs.get_reg(vxe::regi::REG_FAULT_INSTR_ADDR_LO);
				break;
			case vxe::regi::REG_FAULT_INSTR_ADDR_HI:
				if(trans.is_read())
					v = m_regs.get_reg(vxe::regi::REG_FAULT_INSTR_ADDR_HI);
				break;
			case vxe::regi::REG_FAULT_INSTR_LO:
				if(trans.is_read())
					v = m_regs.get_reg(vxe::regi::REG_FAULT_INSTR_LO);
				break;
			case vxe::regi::REG_FAULT_INSTR_HI:
				if(trans.is_read())
					v = m_regs.get_reg(vxe::regi::REG_FAULT_INSTR_HI);
				break;
			default:
				break;
		}

		if(trans.is_read())
			*reinterpret_cast<uint32_t*>(trans.get_data_ptr()) = v;

		trans.set_response_status(tlm::TLM_OK_RESPONSE);
	}

private:
	// Register set
	register_set<uint32_t, vxe::regi::REGS_NUMBER> m_regs;
	// Port transaction handlers
	vxe_slave_port<IO_WIDTH> m_io_slave;
	vxe_master_port<MEM_WIDTH> m_mem_master0;
	vxe_master_port<MEM_WIDTH> m_mem_master1;
};
