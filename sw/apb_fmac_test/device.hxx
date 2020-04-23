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

#include <cstdint>
#pragma once


class fmac_mmio {
	int m_fd;
	void *m_base;
public:
	/**
	 * fmac_mmio - constructor
	 *
	 * @param mmio_base base MMIO address of APB FMAC
	 */
	explicit fmac_mmio(unsigned long mmio_base);

	~fmac_mmio();
	fmac_mmio(const fmac_mmio&) = delete;
	fmac_mmio(fmac_mmio&&) = delete;
	fmac_mmio& operator=(const fmac_mmio&) = delete;

	/**
	 * is_opened - check that device is opened
	 */
	bool is_opened() const { return m_fd >= 0; }

	/**
	 * id_reg - return value if ID register
	 */
	uint32_t id_reg() const;

	/**
	 * fmac - floating point multiply-accumulate
	 *
	 * @param a accumulator
	 * @param b multiplicand
	 * @param c multiplier
	 * @return result of operation
	 */
	uint32_t fmac(uint32_t a, uint32_t b, uint32_t c);
	float fmac(float a, float b, float c) {
		union {
			uint32_t u;
			float f;
		} arg1, arg2, arg3;
		arg1.f = a;
		arg2.f = b;
		arg3.f = c;
		return fmac(arg1.u, arg2.u, arg3.u);
	}
};
