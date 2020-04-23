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
 * APB FMAC device driver
 */

#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include "device.hxx"


fmac_mmio::fmac_mmio(unsigned long mmio_base)
	: m_fd(-1), m_base(nullptr)
{
	// Open memory file (requires root privileges)
	m_fd = open("/dev/mem", O_RDWR | O_SYNC);
	if(m_fd < 0)
		return;

	// Map MMIO space
	m_base = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, m_fd,
		mmio_base);
	if(m_base == MAP_FAILED) {
		close(m_fd);
		m_fd = -1;
	}
}


fmac_mmio::~fmac_mmio()
{
	// Clean up
	munmap(m_base, 4096);
	close(m_fd);
	m_fd = -1;
	m_base = nullptr;
}


uint32_t fmac_mmio::id_reg() const
{
	constexpr int REG_ID = 5;
	volatile uint32_t *regs = static_cast<volatile uint32_t *>(m_base);
	return regs[REG_ID];
}


uint32_t fmac_mmio::fmac(uint32_t a, uint32_t b, uint32_t c)
{
	constexpr int REG_A	= 0;	// Accumulator register
	constexpr int REG_B	= 1;	// Multiplicand register
	constexpr int REG_C	= 2;	// Multiplier register
	constexpr int REG_R	= 3;	// Result register
	constexpr int REG_FLAGS	= 4;	// Flags register
	constexpr int REG_START	= 5;	// Start operation control register
	uint32_t r;
	volatile uint32_t *regs = static_cast<volatile uint32_t *>(m_base);

	// Assign operands
	regs[REG_A] = a;
	regs[REG_B] = b;
	regs[REG_C] = c;

	// Start operation
	regs[REG_START] = 1;

	// Wait for completion
	while(!(regs[REG_FLAGS] & 0x80000000))
		;

	// Return result
	r = regs[REG_R];

	return r;
}
