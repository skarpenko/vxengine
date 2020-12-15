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
 * Rectified linear unit (ReLU) and leaky ReLU
 */

#include "flp/hwfp.hxx"
#pragma once


namespace hwrelu {


/**
 * relu - rectified linear unit
 *
 * @tparam T integral type
 * @tparam EWIDTH exponent width
 * @tparam SWIDTH significand width
 * @param v input value
 * @param r output result
 * @param l =false for ReLU and =true for leaky ReLU
 * @param e exponent diff for leaky ReLU, must be [-1 ... -(1<<(EWIDTH-1))]
 */
template<typename T, unsigned EWIDTH, unsigned SWIDTH>
void relu(const T& v, T& r, bool l, T e)
{
	bool sn;
	T ex, ex2;
	T sg;
	bool zero;
	bool nan;
	bool inf;

	// Unpack
	hwfp::unpack<T, EWIDTH, SWIDTH>(v, sn, ex, sg, zero, nan, inf);

	if(!nan && sn && l) {
		// Sign extend
		e &= ((1 << T(EWIDTH - 1)) - 1); // Only (EWIDTH - 1) bits are picked
		e |= T(-1) & ~((1 << T(EWIDTH - 1)) - 1); // ... then extended with sign
		// Reduce exponent by e
		ex2 = (!inf ? ex + e : ex);
		// Check for underflow
		if(hw::bit(ex2, EWIDTH)) {
			sg = T(0);
			ex = T(0);
		} else
			ex = ex2;
	} else if(!nan && sn) {
		sn = false;
		sg = ex = 0;
	}

	// Pack result
	hwfp::pack<T, EWIDTH, SWIDTH>(sn, ex, sg, r);
}


} // namespace hwrelu
