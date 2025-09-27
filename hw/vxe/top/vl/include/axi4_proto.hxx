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
 * AXI4 protocol common constants and data structures
 */

#include <cstdint>
#include <iosfwd>
#include <iomanip>
#pragma once


namespace axi4 {


// Read or write address phase
template<typename T>
struct areq {
	uint32_t id;
	T addr;
};

// Write data phase
template<typename T>
struct wreq {
	uint32_t strb;
	T data;
};

// Write response phase
struct bresp {
	uint32_t id;
	uint32_t resp;
};

// Read data phase
template<typename T>
struct rresp {
	uint32_t id;
	uint32_t resp;
	T data;
};


typedef areq<uint32_t>	areq32;
typedef wreq<uint32_t>	wreq32;
typedef bresp		bresp32;
typedef rresp<uint32_t>	rresp32;

typedef areq<uint64_t>	areq64;
typedef wreq<uint64_t>	wreq64;
typedef bresp		bresp64;
typedef rresp<uint64_t>	rresp64;


template<typename T>
inline std::ostream& operator<<(std::ostream& os, const areq<T>& v)
{
	std::ios state(nullptr);
	state.copyfmt(os);	// Save current stream state

	// Send data to stream
	os << "AREQ: "
		<< "id="
		<< std::setw(2) << std::setfill('0') << std::hex
		<< v.id
		<< ", addr= "
		<< std::setw(2*sizeof(T)) << std::setfill('0') << std::hex
		<< v.addr;

	// Restore previous stream state
	os.copyfmt(state);

	return os;
}

template<typename T>
inline std::ostream& operator<<(std::ostream& os, const wreq<T>& v)
{
	std::ios state(nullptr);
	state.copyfmt(os);	// Save current stream state

	// Send data to stream
	os << "WREQ: "
		<< "strb="
		<< std::setw(2) << std::setfill('0') << std::hex
		<< v.strb
		<< ", data= "
		<< std::setw(2*sizeof(T)) << std::setfill('0') << std::hex
		<< v.data;

	// Restore previous stream state
	os.copyfmt(state);

	return os;
}

inline std::ostream& operator<<(std::ostream& os, const bresp& v)
{
	std::ios state(nullptr);
	state.copyfmt(os);	// Save current stream state

	// Send data to stream
	os << "BRESP: "
		<< "id="
		<< std::setw(2) << std::setfill('0') << std::hex
		<< v.id
		<< ", resp= "
		<< std::setw(2) << std::setfill('0') << std::hex
		<< v.resp
		<< " (" << (v.resp == 0 ? "OK" : "NOK") << ")";

	// Restore previous stream state
	os.copyfmt(state);

	return os;
}

template<typename T>
inline std::ostream& operator<<(std::ostream& os, const rresp<T>& v)
{
	std::ios state(nullptr);
	state.copyfmt(os);	// Save current stream state

	// Send data to stream
	os << "RRESP: "
		<< "id="
		<< std::setw(2) << std::setfill('0') << std::hex
		<< v.id
		<< ", data= "
		<< std::setw(2*sizeof(T)) << std::setfill('0') << std::hex
		<< v.data;

	// Restore previous stream state
	os.copyfmt(state);

	return os;
}


} // namespace axi4
