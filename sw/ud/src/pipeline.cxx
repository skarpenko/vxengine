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
 * Pipeline
 */

#include <new>
#include "error.hxx"
#include "context.hxx"
#include "pipeline.hxx"


Pipeline::Pipeline()
{}


VxResult Pipeline::init(const VxPipelineCreateInfo& createInfo)
{
	Context *ctx = reinterpret_cast<Context*>(createInfo.context);

	m_drv = ctx->getDrv();
	m_fd = ctx->getFd();

	//TODO:
	// 1. verify resources, generate program, create cmd buffer?
	// 2. pipeline compiler class?

	return VX_SUCCESS;
}


VxResult Pipeline::deinit()
{
	return VX_SUCCESS;
}


VxResult vxCreatePipeline(VxPipelineCreateInfo* pCreateInfo, VxPipeline* pPipeline)
{
	VxResult res;

	Pipeline *pipe = new(std::nothrow) Pipeline();
	if(pipe == nullptr)
		return VX_ERROR_NO_MEMORY;

	res = pipe->init(*pCreateInfo);
	if(res != VX_SUCCESS) {
		delete pipe;
		return res;
	}

	*pPipeline = reinterpret_cast<VxPipeline>(pipe);

	return VX_SUCCESS;
}


VxResult vxDestroyPipeline(VxPipeline pipeline)
{
	Pipeline *pipe = reinterpret_cast<Pipeline*>(pipeline);

	VxResult res = pipe->deinit();
	if(res != VX_SUCCESS)
		return res;

	delete pipe;

	return VX_SUCCESS;
}


VxResult vxPipelineRun(VxPipeline pipeline, VxFence* pFence)
{
	Pipeline *pipe = reinterpret_cast<Pipeline*>(pipeline);

	int res = pipe->getDrv()->cmdBufferRunpgm(pipe->getFd(), pipe->getId(), pFence);
	if(res != 0)
		return errnoToVxResult(res);

	return VX_SUCCESS;
}


VxResult vxFenceWait(VxPipeline pipeline, VxFence fence)
{
	Pipeline *pipe = reinterpret_cast<Pipeline*>(pipeline);

	int res = pipe->getDrv()->fenceWait(pipe->getFd(), fence);
	if(res != 0)
		return errnoToVxResult(res);

	return VX_SUCCESS;
}
