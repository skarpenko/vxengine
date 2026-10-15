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
 * Software emulation backend implementation
 */

#include <cstring>
#include <new>
#include <errno.h>
#include "swemu_backend.hxx"
#include "swemu_impl.hxx"
#include "swemu_prog.hxx"


namespace {
	const uint32_t DEVICES_COUNT = 1;
	const uint32_t DEVICE_HWID = 0xFEFEFAF0;
	const int MAX_CONTEXTS = 32;
	const int MAX_BUFFERS = 1024;
	const uint32_t DEFAULT_VPU_MASK = 3;
}


SwEmuBuffer::SwEmuBuffer(int id, uint32_t size)
	: m_id(id), m_data(nullptr), m_size(0), m_bindCount(0), m_valid(false)
{
	if(size) {
		char *p = new(std::nothrow) char[size];
		if(p != nullptr) {
			m_data = static_cast<void*>(p);
			m_size = size;
			m_valid = true;
		}
	}
}


SwEmuBuffer::~SwEmuBuffer()
{
	char *p = static_cast<char*>(m_data);
	delete[] p;
}


SwEmuDataBuffer::SwEmuDataBuffer(int id, uint32_t length)
	: SwEmuBuffer(id, length * sizeof(float))
{}


SwEmuCmdBuffer::SwEmuCmdBuffer(int id, uint32_t progLen, uint32_t resLen)
	: SwEmuBuffer(id, progLen * sizeof(uint64_t)), m_resLen(resLen), m_res(nullptr)
{
	if(!m_valid || !m_resLen)
		return;

	m_res = new(std::nothrow) R[m_resLen];
	if(m_res == nullptr) {
		m_valid = false;
		return;
	}
}


SwEmuCmdBuffer::~SwEmuCmdBuffer()
{
	delete[] m_res;
}


SwEmuContext::SwEmuContext(uint32_t devId, int fd, int maxBufs, uint32_t vpumask, bool use_mt)
	: m_devId(devId), m_fd(fd), m_idMan(maxBufs)
	, m_executor(vpumask, use_mt)
{}


SwEmuContext::~SwEmuContext()
{
	for(const auto& kv : m_buffers)
		delete kv.second;
}


bool SwEmuContext::insertBuffer(SwEmuBuffer *buffer)
{
	if(buffer == nullptr)
		return false;

	try {
		auto res = m_buffers.insert({buffer->id(), buffer});
		return res.second;
	}
	catch(...)
	{
		return false;
	}
}


SwEmuBuffer *SwEmuContext::getBuffer(int id)
{
	auto it = m_buffers.find(id);
	if(it == m_buffers.end())
		return nullptr;
	else
		return it->second;
}


bool SwEmuContext::deleteBuffer(int id, bool dealloc)
{
	SwEmuBuffer *buf = getBuffer(id);
	if(buf == nullptr)
		return false;
	m_buffers.erase(id);
	m_idMan.free(id);
	if(dealloc)
		delete buf;
	return true;
}


SwEmuDriverBackendImpl::SwEmuDriverBackendImpl(int maxContexts)
	: m_fdMan(maxContexts)
{}


SwEmuDriverBackendImpl::~SwEmuDriverBackendImpl()
{
	for(const auto& kv : m_contexts)
		delete kv.second;
}


bool SwEmuDriverBackendImpl::insertContext(SwEmuContext *context)
{
	if(context == nullptr)
		return false;

	try {
		auto res = m_contexts.insert({context->fd(), context});
		return res.second;
	}
	catch(...)
	{
		return false;
	}
}


SwEmuContext *SwEmuDriverBackendImpl::getContext(int fd)
{
	auto it = m_contexts.find(fd);
	if(it == m_contexts.end())
		return nullptr;
	else
		return it->second;
}


bool SwEmuDriverBackendImpl::deleteContext(int fd, bool dealloc)
{
	SwEmuContext *ctx = getContext(fd);
	if(ctx == nullptr)
		return false;
	m_contexts.erase(fd);
	m_fdMan.free(fd);
	if(dealloc)
		delete ctx;
	return true;
}


