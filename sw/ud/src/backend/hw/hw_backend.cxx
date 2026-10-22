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
 * Hardware backend implementation
 */

#include <vxe_ioctl.h>
#include "hw_backend.hxx"


HwDriverBackend::HwDriverBackend()
{

}


HwDriverBackend::~HwDriverBackend()
{

}


uint32_t HwDriverBackend::devicesCount() const
{
	return 0;
}


int HwDriverBackend::deviceOpen(uint32_t no)
{
	//TODO: need to check errno for error code after ioctl call
	return 0;
}


int HwDriverBackend::deviceClose(int fd)
{
	return 0;
}


int HwDriverBackend::deviceGetinfo(int fd, uint32_t *hwid, uint32_t *vpus)
{
	return 0;
}


int HwDriverBackend::bufferCreate(int fd, uint32_t size, int map, int32_t *out_id, void **out_vaddr)
{
	return 0;
}


int HwDriverBackend::bufferDestroy(int fd, int32_t id)
{
	return 0;
}


int HwDriverBackend::bufferMap(int fd, int32_t id, void **out_vaddr)
{
	return 0;
}


int HwDriverBackend::bufferUnmap(int fd, int32_t id)
{
	return 0;
}


int HwDriverBackend::cmdBufferCreate(int fd, uint64_t *program, uint32_t program_len,
	VxeBinding *bindings, uint32_t bindings_len, int32_t *out_id)
{
	return 0;
}


int HwDriverBackend::cmdBufferRunpgm(int fd, int32_t id, uint64_t *out_fence)
{
	return 0;
}


int HwDriverBackend::cmdBufferUpdate(int fd, int32_t id, VxeBinding *bindings, uint32_t bindings_len)
{
	return 0;
}


int HwDriverBackend::fenceWait(int fd, uint64_t fence)
{
	return 0;
}
