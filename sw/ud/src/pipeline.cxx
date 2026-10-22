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

#define DEBUG_PREFIX "[pipeline] "

#include <new>
#include <iostream>
#include <fstream>
#include <sstream>
#include "error.hxx"
#include "context.hxx"
#include "codegen.hxx"
#include "buffer.hxx"
#include "debug.hxx"
#include "pipeline.hxx"


namespace {

VxeBinding descToBinding(const VxVectorDesc& v)
{
	Buffer *buf = reinterpret_cast<Buffer*>(v.buffer);

	VxeBinding binding(buf->getId());
	binding.index = v.offset;

	return binding;
}

VxeBinding descToBinding(const VxMatrixDesc& m)
{
	Buffer *buf = reinterpret_cast<Buffer*>(m.buffer);

	VxeBinding binding(buf->getId());
	binding.index = m.offset;

	return binding;
}

enum SpecType {
	SPEC_NONE,
	SPEC_RELU,
	SPEC_LRELU
};

bool parseSpecial(const VxPipelineSpecialOp *s, SpecType& st, int& ned)
{
	bool res = true;

	st = SPEC_NONE;
	ned = 0;

	if(s) {
		if(s->opType == VX_PIPELINE_SPECIAL_OPTYPE_RELU) {
			st = SPEC_RELU;
		} else if(s->opType == VX_PIPELINE_SPECIAL_OPTYPE_LRELU) {
			const VxPipelineSpecialOpLReLU *lr = reinterpret_cast<const VxPipelineSpecialOpLReLU*>(s);
			st = SPEC_LRELU;
			ned = lr->negExpD;
		} else
			res = false;
	}

	return res;
}

void finishBatch(CodeGenerator& cg, SpecType st, int ned)
{
	cg.finalize();

	cg.execProd();

	switch(st) {
		case SPEC_RELU:
			cg.execRELU();
			break;
		case SPEC_LRELU:
			cg.execLRELU(ned);
			break;
		default:
			break;
	}

	cg.execStore();
}

void debugDumpProgram(void *pipe, const std::vector<uint64_t>& prog)
{
	if(!vxe_drv_debug_dump)
		return;

	std::stringstream fn;
	fn << pipe << "_prog.bin";

	std::ofstream f(fn.str(), std::ios::out | std::ios::binary);
	f.write(reinterpret_cast<const char*>(prog.data()), prog.size() * sizeof(uint64_t));
	f.close();
}

void debugDumpBindings(void *pipe, const std::vector<VxeBinding>& bind)
{
	if(!vxe_drv_debug_dump)
		return;

	std::stringstream fn;
	fn << pipe << "_bind.txt";

	std::ofstream f(fn.str(), std::ios::out);
	for(size_t i = 0; i < bind.size(); ++i) {
		f << "Binding No. " << i << ":"
			<< " BufferId=" << bind[i].bufferId
			<< ", Index=" << bind[i].index
			<< std::endl;
	}
	f.close();
}

} // namespace


VxResult Pipeline::verifVec(const VxVectorDesc& v)
{
	Buffer *buf = reinterpret_cast<Buffer*>(v.buffer);

	if(v.length > MAX_VEC_LEN)
		return VX_ERROR_INVALID;

	uint32_t last_idx = v.offset + v.length - 1;
	if(last_idx >= buf->getLength())
		return VX_ERROR_OUT_OF_RANGE;

	return VX_SUCCESS;
}


VxResult Pipeline::verifMtx(const VxMatrixDesc& m)
{
	Buffer *buf = reinterpret_cast<Buffer*>(m.buffer);

	if(m.cols > MAX_VEC_LEN)
		return VX_ERROR_INVALID;

	uint32_t last_idx = m.offset + m.rows * m.cols - 1;
	if(last_idx >= buf->getLength())
		return VX_ERROR_OUT_OF_RANGE;

	return VX_SUCCESS;
}


VxResult Pipeline::verifVxV(const VxPipelineStageVxV& stage)
{
	VxResult res = VX_SUCCESS;

	for(uint32_t i = 0; i < stage.nDescriptors; ++i) {
		res = verifVec(stage.pSrc1[i]);
		if(res != VX_SUCCESS) {
			debug_printf("VxV, Src1[%u] descriptor check failed.\n", i);
			break;
		}
		res = verifVec(stage.pSrc2[i]);
		if(res != VX_SUCCESS) {
			debug_printf("VxV, Src2[%u] descriptor check failed.\n", i);
			break;
		}
		res = verifVec(stage.pDst[i]);
		if(res != VX_SUCCESS) {
			debug_printf("VxV, Dst[%u] descriptor check failed.\n", i);
			break;
		}
		if(stage.pSrc1[i].length != stage.pSrc2[i].length) {
			debug_printf("VxV, Src1/Src2[%u] length mismatch.\n", i);
			res = VX_ERROR_INVALID;
			break;
		}
		if(stage.pBias) {
			if(stage.pBias[i].cols != 1 || stage.pBias[i].rows != 1) {
				debug_printf("VxV, Bias[%u] data dimensions check failed.\n", i);
				res = VX_ERROR_INVALID;
				break;
			}
		}
	}

	return res;
}


