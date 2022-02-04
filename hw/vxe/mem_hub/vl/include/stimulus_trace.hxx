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

#include <cstdint>
#include <string>
#include <iosfwd>
#include "stimulus_patgen.hxx"
#pragma once


namespace stimul {

	// Request trace entry
	struct trace_req {
		bool		rnw;	// Read or write request
		uint64_t	addr;	// Address
		uint64_t	data;	// Data for write requests
		uint8_t		ben;	// Byte enables for write requests
		uint8_t		tid;	// Thread Id (VPU only)
		bool		arg;	// Argument type (VPU only)

		trace_req() {}
		trace_req(bool _rnw, uint64_t _addr, uint8_t _ben = 0, uint64_t _data = 0,
			uint8_t _tid = 0, bool _arg = false)
		{
			rnw = _rnw;
			addr = _addr;
			ben = (!rnw ? _ben : 0);
			data = (!rnw ? _data : 0);
			tid = _tid;
			arg = _arg;
		}
	};

	// Stream insertion operator for trace_req
	std::ostream& operator<<(std::ostream& os, const trace_req& a);

	// Response trace entry
	struct trace_res {
		bool		rnw;	// Read or write response
		uint8_t		err;	// Error status
		uint64_t	data;	// Data for read responses
		uint8_t		tid;	// Thread Id (VPU only)
		bool		arg;	// Argument type (VPU only)

		trace_res() {}
		trace_res(bool _rnw, uint8_t _err, uint64_t _data = 0, uint8_t _tid = 0, bool _arg = false)
		{
			rnw = _rnw;
			err = _err;
			data = (rnw ? _data : 0);
			tid = _tid;
			arg = _arg;
		}
	};

	// Comparison operator for trace_res results
	bool operator==(const trace_res& a, const trace_res& b);
	bool operator!=(const trace_res& a, const trace_res& b);
	// Stream insertion operator for trace_res
	std::ostream& operator<<(std::ostream& os, const trace_res& a);

	// Trace generator base class
	class trace_gen_base {
		const std::string m_name;
		bool m_failed;
	public:
		explicit trace_gen_base(const std::string& name) : m_name(name), m_failed(false) {}
		virtual ~trace_gen_base() = default;

		// Trace name
		std::string name() const { return m_name; }

		// Trace generation finished
		virtual bool done() const = 0;

		// Set failed trace flag
		void set_failed(bool v) { m_failed = v; }

		// Get failed trace flag
		bool get_failed() const { return m_failed; }

		// Get next request
		virtual trace_req* next_req() = 0;
		// Mark a request as sent
		virtual void req_sent(trace_req *rq) = 0;
		// Get next reference response
		virtual trace_res* next_res() = 0;
		// Mark a response as verified
		virtual void res_vrfd(trace_res *r) = 0;
	};

	// Linear read trace generator
	class linear_rd_trace: public trace_gen_base {
		patgen::linear_addr_gen m_addr_gen;
		patgen::inc_data_gen m_data_gen;
		uint64_t m_num_addr;
		uint64_t m_num_data;
		uint64_t m_num_verif;
		uint8_t m_tid;
		bool m_arg;
		trace_req m_req;
		trace_res m_res;
	public:
		/**
		 * Read memory trace
		 * @param name Trace name
		 * @param start_addr Startin address
		 * @param len8 Length of a read (in 64-bit words)
		 * @param initial_data Initial data pattern
		 * @param data_inc Data pattern increment
		 * @param tid Thread Id (VPU only)
		 * @param arg Argument (VPU only)
		 */
		linear_rd_trace(const std::string& name, uint64_t start_addr, uint64_t len8, uint64_t initial_data,
				uint64_t data_inc = 1, uint8_t tid = 0, bool arg = false);

		bool done() const override { return m_num_verif == 0; }

		trace_req* next_req() override;
		void req_sent(trace_req *rq) override;
		trace_res* next_res() override;
		void res_vrfd(trace_res *r) override;
	};

	// Linear write trace generator
	class linear_wr_trace: public trace_gen_base {
		patgen::linear_addr_gen m_addr_gen;
		patgen::inc_data_gen m_data_gen;
		uint8_t m_ben;
		uint64_t m_num_addr;
		uint64_t m_num_resp;
		uint64_t m_num_verif;
		uint8_t m_tid;
		bool m_arg;
		trace_req m_req;
		trace_res m_res;
	public:
		/**
		 * Write memory trace
		 * @param name Trace name
		 * @param start_addr Startin address
		 * @param len8 Length of a read (in 64-bit words)
		 * @param initial_data Initial data pattern
		 * @param data_inc Data pattern increment
		 * @param ben Byte enable mask
		 * @param tid Thread Id (VPU only)
		 * @param arg Argument (VPU only)
		 */
		linear_wr_trace(const std::string& name, uint64_t start_addr, uint64_t len8, uint64_t initial_data,
				uint64_t data_inc = 1, uint8_t ben = 0xff, uint8_t tid = 0, bool arg = false);

		bool done() const override { return m_num_verif == 0; }

		trace_req* next_req() override;
		void req_sent(trace_req *rq) override;
		trace_res* next_res() override;
		void res_vrfd(trace_res *r) override;
	};

} // namespace stimul
