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
 * AXI4 internal data structures
 */

#include <cstdint>
#include <iosfwd>
#include <iomanip>
#include <systemc.h>
#pragma once


namespace axi4 {

	// AXI responses
	namespace resp {
		static constexpr unsigned OKAY		= 0;
		static constexpr unsigned EXOKAY	= 1;
		static constexpr unsigned SLVERR	= 2;
		static constexpr unsigned DECERR	= 3;
	}

	// Write address
	struct awaddr {
		uint32_t	awid;
		uint64_t	awaddr;
		uint32_t	awlen;
		uint32_t	awsize;
		uint32_t	awburst;
		bool		awlock;
		uint32_t	awcache;
		uint32_t	awprot;
	};

	// Stream insertion operator for awaddr
	inline std::ostream& operator<<(std::ostream& os, const awaddr& a)
	{
		std::ios state(nullptr);
		state.copyfmt(os);	// Save current stream state

		// Send data to stream
		os << "AWID="
			<< std::setw(2) << std::setfill('0') << std::hex
			<< a.awid
			<< " AWADDR="
			<< std::setw(16) << std::setfill('0') << std::hex
			<< a.awaddr;

		// Restore previous stream state
		os.copyfmt(state);

		return os;
	}

	// Write data
	struct wdata {
		uint64_t wdata;
		uint32_t wstrb;
		bool wlast;
	};

	// Stream insertion operator for wdata
	inline std::ostream& operator<<(std::ostream& os, const wdata& d)
	{
		std::ios state(nullptr);
		state.copyfmt(os);	// Save current stream state

		// Send data to stream
		os << "WDATA="
			<< std::setw(16) << std::setfill('0') << std::hex
			<< d.wdata
			<< " WSTRB="
			<< std::setw(2) << std::setfill('0') << std::hex
			<< d.wstrb;

		// Restore previous stream state
		os.copyfmt(state);

		return os;
	}

	// Write response
	struct bresp {
		uint32_t bid;
		uint32_t bresp;
	};

	// Stream insertion operator for bresp
	inline std::ostream& operator<<(std::ostream& os, const bresp& r)
	{
		std::ios state(nullptr);
		state.copyfmt(os);	// Save current stream state

		// Send data to stream
		os << "BID="
			<< std::setw(2) << std::setfill('0') << std::hex
			<< r.bid
			<< " BRESP="
			<< std::setw(2) << std::setfill('0') << std::hex
			<< r.bresp;

		// Restore previous stream state
		os.copyfmt(state);

		return os;
	}

	// Read address
	struct araddr {
		uint32_t	arid;
		uint64_t	araddr;
		uint32_t	arlen;
		uint32_t	arsize;
		uint32_t	arburst;
		bool		arlock;
		uint32_t	arcache;
		uint32_t	arprot;
	};

	// Stream insertion operator for araddr
	inline std::ostream& operator<<(std::ostream& os, const araddr& a)
	{
		std::ios state(nullptr);
		state.copyfmt(os);	// Save current stream state

		// Send data to stream
		os << "ARID="
			<< std::setw(2) << std::setfill('0') << std::hex
			<< a.arid
			<< " ARADDR="
			<< std::setw(16) << std::setfill('0') << std::hex
			<< a.araddr;

		// Restore previous stream state
		os.copyfmt(state);

		return os;
	}

	// Read response
	struct rresp {
		uint32_t rid;
		uint64_t rdata;
		uint32_t rresp;
		bool rlast;
	};

	// Stream insertion operator for rresp
	inline std::ostream& operator<<(std::ostream& os, const rresp& r)
	{
		std::ios state(nullptr);
		state.copyfmt(os);	// Save current stream state

		// Send data to stream
		os << "RID="
			<< std::setw(2) << std::setfill('0') << std::hex
			<< r.rid
			<< " RDATA="
			<< std::setw(16) << std::setfill('0') << std::hex
			<< r.rdata
			<< " RRESP="
			<< std::setw(2) << std::setfill('0') << std::hex
			<< r.rresp;

		// Restore previous stream state
		os.copyfmt(state);

		return os;
	}

} // namespace axi4
