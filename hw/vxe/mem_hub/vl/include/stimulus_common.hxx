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
 * Stimulus common
 */

#include <cstdint>
#include <systemc.h>
#pragma once


namespace stimul {

	// Memory hub clients
	namespace mhc {
		static constexpr unsigned CU	= 0;	// Control Unit
		static constexpr unsigned VPU0	= 1;	// Vector Processing Unit 0
		static constexpr unsigned VPU1	= 2;	// Vector Processing Unit 1
	} // namespace mhc

	// Request address
	struct req_addr {
		uint8_t		txnid;
		bool		rnw;
		uint64_t	addr;

		uint64_t pack(void) const
		{
			uint64_t t = txnid;
			uint64_t r = (rnw ? 1 : 0);
			uint64_t a = addr;
			t &= 0x3F;
			t <<= 38;
			r <<= 37;
			a >>= 3;
			a &= 0xFFFFFFFFF;
			return t | r | a;
		}
	};

	// Stream insertion operator for req_addr
	inline std::ostream& operator<<(std::ostream& os, const req_addr& rqa)
	{
		std::ios state(nullptr);
		state.copyfmt(os);	// Save current stream state

		// Send data to stream
		os << "TXNID="
			<< std::setw(2) << std::setfill('0') << std::hex
			<< rqa.txnid
			<< " RNW="
			<< std::setw(1)
			<< rqa.rnw
			<< " ADDR="
			<< std::setw(16) << std::setfill('0') << std::hex
			<< rqa.addr;

		// Restore previous stream state
		os.copyfmt(state);

		return os;
	}

	// Request data
	struct req_data {
		uint64_t	data;
		uint8_t		ben;

		sc_bv<72> pack(void) const
		{
			sc_bv<72> r = ben;
			r <<= 64;
			r |= data;
			return r;
		}
	};

	// Stream insertion operator for req_data
	inline std::ostream& operator<<(std::ostream& os, const req_data& rqd)
	{
		std::ios state(nullptr);
		state.copyfmt(os);	// Save current stream state

		// Send data to stream
		os << "DATA="
			<< std::setw(16) << std::setfill('0') << std::hex
			<< rqd.data
			<< " BEN="
			<< std::setw(2) << std::setfill('0') << std::hex
			<< rqd.ben;

		// Restore previous stream state
		os.copyfmt(state);

		return os;
	}

	// Response status
	struct res_stat {
		uint8_t		txnid;
		bool		rnw;
		uint8_t		err;

		void unpack(uint32_t v)
		{
			err = v & 3;
			rnw = (v & (1 << 2)) != 0;
			txnid = v >> 3;
			txnid &= 0x3F;
		}
	};

	// Stream insertion operator for res_stat
	inline std::ostream& operator<<(std::ostream& os, const res_stat& rss)
	{
		std::ios state(nullptr);
		state.copyfmt(os);	// Save current stream state

		// Send data to stream
		os << "TXNID="
			<< std::setw(2) << std::setfill('0') << std::hex
			<< rss.txnid
			<< " RNW="
			<< std::setw(1)
			<< rss.rnw
			<< " ERR="
			<< std::setw(2) << std::setfill('0') << std::hex
			<< rss.err;

		// Restore previous stream state
		os.copyfmt(state);

		return os;
	}

	// Response data
	struct res_data {
		uint64_t	data;

		void unpack(uint64_t v)
		{
			data = v;
		}
	};

	// Stream insertion operator for res_data
	inline std::ostream& operator<<(std::ostream& os, const res_data& rsd)
	{
		std::ios state(nullptr);
		state.copyfmt(os);	// Save current stream state

		// Send data to stream
		os << "DATA="
			<< std::setw(16) << std::setfill('0') << std::hex
			<< rsd.data;

		// Restore previous stream state
		os.copyfmt(state);

		return os;
	}

	/**
	 * Make transaction Id
	 * @param client_id Client Id (CU, VPU0, VPU1)
	 * @param thread_id Thread Id (VPU only)
	 * @param arg Argument type (VPU only)
	 * @return
	 */
	uint8_t mktxnid(uint8_t client_id, uint8_t thread_id, uint8_t arg)
	{
		client_id &= 3;
		thread_id &= 7;
		arg &= 1;
		return (client_id << 4) | (thread_id << 1) | arg;
	}

} // namespace stimul
