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
 * Basic operations used in floating point
 */

#include <type_traits>
#include <limits>
#include "hw.hxx"
#pragma once


namespace hwfp {


/**
 * unpack - unpack floating point fields. (subnormals treated as zeros)
 *
 * @tparam T integral type
 * @tparam EWIDTH exponent width
 * @tparam SWIDTH significand width
 * @param i_v input value with floating point data
 * @param o_sn output sign value
 * @param o_ex output exponent value
 * @param o_sg output significand value
 * @param o_zero set to true if zero
 * @param o_nan set to true if NaN
 * @param o_inf set to trues if Inf
 */
template<typename T, unsigned EWIDTH, unsigned SWIDTH>
void unpack(const T& i_v, bool& o_sn, T& o_ex, T& o_sg, bool& o_zero,
	bool& o_nan, bool& o_inf)
{
	static_assert(std::is_integral<T>::value, "T must be an integral type.");
	static_assert(SWIDTH > EWIDTH, "SWIDTH must be greater than EWIDTH.");
	static_assert(SWIDTH > 0, "SWIDTH cannot be zero.");
	static_assert(EWIDTH > 0, "EWIDTH cannot be zero.");

	// Reset flags
	o_zero = false;
	o_nan = false;
	o_inf = false;

	// Extract fields
	o_sn = hw::extr(i_v, EWIDTH + SWIDTH, EWIDTH + SWIDTH) != 0;
	o_ex = hw::extr(i_v, EWIDTH + SWIDTH - 1, SWIDTH);
	o_sg = hw::extr(i_v, SWIDTH - 1, 0);

	// Ignore subnormals
	if(o_ex == 0) {
		o_sg = 0;
		o_zero = true;
	}

	// Check for NaN and Inf
	if(hw::andr(o_ex, EWIDTH - 1, 0)) {
		o_nan = o_sg ? true : false;
		o_inf = o_sg ? false : true;
	}

	// Set hidden one
	if(!o_zero && !o_nan && !o_inf)
		o_sg = hw::setb(o_sg, SWIDTH, true);
}


/**
 * pack - pack fields to floating point format
 *
 * @tparam T integral type
 * @tparam EWIDTH exponent width
 * @tparam SWIDTH significand width
 * @param i_sn input sign value
 * @param i_ex input exponent value
 * @param i_sg input significand value
 * @param o_v output floating point
 */
template<typename T, unsigned EWIDTH, unsigned SWIDTH>
void pack(const bool& i_sn, const T& i_ex, const T& i_sg, T& o_v)
{
	static_assert(std::is_integral<T>::value, "T must be an integral type.");
	static_assert(SWIDTH > EWIDTH, "SWIDTH must be greater than EWIDTH.");
	static_assert(SWIDTH > 0, "SWIDTH cannot be zero.");
	static_assert(EWIDTH > 0, "EWIDTH cannot be zero.");

	o_v = hw::insr(o_v, i_sn ? T(1) : T(0), EWIDTH + SWIDTH, EWIDTH + SWIDTH);
	o_v = hw::insr(o_v, i_ex, EWIDTH + SWIDTH - 1, SWIDTH);
	o_v = hw::insr(o_v, i_sg, SWIDTH - 1, 0);
}


/**
 * mul - multiply
 *
 * @tparam T integral type
 * @tparam X extended integral type
 * @tparam EWIDTH exponent width
 * @tparam SWIDTH significand width
 * @tparam RSWIDTH round/sticky width
 * @param i_sn1 input first sign operand
 * @param i_ex1 input first exponent operand
 * @param i_sg1 input first significand operand
 * @param i_sn2 input second sign operand
 * @param i_ex2 input second exponent operand
 * @param i_sg2 input second significand operand
 * @param o_sn output sign result
 * @param o_ex output exponent result
 * @param o_sg output significand result
 * @param o_uf set if underflow
 * @param o_of set if overflow
 */
template<typename T, typename X, unsigned EWIDTH, unsigned SWIDTH, unsigned RSWIDTH>
void mul(const bool& i_sn1, const T& i_ex1, const X& i_sg1,
	const bool& i_sn2, const T& i_ex2, const X& i_sg2,
	bool& o_sn, T& o_ex, X& o_sg, bool& o_uf, bool& o_of)
{
	static_assert(std::is_integral<T>::value, "T must be an integral type.");
	static_assert(std::is_integral<X>::value, "X must be an integral type.");
	static_assert(std::numeric_limits<X>::digits >= std::numeric_limits<T>::digits,
		"X must be wider than T.");
	static_assert(SWIDTH > EWIDTH, "SWIDTH must be greater than EWIDTH.");
	static_assert(SWIDTH > 0, "SWIDTH cannot be zero.");
	static_assert(EWIDTH > 0, "EWIDTH cannot be zero.");
	static_assert(RSWIDTH >= 2, "RSWIDTH must be greater or equal 2.");
	static_assert(RSWIDTH < SWIDTH, "RSWIDTH must be less than SWIDTH.");

	// Exponent bias value
	constexpr T BIAS = (T(1) << (EWIDTH - 1)) - 1;

	// Set flags
	o_uf = false;
	o_of = false;
	o_sn = i_sn1 ^ i_sn2;
	o_ex = i_ex1 + i_ex2 - BIAS;

	if(hw::signb(o_ex)) {
		o_uf = true;	// Underflow o_ex < 0
	} else if (hw::andr(o_ex, EWIDTH, 0)) {
		o_of = true;	// Overflow test o_ex >= max. exponent
	}

	// Multiply
	X r = i_sg1 * i_sg2;

	// Truncate and set rs field
	bool s = hw::orr(r, SWIDTH - RSWIDTH, 0);
	r = hw::setb(r, SWIDTH - RSWIDTH, s);
	r >>= SWIDTH - RSWIDTH;

	o_sg = r;
}


/**
 * norm - normalize
 *
 * @tparam T integral type
 * @tparam X extended integral type
 * @tparam EWIDTH exponent width
 * @tparam SWIDTH significand width
 * @tparam RSWIDTH round/sticky width
 * @param i_ex input exponent operand
 * @param i_sg input significand operand
 * @param o_ex output exponent result
 * @param o_sg output significand result
 * @param o_uf set if underflow
 * @param o_of set if overflow
*/
template<typename T, typename X, unsigned EWIDTH, unsigned SWIDTH, unsigned RSWIDTH>
void norm(const T& i_ex, const X& i_sg, T& o_ex, X& o_sg, bool& o_uf, bool& o_of)
{
	static_assert(std::is_integral<T>::value, "T must be an integral type.");
	static_assert(std::is_integral<X>::value, "X must be an integral type.");
	static_assert(std::numeric_limits<X>::digits >= std::numeric_limits<T>::digits,
		"X must be wider than T.");
	static_assert(SWIDTH > EWIDTH, "SWIDTH must be greater than EWIDTH.");
	static_assert(SWIDTH > 0, "SWIDTH cannot be zero.");
	static_assert(EWIDTH > 0, "EWIDTH cannot be zero.");
	static_assert(RSWIDTH >= 2, "RSWIDTH must be greater or equal 2.");
	static_assert(RSWIDTH < SWIDTH, "RSWIDTH must be less than SWIDTH.");

	int d = SWIDTH + RSWIDTH - hw::msb(i_sg);

	o_ex = i_ex;
	o_sg = i_sg;
	o_uf = false;
	o_of = false;

	if(d < 0) {
		d = -d;
		bool s = hw::orr(o_sg, d, 0);
		o_sg = hw::setb(o_sg, d, s);
		o_sg >>= d;
		o_ex += d;
	} else if(d > 0) {
		o_sg <<= d;
		o_ex -= d;
	}

	if(hw::signb(o_ex)) {
		o_uf = true;	// Underflow o_ex < 0
	} else if (hw::andr(o_ex, EWIDTH, 0)) {
		o_of = true;	// Overflow test o_ex >= max. exponent
	}
}


/**
 * round - round to nearest
 *
 * @tparam T integral type
 * @tparam X extended integral type
 * @tparam EWIDTH exponent width
 * @tparam SWIDTH significand width
 * @tparam RSWIDTH round/sticky width
 * @param i_ex input exponent operand
 * @param i_sg input significand operand
 * @param o_ex output exponent result
 * @param o_sg output significand result
 * @param o_of set if overflow
 */
template<typename T, typename X, unsigned EWIDTH, unsigned SWIDTH, unsigned RSWIDTH>
void round(const T& i_ex, const X& i_sg, T& o_ex, T& o_sg, bool& o_of)
{
	static_assert(std::is_integral<T>::value, "T must be an integral type.");
	static_assert(std::is_integral<X>::value, "X must be an integral type.");
	static_assert(std::numeric_limits<X>::digits >= std::numeric_limits<T>::digits,
		"X must be wider than T.");
	static_assert(SWIDTH > EWIDTH, "SWIDTH must be greater than EWIDTH.");
	static_assert(SWIDTH > 0, "SWIDTH cannot be zero.");
	static_assert(EWIDTH > 0, "EWIDTH cannot be zero.");
	static_assert(RSWIDTH >= 2, "RSWIDTH must be greater or equal 2.");
	static_assert(RSWIDTH < SWIDTH, "RSWIDTH must be less than SWIDTH.");

	bool s = hw::orr(i_sg, RSWIDTH - 2, 0);		// Sticky bit
	bool r = (i_sg & T(1) << (RSWIDTH - 1)) != 0;	// Round bit

	o_sg = i_sg >> RSWIDTH;
	o_ex = i_ex;
	o_of = false;

	bool g = o_sg & 1;	// Guard bit

	// Rounding condition
	if((g && r) || (r && s)) {
		o_sg += 1;
		if(hw::bit(o_sg, SWIDTH + 1)) {
			o_ex += 1;
			o_sg >>= 1;
			o_of = hw::bit(o_ex, EWIDTH);
		}
	}
}


/**
 * align - align exponents before addition
 *
 * @tparam T integral type
 * @tparam X extended integral type
 * @tparam EWIDTH exponent width
 * @tparam SWIDTH significand width
 * @tparam RSWIDTH round/sticky width
 * @param i_sn1 input first sign operand
 * @param i_ex1 input first exponent operand
 * @param i_sg1 input first significand operand
 * @param i_sn2 input second sign operand
 * @param i_ex2 input second exponent operand
 * @param i_sg2 input second significand operand
 * @param o_ex output exponent result
 * @param o_sn1 output first sign result
 * @param o_sg1 output first significand result
 * @param o_sn2 output second sign result
 * @param o_sg2 output second significand result
 */
template<typename T, typename X, unsigned EWIDTH, unsigned SWIDTH, unsigned RSWIDTH>
void align(const bool& i_sn1, const T& i_ex1, const X& i_sg1,
	const bool& i_sn2, const T& i_ex2, const X& i_sg2,
	T& o_ex, bool& o_sn1, X& o_sg1, bool& o_sn2, X& o_sg2)
{
	static_assert(std::is_integral<T>::value, "T must be an integral type.");
	static_assert(std::is_integral<X>::value, "X must be an integral type.");
	static_assert(std::numeric_limits<X>::digits >= std::numeric_limits<T>::digits,
		"X must be wider than T.");
	static_assert(SWIDTH > EWIDTH, "SWIDTH must be greater than EWIDTH.");
	static_assert(SWIDTH > 0, "SWIDTH cannot be zero.");
	static_assert(EWIDTH > 0, "EWIDTH cannot be zero.");
	static_assert(RSWIDTH >= 2, "RSWIDTH must be greater or equal 2.");
	static_assert(RSWIDTH < SWIDTH, "RSWIDTH must be less than SWIDTH.");

	o_sg1 = 0;
	o_sg2 = 0;

	T d;

	if(i_ex1 < i_ex2) {
		d = i_ex2 - i_ex1;
		o_ex = i_ex2;
		// Swap input 1 and input 2
		o_sn1 = i_sn2;
		o_sn2 = i_sn1;
		o_sg1 = hw::insr(o_sg1, i_sg2, SWIDTH + RSWIDTH, RSWIDTH);
		o_sg2 = hw::insr(o_sg2, i_sg1, SWIDTH + RSWIDTH, RSWIDTH);
	} else {
		d = i_ex1 - i_ex2;
		o_ex = i_ex1;
		o_sn1 = i_sn1;
		o_sn2 = i_sn2;
		o_sg1 = hw::insr(o_sg1, i_sg1, SWIDTH + RSWIDTH, RSWIDTH);
		o_sg2 = hw::insr(o_sg2, i_sg2, SWIDTH + RSWIDTH, RSWIDTH);
	}

	if(d && d > RSWIDTH) {
		bool s = hw::orr(o_sg2, d, RSWIDTH);
		o_sg2 = hw::setb(o_sg2, d, s);
		o_sg2 >>= d;
	} else if(d)
		o_sg2 >>= d;
}


/**
 * add - addition
 *
 * @tparam T integral type
 * @tparam X extended integral type
 * @tparam EWIDTH exponent width
 * @tparam SWIDTH significand width
 * @tparam RSWIDTH round/sticky width
 * @param i_sn1 first sign operand
 * @param i_sg1 first significand operand
 * @param i_sn2 second sign operand
 * @param i_sg2 second significand operand
 * @param o_sn output sign result
 * @param o_sg output significand result
 * @param o_zero set if zero
 */
template<typename T, typename X, unsigned EWIDTH, unsigned SWIDTH, unsigned RSWIDTH>
void add(const bool& i_sn1, const X& i_sg1, const bool& i_sn2, const X& i_sg2,
	bool& o_sn, X& o_sg, bool& o_zero)
{
	static_assert(std::is_integral<T>::value, "T must be an integral type.");
	static_assert(std::is_integral<X>::value, "X must be an integral type.");
	static_assert(std::numeric_limits<X>::digits >= std::numeric_limits<T>::digits,
		"X must be wider than T.");
	static_assert(SWIDTH > EWIDTH, "SWIDTH must be greater than EWIDTH.");
	static_assert(SWIDTH > 0, "SWIDTH cannot be zero.");
	static_assert(EWIDTH > 0, "EWIDTH cannot be zero.");
	static_assert(RSWIDTH >= 2, "RSWIDTH must be greater or equal 2.");
	static_assert(RSWIDTH < SWIDTH, "RSWIDTH must be less than SWIDTH.");

	X sg1 = i_sn1 ? -i_sg1 : i_sg1;
	X sg2 = i_sn2 ? -i_sg2 : i_sg2;

	o_sg = sg1 + sg2;
	o_sn = hw::signb(o_sg);
	o_zero = (o_sg == 0);

	o_sg = o_sn ? -o_sg : o_sg;
}


} // namespace hwfp
