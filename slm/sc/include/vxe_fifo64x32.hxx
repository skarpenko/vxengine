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
 * 64b-to-32b FIFO
 */

#include <cstdint>
#include <iostream>
#include <list>
#include <systemc.h>
#pragma once


// FIFO 64x32
template<unsigned DEPTH>
SC_MODULE(vxe_fifo64x32) {
	sc_in<bool> clk;
	sc_in<bool> nrst;

	sc_in<uint64_t> i_data;
	sc_in<bool> i_write;
	sc_in<sc_uint<2>> i_valid;
	sc_out<bool> o_full;

	sc_in<bool> i_read;
	sc_out<bool> o_empty;
	sc_out<uint32_t> o_data;

	SC_CTOR(vxe_fifo64x32)
		: clk("clk"), nrst("nrst"), i_data("i_data"), i_write("i_write"), i_valid("i_valid")
		, o_full("o_full"), i_read("i_read"), o_empty("o_empty"), o_data("o_data")
	{
		static_assert(DEPTH > 0, "DEPTH cannot be 0!");

		SC_THREAD(fifo_thread);
			sensitive << clk.pos();
	}

private:
	[[noreturn]] void fifo_thread()
	{
		while(true) {
			do {
				if(!nrst.read())
					m_fifo.resize(0);
				wait();
			} while(!nrst.read());

			bool ignore_wr = false;
			bool ignore_rd = false;

			// Error checking - write operation
			if(i_write.read()) {
				if(m_fifo.size() == DEPTH) {
					std::cerr << name() << ": write to full FIFO!" << std::endl;
					ignore_wr = true;
				}
				if(i_valid.read() == 0) {
					std::cerr << name() << ": i_valid signal is 0!" << std::endl;
					ignore_wr = true;
				}
			} else
				ignore_wr = true;

			// Error checking - read operation
			if(i_read.read()) {
				if(m_fifo.empty()) {
					std::cerr << name() << ": read of empty FIFO!" << std::endl;
					ignore_rd = true;
				}
			} else
				ignore_rd = true;

			// Handle write
			if(!ignore_wr) {
				data_pair d;
				uint32_t v;
				d.u64 = i_data.read();
				v = i_valid.read();
				d.v[0] = ((v & 0x1u) != 0);
				d.v[1] = ((v & 0x2u) != 0);
				m_fifo.push_front(d);
			}

			// Handle read
			if(!ignore_rd) {
				data_pair& d = m_fifo.back();
				if(d.v[0]) {
					o_data.write(d.u32[0]);
					d.v[0] = false;
				} else if(d.v[1]) {
					o_data.write(d.u32[1]);
					d.v[1] = false;
				}

				if(!d.v[0] && !d.v[1]) {
					m_fifo.pop_back();
				}
			}

			// Update state signals
			o_full.write(m_fifo.size() == DEPTH);
			o_empty.write(m_fifo.empty());
		}
	}

private:
	struct data_pair {
		bool v[2];			// Valid bits for 32-bit words
		union {
			uint64_t u64;		// 64-bit word
			uint32_t u32[2];	// 32-bit words
		};
		data_pair() { v[0] = v[1] = false; }
	};

	std::list<data_pair> m_fifo;
};
