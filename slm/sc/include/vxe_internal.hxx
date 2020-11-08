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
 * VxEngine internal constants and data structures
 */

#include <cstdint>
#include <iosfwd>
#include <iomanip>
#include <initializer_list>
#include <type_traits>
#pragma once


namespace vxe {

	// Memory hub clients
	namespace mhc {
		static constexpr unsigned CU	= 0;	// Control Unit
		static constexpr unsigned VPU0	= 1;	// Vector Processing Unit 0
		static constexpr unsigned VPU1	= 2;	// Vector Processing Unit 1
	} // namespace mhc


	// Vector processing unit commands
	namespace vpc {
		static constexpr unsigned SETACC	= 0x08;	// Set accumulator
		static constexpr unsigned SETVL		= 0x09;	// Set vector length
		static constexpr unsigned SETRS		= 0x0a;	// Set Rs address
		static constexpr unsigned SETRT		= 0x0b;	// Set Rt address
		static constexpr unsigned SETRD		= 0x0c;	// Set Rd address
		static constexpr unsigned SETEN		= 0x0d;	// Set thread enable
		static constexpr unsigned PROD		= 0x10;	// Compute product
		static constexpr unsigned STORE		= 0x14;	// Store result to Rd address
	} // namespace vpc


	// Memory request
	struct vxe_mem_rq {
		enum class rqtype {
			REQ_RD,	// Read request
			REQ_WR	// Write request
		};
		enum class rstype {
			RES_NA,	// Not available
			RES_OK,	// OK response to request
			RES_AE,	// Address error response
			RES_DE	// Data error response
		};
		uint32_t tid;			// Transaction Id
		uint64_t addr;			// Memory address
		rqtype req;			// Request type
		rstype res;			// Response type
		union {
			// Read or write data
			uint8_t data_u8[8];
			uint16_t data_u16[4];
			uint32_t data_u32[2];
			uint64_t data_u64[1];
		};
		bool ben[8];			// Byte enables

		// Constructor
		vxe_mem_rq() {
			tid = 0;
			addr = 0;
			req = rqtype::REQ_RD;
			res = rstype::RES_NA;
			data_u64[0] = 0;
			for(bool& b : ben) b = false;
		}

		/**
		 * Set transaction client id
		 * @param cid client id
		 */
		void set_client_id(unsigned cid)
		{
			cid &= 0xFF;
			tid &= 0xFFFFFF00;
			tid |= cid;
		}

		/**
		 * Get transaction client id
		 * @return client id
		 */
		unsigned get_client_id() const
		{
			return tid & 0xFF;
		}

		/**
		 * Set VPU thread id
		 * @param vid thread id
		 */
		void set_thread_id(unsigned vid)
		{
			vid &= 0xFF;
			tid &= 0xFFFF00FF;
			tid |= vid << 8;
		}

		/**
		 * Get VPU thread id
		 * @return thread id
		 */
		unsigned get_thread_id() const
		{
			return (tid >> 8) & 0xFF;
		}

		/**
		 * Set optional VPU thread argument
		 * @param arg argument value
		 */
		void set_thread_arg(unsigned arg)
		{
			arg &= 0xFF;
			tid &= 0xFF00FFFF;
			tid |= arg << 16;
		}

		/**
		 * Get optional VPU thread argument
		 * @return argument value
		 */
		unsigned get_thread_arg() const
		{
			return (tid >> 16) & 0xFF;
		}

		/**
		 * Set byte enables
		 * @param mask bit mask
		 */
		void set_ben_mask(unsigned mask)
		{
			for(bool& b : ben) {
				b = ((mask & 1u) == 1);
				mask >>= 1u;
			}
		}

		/**
		 * Get byte enables
		 * @return bit mask
		 */
		unsigned get_ben_mask() const
		{
			unsigned mask = 0;
			for(const bool& b : ben) {
				mask |= (b ? 1u : 0u);
				mask <<= 1u;
			}
			return mask;
		}
	};

	// Stream insertion operator for vxe_mem_rq
	inline std::ostream& operator<<(std::ostream& os, const vxe_mem_rq& rq)
	{
		std::ios state(nullptr);
		state.copyfmt(os);	// Save current stream state

		// Prepare byte enables mask
		unsigned ben = 0;
		for(int i = 0; i < 8; ++i)
			ben |= (rq.ben[i] << i);

		// Send transaction data to stream
		os << (rq.res != vxe_mem_rq::rstype::RES_NA ? "RESP" :
				rq.req == vxe_mem_rq::rqtype::REQ_WR ? "WRITE" : "READ")
			<< (rq.res == vxe_mem_rq::rstype::RES_OK ? " OKAY" :
				rq.res == vxe_mem_rq::rstype::RES_AE ? " AERR" :
				rq.res == vxe_mem_rq::rstype::RES_DE ? " DERR" : "")
			<< " tid="
			<< std::setw(4) << std::setfill('0') << std::hex
			<< rq.tid
			<< " addr="
			<< std::setw(16) << std::setfill('0') << std::hex
			<< rq.addr
			<< " data="
			<< std::setw(16) << std::setfill('0') << std::hex
			<< rq.data_u64[0]
			<< " ben="
			<< std::setw(2) << std::setfill('0') << std::hex
			<< ben;

		// Restore previous stream state
		os.copyfmt(state);

		return os;
	}

	// Word enable
	template<size_t NWORDS>
	struct word_enable {
		bool we[NWORDS];

		// Constructors
		word_enable() { for(bool& w : we) w = false; }
		word_enable(std::initializer_list<bool> l) {
			bool *i1;
			std::initializer_list<bool>::const_iterator i2;
			for(i1 = &we[0], i2 = l.begin(); i1 != &we[NWORDS] && i2 != l.end(); ++i1, ++i2)
				*i1 = *i2;
		}

		/**
		 * Pack word enables into T type
		 * @tparam T type (must be integral type wider than NWORDS bits)
		 * @return packed word enables
		 */
		template<typename T>
		T bits() const {
			static_assert(std::is_integral<T>::value, "T must be an integral type.");
			static_assert(std::numeric_limits<T>::digits >= NWORDS, "T must be wider than NWORDS bits.");
			T m = 0;
			for(size_t i = 0; i < NWORDS; ++i) {
				m |= T(we[i] << i);
			}
			return m;
		}
	};

	// Stream insertion operator for word_enable
	template<size_t NWORDS>
	inline std::ostream& operator<<(std::ostream& os, const word_enable<NWORDS>& we)
	{
		os << "[";
		for(size_t i = 0; i < NWORDS; ++i) {
			os << we.we[i];
			if(i < NWORDS - 1)
				os << ", ";
		}
		os << "]";
		return os;
	}

} // namespace vxe
