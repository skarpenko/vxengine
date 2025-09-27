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
 * Fake CPU model
 */

#include <string>
#include <systemc.h>
#include "axi4_proto.hxx"
#include "fake_cpu_api.h"
#pragma once


// Fake CPU
SC_MODULE(fake_cpu) {
	static constexpr unsigned ID = 0x5;

	sc_in<bool> clk;
	sc_in<bool> nrst;
	sc_in<bool> i_intr;

	// Master I/O port
	sc_fifo_out<axi4::areq32> m_aw_fifo_out;
	sc_fifo_out<axi4::wreq32> m_w_fifo_out;
	sc_fifo_in<axi4::bresp32> m_b_fifo_in;
	sc_fifo_out<axi4::areq32> m_ar_fifo_out;
	sc_fifo_in<axi4::rresp32> m_r_fifo_in;

	SC_HAS_PROCESS(fake_cpu);

	fake_cpu(::sc_core::sc_module_name name, bool allow_stop=true);

	void set_mem(void *ptr, uint64_t size);
	void set_so_file(const std::string& so);

	struct fake_cpu_dmi get_dmi() const;
	int get_retval() const;

private:
	void cpu_thread();

private:
	bool m_allow_stop;		// If =true simulation will end when program returns
	std::string so_file;		// App. shared object
	struct fake_cpu_dmi dmi;	// Direct memory interface info
	struct fake_cpu_api cpu_api;	// CPU/App interface
	int retval;			// Program return value
};
