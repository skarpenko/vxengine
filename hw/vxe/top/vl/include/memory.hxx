/*
 * Copyright (c) 2020-2025 The VxEngine Project. All rights reserved.
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
 * Memory model
 */

#include <iostream>
#include <systemc.h>
#include "axi4_proto.hxx"
#pragma once


// Memory model
SC_MODULE(memory) {
	sc_in<bool> clk;
	sc_in<bool> nrst;

	// Port 0
	sc_fifo_in<axi4::areq64> s0_aw_fifo_in;
	sc_fifo_in<axi4::wreq64> s0_w_fifo_in;
	sc_fifo_out<axi4::bresp64> s0_b_fifo_out;
	sc_fifo_in<axi4::areq64> s0_ar_fifo_in;
	sc_fifo_out<axi4::rresp64> s0_r_fifo_out;

	// Port 1
	sc_fifo_in<axi4::areq64> s1_aw_fifo_in;
	sc_fifo_in<axi4::wreq64> s1_w_fifo_in;
	sc_fifo_out<axi4::bresp64> s1_b_fifo_out;
	sc_fifo_in<axi4::areq64> s1_ar_fifo_in;
	sc_fifo_out<axi4::rresp64> s1_r_fifo_out;


	SC_CTOR(memory)
		: clk("clk"), nrst("nrst")
		, s0_aw_fifo_in("s0_aw_fifo_in"), s0_w_fifo_in("s0_w_fifo_in"), s0_b_fifo_out("s0_b_fifo_out")
		, s0_ar_fifo_in("s0_ar_fifo_in"), s0_r_fifo_out("s0_r_fifo_out")
		, s1_aw_fifo_in("s1_aw_fifo_in"), s1_w_fifo_in("s1_w_fifo_in"), s1_b_fifo_out("s1_b_fifo_out")
		, s1_ar_fifo_in("s1_ar_fifo_in"), s1_r_fifo_out("s1_r_fifo_out")
	{
		SC_THREAD(s0_wr_thread);
		SC_THREAD(s0_rd_thread);
		SC_THREAD(s1_wr_thread);
		SC_THREAD(s1_rd_thread);

		mem.resize(0x1000); // default size
	}

private:
	bool rd_mem(uint64_t addr, uint64_t& data)
	{
		if(addr > (mem.size() - sizeof(uint64_t) - 1))
			return false;

		data = *reinterpret_cast<uint64_t*>(&mem[addr]);

		return true;
	}

	bool wr_mem(uint64_t addr, uint64_t strb, uint64_t data)
	{
		size_t tx_sz = sizeof(data);

		if(strb == 0xFF) {
			if(addr > (mem.size() - tx_sz - 1))
				return false;
			*reinterpret_cast<uint64_t*>(&mem[addr]) = data;
		} else if(strb == 0x0F) {
			tx_sz >>= 1;
			if(addr > (mem.size() - tx_sz - 1))
				return false;
			*reinterpret_cast<uint32_t*>(&mem[addr]) = static_cast<uint32_t>(data);
		} else if(strb == 0xF0) {
			tx_sz >>= 1;
			addr += sizeof(uint32_t);
			if(addr > (mem.size() - tx_sz - 1))
				return false;
			*reinterpret_cast<uint32_t*>(&mem[addr]) = static_cast<uint32_t>(data >> 32);
		} else {
			std::cerr << name() << ": invalid strb!" << std::endl;
		}

		return true;
	}

private:
	[[noreturn]] void s0_wr_thread()
	{
		while(true) {
			axi4::areq64 rqa = s0_aw_fifo_in.read();
			axi4::wreq64 rqd = s0_w_fifo_in.read();

			bool r = wr_mem(rqa.addr, rqd.strb, rqd.data);

			axi4::bresp64 rsp;
			rsp.id = rqa.id;
			rsp.resp = (r ? 0 : 2); // 2 - AXI SLVERR

			s0_b_fifo_out.write(rsp);
		}
	}

	[[noreturn]] void s0_rd_thread()
	{
		while(true) {
			axi4::areq64 rqa = s0_ar_fifo_in.read();

			uint64_t data = 0;
			bool r = rd_mem(rqa.addr, data);

			axi4::rresp64 rsp;
			rsp.id = rqa.id;
			rsp.resp = (r ? 0 : 2); // 2 - AXI SLVERR
			rsp.data = data;

			s0_r_fifo_out.write(rsp);
		}
	}

	[[noreturn]] void s1_wr_thread()
	{
		while(true) {
			axi4::areq64 rqa = s1_aw_fifo_in.read();
			axi4::wreq64 rqd = s1_w_fifo_in.read();

			bool r = wr_mem(rqa.addr, rqd.strb, rqd.data);

			axi4::bresp64 rsp;
			rsp.id = rqa.id;
			rsp.resp = (r ? 0 : 2); // 2 - AXI SLVERR

			s1_b_fifo_out.write(rsp);
		}
	}

	[[noreturn]] void s1_rd_thread()
	{
		while(true) {
			axi4::areq64 rqa = s1_ar_fifo_in.read();

			uint64_t data = 0;
			bool r = rd_mem(rqa.addr, data);

			axi4::rresp64 rsp;
			rsp.id = rqa.id;
			rsp.resp = (r ? 0 : 2); // 2 - AXI SLVERR
			rsp.data = data;

			s1_r_fifo_out.write(rsp);
		}
	}

public:
	// Storage
	std::vector<uint8_t> mem;
};
