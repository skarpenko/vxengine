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
 * Utilities
 */

#include <utility>
#include <memory>
#pragma once


namespace ut {

	/**
	 * Scope guard
	 */
	class scope_guard {
		// Internal implementation base
		class impl_base {
		public:
			virtual ~impl_base() = default;
			virtual void release() = 0;
		};

		// Internal implementation
		template<class Callable>
		class impl: public impl_base {
			Callable m_c;
		public:
			impl(Callable&& c) : m_c(std::forward<Callable>(c)) { }
			void release() override {
				m_c();
			}
		};

		std::shared_ptr<impl_base> m_c;
	public:
		/**
		 * Constructor
		 * @tparam Callable callable type
		 * @param c callable object to call on release
		 */
		template<class Callable>
		scope_guard(Callable&& c)
		{
			m_c = std::make_shared<impl<Callable>>(std::forward<Callable>(c));
		}
		scope_guard(scope_guard&& other) noexcept { *this = std::move(other); }
		scope_guard(const scope_guard&) = delete;
		scope_guard& operator=(const scope_guard&) = delete;
		scope_guard& operator=(const scope_guard&& other) noexcept {
			if(this != &other) {
				m_c = std::move(other.m_c);
			}
			return *this;
		}
		~scope_guard() { m_c->release(); }
	};


} // namespace ut
