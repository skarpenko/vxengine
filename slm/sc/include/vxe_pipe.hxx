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
 * Simple N-stage pipe
 */

#include <list>
#include <systemc.h>
#pragma once


// Pipe template
template<typename T, unsigned NSTAGES>
SC_MODULE(vxe_pipe) {
	sc_in<bool> clk;
	sc_in<bool> nrst;

	sc_in<T> in;
	sc_out<T> out;

	SC_CTOR(vxe_pipe)
		: clk("clk"), nrst("nrst")
	{
		static_assert(NSTAGES > 0, "NSTAGES cannot be 0!");

		SC_THREAD(pipe_thread);
			sensitive << clk.pos();

		m_pipe.resize(NSTAGES);
	}

private:
	[[noreturn]] void pipe_thread()
	{
		while(true) {
			do {
				wait();
			} while(!nrst.read());

			// Advance pipe
			m_pipe.pop_back();
			m_pipe.push_front(in.read());
			out.write(m_pipe.back());
		}
	}

private:
	std::list<T> m_pipe;
};
