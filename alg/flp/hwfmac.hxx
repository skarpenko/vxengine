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
 * Floating point add, mul and mac.
 */

#include "hwfp.hxx"
#pragma once


namespace hwfmac {


/**
 * mul - multiplication
 *
 * @tparam T integral type
 * @tparam X extended integral type
 * @tparam EWIDTH exponent width
 * @tparam SWIDTH significand width
 * @tparam RSWIDTH round/sticky width
 * @param a input first operand
 * @param b input second operand
 * @param r output result
 */
template<typename T, typename X, unsigned EWIDTH, unsigned SWIDTH, unsigned RSWIDTH>
void mul(const T& a, const T& b, T& r)
{
	bool sn1, sn2;
	T ex1, ex2;
	T sg1, sg2;
	bool zero1, zero2;
	bool nan1, nan2;
	bool inf1, inf2;

	// Unpack
	hwfp::unpack<T, EWIDTH, SWIDTH>(a, sn1, ex1, sg1, zero1, nan1, inf1);
	hwfp::unpack<T, EWIDTH, SWIDTH>(b, sn2, ex2, sg2, zero2, nan2, inf2);

	bool uf, of;
	bool sn;
	X sg;
	T ex;

	// Multiply
	hwfp::mul<T, X, EWIDTH, SWIDTH, RSWIDTH>(sn1, ex1, sg1, sn2, ex2, sg2,
		sn, ex, sg, uf, of);

	bool nuf, nof;
	X nsg;
	T nex;

	// Normalize
	hwfp::norm<T, X, EWIDTH, SWIDTH, RSWIDTH>(ex, sg, nex, nsg, nuf, nof);

	bool rof;
	T rsg;
	T rex;

	// Round
	hwfp::round<T, X, EWIDTH, SWIDTH, RSWIDTH>(nex, nsg, rex, rsg, rof);

	T v = T(0);
	bool zero = zero1 || zero2 || uf || nuf;
	bool nan = nan1 || nan2 || (zero1 && inf2) || (zero2 && inf1);
	bool inf = inf1 || inf2 || of || nof;

	// Check for special values
	if(nan) {
		rex = -1;
		rsg = -1;
	} else if(inf) {
		rex = -1;
		rsg = 0;
	} else if(zero) {
		rex = rsg = 0;
	}

	// Pack result
	hwfp::pack<T, EWIDTH, SWIDTH>(sn, rex, rsg, v);

	r = v;
}


/**
 * add - addition
 *
 * @tparam T integral type
 * @tparam X extended integral type
 * @tparam EWIDTH exponent width
 * @tparam SWIDTH significand width
 * @tparam RSWIDTH round/sticky width
 * @param a input first operand
 * @param b input second operand
 * @param r output result
 */
template<typename T, typename X, unsigned EWIDTH, unsigned SWIDTH, unsigned RSWIDTH>
void add(const T& a, const T& b, T& r)
{
	bool sn1, sn2;
	T ex1, ex2;
	T sg1, sg2;
	bool zero1, zero2;
	bool nan1, nan2;
	bool inf1, inf2;

	// Unpack
	hwfp::unpack<T, EWIDTH, SWIDTH>(a, sn1, ex1, sg1, zero1, nan1, inf1);
	hwfp::unpack<T, EWIDTH, SWIDTH>(b, sn2, ex2, sg2, zero2, nan2, inf2);

	T aex;
	bool asn1, asn2;
	X asg1, asg2;

	// Align exponents
	hwfp::align<T, X, EWIDTH, SWIDTH, RSWIDTH>(sn1, ex1, sg1, sn2, ex2, sg2,
		aex, asn1, asg1, asn2, asg2);

	bool sn;
	X sg;
	bool azero;

	// Add
	hwfp::add<T, X, EWIDTH, SWIDTH, RSWIDTH>(asn1, asg1, asn2, asg2, sn, sg,
		azero);

	bool nuf, nof;
	X nsg;
	T nex;

	// Normalize
	hwfp::norm<T, X, EWIDTH, SWIDTH, RSWIDTH>(aex, sg, nex, nsg, nuf, nof);

	bool rof;
	T rsg;
	T rex;

	// Round
	hwfp::round<T, X, EWIDTH, SWIDTH, RSWIDTH>(nex, nsg, rex, rsg, rof);

	T v = T(0);
	bool sign = (inf1 || inf2 ? (inf1 && sn1) || (inf2 && sn2) : sn);
	bool zero = (zero1 && zero2) || azero || nuf;
	bool nan = nan1 || nan2 || (inf1 && inf2 && (sn1 ^ sn2));
	bool inf = inf1 || inf2 || nof;

	// Check for special values
	if(nan) {
		rex = -1;
		rsg = -1;
	} else if(inf) {
		rex = -1;
		rsg = 0;
	} else if(zero) {
		rex = rsg = 0;
	}

	// Pack result
	hwfp::pack<T, EWIDTH, SWIDTH>(sign, rex, rsg, v);

	r = v;
}


/**
 * mac - multiply-accumulate
 *
 * @tparam T integral type
 * @tparam X extended integral type
 * @tparam EWIDTH exponent width
 * @tparam SWIDTH significand width
 * @tparam RSWIDTH round/sticky width
 * @param a input first operand (accumulator)
 * @param b input second operand
 * @param c input third operand
 * @param r output result
 */
template<typename T, typename X, unsigned EWIDTH, unsigned SWIDTH, unsigned RSWIDTH>
void mac(const T& a, const T& b, const T& c, T& r)
{
	bool sn1, sn2, sn3;
	T ex1, ex2, ex3;
	T sg1, sg2, sg3;
	bool zero1, zero2, zero3;
	bool nan1, nan2, nan3;
	bool inf1, inf2, inf3;

	// Unpack
	hwfp::unpack<T, EWIDTH, SWIDTH>(a, sn1, ex1, sg1, zero1, nan1, inf1);
	hwfp::unpack<T, EWIDTH, SWIDTH>(b, sn2, ex2, sg2, zero2, nan2, inf2);
	hwfp::unpack<T, EWIDTH, SWIDTH>(c, sn3, ex3, sg3, zero3, nan3, inf3);

	bool m_uf, m_of;
	bool m_sn;
	X m_sg;
	T m_ex;

	// Multiply
	hwfp::mul<T, X, EWIDTH, SWIDTH, RSWIDTH>(sn2, ex2, sg2, sn3, ex3, sg3,
		m_sn, m_ex, m_sg, m_uf, m_of);

	// Extend accumulator
	X p_sg1 = 0;
	p_sg1 = hw::insr(p_sg1, X(sg1), SWIDTH + RSWIDTH, RSWIDTH);

	T aex;
	bool asn1, asn2;
	X asg1, asg2;

	// Align exponents
	hwfp::alignr<T, X, EWIDTH, SWIDTH>(sn1, ex1, p_sg1, m_sn, m_ex, m_sg,
		aex, asn1, asg1, asn2, asg2);

	bool sn;
	X sg;
	bool azero;

	// Add
	hwfp::add<T, X, EWIDTH, SWIDTH, RSWIDTH>(asn1, asg1, asn2, asg2, sn, sg,
		azero);

	bool nuf, nof;
	X nsg;
	T nex;

	// Normalize
	hwfp::norm<T, X, EWIDTH, SWIDTH, RSWIDTH>(aex, sg, nex, nsg, nuf, nof);

	bool rof;
	T rsg;
	T rex;

	// Round
	hwfp::round<T, X, EWIDTH, SWIDTH, RSWIDTH>(nex, nsg, rex, rsg, rof);

	T v = T(0);
	// Multiplication flags
	bool m_zero = zero2 || zero3 || m_uf;
	bool m_nan = nan2 || nan3 || (zero2 && inf3) || (zero3 && inf2);
	bool m_inf = inf2 || inf3 || m_of;
	// Resulting flags
	bool zero = (zero1 && m_zero) || azero || nuf;
	bool nan = nan1 || m_nan || (inf1 && m_inf && (sn1 ^ m_sn));
	bool inf = inf1 || m_inf || nof;

	// Check for special values
	if(nan) {
		rex = -1;
		rsg = -1;
	} else if(inf) {
		rex = -1;
		rsg = 0;
	} else if(zero) {
		rex = rsg = 0;
	}

	// Pack result
	hwfp::pack<T, EWIDTH, SWIDTH>(sn, rex, rsg, v);

	r = v;
}


} // namespace hwfmac
