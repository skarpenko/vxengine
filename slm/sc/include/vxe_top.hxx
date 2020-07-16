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
#include "vxe_internal.hxx"
#include "vxe_tlm_ext.hxx"
#include "tlm_payload.hxx"
#include "vxe_slave_port.hxx"
#include "vxe_master_port.hxx"
#include "vxe_mem_hub.hxx"
#include "vxe_ctrl_unit.hxx"
#include "vxe_vector_unit.hxx"
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

	// Instances of internal blocks
	vxe_mem_hub mem_hub;	// Memory Hub
	vxe_ctrl_unit cu;	// Control Unit
	vxe_vector_unit vpu0;	// Vector Processing Unit 0
	vxe_vector_unit vpu1;	// Vector Processing Unit 1

	SC_CTOR(vxe_top)
		: clk("clk"), nrst("nrst")
		, mem_hub("mem_hub")
		, cu("cu", vxe::mhc::CU)
		, vpu0("vpu0", vxe::mhc::VPU0), vpu1("vpu1", vxe::mhc::VPU1)
		, m_io_slave("m_io_slave"), m_mem_master0("m_mem_master0"), m_mem_master1("m_mem_master1")
	{
		SC_THREAD(mem_master0_thread);
			sensitive << clk.pos();

		SC_THREAD(mem_master1_thread);
			sensitive << clk.pos();

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
				if(phase != tlm::tlm_phase_enum::BEGIN_RESP)
					std::cerr << name() << ": wrong response phase on master 0!" << std::endl;

				handle_downstream(&trans, master0_fifo_ds);

				return tlm::TLM_COMPLETED;
			}
		);
		m_mem_master1.set_handler(
			[&](tlm::tlm_generic_payload& trans, tlm::tlm_phase& phase, sc_time& t) -> tlm::tlm_sync_enum
			{
				if(phase != tlm::tlm_phase_enum::BEGIN_RESP)
					std::cerr << name() << ": wrong response phase on master 1!" << std::endl;

				handle_downstream(&trans, master1_fifo_ds);

				return tlm::TLM_COMPLETED;
			}
		);

		// Setup memory hub connections
		mem_hub.clk(clk);
		mem_hub.nrst(nrst);
		mem_hub.cu_fifo_in(cu_fifo_us);
		mem_hub.cu_fifo_out(cu_fifo_ds);
		mem_hub.vpu0_fifo_in(vpu0_fifo_us);
		mem_hub.vpu0_fifo_out(vpu0_fifo_ds);
		mem_hub.vpu1_fifo_in(vpu1_fifo_us);
		mem_hub.vpu1_fifo_out(vpu1_fifo_ds);
		mem_hub.master0_fifo_in(master0_fifo_ds);
		mem_hub.master0_fifo_out(master0_fifo_us);
		mem_hub.master1_fifo_in(master1_fifo_ds);
		mem_hub.master1_fifo_out(master1_fifo_us);
		// Setup control unit connections
		cu.clk(clk);
		cu.nrst(nrst);
		cu.mem_fifo_in(cu_fifo_ds);
		cu.mem_fifo_out(cu_fifo_us);
		// Setup vector processing units connections
		vpu0.clk(clk);
		vpu0.nrst(nrst);
		vpu0.mem_fifo_in(vpu0_fifo_ds);
		vpu0.mem_fifo_out(vpu0_fifo_us);
		vpu1.clk(clk);
		vpu1.nrst(nrst);
		vpu1.mem_fifo_in(vpu1_fifo_ds);
		vpu1.mem_fifo_out(vpu1_fifo_us);
	}

