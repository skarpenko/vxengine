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
 * Driver backend interface
 */

#include <cstdint>
#pragma once


struct VxeBinding {
	int32_t bufferId;	// Buffer Id
	uint32_t index;		// Index of fp32 value within the buffer
	explicit VxeBinding(int32_t id = -1)
		: bufferId(id), index(0)
	{}
};


// Driver backend interface (SW emul., Kernel driver, etc.)
class VxeDriverBackend {
public:
	VxeDriverBackend() = default;
	virtual ~VxeDriverBackend() = default;

	VxeDriverBackend(const VxeDriverBackend&) = delete;
	VxeDriverBackend& operator=(const VxeDriverBackend&) = delete;

	// Return available devices count
	virtual uint32_t devicesCount() const = 0;

	// Device open / close API
	virtual int deviceOpen(uint32_t no) = 0;
	virtual int deviceClose(int fd) = 0;
	virtual int deviceGetinfo(int fd, uint32_t *hwid, uint32_t *vpus) = 0;

	// Buffer API
	virtual int bufferCreate(int fd, uint32_t size, int map, int32_t *out_id, void **out_vaddr) = 0;
	virtual int bufferDestroy(int fd, int32_t id) = 0;
	virtual int bufferMap(int fd, int32_t id, void **out_vaddr) = 0;
	virtual int bufferUnmap(int fd, int32_t id) = 0;

	// Command buffer API
	virtual int cmdBufferCreate(int fd, uint64_t *program, uint32_t program_len,
		VxeBinding *bindings, uint32_t bindings_len, int32_t *out_id) = 0;
	virtual int cmdBufferRunpgm(int fd, int32_t id, uint64_t *out_fence) = 0;
	virtual int cmdBufferUpdate(int fd, int32_t id, VxeBinding *bindings, uint32_t bindings_len) = 0;

	// Synchronization API
	virtual int fenceWait(int fd, uint64_t fence) = 0;
};
