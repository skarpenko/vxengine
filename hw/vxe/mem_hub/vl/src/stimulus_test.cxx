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

#include <stdexcept>
#include <stimulus_test.hxx>


// Local definitions
namespace {
	uint64_t REGIONS_BASE = 0x1000;		// Base address for regions
	uint64_t REGION_SIZE = 0;		// Region size (must be set externally)
	uint64_t region_bases[16];
}


size_t stimul::init_test_regions(size_t region_size)
{
	unsigned n = sizeof(region_bases) / sizeof(region_bases[0]);
	uint64_t region = REGIONS_BASE;

	REGION_SIZE = region_size;

	for(unsigned i = 0; i < n; ++i) {
		region_bases[i] = region;
		region += REGION_SIZE;
	}

	return REGIONS_BASE + n * REGION_SIZE + 0x1000 /* extra page */;
}


bool stimul::test_base::done() const
{
	int c = 0;

	if(m_cu_trace == nullptr || m_cu_trace->done())
		++c;

	if(m_vpu0_trace == nullptr || m_vpu0_trace->done())
		++c;

	if(m_vpu1_trace == nullptr || m_vpu1_trace->done())
		++c;

	return c == 3;
}

stimul::test_write_region::test_write_region(const std::string& name, unsigned region_no, unsigned vpu_no, uint64_t pattern)
	: test_base(name)
{
	if(region_no >= (sizeof(region_bases) / sizeof(region_bases[0])))
		throw std::runtime_error(name + ": Region No. is out of range.");

	auto wr_trace = std::make_shared<linear_wr_trace>("write", region_bases[region_no],
				REGION_SIZE / sizeof(uint64_t), pattern, 1);

	if(vpu_no == 0)
		m_vpu0_trace = wr_trace;
	else
		m_vpu1_trace = wr_trace;
}

stimul::test_read_regions::test_read_regions(const std::string& name, bool use_cu, bool cu_m_sel, unsigned cu_region_no,
	uint64_t cu_pattern, bool cu_inc, bool use_vpu0, bool vpu0_arg, unsigned vpu0_region_no, uint64_t vpu0_pattern,
	bool vpu0_inc, bool use_vpu1, bool vpu1_arg, unsigned vpu1_region_no, uint64_t vpu1_pattern, bool vpu1_inc)
	: test_base(name)
{
	if(cu_region_no >= (sizeof(region_bases) / sizeof(region_bases[0])))
		throw std::runtime_error(name + ": CU Region No. is out of range.");
	if(vpu0_region_no >= (sizeof(region_bases) / sizeof(region_bases[0])))
		throw std::runtime_error(name + ": VPU0 Region No. is out of range.");
	if(vpu1_region_no >= (sizeof(region_bases) / sizeof(region_bases[0])))
		throw std::runtime_error(name + ": VPU1 Region No. is out of range.");

	if(use_cu) {
		m_cu_trace = std::make_shared<linear_rd_trace>("cu_read", region_bases[cu_region_no],
				REGION_SIZE / sizeof(uint64_t), cu_pattern, cu_inc);
		m_cu_mas = cu_m_sel ? 1 : 0;
	}

	if(use_vpu0) {
		m_vpu0_trace = std::make_shared<linear_rd_trace>("vpu0_read", region_bases[vpu0_region_no],
				REGION_SIZE / sizeof(uint64_t), vpu0_pattern, vpu0_inc,0, vpu0_arg);
	}

	if(use_vpu1) {
		m_vpu1_trace = std::make_shared<linear_rd_trace>("vpu1_read", region_bases[vpu1_region_no],
				REGION_SIZE / sizeof(uint64_t), vpu1_pattern, vpu1_inc,0, vpu1_arg);
	}
}

stimul::test_rdwr_regions::test_rdwr_regions(const std::string& name, bool cu_m_sel, unsigned cu_region_no, uint64_t cu_pattern,
	bool rnw_vpu0, bool vpu0_arg, unsigned vpu0_region_no, uint64_t vpu0_pattern, uint8_t vpu0_ben, bool vpu0_inc,
	bool rnw_vpu1, bool vpu1_arg, unsigned vpu1_region_no, uint64_t vpu1_pattern, uint8_t vpu1_ben, bool vpu1_inc)
	: test_base(name)
{
	if(cu_region_no >= (sizeof(region_bases) / sizeof(region_bases[0])))
		throw std::runtime_error(name + ": CU Region No. is out of range.");
	if(vpu0_region_no >= (sizeof(region_bases) / sizeof(region_bases[0])))
		throw std::runtime_error(name + ": VPU0 Region No. is out of range.");
	if(vpu1_region_no >= (sizeof(region_bases) / sizeof(region_bases[0])))
		throw std::runtime_error(name + ": VPU1 Region No. is out of range.");

	m_cu_trace = std::make_shared<linear_rd_trace>("cu_read", region_bases[cu_region_no],
			REGION_SIZE / sizeof(uint64_t), cu_pattern, 1);
	m_cu_mas = cu_m_sel ? 1 : 0;

	if(rnw_vpu0) {
		m_vpu0_trace = std::make_shared<linear_rd_trace>("vpu0_read", region_bases[vpu0_region_no],
				REGION_SIZE / sizeof(uint64_t), vpu0_pattern, vpu0_inc, 0, vpu0_arg);
	} else {
		m_vpu0_trace = std::make_shared<linear_wr_trace>("vpu0_write", region_bases[vpu0_region_no],
				REGION_SIZE / sizeof(uint64_t), vpu0_pattern, vpu0_inc, vpu0_ben,
				0, vpu0_arg);
	}

	if(rnw_vpu1) {
		m_vpu1_trace = std::make_shared<linear_rd_trace>("vpu1_read", region_bases[vpu1_region_no],
				REGION_SIZE / sizeof(uint64_t), vpu1_pattern, vpu0_inc,0, vpu1_arg);
	} else {
		m_vpu1_trace = std::make_shared<linear_wr_trace>("vpu1_write", region_bases[vpu1_region_no],
				REGION_SIZE / sizeof(uint64_t), vpu1_pattern, vpu0_inc, vpu1_ben,
				0, vpu1_arg);
	}
}
