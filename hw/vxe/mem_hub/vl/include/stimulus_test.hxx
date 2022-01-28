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
 * Stimulus generators / tests
 */

#include <cstdint>
#include <memory>
#include "stimulus_trace.hxx"
#pragma once


namespace stimul {

	// Test base class
	class test_base {
		const std::string m_name;
		int m_cu_mas;
	protected:
		std::shared_ptr<trace_gen_base> m_cu_trace;
		std::shared_ptr<trace_gen_base> m_vpu0_trace;
		std::shared_ptr<trace_gen_base> m_vpu1_trace;
	public:
		explicit test_base(const std::string& name, int cu_mas = 0) : m_name(name), m_cu_mas(!!cu_mas) {}
		virtual ~test_base() = default;

		test_base(const test_base&) = delete;
		test_base& operator=(const test_base&) = delete;

		// Test name
		std::string name() const { return m_name; }

		// Test finished
		bool done() const;

		// CU master port number
		int cu_mas() const { return m_cu_mas; }

		// Test has a trace for CU
		bool has_cu_trace() const { return m_cu_trace != nullptr; }

		// Test has a trace for VPU0
		bool has_vpu0_trace() const { return m_vpu0_trace != nullptr; }

		// Test has a trace for VPU1
		bool has_vpu1_trace() const { return m_vpu1_trace != nullptr; }

		// Get CU trace
		std::shared_ptr<trace_gen_base> get_cu_trace() const { return m_cu_trace; }

		// Get VPU0 trace
		std::shared_ptr<trace_gen_base> get_vpu0_trace() const { return m_vpu0_trace; }

		// Get VPU1 trace
		std::shared_ptr<trace_gen_base> get_vpu1_trace() const { return m_vpu1_trace; }
	};

	// Test: write to a memory region
	class test_write_region: public test_base {
	public:
		/**
		 * Write to memory
		 * @param name Test name
		 * @param region_no Memory region number
		 * @param vpu_no VPU number to use
		 * @param pattern Initial data pattern
		 */
		test_write_region(const std::string& name, unsigned region_no, unsigned vpu_no, uint64_t pattern);
	};

} // namespace stimul
