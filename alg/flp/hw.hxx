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
 * Basic bit manipulation operations
 */

#include <type_traits>
#pragma once


namespace hw {


/**
 * extr - extract bit field
 *
 * @tparam T integral type
 * @param a input value
 * @param h most significant bit of the field
 * @param l least significant bit of the field
 * @return field value
 */
template<typename T>
T extr(T a, unsigned h, unsigned l)
{
	static_assert(std::is_integral<T>::value, "T must be an integral type.");
	T mask = (T(1) << (h - l + 1)) - 1;
	mask <<= l;
	return (a & mask) >> l;
}


/**
 * insr - insert bit field
 *
 * @tparam T integral type
 * @param a input value to insert into
 * @param v value to insert
 * @param h most significant bit of the field
 * @param l least significant bit of the field
 * @return new value of a
 */
template<typename T>
T insr(T a, T v, unsigned h, unsigned l)
{
	static_assert(std::is_integral<T>::value, "T must be an integral type.");
	T mask = (T(1) << (h - l + 1)) - 1;
	v &= mask;
	mask <<= l;
	a &= ~mask;
	a |= v << l;
	return a;
}


/**
 * setb - set bit
 *
 * @tparam T integral type
 * @param a input value to set bit into
 * @param bit bit position
 * @param v bit value
 * @return new value of a
 */
template<typename T>
T setb(T a, unsigned bit, bool v)
{
	static_assert(std::is_integral<T>::value, "T must be an integral type.");
	T mask = T(1) << bit;
	return v ? a | mask : a & ~mask;
}


/**
 * bit - get bit value
 *
 * @tparam T integral type
 * @param a input value
 * @param bit bit position
 * @return bit value
 */
template<typename T>
bool bit(T a, unsigned bit)
{
	static_assert(std::is_integral<T>::value, "T must be an integral type.");
	T mask = T(1) << bit;
	return (a & mask) != 0;
}


/**
 * orr - OR reduction
 *
 * @tparam T integral type
 * @param a input value
 * @param h most significant bit for OR reduction
 * @param l least significant bit for OR reduction
 * @return new value of a
 */
template<typename T>
bool orr(T a, unsigned h, unsigned l)
{
	static_assert(std::is_integral<T>::value, "T must be an integral type.");
	T mask = (T(1) << (h - l + 1)) - 1;
	mask <<= l;
	return (a & mask) != 0;
}


/**
 * andr - AND reduction
 *
 * @tparam T integral type
 * @param a input value
 * @param h most significant bit for AND reduction
 * @param l least significant bit for AND reduction
 * @return new value of a
 */
template<typename T>
bool andr(T a, unsigned h, unsigned l)
{
	static_assert(std::is_integral<T>::value, "T must be an integral type.");
	T mask = (T(1) << (h - l + 1)) - 1;
	mask <<= l;
	return (a & mask) == mask;
}


/**
 * msb - get position of most significant bit
 *
 * @tparam T integral type
 * @param a input value
 * @return position or -1 if a is zero
 */
template<typename T>
int msb(T a)
{
	static_assert(std::is_integral<T>::value, "T must be an integral type.");
	int t = 8 * sizeof(T) - 1;
	T mask = T(1) << t;
	while(mask) {
		if (a & mask)
			return t;
		--t;
		mask >>= 1;
	}
	return -1;
}


/**
 * signb - get value of a sign bit
 *
 * @tparam T integral type
 * @param a input value
 * @return sign bit value
 */
template<typename T>
bool signb(T a)
{
	int t = 8 * sizeof(T) - 1;
	T mask = T(1) << t;
	return (a & mask) != 0;
}


} // namespace hw
