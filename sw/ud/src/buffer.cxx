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
 * Buffer
 */

#include <new>
#include "error.hxx"
#include "context.hxx"
#include "buffer.hxx"


Buffer::Buffer()
{}


VxResult Buffer::init(const VxBufferCreateInfo& createInfo)
{
	Context *ctx = reinterpret_cast<Context*>(createInfo.context);

	m_drv = ctx->getDrv();
	m_fd = ctx->getFd();
	m_vaddr = nullptr;

	uint32_t size = createInfo.rows * createInfo.cols * sizeof(float);

	int res = m_drv->bufferCreate(m_fd, size, createInfo.map, &m_id, &m_vaddr);
	if(res != 0)
		return errnoToVxResult(res, VX_ERROR_MMAP_FAILED);

	return VX_SUCCESS;
}


VxResult Buffer::deinit()
{
	int res = m_drv->bufferDestroy(m_fd, m_id);

	if(res != 0)
		return errnoToVxResult(res);

	return VX_SUCCESS;
}


VxResult Buffer::map(VxFloat** pCpuAddr)
{
	if(m_vaddr != nullptr) {
		*pCpuAddr = static_cast<VxFloat*>(m_vaddr);
		return VX_SUCCESS;
	}

	int res = m_drv->bufferMap(m_fd, m_id, &m_vaddr);
	if(res != 0)
		return errnoToVxResult(res);

	*pCpuAddr = static_cast<VxFloat*>(m_vaddr);

	return VX_SUCCESS;
}


VxResult Buffer::unmap()
{
	if(m_vaddr == nullptr)
		return VX_SUCCESS;

	m_vaddr = nullptr;

	int res = m_drv->bufferUnmap(m_fd, m_id);
	if(res != 0)
		return errnoToVxResult(res);

	return VX_SUCCESS;
}


VxResult vxCreateBuffer(VxBufferCreateInfo* pCreateInfo, VxBuffer* pBuffer, VxFloat** pCpuAddr)
{
	VxResult res;

	Buffer *buf = new(std::nothrow) Buffer();
	if(buf == nullptr)
		return VX_ERROR_NO_MEMORY;

	res = buf->init(*pCreateInfo);
	if(res != VX_SUCCESS) {
		delete buf;
		return res;
	}

	if(pCreateInfo->map)
		buf->map(pCpuAddr);

	*pBuffer = reinterpret_cast<VxBuffer>(buf);

	return VX_SUCCESS;
}


VxResult vxDestroyBuffer(VxBuffer buffer)
{
	Buffer *buf = reinterpret_cast<Buffer*>(buffer);

	VxResult res = buf->deinit();
	if(res != VX_SUCCESS)
		return res;

	delete buf;

	return VX_SUCCESS;
}


VxResult vxMapBuffer(VxBuffer buffer, VxFloat** pCpuAddr)
{
	Buffer *buf = reinterpret_cast<Buffer*>(buffer);
	return buf->map(pCpuAddr);
}


VxResult vxUnmapBuffer(VxBuffer buffer)
{
	Buffer *buf = reinterpret_cast<Buffer*>(buffer);
	return buf->unmap();
}
