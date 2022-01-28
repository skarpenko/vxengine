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
	uint64_t REGION_SIZE = 8 * 1024;	// 8KB
	uint64_t region_bases[] = {
		REGIONS_BASE + 0 * REGION_SIZE,
		REGIONS_BASE + 1 * REGION_SIZE,
		REGIONS_BASE + 2 * REGION_SIZE,
		REGIONS_BASE + 3 * REGION_SIZE,
		REGIONS_BASE + 4 * REGION_SIZE,
		REGIONS_BASE + 5 * REGION_SIZE,
		REGIONS_BASE + 6 * REGION_SIZE,
		REGIONS_BASE + 7 * REGION_SIZE
	};
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
