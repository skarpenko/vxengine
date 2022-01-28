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
 * Stimulus pattern generators
 */

#include <cstdint>
#pragma once


namespace stimul {

namespace patgen {

	// Base class for address generators
	class addr_gen_base {
	public:
		addr_gen_base() = default;

		virtual ~addr_gen_base() = default;

		virtual uint64_t next_addr() = 0;
	};

	// Base class for data generators
	class data_gen_base {
	public:
		data_gen_base() = default;

		virtual ~data_gen_base() = default;

		virtual uint64_t next_data() = 0;
	};

	// Base class for byte enable generators
	class ben_gen_base {
	public:
		ben_gen_base() = default;

		virtual ~ben_gen_base() = default;

		virtual uint64_t next_ben() = 0;
	};

	// Linear address generator
	class linear_addr_gen : public addr_gen_base {
		uint64_t m_start;
		uint64_t m_step;
	public:
		explicit linear_addr_gen(uint64_t start_addr, uint64_t step = 8)
			: m_start(start_addr), m_step(step) {}

		uint64_t next_addr() override {
			uint64_t addr = m_start;
			m_start += m_step;
			return addr;
		}
	};

	// Incremental data generator
	class inc_data_gen : public data_gen_base {
		uint64_t m_data;
		uint64_t m_inc;
	public:
		inc_data_gen(uint64_t initial_data, uint64_t increment)
			: m_data(initial_data), m_inc(increment) {}

		uint64_t next_data() override {
			uint64_t data = m_data;
			m_data += m_inc;
			return data;
		}
	};

	// Inverted data generator
	class inv_data_gen : public data_gen_base {
		uint64_t m_data;
	public:
		explicit inv_data_gen(uint64_t initial_data)
			: m_data(initial_data) {}

		uint64_t next_data() override {
			uint64_t data = m_data;
			m_data = ~m_data;
			return data;
		}
	};

	// Constant byte enable generator
	class const_ben_gen : public ben_gen_base {
		uint8_t m_ben;
	public:
		explicit const_ben_gen(uint8_t initial_ben = 0xFF)
			: m_ben(initial_ben) {}

		uint64_t next_ben() override {
			return m_ben;
		}
	};

	// Inverted byte enable generator
	class inv_ben_gen : public ben_gen_base {
		uint8_t m_ben;
	public:
		explicit inv_ben_gen(uint8_t initial_ben = 0xFF)
			: m_ben(initial_ben) {}

		uint64_t next_ben() override {
			uint64_t ben = m_ben;
			m_ben = ~m_ben;
			return ben;
		}
	};

} // namespace patgen

} // namespace stimul