VxResult Pipeline::verifMxV(const VxPipelineStageMxV& stage)
{
	VxResult res = VX_SUCCESS;

	for(uint32_t i = 0; i < stage.nDescriptors; ++i) {
		res = verifMtx(stage.pSrc1[i]);
		if(res != VX_SUCCESS) {
			debug_printf("MxV, Src1[%u] descriptor check failed.\n", i);
			break;
		}
		res = verifVec(stage.pSrc2[i]);
		if(res != VX_SUCCESS) {
			debug_printf("MxV, Src2[%u] descriptor check failed.\n", i);
			break;
		}
		res = verifVec(stage.pDst[i]);
		if(res != VX_SUCCESS) {
			debug_printf("MxV, Dst[%u] descriptor check failed.\n", i);
			break;
		}
		if(stage.pSrc1[i].cols != stage.pSrc2[i].length) {
			debug_printf("MxV, Src1/Src2[%u] dimensions mismatch.\n", i);
			res = VX_ERROR_INVALID;
			break;
		}
		if(stage.pDst[i].length < stage.pSrc1[i].rows) {
			debug_printf("MxV, Dst[%u] has not enough space.\n", i);
			res = VX_ERROR_INVALID;
			break;
		}
		if(stage.pBias) {
			if(stage.pBias[i].cols != 1 || stage.pBias[i].rows != stage.pSrc1[i].rows) {
				debug_printf("MxV, Bias[%u] data dimensions check failed.\n", i);
				res = VX_ERROR_INVALID;
				break;
			}
		}
	}

	return res;
}


VxResult Pipeline::verifMxM(const VxPipelineStageMxM& stage)
{
	VxResult res = VX_SUCCESS;

	for(uint32_t i = 0; i < stage.nDescriptors; ++i) {
		res = verifMtx(stage.pSrc1[i]);
		if(res != VX_SUCCESS) {
			debug_printf("MxM, Src1[%u] descriptor check failed.\n", i);
			break;
		}
		res = verifMtx(stage.pSrc2_T[i]);
		if(res != VX_SUCCESS) {
			debug_printf("MxM, Src2[%u] descriptor check failed.\n", i);
			break;
		}
		res = verifMtx(stage.pDst[i]);
		if(res != VX_SUCCESS) {
			debug_printf("MxM, Dst[%u] descriptor check failed.\n", i);
			break;
		}
		if(stage.pSrc1[i].cols != stage.pSrc2_T[i].cols) {
			debug_printf("MxM, Src1/Src2[%u] dimensions mismatch.\n", i);
			res = VX_ERROR_INVALID;
			break;
		}
		if(stage.pDst[i].rows != stage.pSrc1[i].rows || stage.pDst[i].cols != stage.pSrc2_T[i].rows) {
			debug_printf("MxM, Dst[%u] has wrong dimensions.\n", i);
			res = VX_ERROR_INVALID;
			break;
		}
		if(stage.pBias) {
			if(stage.pBias[i].rows != stage.pSrc1[i].rows || stage.pBias[i].cols != stage.pSrc2_T[i].rows) {
				debug_printf("MxM, Bias[%u] data dimensions check failed.\n", i);
				res = VX_ERROR_INVALID;
				break;
			}
		}
	}

	return res;
}


void Pipeline::compileVxV(CodeGenerator& cg, const VxPipelineStageVxV& stage)
{
	SpecType st;
	int ned;

	if(!parseSpecial(stage.pSpecialOp, st, ned)) {
		debug_printf("VxV, malformed specialOp field.\n");
	}

	for(uint32_t i = 0; i < stage.nDescriptors; ++i) {
		float bias = stage.pBias ? stage.pBias[i].pValue[0] : 0.0f;
		VxeBinding rs = descToBinding(stage.pSrc1[i]);
		VxeBinding rt = descToBinding(stage.pSrc2[i]);
		VxeBinding rd = descToBinding(stage.pDst[i]);
		size_t len = stage.pSrc1[i].length;

		if(!cg.allocThread(bias, rs, rt, rd, len)) {
			finishBatch(cg, st, ned);
			cg.allocThread(bias, rs, rt, rd, len);
		}
	}

	finishBatch(cg, st, ned);
}


void Pipeline::compileMxV(CodeGenerator& cg, const VxPipelineStageMxV& stage)
{
	SpecType st;
	int ned;

	if(!parseSpecial(stage.pSpecialOp, st, ned)) {
		debug_printf("MxV, malformed specialOp field.\n");
	}

	for(uint32_t i = 0; i < stage.nDescriptors; ++i) {
		VxeBinding rs = descToBinding(stage.pSrc1[i]);
		VxeBinding rt = descToBinding(stage.pSrc2[i]);
		VxeBinding rd = descToBinding(stage.pDst[i]);
		size_t len = stage.pSrc1[i].cols;

		for(uint32_t r = 0; r < stage.pSrc1[i].rows; ++r) {
			float bias = stage.pBias ? stage.pBias[i].pValue[r] : 0.0f;

			if(!cg.allocThread(bias, rs, rt, rd, len)) {
				finishBatch(cg, st, ned);
				cg.allocThread(bias, rs, rt, rd, len);
			}

			rs.index += stage.pSrc1[i].cols;
			rd.index += 1;
		}
	}

	finishBatch(cg, st, ned);
}


