/*
 * Copyright (c) 2020-2022 The VxEngine Project. All rights reserved.
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
 * VxEngine Control Unit
 */

#include <iostream>
#include <systemc.h>
#include "register_set.hxx"
#include "vxe_common.hxx"
#include "vxe_internal.hxx"


// VxEngine Control Unit
SC_MODULE(vxe_ctrl_unit) {
	sc_in<bool> clk;
	sc_in<bool> nrst;

	// Memory interface
	sc_fifo_in<vxe::vxe_mem_rq> mem_fifo_in;
	sc_fifo_out<vxe::vxe_mem_rq> mem_fifo_out;

	// Control signals
	sc_in<bool> i_start;
	sc_out<bool> o_busy;

	// Interrupt request signal
	sc_out<bool> o_intr;

	// VPUs status and command buses signals
	sc_in<bool> i_vpu0_busy;
	sc_in<bool> i_vpu1_busy;
	sc_in<bool> i_vpu0_err;
	sc_in<bool> i_vpu1_err;
	sc_out<bool> o_cmd_select_vpu0;
	sc_in<bool> i_cmd_ack_vpu0;
	sc_out<uint8_t> o_cmd_op_vpu0;
	sc_out<uint8_t> o_cmd_thread_vpu0;
	sc_out<uint64_t> o_cmd_wdata_vpu0;
	sc_out<bool> o_cmd_select_vpu1;
	sc_in<bool> i_cmd_ack_vpu1;
	sc_out<uint8_t> o_cmd_op_vpu1;
	sc_out<uint8_t> o_cmd_thread_vpu1;
	sc_out<uint64_t> o_cmd_wdata_vpu1;

	SC_HAS_PROCESS(vxe_ctrl_unit);

	vxe_ctrl_unit(::sc_core::sc_module_name name, unsigned client_id, register_set_if<uint32_t>& regs)
		: ::sc_core::sc_module(name), clk("clk"), nrst("nrst")
		, mem_fifo_in("mem_fifo_in"), mem_fifo_out("mem_fifo_out")
		, i_start("i_start"), o_busy("o_busy")
		, o_intr("o_intr")
		, i_vpu0_busy("i_vpu0_busy"), i_vpu1_busy("i_vpu1_busy")
		, i_vpu0_err("i_vpu0_err"), i_vpu1_err("i_vpu1_err")
		, o_cmd_select_vpu0("o_cmd_select_vpu0"), i_cmd_ack_vpu0("i_cmd_ack_vpu0")
		, o_cmd_op_vpu0("o_cmd_op_vpu0"), o_cmd_thread_vpu0("o_cmd_thread_vpu0")
		, o_cmd_wdata_vpu0("o_cmd_wdata_vpu0"), o_cmd_select_vpu1("o_cmd_select_vpu1")
		, i_cmd_ack_vpu1("i_cmd_ack_vpu1"), o_cmd_op_vpu1("o_cmd_op_vpu1")
		, o_cmd_thread_vpu1("o_cmd_thread_vpu1"), o_cmd_wdata_vpu1("o_cmd_wdata_vpu1")
		, m_client_id(client_id), m_regs(regs)
	{
		SC_THREAD(instr_fetch_thread);
			sensitive << clk.pos();

		SC_THREAD(instr_exec_thread);
			sensitive << clk.pos();

		SC_THREAD(vpu0_exec_thread);
			sensitive << clk.pos();

		SC_THREAD(vpu1_exec_thread);
			sensitive << clk.pos();

		SC_THREAD(intr_thread);
			sensitive << clk.pos();

		SC_THREAD(vpu_error_thread);
			sensitive << clk.pos();

		SC_METHOD(busy_logic_method);
			sensitive << s_ifetch_busy;
	}

private:

	/**
	 * Instruction fetch thread
	 * Sends instruction fetch requests to a memory hub
	 */
	[[noreturn]] void instr_fetch_thread()
	{
		while(true) {
			s_ifetch_busy.write(false);

			// Wait for start trigger
			wait();

			if(!i_start.read())
				continue;

			// Check for logic error
			if(o_busy.read())
				std::cerr << name() << ": start signal asserted while in busy state!"
					<< std::endl;

			// Start instruction requests
			s_ifetch_busy.write(true);

			// Form a program counter
			uint64_t pgm_lo = m_regs.get_reg(vxe::regi::REG_PGM_ADDR_LO);
			uint64_t pgm_hi = m_regs.get_reg(vxe::regi::REG_PGM_ADDR_HI);
			m_pgm_counter = (pgm_hi << 32u) | pgm_lo;

			while(!s_ifetch_stop.read()) {
				// Prepare request
				vxe::vxe_mem_rq rq;
				rq.set_client_id(m_client_id);
				rq.req = vxe::vxe_mem_rq::rqtype::REQ_RD;
				rq.addr = m_pgm_counter;
				rq.set_ben_mask(0xFF);
				// Push to outstanding requests FIFO
				out_rqs_fifo.write(true);
				// Send request
				mem_fifo_out.write(rq);
				// Increment program counter
				m_pgm_counter += sizeof(vxe::instr::generic);
			}

			// Wait while exec thread drains input FIFO
			while(s_iexec_busy.read())
				wait();
		}
	}

	/**
	 * Drain incoming instructions FIFO
	 */
	void drain_instr_fifo()
	{
		bool fetched, outstanding;
		vxe::vxe_mem_rq rq;
		bool ignored;

		// Keep fetching until no requests on the fly remain
		do {
			outstanding = out_rqs_fifo.nb_read(ignored);
			fetched = false;
			// Wait for and drop response data
			while(outstanding && !fetched) {
				fetched = mem_fifo_in.nb_read(rq);
				wait();
			}
		} while(outstanding);
	}

	/**
	 * Send an instruction to VPU
	 */
	bool send_vpu_instr(unsigned vpu_no, uint8_t cmd, uint8_t thread, uint64_t wdata)
	{
		if(vpu_no == 0) {
			// Send to VPU0
			o_cmd_select_vpu0.write(true);
			o_cmd_op_vpu0.write(cmd);
			o_cmd_thread_vpu0.write(thread);
			o_cmd_wdata_vpu0.write(wdata);
			wait();	// Wait for next positive edge

			// De-assert select signals
			o_cmd_select_vpu0.write(false);

			// Wait for acknowledgement from VPU
			bool ack = false;
			bool err = false;
			while(!ack) {
				ack = i_cmd_ack_vpu0.read();
				err = i_vpu0_err.read();
				wait();
			}

			return err;
		} else if(vpu_no == 1) {
			// Send to VPU1
			o_cmd_select_vpu1.write(true);
			o_cmd_op_vpu1.write(cmd);
			o_cmd_thread_vpu1.write(thread);
			o_cmd_wdata_vpu1.write(wdata);
			wait();	// Wait for next positive edge

			// De-assert select signals
			o_cmd_select_vpu1.write(false);

			// Wait for acknowledgement from VPU
			bool ack = false;
			bool err = false;
			while(!ack) {
				ack = i_cmd_ack_vpu1.read();
				err = i_vpu1_err.read();
				wait();
			}

			return err;
		} else {
			std::cerr << name() << ": invalid vpu_no for send_vpu_instr!"
				<< std::endl;
			return true;
		}
	}

	/**
	 * Wait while VPUs are busy
	 */
	void wait_for_vpus()
	{
		while((i_vpu0_busy.read() || vpu0_instr_fifo.num_available() != 0)
			|| (i_vpu1_busy.read() || vpu1_instr_fifo.num_available() != 0))
			wait();
	}

	/**
	 * Get VPU number from dst field of the instruction
	 * @param dst destination
	 * @return VPU number 0 or 1
	 */
	unsigned vpu_number(unsigned dst)
	{
		return (dst & 0x8u ? 1 : 0);
	}

	/**
	 * Check if destination is VPU0
	 * @param dst destination
	 * @return true if destination is VPU0
	 */
	bool is_vpu0_dst(unsigned dst)
	{
		return vpu_number(dst) == 0;
	}

	/**
	 * Check if destination is VPU1
	 * @param dst destination
	 * @return true if destination VPU1
	 */
	bool is_vpu1_dst(unsigned dst)
	{
		return vpu_number(dst) == 1;
	}

	/**
	 * Get VPU local thread id from dst field of the instruction
	 * @param dst destination
	 * @return VPU local thread id
	 */
	unsigned vpu_local_tid(unsigned dst)
	{
		return dst & 0x7u;
	}

	/**
	 * Check if instruction broadcasts
	 * (for broadcast sub-class of instructions)
	 * @param dst destination field
	 * @return true if broadcast otherwise destination is a single VPU
	 */
	bool is_vpu_broadcast(unsigned dst)
	{
		return (dst & 0x1) == 0;
	}

	/**** CU INSTRUCTIONS IMPLEMENTATION ****/

	/**
	 * NOP - No Operation
	 */
	void cu_instr_nop(const vxe::instr::nop& nop)
	{
		wait();
	}

	/**
	 * SYNC - Synchronize
	 */
	void cu_instr_sync(const vxe::instr::sync& sync)
	{
		/* Wait if VPUs are busy */
		wait_for_vpus();

		/* If stop of execution requested */
		if(sync.stop) {
			s_ifetch_stop.write(true);
			drain_instr_fifo();
		}

		/* If interrupt requested */
		if(sync.intr)
			s_sync_intr.write(true);
	}

	/****************************************/

	/**
	 * Forward an instruction to a designated VPU or VPUs
	 */
	void fwd_vpu_instr(const vxe::instr::generic_vpu& vpug)
	{
		bool vpu0 = false;
		bool vpu1 = false;

		// Route instruction
		switch(vpug.op) {
			// Never broadcast subclass of instructions
			case vxe::instr::setacc::OP:
			case vxe::instr::setvl::OP:
			case vxe::instr::setrs::OP:
			case vxe::instr::setrt::OP:
			case vxe::instr::setrd::OP:
			case vxe::instr::seten::OP:
				vpu0 = is_vpu0_dst(vpug.dst);
				vpu1 = is_vpu1_dst(vpug.dst);
				break;
			// Can broadcast subclass of instructions
			case vxe::instr::prod::OP:
			case vxe::instr::store::OP:
			case vxe::instr::generic_af::OP:
				if(!is_vpu_broadcast(vpug.dst)) {
					vpu0 = is_vpu0_dst(vpug.dst);
					vpu1 = is_vpu1_dst(vpug.dst);
				} else {
					vpu0 = vpu1 = true;
				}
				break;
			default:
				invalid_instruction();
				break;
		}

		if(vpu0)
			vpu0_instr_fifo.write(vpug);

		if(vpu1)
			vpu1_instr_fifo.write(vpug);
	}

	/**
	 * Stops execution and asserts invalid instruction condition
	 * (to use in instr_exec_thread)
	 */
	void invalid_instruction()
	{
		s_ifetch_stop.write(true);
		drain_instr_fifo();
		s_err_instr_intr.write(true);
	}

	/**
	 * Instructions execution thread
	 * Receives instruction stream from a memory hub
	 */
	[[noreturn]] void instr_exec_thread()
	{
		while(true) {
			// Set to initial state
			s_iexec_busy.write(false);
			s_ifetch_stop.write(false);
			s_sync_intr.write(false);
			s_err_fetch_intr.write(false);
			s_err_instr_intr.write(false);

			wait();	// Wait for positive edge

			// Loop until instruction fetch stop is requested
			while(!s_ifetch_stop.read()) {
				vxe::vxe_mem_rq rq;
				// Read incoming instructions FIFO
				rq = mem_fifo_in.read();
				// Drop outstanding request
				out_rqs_fifo.read();

				// Switch execution unit to busy state
				s_iexec_busy.write(true);

				// Check for error response
				if(rq.res != vxe::vxe_mem_rq::rstype::RES_OK) {
					s_ifetch_stop.write(true);
					drain_instr_fifo();
					s_err_fetch_intr.write(true);
					wait();
					continue;
				}

				// Check for VPU errors
				if(s_vpu_err.read()) {
					invalid_instruction();
					wait();
					continue;
				}

				// Generic instruction
				vxe::instr::generic g(rq.data_u64[0]);

				// Decode and execute
				switch(g.op) {
					// CU instructions
					case vxe::instr::nop::OP:
						cu_instr_nop(g);
						break;
					case vxe::instr::sync::OP:
						cu_instr_sync(g);
						break;
					// VPU instructions
					case vxe::instr::setacc::OP:
					case vxe::instr::setvl::OP:
					case vxe::instr::setrs::OP:
					case vxe::instr::setrt::OP:
					case vxe::instr::setrd::OP:
					case vxe::instr::seten::OP:
					case vxe::instr::prod::OP:
					case vxe::instr::store::OP:
					case vxe::instr::generic_af::OP:
						fwd_vpu_instr(g);
						break;
					default:
						invalid_instruction();
						break;
				}

				wait();	// Wait for positive edge before returning to idle state
			}
		}
	}

	/**
	 * VPU0 instructions execution thread
	 * Receives instruction stream from an internal FIFO
	 */
	[[noreturn]] void vpu0_exec_thread()
	{
		while(true) {
			vxe::instr::generic_vpu vpug = vpu0_instr_fifo.read();
			if(!s_vpu_err.read())
				send_vpu_instr(0, vpug.op, vpu_local_tid(vpug.dst), vpug.pl);
		}
	}

	/**
	 * VPU1 instructions execution thread
	 * Receives instruction stream from an internal FIFO
	 */
	[[noreturn]] void vpu1_exec_thread()
	{
		while(true) {
			vxe::instr::generic_vpu vpug = vpu1_instr_fifo.read();
			if(!s_vpu_err.read())
				send_vpu_instr(1, vpug.op, vpu_local_tid(vpug.dst), vpug.pl);
		}
	}

	/**
	 * Interrupt generation logic thread
	 */
	[[noreturn]] void intr_thread()
	{
		o_intr.write(false);	// Initialize to low

		while(true) {
			wait();	// wait for clock positive edge

			uint32_t new_ints = 0;		// Newly triggered raw interrupts
			uint32_t new_ints_masked;	// New active interrupts
			// Read interrupt condition signals
			bool sync = s_sync_intr.read();
			bool err_fetch = s_err_fetch_intr.read();
			bool err_instr = s_err_instr_intr.read() || i_vpu0_err.read() || i_vpu1_err.read();

			// Form raw interrupts register value
			new_ints = vxe::setbits(new_ints, (sync ? 1u : 0u),
				vxe::bits::REG_INTR_ACT::COMPLETED_MASK, vxe::bits::REG_INTR_ACT::COMPLETED_SHIFT);
			new_ints = vxe::setbits(new_ints, (err_fetch ? 1u : 0u),
				vxe::bits::REG_INTR_ACT::ERR_FETCH_MASK, vxe::bits::REG_INTR_ACT::ERR_FETCH_SHIFT);
			new_ints = vxe::setbits(new_ints, (err_instr ? 1u : 0u),
				vxe::bits::REG_INTR_ACT::ERR_INSTR_MASK, vxe::bits::REG_INTR_ACT::ERR_INSTR_SHIFT);

			// Apply interrupt mask
			new_ints_masked = new_ints & ~m_regs.get_reg(vxe::regi::REG_INTR_MSK);

			// Merge with current active interrupts
			new_ints |= m_regs.get_reg(vxe::regi::REG_INTR_ACT);
			new_ints_masked |= m_regs.get_reg(vxe::regi::REG_INTR_ACT);

			// Update registers
			m_regs.set_reg(vxe::regi::REG_INTR_ACT, new_ints_masked);
			m_regs.set_reg(vxe::regi::REG_INTR_RAW, new_ints);

			// Update interrupt signal
			o_intr.write(new_ints_masked != 0);
		}
	}

	/**
	 * VPUs errors tracking thread
	 */
	[[noreturn]] void vpu_error_thread()
	{
		while(true) {
			s_vpu_err.write(false);

			if(i_vpu0_err.read() || i_vpu1_err.read()) {
				s_vpu_err.write(true);
				do {
					wait();
				} while(o_busy.read());
			} else
				wait();
		}
	}

	/**
	 * Busy state logic for VxEngine
	 */
	void busy_logic_method()
	{
		bool busy;
		bool vpus_busy = (i_vpu0_busy.read() || vpu0_instr_fifo.num_available() != 0)
			|| (i_vpu1_busy.read() || vpu1_instr_fifo.num_available() != 0);

		if(s_ifetch_busy.read() || vpus_busy)
			busy = true;
		else
			busy = false;

		// Update busy signal
		o_busy.write(busy);

		// Update status register
		uint32_t status = m_regs.get_reg(vxe::regi::REG_STATUS);
		status = vxe::setbits(status, (busy ? 1u : 0u), vxe::bits::REG_STATUS::BUSY_MASK,
			vxe::bits::REG_STATUS::BUSY_SHIFT);
		m_regs.set_reg(vxe::regi::REG_STATUS, status);
	}

private:
	const unsigned m_client_id;
	// VxE register file
	register_set_if<uint32_t>& m_regs;
	// Internal control signals
	sc_signal<bool> s_ifetch_busy;
	sc_signal<bool> s_ifetch_stop;
	sc_signal<bool> s_iexec_busy;
	sc_signal<bool> s_sync_intr;
	sc_signal<bool> s_err_fetch_intr;
	sc_signal<bool> s_err_instr_intr;
	sc_signal<bool> s_vpu_err;
	// Internal control FIFOs
	sc_fifo<bool> out_rqs_fifo;
	sc_fifo<vxe::instr::generic_vpu> vpu0_instr_fifo;
	sc_fifo<vxe::instr::generic_vpu> vpu1_instr_fifo;
	// Internal registers
	uint64_t m_pgm_counter;
};
