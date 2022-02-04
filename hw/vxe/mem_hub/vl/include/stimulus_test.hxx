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

	/**
	 * Initialize test memory regions
	 * @param region_size size
	 * @return overall memory size
	 */
	size_t init_test_regions(size_t region_size);

	// Test base class
	class test_base {
		const std::string m_name;
	protected:
		int m_cu_mas;
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

	// Test: read memory regions
	class test_read_regions: public test_base {
	public:
		/**
		 * Read memory regions
		 * @param name test name
		 * @param use_cu use CU
		 * @param cu_m_sel CU master select
		 * @param cu_region_no CU region number
		 * @param cu_pattern CU pattern to read
		 * @param cu_inc increment CU pattern
		 * @param use_vpu0 use VPU0
		 * @param vpu0_arg VPU0 argument type (Rs / Rt)
		 * @param vpu0_region_no VPU0 region number
		 * @param vpu0_pattern VPU0 pattern to read
		 * @param vpu0_inc increment VPU0 pattern
		 * @param use_vpu1 use VPU1
		 * @param vpu1_arg VPU1 argument type (Rs / Rt)
		 * @param vpu1_region_no VPU1 region number
		 * @param vpu1_pattern VPU1 pattern to read
		 * @param vpu1_inc increment VPU1 pattern
		 */
		test_read_regions(const std::string& name, bool use_cu, bool cu_m_sel, unsigned cu_region_no, uint64_t cu_pattern,
				bool cu_inc, bool use_vpu0, bool vpu0_arg, unsigned vpu0_region_no, uint64_t vpu0_pattern, bool vpu0_inc,
				bool use_vpu1, bool vpu1_arg, unsigned vpu1_region_no, uint64_t vpu1_pattern, bool vpu1_inc);
	};

	// Test: read/write memory regions
	class test_rdwr_regions: public test_base {
	public:
		/**
		 * Read memory regions
		 * @param name test name
		 * @param cu_m_sel CU master select
		 * @param cu_region_no CU region number
		 * @param cu_pattern CU pattern to read
		 * @param rnw_vpu0 read or write for VPU0
		 * @param vpu0_arg VPU0 argument type (Rs / Rt)
		 * @param vpu0_region_no VPU0 region number
		 * @param vpu0_pattern VPU0 pattern to read
		 * @param vpu0_ben byte enable for VPU0 writes
		 * @param vpu0_inc increment pattern for VPU0
		 * @param rnw_vpu1 read or write for VPU1
		 * @param vpu1_arg VPU1 argument type (Rs / Rt)
		 * @param vpu1_region_no VPU1 region number
		 * @param vpu1_pattern VPU1 pattern to read
		 * @param vpu1_ben byte enable for VPU1 writes
		 * @param vpu1_inc increment pattern for VPU1
		 */
		test_rdwr_regions(const std::string& name, bool cu_m_sel, unsigned cu_region_no, uint64_t cu_pattern,
			bool rnw_vpu0, bool vpu0_arg, unsigned vpu0_region_no, uint64_t vpu0_pattern, uint8_t vpu0_ben, bool vpu0_inc,
			bool rnw_vpu1, bool vpu1_arg, unsigned vpu1_region_no, uint64_t vpu1_pattern, uint8_t vpu1_ben, bool vpu1_inc);
	};

} // namespace stimul