SwEmuDriverBackend::SwEmuDriverBackend(bool use_mt)
	: m_MT(use_mt)
{
	m_impl = new(std::nothrow) SwEmuDriverBackendImpl(MAX_CONTEXTS);
}


SwEmuDriverBackend::~SwEmuDriverBackend()
{
	delete m_impl;
}


uint32_t SwEmuDriverBackend::devicesCount() const
{
	return DEVICES_COUNT;
}


int SwEmuDriverBackend::deviceOpen(uint32_t no)
{
	int fd = -1;

	if(m_impl == nullptr || no >= DEVICES_COUNT)
		return fd;

	fd = m_impl->allocFd();
	if(fd < 0)
		return fd;

	SwEmuContext *ctx = new(std::nothrow) SwEmuContext(no, fd, MAX_BUFFERS, DEFAULT_VPU_MASK, m_MT);
	if(!m_impl->insertContext(ctx)) {
		delete ctx;
		m_impl->deallocFd(fd);
		fd = -1;
	}

	// If multithreading failed when requested - return failure
	if(fd != -1 && m_MT != ctx->isMT()) {
		m_impl->deleteContext(fd, true);
		fd = -1;
	}

	return fd;
}


int SwEmuDriverBackend::deviceClose(int fd)
{
	if(m_impl == nullptr || fd < 0)
		return EBADF;

	if(!m_impl->deleteContext(fd, true))
		return EBADF;

	return 0;
}


int SwEmuDriverBackend::deviceGetinfo(int fd, uint32_t *hwid)
{
	if(m_impl == nullptr || fd < 0 || m_impl->getContext(fd) == nullptr)
		return EBADF;

	*hwid = DEVICE_HWID;

	return 0;
}


int SwEmuDriverBackend::bufferCreate(int fd, uint32_t size, int map, int32_t *out_id, void **out_vaddr)
{
	if(m_impl == nullptr || fd < 0)
		return EBADF;

	SwEmuContext *ctx = m_impl->getContext(fd);
	if(!ctx)
		return EBADF;

	int id = ctx->allocId();
	if(id < 0)
		return ENOSPC;

	SwEmuDataBuffer *buf = new(std::nothrow) SwEmuDataBuffer(id, (size + sizeof(float) - 1) / sizeof(float));
	if(!buf->valid() || !ctx->insertBuffer(buf)) {
		delete buf;
		ctx->deallocId(id);
		return ENOMEM;
	}

	*out_id = id;
	if(map)
		*out_vaddr = buf->data();

	return 0;
}


int SwEmuDriverBackend::bufferDestroy(int fd, int32_t id)
{
	if(m_impl == nullptr || fd < 0)
		return EBADF;

	SwEmuContext *ctx = m_impl->getContext(fd);
	if(!ctx)
		return EBADF;

	SwEmuBuffer *buffer = ctx->getBuffer(id);
	if(!buffer)
		return ENOENT;
	if(buffer->locked())
		return EPERM;

	ctx->deleteBuffer(id, true);

	return 0;
}


int SwEmuDriverBackend::bufferMap(int fd, int32_t id, void **out_vaddr)
{
	if(m_impl == nullptr || fd < 0)
		return EBADF;

	SwEmuContext *ctx = m_impl->getContext(fd);
	if(!ctx)
		return EBADF;

	SwEmuBuffer *buf = ctx->getBuffer(id);
	if(!buf)
		return ENOENT;

	if(isCmdBuffer(buf))
		return EPERM;

	*out_vaddr = buf->data();

	return 0;
}


int SwEmuDriverBackend::bufferUnmap(int fd, int32_t id)
{
	if(m_impl == nullptr || fd < 0)
		return EBADF;

	SwEmuContext *ctx = m_impl->getContext(fd);
	if(!ctx)
		return EBADF;

	SwEmuBuffer *buf = ctx->getBuffer(id);
	if(!buf)
		return ENOENT;

	return 0;
}


