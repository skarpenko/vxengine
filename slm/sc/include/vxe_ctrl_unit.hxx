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

	SC_HAS_PROCESS(vxe_ctrl_unit);

	vxe_ctrl_unit(::sc_core::sc_module_name name, unsigned client_id, register_set_if<uint32_t>& regs)
		: ::sc_core::sc_module(name), clk("clk"), nrst("nrst")
		, mem_fifo_in("mem_fifo_in"), mem_fifo_out("mem_fifo_out")
		, i_start("i_start"), o_busy("o_busy")
		, o_intr("o_intr")
		, m_client_id(client_id), m_regs(regs)
	{
		SC_THREAD(instr_fetch_thread);
			sensitive << clk.pos();

		SC_THREAD(instr_exec_thread);
			sensitive << clk.pos();

		SC_THREAD(intr_thread);
			sensitive << clk.pos();

		SC_METHOD(busy_logic_method);
			sensitive << ifetch_busy;
	}

private:

	/**
	 * Instruction fetch thread
	 * Sends instruction fetch requests to a memory hub
	 */
	[[noreturn]] void instr_fetch_thread()
	{
		while(1) {
			ifetch_busy.write(false);

			// Wait for start trigger
			wait();

			if(!i_start.read())
				continue;

			// Check for logic error
			if(o_busy.read())
				std::cerr << name() << ": start signal asserted while in busy state!"
					<< std::endl;

			// Start instruction requests
			ifetch_busy.write(true);

			// Form a program counter
			uint64_t pgm_lo = m_regs.get_reg(vxe::regi::REG_PGM_ADDR_LO);
			uint64_t pgm_hi = m_regs.get_reg(vxe::regi::REG_PGM_ADDR_HI);
			m_pgm_counter = (pgm_hi << 32u) | pgm_lo;

			while(!ifetch_stop.read()) {
				// Prepare request
				vxe::vxe_mem_rq rq;
				rq.set_client_id(m_client_id);
				rq.type = vxe::vxe_mem_rq::rtype::CMD_RD;
				rq.addr = m_pgm_counter;
				rq.set_ben_mask(0xFF);
				// Send request
				mem_fifo_out.write(rq);
				// Push to outstanding requests FIFO
				out_rqs_fifo.write(true);
				// Increment program counter
				m_pgm_counter += sizeof(vxe::instr::generic);
			}

			// Wait while exec thread drains input FIFO
			while(iexec_busy.read())
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

	/**** INSTRUCTIONS IMPLEMENTATION ****/

	/**
	 * NOP - No Operation
	 */
	void instr_nop(const vxe::instr::nop& nop)
	{
		wait();
	}

	/**
	 * SETACC - Set Accumulator
	 */
	void instr_setacc(const vxe::instr::setacc& setacc)
	{
		//TODO:
	}

	/**
	 * SETVL - Set Vector Length
	 */
	void instr_setvl(const vxe::instr::setvl& setvl)
	{
		//TODO:
	}

	/**
	 * SETRS - Set First Operand
	 */
	void instr_setrs(const vxe::instr::setrs& setrs)
	{
		//TODO:
	}

	/**
	 * SETRT - Set Second Operand
	 */
	void instr_setrt(const vxe::instr::setrt& setrt)
	{
		//TODO:
	}

	/**
	 * SETRD - Set Destination
	 */
	void instr_setrd(const vxe::instr::setrd& setrd)
	{
		//TODO:
	}

	/**
	 * SETEN - Set Thread Enable
	 */
	void instr_seten(const vxe::instr::seten& seten)
	{
		//TODO:
	}

	/**
	 * PROD - Vector Product
	 */
	void instr_prod(const vxe::instr::prod& prod)
	{
		//TODO:
	}

	/**
	 * STORE - Store Result
	 */
	void instr_store(const vxe::instr::store& store)
	{
		//TODO:
	}

	/**
	 * SYNC - Synchronize
	 */
	void instr_sync(const vxe::instr::sync& sync)
	{
		/* If stop of execution requested */
		if(sync.stop) {
			ifetch_stop.write(true);
			drain_instr_fifo();
		}

		/* If interrupt requested */
		if(sync.intr)
			sync_intr.write(true);
	}

	/**
	 * Instructions execution thread
	 * Receives instruction stream from a memory hub
	 */
	[[noreturn]] void instr_exec_thread()
	{
		while(1) {
			// Set to initial state
			iexec_busy.write(false);
			ifetch_stop.write(false);
			err_fetch_intr.write(false);
			err_instr_intr.write(false);

			wait();	// Wait for positive edge

			// Loop until instruction fetch stop is requested
			while(!ifetch_stop.read()) {
				vxe::vxe_mem_rq rq;
				// Read incoming instructions FIFO
				rq = mem_fifo_in.read();
				// Drop outstanding request
				out_rqs_fifo.read();

				// Switch execution unit to busy state
				iexec_busy.write(true);

				// Check for error response
				if(rq.type != vxe::vxe_mem_rq::rtype::RES_OK)
				{
					ifetch_stop.write(true);
					drain_instr_fifo();
					err_fetch_intr.write(true);
					wait();
					continue;
				}

				// Generic instruction
				vxe::instr::generic g(rq.data_u64[0]);

				// Decode and execute
				switch (g.op) {
					case vxe::instr::nop::OP:
						instr_nop(g);
						break;
					case vxe::instr::setacc::OP:
						instr_setacc(g);
						break;
					case vxe::instr::setvl::OP:
						instr_setvl(g);
						break;
					case vxe::instr::setrs::OP:
						instr_setrs(g);
						break;
					case vxe::instr::setrt::OP:
						instr_setrt(g);
						break;
					case vxe::instr::setrd::OP:
						instr_setrd(g);
						break;
					case vxe::instr::seten::OP:
						instr_seten(g);
						break;
					case vxe::instr::prod::OP:
						instr_prod(g);
						break;
					case vxe::instr::store::OP:
						instr_store(g);
						break;
					case vxe::instr::sync::OP:
						instr_sync(g);
						break;
					default:
						// Invalid instruction
						ifetch_stop.write(true);
						drain_instr_fifo();
						err_instr_intr.write(true);
						break;
				}

				wait();	// Wait for positive edge before returning to idle state
			}
		}
	}

	/**
	 * Interrupt generation logic thread
	 */
	[[noreturn]] void intr_thread()
	{
		o_intr.write(false);	// Initialize to low

		while(1) {
			wait();	// wait for clock positive edge

			o_intr.write(false);

			uint32_t new_ints = 0;		// Newly triggered raw interrupts
			uint32_t new_ints_masked;	// New active interrupts
			// Read interrupt condition signals
			bool sync = sync_intr.read();
			bool err_fetch = err_fetch_intr.read();
			bool err_instr = err_instr_intr.read();

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
	 * Busy state logic for VxEngine
	 */
	void busy_logic_method()
	{
		bool busy;

		if(ifetch_busy.read())
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
	sc_signal<bool> ifetch_busy;
	sc_signal<bool> ifetch_stop;
	sc_signal<bool> iexec_busy;
	sc_signal<bool> sync_intr;
	sc_signal<bool> err_fetch_intr;
	sc_signal<bool> err_instr_intr;
	// Internal control FIFOs
	sc_fifo<bool> out_rqs_fifo;
	// Internal registers
	uint64_t m_pgm_counter;
};