void Pipeline::compileMxM(CodeGenerator& cg, const VxPipelineStageMxM& stage)
{
	SpecType st;
	int ned;

	if(!parseSpecial(stage.pSpecialOp, st, ned)) {
		debug_printf("MxM, malformed specialOp field.\n");
	}

	for(uint32_t i = 0; i < stage.nDescriptors; ++i) {
		VxeBinding rs = descToBinding(stage.pSrc1[i]);
		VxeBinding rt = descToBinding(stage.pSrc2_T[i]);
		VxeBinding rd = descToBinding(stage.pDst[i]);
		size_t len = stage.pSrc1[i].cols;

		for(uint32_t rl = 0; rl < stage.pSrc1[i].rows; ++rl) {
			VxeBinding rt2 = rt;
			for(uint32_t rr = 0; rr < stage.pSrc2_T[i].rows; ++rr) {
				float bias = stage.pBias ? stage.pBias[i].pValue[rr * stage.pSrc2_T[i].rows + rr] : 0.0f;

				if(!cg.allocThread(bias, rs, rt2, rd, len)) {
					finishBatch(cg, st, ned);
					cg.allocThread(bias, rs, rt2, rd, len);
				}

				rt2.index += stage.pSrc2_T[i].cols;
				rd.index += 1;
			}
			rs.index += stage.pSrc1[i].cols;
		}
	}

	finishBatch(cg, st, ned);
}


Pipeline::Pipeline()
{}


VxResult Pipeline::init(const VxPipelineCreateInfo& createInfo)
{
	Context *ctx = reinterpret_cast<Context*>(createInfo.context);

	m_drv = ctx->getDrv();
	m_fd = ctx->getFd();

	// Verify inputs
	for(VxSize i = 0; i < createInfo.nStages; ++i) {
		VxResult err;
		switch(createInfo.ppStages[i]->stageType) {
			case VX_PIPELINE_STAGE_TYPE_VXV:
				err = verifVxV(*reinterpret_cast<const VxPipelineStageVxV*>(createInfo.ppStages[i]));
				break;
			case VX_PIPELINE_STAGE_TYPE_MXV:
				err = verifMxV(*reinterpret_cast<const VxPipelineStageMxV*>(createInfo.ppStages[i]));
				break;
			case VX_PIPELINE_STAGE_TYPE_MXM:
				err = verifMxM(*reinterpret_cast<const VxPipelineStageMxM*>(createInfo.ppStages[i]));
				break;
			default:
				err = VX_ERROR_INVALID;
		}
		if(err != VX_SUCCESS)
			return err;
	}

	// Generate program and create command buffer
	try {
		CodeGenerator codeGen(ctx->getVPUs(), ctx->getVPUMask());
		codeGen.prepare();
		for(VxSize i = 0; i < createInfo.nStages; ++i) {
			switch(createInfo.ppStages[i]->stageType) {
				case VX_PIPELINE_STAGE_TYPE_VXV:
					compileVxV(codeGen, *reinterpret_cast<const VxPipelineStageVxV*>(createInfo.ppStages[i]));
					break;
				case VX_PIPELINE_STAGE_TYPE_MXV:
					compileMxV(codeGen, *reinterpret_cast<const VxPipelineStageMxV*>(createInfo.ppStages[i]));
					break;
				case VX_PIPELINE_STAGE_TYPE_MXM:
					compileMxM(codeGen, *reinterpret_cast<const VxPipelineStageMxM*>(createInfo.ppStages[i]));
					break;
				default:
					return VX_ERROR_UNKNOWN;
			}
		}

		// Debug dumps
		debugDumpProgram(this, codeGen.program);
		debugDumpBindings(this, codeGen.bindings);

		// Create command buffer
		int res = m_drv->cmdBufferCreate(m_fd, codeGen.program.data(), static_cast<uint32_t>(codeGen.program.size()),
				codeGen.bindings.data(), static_cast<uint32_t>(codeGen.bindings.size()), &m_id);
		if(res != 0)
			return errnoToVxResult(res);
	}
	catch(const std::bad_alloc& e)
	{
		return VX_ERROR_NO_MEMORY;
	}
	catch(...)
	{
		return VX_ERROR_UNKNOWN;
	}

	return VX_SUCCESS;
}


VxResult Pipeline::deinit()
{
	int res = m_drv->bufferDestroy(m_fd, m_id);

	if(res != 0)
		return errnoToVxResult(res);

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