int SwEmuDriverBackend::cmdBufferCreate(int fd, uint64_t *program, uint32_t program_len,
	VxeBinding *bindings, uint32_t bindings_len, int32_t *out_id)
{
	if(m_impl == nullptr || fd < 0)
		return EBADF;

	SwEmuContext *ctx = m_impl->getContext(fd);
	if(!ctx)
		return EBADF;

	int id = ctx->allocId();
	if(id < 0)
		return ENOSPC;

	SwEmuCmdBuffer *cbuf = new(std::nothrow) SwEmuCmdBuffer(id, program_len + ProgramAssembler::NRSVD,
		bindings_len);
	if(!cbuf->valid() || !ctx->insertBuffer(cbuf)) {
		delete cbuf;
		ctx->deallocId(id);
		return ENOMEM;
	}

	// Copy buffers (resources)
	for(uint32_t i = 0; i < bindings_len; ++i) {
		SwEmuBuffer *buf = ctx->getBuffer(bindings[i].bufferId);
		if(buf == nullptr) {
			delete cbuf;
			ctx->deallocId(id);
			return ENOENT;
		}
		SwEmuDataBuffer *dbuf = toDataBuffer(buf);
		if(dbuf == nullptr) {
			delete cbuf;
			ctx->deallocId(id);
			return EINVAL;
		}
		cbuf->resData()[i].data = dbuf;
		cbuf->resData()[i].index = bindings[i].index;
	}

	// Copy program
	memcpy(cbuf->progData(), program, program_len * sizeof(uint64_t));

	// Program assembler and verifier
	ProgramAssembler pgmAsm(cbuf);
	int err = pgmAsm.prepareProg();
	if(err) {
			delete cbuf;
			ctx->deallocId(id);
			return err;
	}

	// Bind buffers
	for(uint32_t i = 0; i < cbuf->resLength(); ++i)
		cbuf->resData()[i].data->incBindCount();

	*out_id = id;

	return 0;
}


int SwEmuDriverBackend::cmdBufferRunpgm(int fd, int32_t id, uint64_t *out_fence)
{
	if(m_impl == nullptr || fd < 0)
		return EBADF;

	SwEmuContext *ctx = m_impl->getContext(fd);
	if(!ctx)
		return EBADF;

	SwEmuBuffer *buf = ctx->getBuffer(id);
	if(buf == nullptr)
		return ENOENT;

	SwEmuCmdBuffer *cbuf = toCmdBuffer(buf);
	if(cbuf == nullptr)
		return EINVAL;

	*out_fence = 0;

	ctx->execute(cbuf);

	return 0;
}


int SwEmuDriverBackend::cmdBufferUpdate(int fd, int32_t id, VxeBinding *bindings, uint32_t bindings_len)
{
	if(m_impl == nullptr || fd < 0)
		return EBADF;

	SwEmuContext *ctx = m_impl->getContext(fd);
	if(!ctx)
		return EBADF;

	SwEmuBuffer *buf = ctx->getBuffer(id);
	if(buf == nullptr)
		return ENOENT;

	SwEmuCmdBuffer *cbuf = toCmdBuffer(buf);
	if(cbuf == nullptr)
		return EINVAL;

	// Number of resources must match
	if(cbuf->resLength() != bindings_len)
		return EINVAL;

	// Verify resources first
	for(uint32_t i = 0; i < cbuf->resLength(); ++i) {
		if(cbuf->resData()[i].vlen < 0)
			continue;

		SwEmuBuffer *b = ctx->getBuffer(bindings[i].bufferId);
		if(b == nullptr)
			return ENOENT;
		SwEmuDataBuffer *db = toDataBuffer(b);
		if(db == nullptr)
			return EINVAL;

		uint32_t blen = db->length();
		uint32_t idx = bindings[i].index;

		if(idx > blen)
			return EINVAL;
		if((blen - idx) < static_cast<uint32_t>(cbuf->resData()[i].vlen))
			return EINVAL;
	}

	// Swap resources
	for(uint32_t i = 0; i < cbuf->resLength(); ++i) {
		if(cbuf->resData()[i].vlen < 0)
			continue;

		cbuf->resData()[i].data->decBindCount();
		cbuf->resData()[i].data = toDataBuffer(ctx->getBuffer(bindings[i].bufferId));
		cbuf->resData()[i].data->incBindCount();
		cbuf->resData()[i].index = bindings[i].index;
	}

	return 0;
}


int SwEmuDriverBackend::fenceWait(int fd, uint64_t fence)
{
	// NOTHING TO DO
	return 0;
}
