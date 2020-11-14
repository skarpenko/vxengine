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
 * Simple memory allocator
 */

#include <cstdint>
#pragma once


namespace sw {

	/**
	 * Simple memory allocator
	 */
	class simple_allocator {
		uint8_t *m_ptr;		// Pointer to real memory chunk
		uint64_t m_start;	// Start address
		uint64_t m_end;		// End address
		uint64_t m_next;	// Next available address
	public:
		/**
		 * Allocation
		 */
		struct allocation {
			void *vaddr;		// CPU address
			uint64_t paddr;		// Device address
		};

	public:
		// Constructors
		simple_allocator() noexcept
			: m_ptr(nullptr), m_start(0), m_end(0)
		{
			m_next = m_start;
		}
		simple_allocator(void *ptr, uint64_t start, uint64_t end) noexcept
			: m_ptr(reinterpret_cast<uint8_t*>(ptr)), m_start(start), m_end(end)
		{
			m_next = m_start;
		}
		simple_allocator(simple_allocator&& other) noexcept
		{
			m_ptr = other.m_ptr;
			m_start = other.m_start;
			m_end = other.m_end;
			m_next = other.m_next;
			other.m_ptr = nullptr;
			other.m_start = other.m_end = other.m_next = 0;
		}
		simple_allocator(const simple_allocator& other) = delete;
		~simple_allocator() {}

		// Assignment operators
		simple_allocator& operator=(const simple_allocator& other) = delete;
		simple_allocator& operator=(simple_allocator&& other) noexcept
		{
			if(this != &other) {
				m_ptr = other.m_ptr;
				m_start = other.m_start;
				m_end = other.m_end;
				m_next = other.m_next;
				other.m_ptr = nullptr;
				other.m_start = other.m_end = other.m_next = 0;
			}
			return *this;
		}

		/**
		 * Reset (free) all current allocations
		 */
		void reset() noexcept { m_next = m_start; }

		/**
		 * Allocate memory
		 * @param size allocation size
		 * @param alignment alignment
		 * @return allocation descriptor
		 */
		struct allocation allocate(size_t size, size_t alignment = 4) noexcept
		{
			struct allocation a = {};
			uint64_t next = m_next;
			uint64_t rem;

			if(alignment == 0)
				alignment = 4;

			// Adjust alignment
			rem = next % alignment;
			next += rem;

			// Check if memory is available
			if(next + size > (m_end + 1))
				return a;

			// Allocate
			a.paddr = next;
			a.vaddr = &m_ptr[next - m_start];

			// Update address of the next available chunk
			m_next = next + size;

			return a;
		}
	};

} // namespace sw
