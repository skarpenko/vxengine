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
 * Vector utilities
 */

#pragma once


namespace sw {

	/**
	 * Generate vector of Fibonacci-like sequence
	 * @tparam T type of vector elements
	 * @param n1 starting condition 1
	 * @param n2 starting condition 2
	 * @param out output vector
	 * @param len output vector length
	 */
	template<typename T>
	void gen_vector0(T n1, T n2, T *out, size_t len)
	{
		for(size_t i = 0; i < len; ++i) {
			out[i] = n1 + n2;
			n1 = n2;
			n2 = out[i];
		}
	}

	/**
	 * Generate a vector of a numeric sequence
	 * @tparam T type of vector elements
	 * @param n0 starting condition 0 (must not be zero)
	 * @param n1 starting condition 1
	 * @param n2 starting condition 2
	 * @param out output vector
	 * @param len output vector length
	 */
	template<typename T>
	void gen_vector1(T n0, T n1, T n2, T *out, size_t len)
	{
		for(size_t i = 0; i < len; ++i) {
			out[i] = (n1 + n2) / n0;
			n0 = n1;
			n1 = n2;
			n2 = out[i];
		}
	}

	/**
	 * Generate a vector of a numeric sequence
	 * @tparam T type of vector elements
	 * @param n0 starting condition 0
	 * @param n1 starting condition 1 (must not be zero)
	 * @param n2 starting condition 2
	 * @param n3 starting condition 3
	 * @param out output vector
	 * @param len output vector length
	 */
	template<typename T>
	void gen_vector2(T n0, T n1, T n2, T n3, T *out, size_t len)
	{
		for(size_t i = 0; i < len; ++i) {
			out[i] = (n2 + n3) / n1 - n0;
			n0 = n1;
			n1 = n2;
			n2 = n3;
			n3 = out[i];
		}
	}

	/**
	 * Generate a vector of a linear numeric sequence
	 * @tparam T type of vector elements
	 * @param n0 start value
	 * @param s step
	 * @param out output vector
	 * @param len output vector length
	 */
	template<typename T>
	void gen_vector_linear(T n0, T s, T *out, size_t len)
	{
		for(size_t i = 0; i < len; ++i) {
			out[i] = n0;
			n0 += s;
		}
	}

} // namespace sw
