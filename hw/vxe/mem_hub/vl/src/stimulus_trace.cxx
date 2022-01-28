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
 * Stimulus trace generation
 */

#include <iomanip>
#include <stimulus_trace.hxx>


std::ostream& stimul::operator<<(std::ostream& os, const trace_req& a)
{
	std::ios state(nullptr);
	state.copyfmt(os);	// Save current stream state

	// Send data to stream
	os << "RnW="
		<< a.rnw
		<< " Addr="
		<< std::setw(16) << std::setfill('0') << std::hex
		<< a.addr
		<< " Data="
		<< std::setw(16) << std::setfill('0') << std::hex
		<< a.data
		<< " BEn="
		<< std::setw(2) << std::setfill('0') << std::hex
		<< static_cast<unsigned>(a.ben)
		<< " TId="
		<< std::setw(2) << std::setfill('0') << std::hex
		<< static_cast<unsigned>(a.tid)
		<< " Arg="
		<< a.arg;

	// Restore previous stream state
	os.copyfmt(state);

	return os;
}

bool stimul::operator==(const trace_res& a, const trace_res& b)
{
	return (a.rnw == b.rnw)
		&& (a.err == b.err)
		&& (a.data == b.data)
		&& (a.tid == b.tid)
		&& (a.arg == b.arg);
}

bool stimul::operator!=(const trace_res& a, const trace_res& b)
{
	return (a.rnw != b.rnw)
		|| (a.err != b.err)
		|| (a.data != b.data)
		|| (a.tid != b.tid)
		|| (a.arg != b.arg);
}

std::ostream& stimul::operator<<(std::ostream& os, const trace_res& a)
{
	std::ios state(nullptr);
	state.copyfmt(os);	// Save current stream state

	// Send data to stream
	os << "RnW="
		<< a.rnw
		<< " Err="
		<< std::setw(2) << std::setfill('0') << std::hex
		<< static_cast<unsigned>(a.err)
		<< " Data="
		<< std::setw(16) << std::setfill('0') << std::hex
	 	<< a.data
		<< " TId="
		<< std::setw(2) << std::setfill('0') << std::hex
		<< static_cast<unsigned>(a.tid)
		<< " Arg="
		<< a.arg;

	// Restore previous stream state
	os.copyfmt(state);

	return os;
}

stimul::linear_rd_trace::linear_rd_trace(const std::string& name, uint64_t start_addr, uint64_t len8,
	uint64_t initial_data, uint64_t data_inc, uint8_t tid, bool arg)
	: trace_gen_base(name), m_addr_gen(start_addr), m_data_gen(initial_data, data_inc)
	, m_num_addr(len8), m_num_data(len8), m_tid(tid), m_arg(arg)
{
}

stimul::trace_req* stimul::linear_rd_trace::next_req()
{
	static trace_req req;

	if(m_num_addr == 0)
		return nullptr;

	--m_num_addr;

	req.rnw = true;
	req.tid = m_tid;
	req.arg = m_arg;
	req.addr = m_addr_gen.next_addr();
	req.data = 0; // not used
	req.ben = 0xff;

	return &req;
}

stimul::trace_res* stimul::linear_rd_trace::next_res()
{
	static trace_res res;

	if(m_num_data == 0)
		return nullptr;

	--m_num_data;

	res.rnw = true;
	res.err = 0;
	res.data = m_data_gen.next_data();

	return &res;
}


stimul::linear_wr_trace::linear_wr_trace(const std::string& name, uint64_t start_addr, uint64_t len8,
	uint64_t initial_data, uint64_t data_inc, uint8_t ben, uint8_t tid, bool arg)
	: trace_gen_base(name), m_addr_gen(start_addr), m_data_gen(initial_data, data_inc)
	, m_ben(ben), m_num_addr(len8), m_num_resp(len8), m_tid(tid), m_arg(arg)
{
}

stimul::trace_req* stimul::linear_wr_trace::linear_wr_trace::next_req()
{
	static trace_req req;

	if(m_num_addr == 0)
		return nullptr;

	--m_num_addr;

	req.rnw = false;
	req.tid = m_tid;
	req.arg = m_arg;
	req.addr = m_addr_gen.next_addr();
	req.data = m_data_gen.next_data();
	req.ben = m_ben;

	return &req;
}

stimul::trace_res* stimul::linear_wr_trace::linear_wr_trace::next_res()
{
	static trace_res res;

	if(m_num_resp == 0)
		return nullptr;

	--m_num_resp;

	res.rnw = false;
	res.tid = m_tid;
	res.arg = m_arg;
	res.err = 0;
	res.data = 0;

	return &res;
}
