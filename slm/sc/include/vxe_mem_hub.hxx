/*
 * Copyright (c) 2020-2021 The VxEngine Project. All rights reserved.
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
 * VxEngine Memory Hub block routes memory requests from functional units
 * to external master ports.
 */

#include <iostream>
#include <systemc.h>
#include "register_set.hxx"
#include "vxe_common.hxx"
#include "vxe_internal.hxx"


// VxEngine Memory Hub
SC_MODULE(vxe_mem_hub) {
	sc_in<bool> clk;
	sc_in<bool> nrst;

	// Control Unit memory interface
	sc_fifo_in<vxe::vxe_mem_rq> cu_fifo_in;
	sc_fifo_out<vxe::vxe_mem_rq> cu_fifo_out;

	// Vector Processing Unit 0 memory interface
	sc_fifo_in<vxe::vxe_mem_rq> vpu0_fifo_in;
	sc_fifo_out<vxe::vxe_mem_rq> vpu0_fifo_out;

	// Vector Processing Unit 1 memory interface
	sc_fifo_in<vxe::vxe_mem_rq> vpu1_fifo_in;
	sc_fifo_out<vxe::vxe_mem_rq> vpu1_fifo_out;

	// External master interface 0
	sc_fifo_in<vxe::vxe_mem_rq> master0_fifo_in;
	sc_fifo_out<vxe::vxe_mem_rq> master0_fifo_out;

	// External master interface 1
	sc_fifo_in<vxe::vxe_mem_rq> master1_fifo_in;
	sc_fifo_out<vxe::vxe_mem_rq> master1_fifo_out;

	SC_HAS_PROCESS(vxe_mem_hub);

	vxe_mem_hub(::sc_core::sc_module_name name, register_set_if<uint32_t>& regs)
		: ::sc_core::sc_module(name), clk("clk"), nrst("nrst")
		, cu_fifo_in("cu_fifo_in"), cu_fifo_out("cu_fifo_out")
		, vpu0_fifo_in("vpu0_fifo_in"), vpu0_fifo_out("vpu0_fifo_out")
		, vpu1_fifo_in("vpu1_fifo_in"), vpu1_fifo_out("vpu1_fifo_out")
		, master0_fifo_in("master0_fifo_in"), master0_fifo_out("master0_fifo_out")
		, master1_fifo_in("master1_fifo_in"), master1_fifo_out("master1_fifo_out")
		, m_regs(regs)
	{
		SC_THREAD(cu_fifo_in_thread);
			sensitive << clk.pos();

		SC_THREAD(cu_fifo_out_thread);
			sensitive << clk.pos();

		SC_THREAD(vpu0_fifo_in_thread);
			sensitive << clk.pos();

		SC_THREAD(vpu0_fifo_out_thread);
			sensitive << clk.pos();

		SC_THREAD(vpu1_fifo_in_thread);
			sensitive << clk.pos();

		SC_THREAD(vpu1_fifo_out_thread);
			sensitive << clk.pos();

		SC_THREAD(master0_fifo_in_thread);
			sensitive << clk.pos();

		SC_THREAD(master0_fifo_out_thread);
			sensitive << clk.pos();

		SC_THREAD(master1_fifo_in_thread);
			sensitive << clk.pos();

		SC_THREAD(master1_fifo_out_thread);
			sensitive << clk.pos();
	}

private:
	enum class dest_port { M0, M1 };	// Master 0 or Master 1

	// Returns destination master port for a given request
	dest_port pick_port(const vxe::vxe_mem_rq& rq)
	{
		// Master for CU requests is selected through REG_CTRL register
		if(rq.get_client_id() == vxe::mhc::CU)
			return m_regs.get_reg(vxe::regi::REG_CTRL) & vxe::bits::REG_CTRL::CU_MAS_SEL_MASK
				? dest_port::M1 : dest_port::M0;

		// VPU loads depend on argument type, stores depend on VPU number
		if(rq.req == vxe::vxe_mem_rq::rqtype::REQ_RD)
			return rq.get_thread_arg() == 0 ? dest_port::M0 : dest_port::M1;
		else
			return rq.get_client_id() == vxe::mhc::VPU0 ? dest_port::M0 : dest_port::M1;
	}

private:
	[[noreturn]] void cu_fifo_in_thread()
	{
		while(true) {
			vxe::vxe_mem_rq rq = cu_fifo_in.read();
			switch(pick_port(rq)) {
				case dest_port::M0:
					fifo_cu_to_m0.write(rq);
					break;
				case dest_port::M1:
					fifo_cu_to_m1.write(rq);
					break;
				default:
					std::cerr << name()
						<< ": cu_fifo_in_thread: wrong destination port!"
						<< std::endl;
					break;
			}
		}
	}

	[[noreturn]] void cu_fifo_out_thread()
	{
		while(true) {
			vxe::vxe_mem_rq rq;

			wait();
			if(fifo_m0_to_cu.nb_read(rq))
				cu_fifo_out.write(rq);

			wait();
			if(fifo_m1_to_cu.nb_read(rq))
				cu_fifo_out.write(rq);
		}
	}

	[[noreturn]] void vpu0_fifo_in_thread()
	{
		while(true) {
			vxe::vxe_mem_rq rq = vpu0_fifo_in.read();
			switch(pick_port(rq)) {
				case dest_port::M0:
					fifo_vpu0_to_m0.write(rq);
					break;
				case dest_port::M1:
					fifo_vpu0_to_m1.write(rq);
					break;
				default:
					std::cerr << name()
						<< ": vpu0_fifo_in_thread: wrong destination port!"
						<< std::endl;
					break;
			}
		}
	}

	[[noreturn]] void vpu0_fifo_out_thread()
	{
		while(true) {
			vxe::vxe_mem_rq rq;

			wait();
			if(fifo_m0_to_vpu0.nb_read(rq))
				vpu0_fifo_out.write(rq);

			wait();
			if(fifo_m1_to_vpu0.nb_read(rq))
				vpu0_fifo_out.write(rq);
		}
	}

	[[noreturn]] void vpu1_fifo_in_thread()
	{
		while(true) {
			vxe::vxe_mem_rq rq = vpu1_fifo_in.read();
			switch(pick_port(rq)) {
				case dest_port::M0:
					fifo_vpu1_to_m0.write(rq);
					break;
				case dest_port::M1:
					fifo_vpu1_to_m1.write(rq);
					break;
				default:
					std::cerr << name()
						<< ": vpu1_fifo_in_thread: wrong destination port!"
						<< std::endl;
					break;
			}
		}
	}

	[[noreturn]] void vpu1_fifo_out_thread()
	{
		while(true) {
			vxe::vxe_mem_rq rq;

			wait();
			if(fifo_m0_to_vpu1.nb_read(rq))
				vpu1_fifo_out.write(rq);

			wait();
			if(fifo_m1_to_vpu1.nb_read(rq))
				vpu1_fifo_out.write(rq);
		}
	}

	[[noreturn]] void master0_fifo_in_thread()
	{
		while(true) {
			vxe::vxe_mem_rq rq = master0_fifo_in.read();
			switch(rq.get_client_id()) {
				case vxe::mhc::CU:
					fifo_m0_to_cu.write(rq);
					break;
				case vxe::mhc::VPU0:
					fifo_m0_to_vpu0.write(rq);
					break;
				case vxe::mhc::VPU1:
					fifo_m0_to_vpu1.write(rq);
					break;
				default:
					std::cerr << name()
						<< ": master0_fifo_in_thread: wrong client id!"
						<< std::endl;
					break;
			}
		}
	}

	[[noreturn]] void master0_fifo_out_thread()
	{
		while(true) {
			vxe::vxe_mem_rq rq;

			wait();
			if(fifo_cu_to_m0.nb_read(rq))
				master0_fifo_out.write(rq);

			wait();
			if(fifo_vpu0_to_m0.nb_read(rq))
				master0_fifo_out.write(rq);

			wait();
			if(fifo_vpu1_to_m0.nb_read(rq))
				master0_fifo_out.write(rq);
		}
	}

	[[noreturn]] void master1_fifo_in_thread()
	{
		while(true) {
			vxe::vxe_mem_rq rq = master1_fifo_in.read();
			switch(rq.get_client_id()) {
				case vxe::mhc::CU:
					fifo_m1_to_cu.write(rq);
					break;
				case vxe::mhc::VPU0:
					fifo_m1_to_vpu0.write(rq);
					break;
				case vxe::mhc::VPU1:
					fifo_m1_to_vpu1.write(rq);
					break;
				default:
					std::cerr << name()
						<< ": master1_fifo_in_thread: wrong client id!"
						<< std::endl;
					break;
			}
		}
	}

	[[noreturn]] void master1_fifo_out_thread()
	{
		while(true) {
			vxe::vxe_mem_rq rq;

			wait();
			if(fifo_cu_to_m1.nb_read(rq))
				master1_fifo_out.write(rq);

			wait();
			if(fifo_vpu0_to_m1.nb_read(rq))
				master1_fifo_out.write(rq);

			wait();
			if(fifo_vpu1_to_m1.nb_read(rq))
				master1_fifo_out.write(rq);
		}
	}

private:
	// VxE register file
	register_set_if<uint32_t>& m_regs;
	// Upstream traffic FIFOs
	sc_fifo<vxe::vxe_mem_rq> fifo_cu_to_m0;
	sc_fifo<vxe::vxe_mem_rq> fifo_cu_to_m1;
	sc_fifo<vxe::vxe_mem_rq> fifo_vpu0_to_m0;
	sc_fifo<vxe::vxe_mem_rq> fifo_vpu0_to_m1;
	sc_fifo<vxe::vxe_mem_rq> fifo_vpu1_to_m0;
	sc_fifo<vxe::vxe_mem_rq> fifo_vpu1_to_m1;
	// Downstream traffic FIFOs
	sc_fifo<vxe::vxe_mem_rq> fifo_m0_to_cu;
	sc_fifo<vxe::vxe_mem_rq> fifo_m0_to_vpu0;
	sc_fifo<vxe::vxe_mem_rq> fifo_m0_to_vpu1;
	sc_fifo<vxe::vxe_mem_rq> fifo_m1_to_cu;
	sc_fifo<vxe::vxe_mem_rq> fifo_m1_to_vpu0;
	sc_fifo<vxe::vxe_mem_rq> fifo_m1_to_vpu1;
};