private:
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

	// Handler of downstream memory traffic
	void handle_downstream(tlm::tlm_generic_payload *gp, sc_fifo<vxe::vxe_mem_rq>& fifo_ds)
	{
		// Create payload for downstream
		vxe::vxe_mem_rq rq;

		// Setup payload fields
		rq.tid = gp->get_extension<vxe::vxe_tlm_gp_ext>()->get_tid();
		rq.addr = gp->get_address();
		memcpy(rq.data_u8, gp->get_data_ptr(), sizeof(rq.data_u8));
		for(size_t i=0; i < sizeof(rq.ben); ++i) {
			unsigned char *be = gp->get_byte_enable_ptr();
			rq.ben[i] = (be[i] == TLM_BYTE_ENABLED);
		}

		// Check response status
		tlm::tlm_response_status status = gp->get_response_status();
		if(status != tlm::tlm_response_status::TLM_OK_RESPONSE) {
			rq.type = (status == tlm::tlm_response_status::TLM_ADDRESS_ERROR_RESPONSE ?
				vxe::vxe_mem_rq::rtype::RES_AE : vxe::vxe_mem_rq::rtype::RES_DE);
			std::cerr << name() << ": Error response => " << rq << std::endl;
			/* fifo_ds.write(rq); */
		} else {
			rq.type = vxe::vxe_mem_rq::rtype::RES_OK;
			fifo_ds.write(rq);
		}

		// Release TLM payload
		gp->release();
	}

	// Handler of upstream memory traffic
	void handle_upstream(tlm::tlm_initiator_socket<MEM_WIDTH>& port, sc_fifo<vxe::vxe_mem_rq>& fifo_us,
		sc_fifo<vxe::vxe_mem_rq>& fifo_ds)
	{
		// Fetch new request
		vxe::vxe_mem_rq rq;
		rq = fifo_us.read();

		// Create payload
		tlm::tlm_generic_payload *gp = tlm_pl::alloc_gp(sizeof(rq.data_u8), sizeof(rq.ben));
		vxe::vxe_tlm_gp_ext *ext = new vxe::vxe_tlm_gp_ext();
		gp->set_extension(ext);

		// Setup payload fields
		ext->set_tid(rq.tid);
		gp->set_command(rq.type == vxe::vxe_mem_rq::rtype::CMD_RD ?
			tlm::tlm_command::TLM_READ_COMMAND : tlm::tlm_command::TLM_WRITE_COMMAND);
		gp->set_address(rq.addr);
		gp->set_data_length(sizeof(rq.data_u8));
		memcpy(gp->get_data_ptr(), rq.data_u8, sizeof(rq.data_u8));
		gp->set_byte_enable_length(sizeof(rq.ben));
		for(size_t i=0; i < sizeof(rq.ben); ++i) {
			unsigned char *be = gp->get_byte_enable_ptr();
			be[i] = (rq.ben[i] ? TLM_BYTE_ENABLED : TLM_BYTE_DISABLED);
		}

		// Initiate transaction
		tlm::tlm_phase phase(tlm::tlm_phase_enum::BEGIN_REQ);
		sc_time t;
		tlm::tlm_sync_enum ret = port->nb_transport_fw(*gp, phase, t);

		wait(t);

		// Check return status
		if(ret == tlm::tlm_sync_enum::TLM_COMPLETED)
			handle_downstream(gp, fifo_ds);
	}

	[[noreturn]] void mem_master0_thread()
	{
		while(1) {
			handle_upstream(mem_initiator0, master0_fifo_us, master0_fifo_ds);
		}

	}

	[[noreturn]] void mem_master1_thread()
	{
		while(1) {
			handle_upstream(mem_initiator1, master1_fifo_us, master1_fifo_ds);
		}
	}

private:
	// Register set
	register_set<uint32_t, vxe::regi::REGS_NUMBER> m_regs;
	// Port transaction handlers
	vxe_slave_port<IO_WIDTH> m_io_slave;
	vxe_master_port<MEM_WIDTH> m_mem_master0;
	vxe_master_port<MEM_WIDTH> m_mem_master1;
	// Memory hub interface - upstream FIFOs
	sc_fifo<vxe::vxe_mem_rq> cu_fifo_us;
	sc_fifo<vxe::vxe_mem_rq> vpu0_fifo_us;
	sc_fifo<vxe::vxe_mem_rq> vpu1_fifo_us;
	sc_fifo<vxe::vxe_mem_rq> master0_fifo_us;
	sc_fifo<vxe::vxe_mem_rq> master1_fifo_us;
	// Memory hub interface - downstream FIFOs
	sc_fifo<vxe::vxe_mem_rq> cu_fifo_ds;
	sc_fifo<vxe::vxe_mem_rq> vpu0_fifo_ds;
	sc_fifo<vxe::vxe_mem_rq> vpu1_fifo_ds;
	sc_fifo<vxe::vxe_mem_rq> master0_fifo_ds;
	sc_fifo<vxe::vxe_mem_rq> master1_fifo_ds;
};
