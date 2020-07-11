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
 * VxEngine TLM extensions
 */

#include <tlm.h>
#pragma once


namespace vxe {

	/**
	 * VxEngine TLM protocol extension
	 */
	class vxe_tlm_gp_ext : public tlm::tlm_extension<vxe_tlm_gp_ext> {
		unsigned m_tid;	// Transaction ID
	public:
		vxe_tlm_gp_ext() : m_tid(0) {}

		vxe_tlm_gp_ext(const vxe_tlm_gp_ext &) = delete;

		vxe_tlm_gp_ext(vxe_tlm_gp_ext &&) = delete;

		vxe_tlm_gp_ext &operator=(const vxe_tlm_gp_ext &) = delete;

		/**
		 * Clone the extension object
		 * @return cloned extension
		 */
		tlm_extension_base *clone() const override {
			auto *cl = new vxe_tlm_gp_ext();
			cl->copy_from(*this);
			return cl;
		}

		/**
		 * Copy data from other extension object
		 * @param ext source extension
		 */
		void copy_from(const tlm_extension_base &ext) override {
			auto &src = dynamic_cast<const vxe_tlm_gp_ext &>(ext);
			m_tid = src.m_tid;
		}

		/**
		 * Set transaction ID
		 * @param id transaction ID
		 */
		void set_tid(unsigned id) { m_tid = id; }

		/**
		 * Get transaction ID
		 * @return transaction ID
		 */
		unsigned get_tid() const { return m_tid; }
	};

} // namespace vxe
