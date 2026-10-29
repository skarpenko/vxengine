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
 * Context
 */

#include <new>
#include "error.hxx"
#include "device.hxx"
#include "context.hxx"


Context::Context()
{}


VxResult Context::init(const VxContextCreateInfo& createInfo)
{
	Device *dev = reinterpret_cast<Device*>(createInfo.device);

	m_drv = dev->getDrv();
	m_vpus = dev->getVPUs();
	m_vpuMask = createInfo.vpuMask ? createInfo.vpuMask : m_vpus;

	m_fd = m_drv->deviceOpen(dev->getNo());
	if(m_fd < 0)
		return VX_ERROR_NO_DEVICE;

	return VX_SUCCESS;
}


VxResult Context::deinit()
{
	int res = m_drv->deviceClose(m_fd);
	if(res != 0)
		return errnoToVxResult(res);

	return VX_SUCCESS;
}


VxResult vxCreateContext(const VxContextCreateInfo* pCreateInfo, VxContext* pContext)
{
	VxResult res;

	Context *ctx = new(std::nothrow) Context();
	if(ctx == nullptr)
		return VX_ERROR_NO_MEMORY;

	res = ctx->init(*pCreateInfo);
	if(res != VX_SUCCESS) {
		delete ctx;
		return res;
	}

	*pContext = reinterpret_cast<VxContext>(ctx);

	return VX_SUCCESS;
}


VxResult vxDestroyContext(VxContext context)
{
	Context *ctx = reinterpret_cast<Context*>(context);

	VxResult res = ctx->deinit();
	if(res != VX_SUCCESS)
		return res;

	delete ctx;

	return VX_SUCCESS;
}
