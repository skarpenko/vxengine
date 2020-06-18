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
 * TLM payloads management
 */

#include "tlm_payload.hxx"


// Private namespace
namespace {

	/**
	 * TLM generic payload memory manager
	 */
	class tlm_gp_mm: public tlm::tlm_mm_interface {
	public:
		void free(tlm::tlm_generic_payload *pl) override
		{
			unsigned char *data_ptr = pl->get_data_ptr();
			pl->reset();
			if(data_ptr)
				delete [] data_ptr;
			delete pl;
		}
	};
	// Private MM instance
	tlm_gp_mm mm;

} // Private namespace


tlm::tlm_generic_payload* tlm_pl::alloc_gp(size_t data_size)
{
	tlm::tlm_generic_payload *pl = new tlm::tlm_generic_payload(&mm);
	unsigned char *data_ptr = nullptr;

	pl->acquire();	// ++ref_count

	try {
		if(data_size)
			data_ptr = new unsigned char[data_size];
	}
	catch(...) {
		pl->release();
		throw;
	}

	pl->set_data_ptr(data_ptr);

	return pl;
}
