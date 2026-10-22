/*
 * Copyright (c) 2020-2026 The VxEngine Project. All rights reserved.
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
 * Hardware backend interface
 */

#include "../../backend.hxx"
#pragma once


class HwDriverBackend: public VxeDriverBackend {
public:
	HwDriverBackend();
	virtual ~HwDriverBackend();

	virtual uint32_t devicesCount() const;

	virtual int deviceOpen(uint32_t no);
	virtual int deviceClose(int fd);
	virtual int deviceGetinfo(int fd, uint32_t *hwid, uint32_t *vpus);

	virtual int bufferCreate(int fd, uint32_t size, int map, int32_t *out_id, void **out_vaddr);
	virtual int bufferDestroy(int fd, int32_t id);
	virtual int bufferMap(int fd, int32_t id, void **out_vaddr);
	virtual int bufferUnmap(int fd, int32_t id);

	virtual int cmdBufferCreate(int fd, uint64_t *program, uint32_t program_len,
		VxeBinding *bindings, uint32_t bindings_len, int32_t *out_id);
	virtual int cmdBufferRunpgm(int fd, int32_t id, uint64_t *out_fence);
	virtual int cmdBufferUpdate(int fd, int32_t id, VxeBinding *bindings, uint32_t bindings_len);

	virtual int fenceWait(int fd, uint64_t fence);
};
