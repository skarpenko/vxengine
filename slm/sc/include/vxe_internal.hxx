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
#pragma once


namespace vxe {

	// Memory hub clients
	namespace mhc {
		static constexpr unsigned CU	= 0;	// Control Unit
		static constexpr unsigned VPU0	= 1;	// Vector Processing Unit 0
		static constexpr unsigned VPU1	= 2;	// Vector Processing Unit 1
	} // namespace mhc


	// Memory request
	struct vxe_mem_rq {
		unsigned tid;			// Transaction Id
		uint64_t addr;			// Memory address
		bool rnw;			// Read / !Write
		bool resp;			// =true if response to request
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
			rnw = false;
			resp = false;
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
			tid &= 0xFF;
			tid |= cid << 8;
		}

		/**
		 * Get transaction client id
		 * @return client id
		 */
		unsigned get_client_id() const
		{
			return (tid >> 8) & 0xFF;
		}

		/**
		 * Set VPU thread id
		 * @param vid thread id
		 */
		void set_thread_id(unsigned vid)
		{
			vid &= 0xFF;
			tid &= 0xFF00;
			tid |= vid;
		}

		/**
		 * Get VPU thread id
		 * @return thread id
		 */
		unsigned get_thread_id() const
		{
			return tid & 0xFF;
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
		os << (rq.rnw ? "READ" : "WRITE")
			<< " "
			<< (rq.resp ? "RESP" : "REQ")
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

} // namespace vxe
