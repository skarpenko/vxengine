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
 * Simple test application
 */

#include <cstdint>
#include <cstring>
#include <iostream>
#include <vector>
#include <string>
#include <vxengine/vxengine.h>


void testVxV(VxContext context, bool useBias)
{
	const int vec_len = 256;	// Vectors length
	const int num_vop = 100;	// Number of vector operations

	std::cout << "Test: " << __func__ << (useBias ? " (bias)" : "") << std::endl;

	struct Cleaner {
		VxBuffer Rs = VX_NULL_HANDLE;
		VxBuffer Rt = VX_NULL_HANDLE;
		VxBuffer Rd = VX_NULL_HANDLE;
		VxPipeline Pipe = VX_NULL_HANDLE;

		~Cleaner() {
			VxResult res;
			if(Pipe != VX_NULL_HANDLE) {
				res = vxDestroyPipeline(Pipe);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy pipeline!" << std::endl;
			}
			if(Rs != VX_NULL_HANDLE) {
				res = vxDestroyBuffer(Rs);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy Rs buffer!" << std::endl;
			}
			if(Rt != VX_NULL_HANDLE) {
				res = vxDestroyBuffer(Rt);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy Rt buffer!" << std::endl;
			}
			if(Rd != VX_NULL_HANDLE) {
				res = vxDestroyBuffer(Rd);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy Rd buffer!" << std::endl;
			}
		}
	} cl;

	VxResult res;

	// Bias
	VxFloat biasValue = 10.0f;

	// Create buffers
	VxBufferCreateInfo bufferCreateInfo;
	bufferCreateInfo.context = context;
	bufferCreateInfo.cols = vec_len;
	bufferCreateInfo.rows = 1;
	bufferCreateInfo.map = VX_TRUE;

	VxFloat *Rs, *Rt, *Rd;
	VxFloat Ref;

	res = vxCreateBuffer(&bufferCreateInfo, &cl.Rs, &Rs);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create Rs buffer!" << std::endl;
		return;
	}

	res = vxCreateBuffer(&bufferCreateInfo, &cl.Rt, &Rt);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create Rt buffer!" << std::endl;
		return;
	}

	bufferCreateInfo.cols = num_vop;	// Rd contains results for each operation

	res = vxCreateBuffer(&bufferCreateInfo, &cl.Rd, &Rd);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create Rd buffer!" << std::endl;
		return;
	}

	// Generate input data and reference value
	Ref = useBias ? biasValue : 0.0f;
	for(int i = 0; i < vec_len; ++i) {
		Rs[i] = (float)(i + 1);
		Rt[i] = 1.0f / (float)(i + 1);
		Ref += Rs[i] * Rt[i];
	}

	// Create pipeline
	std::vector<VxVectorDesc> RsDesc;
	std::vector<VxVectorDesc> RtDesc;
	std::vector<VxVectorDesc> RdDesc;
	std::vector<VxBias> Biases;
	for(int i = 0; i < num_vop; ++i) {
		VxVectorDesc d;
		// Rs
		d.buffer = cl.Rs;
		d.offset = 0;
		d.length = vec_len;
		RsDesc.push_back(d);
		// Rt
		d.buffer = cl.Rt;
		d.offset = 0;
		d.length = vec_len;
		RtDesc.push_back(d);
		// Rd
		d.buffer = cl.Rd;
		d.offset = i;
		d.length = 1;
		RdDesc.push_back(d);
		// Bias
		VxBias bias;
		bias.rows = 1;
		bias.cols = 1;
		bias.pValue = &biasValue;
		Biases.push_back(bias);
	}

	// Pipeline stage
	VxPipelineStageVxV stg_vxv;
	stg_vxv.base.stageType = VX_PIPELINE_STAGE_TYPE_VXV;
	stg_vxv.nDescriptors = num_vop;
	stg_vxv.pSrc1 = RsDesc.data();
	stg_vxv.pSrc2 = RtDesc.data();
	stg_vxv.pDst = RdDesc.data();
	stg_vxv.pSpecialOp = nullptr;
	stg_vxv.pBias = useBias ? Biases.data() : nullptr;

	VxPipelineStage *stg = &stg_vxv.base;

	VxPipelineCreateInfo pipelineCreateInfo;
	pipelineCreateInfo.context = context;
	pipelineCreateInfo.nStages = 1;
	pipelineCreateInfo.ppStages = &stg;

	res = vxCreatePipeline(&pipelineCreateInfo, &cl.Pipe);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create pipeline!" << std::endl;
		return;
	}

	// Run pipeline
	VxFence f;
	res = vxPipelineRun(cl.Pipe, &f);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to run pipeline!" << std::endl;
		return;
	}

	// Wait for completion
	res = vxFenceWait(cl.Pipe, f);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to wait for fence!" << std::endl;
		return;
	}

	// Verify result
	for(int i = 0; i < num_vop; ++i) {
		if(Rd[i] != Ref)
			std::cerr << "Result mismatch! "
				<< i << ": " << Rd[i] << " != " << Ref << std::endl;
	}
}


void testMxV(VxContext context, bool useBias)
{
	const int mat_rows = 100;	// Number of rows
	const int mat_cols = 256;	// Number of cols
	const int num_vop = 100;	// Number of vector operations

	std::cout << "Test: " << __func__ << (useBias ? " (bias)" : "") << std::endl;

	struct Cleaner {
		VxBuffer Rs = VX_NULL_HANDLE;
		VxBuffer Rt = VX_NULL_HANDLE;
		VxBuffer Rd = VX_NULL_HANDLE;
		VxPipeline Pipe = VX_NULL_HANDLE;

		~Cleaner() {
			VxResult res;
			if(Pipe != VX_NULL_HANDLE) {
				res = vxDestroyPipeline(Pipe);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy pipeline!" << std::endl;
			}
			if(Rs != VX_NULL_HANDLE) {
				res = vxDestroyBuffer(Rs);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy Rs buffer!" << std::endl;
			}
			if(Rt != VX_NULL_HANDLE) {
				res = vxDestroyBuffer(Rt);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy Rt buffer!" << std::endl;
			}
			if(Rd != VX_NULL_HANDLE) {
				res = vxDestroyBuffer(Rd);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy Rd buffer!" << std::endl;
			}
		}
	} cl;

	VxResult res;

	// Bias
	VxFloat biasValue = 10.0f;
	std::vector<VxFloat> biasStorage;
	biasStorage.resize(mat_rows, biasValue);

	// Create buffers
	VxBufferCreateInfo bufferCreateInfo;
	bufferCreateInfo.context = context;
	bufferCreateInfo.cols = mat_cols;
	bufferCreateInfo.rows = mat_rows;
	bufferCreateInfo.map = VX_TRUE;

	VxFloat *Rs, *Rt, *Rd;
	VxFloat Ref;

	res = vxCreateBuffer(&bufferCreateInfo, &cl.Rs, &Rs);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create Rs buffer!" << std::endl;
		return;
	}

	bufferCreateInfo.rows = 1;	// Second argument is a vector

	res = vxCreateBuffer(&bufferCreateInfo, &cl.Rt, &Rt);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create Rt buffer!" << std::endl;
		return;
	}

	bufferCreateInfo.cols = mat_rows;
	bufferCreateInfo.rows = num_vop;

	res = vxCreateBuffer(&bufferCreateInfo, &cl.Rd, &Rd);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create Rd buffer!" << std::endl;
		return;
	}

	// Generate input data and reference value
	Ref = useBias ? biasValue : 0.0f;
	for(int i = 0; i < mat_cols; ++i) {
		Rs[i] = (float)(i + 1);
		Rt[i] = 1.0f / (float)(i + 1);
		Ref += Rs[i] * Rt[i];
	}
	// Copy first row to other rows
	for(int i = 1; i < mat_rows; ++i) {
		memcpy(&Rs[i * mat_cols], &Rs[0], mat_cols * sizeof(VxFloat));
	}

	// Create pipeline
	std::vector<VxMatrixDesc> RsDesc;
	std::vector<VxVectorDesc> RtDesc;
	std::vector<VxVectorDesc> RdDesc;
	std::vector<VxBias> Biases;
	for(int i = 0; i < num_vop; ++i) {
		VxMatrixDesc m;
		VxVectorDesc v;
		// Rs
		m.buffer = cl.Rs;
		m.offset = 0;
		m.rows = mat_rows;
		m.cols = mat_cols;
		RsDesc.push_back(m);
		// Rt
		v.buffer = cl.Rt;
		v.offset = 0;
		v.length = mat_cols;
		RtDesc.push_back(v);
		// Rd
		v.buffer = cl.Rd;
		v.offset = i * mat_rows;
		v.length = mat_rows;
		RdDesc.push_back(v);
		// Bias
		VxBias bias;
		bias.rows = mat_rows;
		bias.cols = 1;
		bias.pValue = biasStorage.data();
		Biases.push_back(bias);
	}

	// Pipeline stage
	VxPipelineStageMxV stg_mxv;
	stg_mxv.base.stageType = VX_PIPELINE_STAGE_TYPE_MXV;
	stg_mxv.nDescriptors = num_vop;
	stg_mxv.pSrc1 = RsDesc.data();
	stg_mxv.pSrc2 = RtDesc.data();
	stg_mxv.pDst = RdDesc.data();
	stg_mxv.pSpecialOp = nullptr;
	stg_mxv.pBias = useBias ? Biases.data() : nullptr;

	VxPipelineStage *stg = &stg_mxv.base;

	VxPipelineCreateInfo pipelineCreateInfo;
	pipelineCreateInfo.context = context;
	pipelineCreateInfo.nStages = 1;
	pipelineCreateInfo.ppStages = &stg;

	res = vxCreatePipeline(&pipelineCreateInfo, &cl.Pipe);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create pipeline!" << std::endl;
		return;
	}

	// Run pipeline
	VxFence f;
	res = vxPipelineRun(cl.Pipe, &f);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to run pipeline!" << std::endl;
		return;
	}

	// Wait for completion
	res = vxFenceWait(cl.Pipe, f);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to wait for fence!" << std::endl;
		return;
	}

	// Verify result
	for(int j = 0; j < num_vop; ++j) {
		for(int i = 0; i < mat_rows; ++i) {
			if(Rd[j * mat_rows + i] != Ref)
				std::cerr << "Result mismatch! "
					<< j << "x" << i << ": "
					<< Rd[i] << " != " << Ref << std::endl;
		}
	}
}


void testMxM(VxContext context, bool useBias)
{
	const int mat1_rows = 40;	// Number of rows in matrix 1
	const int mat2_rows = 50;	// Number of rows in matrix 2
	const int mat_cols = 256;	// Number of cols
	const int num_vop = 10;		// Number of vector operations

	std::cout << "Test: " << __func__ << (useBias ? " (bias)" : "") << std::endl;

	struct Cleaner {
		VxBuffer Rs = VX_NULL_HANDLE;
		VxBuffer Rt = VX_NULL_HANDLE;
		VxBuffer Rd = VX_NULL_HANDLE;
		VxPipeline Pipe = VX_NULL_HANDLE;

		~Cleaner() {
			VxResult res;
			if(Pipe != VX_NULL_HANDLE) {
				res = vxDestroyPipeline(Pipe);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy pipeline!" << std::endl;
			}
			if(Rs != VX_NULL_HANDLE) {
				res = vxDestroyBuffer(Rs);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy Rs buffer!" << std::endl;
			}
			if(Rt != VX_NULL_HANDLE) {
				res = vxDestroyBuffer(Rt);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy Rt buffer!" << std::endl;
			}
			if(Rd != VX_NULL_HANDLE) {
				res = vxDestroyBuffer(Rd);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy Rd buffer!" << std::endl;
			}
		}
	} cl;

	VxResult res;

	// Bias
	VxFloat biasValue = 10.0f;
	std::vector<VxFloat> biasStorage;
	biasStorage.resize(mat1_rows * mat2_rows, biasValue);

	// Create buffers
	VxBufferCreateInfo bufferCreateInfo;
	bufferCreateInfo.context = context;
	bufferCreateInfo.cols = mat_cols;
	bufferCreateInfo.rows = mat1_rows;
	bufferCreateInfo.map = VX_TRUE;

	VxFloat *Rs, *Rt, *Rd;
	VxFloat Ref;

	res = vxCreateBuffer(&bufferCreateInfo, &cl.Rs, &Rs);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create Rs buffer!" << std::endl;
		return;
	}

	bufferCreateInfo.rows = mat2_rows;

	res = vxCreateBuffer(&bufferCreateInfo, &cl.Rt, &Rt);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create Rt buffer!" << std::endl;
		return;
	}

	bufferCreateInfo.cols = mat1_rows * mat2_rows;
	bufferCreateInfo.rows = num_vop;

	res = vxCreateBuffer(&bufferCreateInfo, &cl.Rd, &Rd);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create Rd buffer!" << std::endl;
		return;
	}

	// Generate input data and reference value
	Ref = useBias ? biasValue : 0.0f;
	for(int i = 0; i < mat_cols; ++i) {
		Rs[i] = (float)(i + 1);
		Rt[i] = 1.0f / (float)(i + 1);
		Ref += Rs[i] * Rt[i];
	}
	// Copy first row to other rows
	for(int i = 1; i < mat1_rows; ++i) {
		memcpy(&Rs[i * mat_cols], &Rs[0], mat_cols * sizeof(VxFloat));
	}
	for(int i = 1; i < mat2_rows; ++i) {
		memcpy(&Rt[i * mat_cols], &Rt[0], mat_cols * sizeof(VxFloat));
	}

	// Create pipeline
	std::vector<VxMatrixDesc> RsDesc;
	std::vector<VxMatrixDesc> RtDesc;
	std::vector<VxMatrixDesc> RdDesc;
	std::vector<VxBias> Biases;
	for(int i = 0; i < num_vop; ++i) {
		VxMatrixDesc m;
		// Rs
		m.buffer = cl.Rs;
		m.offset = 0;
		m.rows = mat1_rows;
		m.cols = mat_cols;
		RsDesc.push_back(m);
		// Rt
		m.buffer = cl.Rt;
		m.offset = 0;
		m.rows = mat2_rows;
		m.cols = mat_cols;
		RtDesc.push_back(m);
		// Rd
		m.buffer = cl.Rd;
		m.offset = i * mat1_rows * mat2_rows;
		m.rows = mat1_rows;
		m.cols = mat2_rows;
		RdDesc.push_back(m);
		// Bias
		VxBias bias;
		bias.rows = mat1_rows;
		bias.cols = mat2_rows;
		bias.pValue = biasStorage.data();
		Biases.push_back(bias);
	}

	// Pipeline stage
	VxPipelineStageMxM stg_mxm;
	stg_mxm.base.stageType = VX_PIPELINE_STAGE_TYPE_MXM;
	stg_mxm.nDescriptors = num_vop;
	stg_mxm.pSrc1 = RsDesc.data();
	stg_mxm.pSrc2_T = RtDesc.data();
	stg_mxm.pDst = RdDesc.data();
	stg_mxm.pSpecialOp = nullptr;
	stg_mxm.pBias = useBias ? Biases.data() : nullptr;

	VxPipelineStage *stg = &stg_mxm.base;

	VxPipelineCreateInfo pipelineCreateInfo;
	pipelineCreateInfo.context = context;
	pipelineCreateInfo.nStages = 1;
	pipelineCreateInfo.ppStages = &stg;

	res = vxCreatePipeline(&pipelineCreateInfo, &cl.Pipe);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create pipeline!" << std::endl;
		return;
	}

	// Run pipeline
	VxFence f;
	res = vxPipelineRun(cl.Pipe, &f);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to run pipeline!" << std::endl;
		return;
	}

	// Wait for completion
	res = vxFenceWait(cl.Pipe, f);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to wait for fence!" << std::endl;
		return;
	}

	// Verify result
	for(int k = 0; k < num_vop; ++k) {
		for(int j = 0; j < mat1_rows; ++j) {
			for(int i = 0; i < mat2_rows; ++i) {
				if(Rd[k * mat1_rows * mat2_rows + j * mat2_rows + i] != Ref)
					std::cerr << "Result mismatch! "
						<< k << "x" << j << "x" << i << ": "
						<< Rd[i] << " != " << Ref << std::endl;
			}
		}
	}
}


void testRELU(VxContext context)
{
	const int vec_len = 256;	// Vectors length
	const int num_vop = 100;	// Number of vector operations

	std::cout << "Test: " << __func__ << std::endl;

	struct Cleaner {
		VxBuffer Rs = VX_NULL_HANDLE;
		VxBuffer Rt = VX_NULL_HANDLE;
		VxBuffer Rd = VX_NULL_HANDLE;
		VxPipeline Pipe = VX_NULL_HANDLE;

		~Cleaner() {
			VxResult res;
			if(Pipe != VX_NULL_HANDLE) {
				res = vxDestroyPipeline(Pipe);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy pipeline!" << std::endl;
			}
			if(Rs != VX_NULL_HANDLE) {
				res = vxDestroyBuffer(Rs);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy Rs buffer!" << std::endl;
			}
			if(Rt != VX_NULL_HANDLE) {
				res = vxDestroyBuffer(Rt);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy Rt buffer!" << std::endl;
			}
			if(Rd != VX_NULL_HANDLE) {
				res = vxDestroyBuffer(Rd);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy Rd buffer!" << std::endl;
			}
		}
	} cl;

	VxResult res;

	// Bias
	VxFloat biasValue0 = 0.0f;
	VxFloat biasValue1 = -100000.0f;

	// Create buffers
	VxBufferCreateInfo bufferCreateInfo;
	bufferCreateInfo.context = context;
	bufferCreateInfo.cols = vec_len;
	bufferCreateInfo.rows = 1;
	bufferCreateInfo.map = VX_TRUE;

	VxFloat *Rs, *Rt, *Rd;
	VxFloat Ref;

	res = vxCreateBuffer(&bufferCreateInfo, &cl.Rs, &Rs);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create Rs buffer!" << std::endl;
		return;
	}

	res = vxCreateBuffer(&bufferCreateInfo, &cl.Rt, &Rt);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create Rt buffer!" << std::endl;
		return;
	}

	bufferCreateInfo.cols = num_vop;	// Rd contains results for each operation

	res = vxCreateBuffer(&bufferCreateInfo, &cl.Rd, &Rd);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create Rd buffer!" << std::endl;
		return;
	}

	// Generate input data and reference value
	Ref = 0.0f;
	for(int i = 0; i < vec_len; ++i) {
		Rs[i] = (float)(i + 1);
		Rt[i] = 1.0f / (float)(i + 1);
		Ref += Rs[i] * Rt[i];
	}

	// Create pipeline
	std::vector<VxVectorDesc> RsDesc;
	std::vector<VxVectorDesc> RtDesc;
	std::vector<VxVectorDesc> RdDesc;
	std::vector<VxBias> Biases;
	for(int i = 0; i < num_vop; ++i) {
		VxVectorDesc d;
		// Rs
		d.buffer = cl.Rs;
		d.offset = 0;
		d.length = vec_len;
		RsDesc.push_back(d);
		// Rt
		d.buffer = cl.Rt;
		d.offset = 0;
		d.length = vec_len;
		RtDesc.push_back(d);
		// Rd
		d.buffer = cl.Rd;
		d.offset = i;
		d.length = 1;
		RdDesc.push_back(d);
		// Bias
		VxBias bias;
		bias.rows = 1;
		bias.cols = 1;
		bias.pValue = i & 1 ? &biasValue1 : &biasValue0;
		Biases.push_back(bias);
	}

	// Pipeline stage
	VxPipelineSpecialOpReLU relu;
	relu.base.opType = VX_PIPELINE_SPECIAL_OPTYPE_RELU;
	VxPipelineStageVxV stg_vxv;
	stg_vxv.base.stageType = VX_PIPELINE_STAGE_TYPE_VXV;
	stg_vxv.nDescriptors = num_vop;
	stg_vxv.pSrc1 = RsDesc.data();
	stg_vxv.pSrc2 = RtDesc.data();
	stg_vxv.pDst = RdDesc.data();
	stg_vxv.pSpecialOp = &relu.base;
	stg_vxv.pBias = Biases.data();

	VxPipelineStage *stg = &stg_vxv.base;

	VxPipelineCreateInfo pipelineCreateInfo;
	pipelineCreateInfo.context = context;
	pipelineCreateInfo.nStages = 1;
	pipelineCreateInfo.ppStages = &stg;

	res = vxCreatePipeline(&pipelineCreateInfo, &cl.Pipe);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create pipeline!" << std::endl;
		return;
	}

	// Run pipeline
	VxFence f;
	res = vxPipelineRun(cl.Pipe, &f);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to run pipeline!" << std::endl;
		return;
	}

	// Wait for completion
	res = vxFenceWait(cl.Pipe, f);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to wait for fence!" << std::endl;
		return;
	}

	// Verify result
	for(int i = 0; i < num_vop; ++i) {
		float Ref_tmp = i & 1 ? 0.0f : Ref;
		if(Rd[i] != Ref_tmp)
			std::cerr << "Result mismatch! "
				<< i << ": " << Rd[i] << " != " << Ref_tmp << std::endl;
	}
}


void testUpdate(VxContext context)
{
	const int vec_len = 256;	// Vectors length
	const int num_vop = 100;	// Number of vector operations

	std::cout << "Test: " << __func__ << std::endl;

	struct Cleaner {
		VxBuffer Rs1 = VX_NULL_HANDLE;
		VxBuffer Rt1 = VX_NULL_HANDLE;
		VxBuffer Rd1 = VX_NULL_HANDLE;
		VxBuffer Rs2 = VX_NULL_HANDLE;
		VxBuffer Rt2 = VX_NULL_HANDLE;
		VxBuffer Rd2 = VX_NULL_HANDLE;
		VxPipeline Pipe = VX_NULL_HANDLE;

		~Cleaner() {
			VxResult res;
			if(Pipe != VX_NULL_HANDLE) {
				res = vxDestroyPipeline(Pipe);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy pipeline!" << std::endl;
			}
			if(Rs1 != VX_NULL_HANDLE) {
				res = vxDestroyBuffer(Rs1);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy Rs1 buffer!" << std::endl;
			}
			if(Rt1 != VX_NULL_HANDLE) {
				res = vxDestroyBuffer(Rt1);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy Rt1 buffer!" << std::endl;
			}
			if(Rd1 != VX_NULL_HANDLE) {
				res = vxDestroyBuffer(Rd1);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy Rd1 buffer!" << std::endl;
			}
			if(Rs2 != VX_NULL_HANDLE) {
				res = vxDestroyBuffer(Rs2);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy Rs2 buffer!" << std::endl;
			}
			if(Rt2 != VX_NULL_HANDLE) {
				res = vxDestroyBuffer(Rt2);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy Rt2 buffer!" << std::endl;
			}
			if(Rd2 != VX_NULL_HANDLE) {
				res = vxDestroyBuffer(Rd2);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy Rd2 buffer!" << std::endl;
			}
		}
	} cl;

	VxResult res;

	// Create buffers
	VxBufferCreateInfo bufferCreateInfo;
	bufferCreateInfo.context = context;
	bufferCreateInfo.cols = vec_len;
	bufferCreateInfo.rows = 1;
	bufferCreateInfo.map = VX_TRUE;

	VxFloat *Rs1, *Rt1, *Rd1;
	VxFloat Ref1;
	VxFloat *Rs2, *Rt2, *Rd2;
	VxFloat Ref2;

	res = vxCreateBuffer(&bufferCreateInfo, &cl.Rs1, &Rs1);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create Rs1 buffer!" << std::endl;
		return;
	}

	res = vxCreateBuffer(&bufferCreateInfo, &cl.Rt1, &Rt1);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create Rt1 buffer!" << std::endl;
		return;
	}

	res = vxCreateBuffer(&bufferCreateInfo, &cl.Rs2, &Rs2);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create Rs2 buffer!" << std::endl;
		return;
	}

	res = vxCreateBuffer(&bufferCreateInfo, &cl.Rt2, &Rt2);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create Rt2 buffer!" << std::endl;
		return;
	}

	bufferCreateInfo.cols = num_vop;	// Rd contains results for each operation

	res = vxCreateBuffer(&bufferCreateInfo, &cl.Rd1, &Rd1);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create Rd1 buffer!" << std::endl;
		return;
	}

	res = vxCreateBuffer(&bufferCreateInfo, &cl.Rd2, &Rd2);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create Rd2 buffer!" << std::endl;
		return;
	}

	// Generate input data and reference value
	Ref1 = 0.0f;
	Ref2 = 0.0f;
	for(int i = 0; i < vec_len; ++i) {
		Rs1[i] = (float)(i + 1);
		Rt1[i] = 1.0f / (float)(i + 1);
		Ref1 += Rs1[i] * Rt1[i];
		Rs2[i] = 2.0f * (float)(i + 1);
		Rt2[i] = 2.0f / (float)(i + 1);
		Ref2 += Rs2[i] * Rt2[i];
	}

	// Create pipeline
	std::vector<VxVectorDesc> RsDesc;
	std::vector<VxVectorDesc> RtDesc;
	std::vector<VxVectorDesc> RdDesc;
	for(int i = 0; i < num_vop; ++i) {
		VxVectorDesc d;
		// Rs
		d.buffer = cl.Rs1;
		d.offset = 0;
		d.length = vec_len;
		RsDesc.push_back(d);
		// Rt
		d.buffer = cl.Rt1;
		d.offset = 0;
		d.length = vec_len;
		RtDesc.push_back(d);
		// Rd
		d.buffer = cl.Rd1;
		d.offset = i;
		d.length = 1;
		RdDesc.push_back(d);
	}

	// Pipeline stage
	VxPipelineStageVxV stg_vxv;
	stg_vxv.base.stageType = VX_PIPELINE_STAGE_TYPE_VXV;
	stg_vxv.nDescriptors = num_vop;
	stg_vxv.pSrc1 = RsDesc.data();
	stg_vxv.pSrc2 = RtDesc.data();
	stg_vxv.pDst = RdDesc.data();
	stg_vxv.pSpecialOp = nullptr;
	stg_vxv.pBias = nullptr;

	VxPipelineStage *stg = &stg_vxv.base;

	VxPipelineCreateInfo pipelineCreateInfo;
	pipelineCreateInfo.context = context;
	pipelineCreateInfo.nStages = 1;
	pipelineCreateInfo.ppStages = &stg;

	res = vxCreatePipeline(&pipelineCreateInfo, &cl.Pipe);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create pipeline!" << std::endl;
		return;
	}

	// Run pipeline
	VxFence f;
	res = vxPipelineRun(cl.Pipe, &f);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to run pipeline!" << std::endl;
		return;
	}

	// Wait for completion
	res = vxFenceWait(cl.Pipe, f);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to wait for fence!" << std::endl;
		return;
	}

	// Update resource for the second run
	for(int i = 0; i < num_vop; ++i) {
		// Rs
		RsDesc[i].buffer = cl.Rs2;
		// Rt
		RtDesc[i].buffer = cl.Rt2;
		// Rd
		RdDesc[i].buffer = cl.Rd2;
	}

	// Update
	res = vxUpdateResources(cl.Pipe, &pipelineCreateInfo);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to update resources!" << std::endl;
		return;
	}

	// Run pipeline (2nd run)
	res = vxPipelineRun(cl.Pipe, &f);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to run pipeline!" << std::endl;
		return;
	}

	// Wait for completion
	res = vxFenceWait(cl.Pipe, f);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to wait for fence!" << std::endl;
		return;
	}

	// Verify result
	for(int i = 0; i < num_vop; ++i) {
		if(Rd1[i] != Ref1)
			std::cerr << "Result 1 mismatch! "
				<< i << ": " << Rd1[i] << " != " << Ref1 << std::endl;
		if(Rd2[i] != Ref2)
			std::cerr << "Result 2 mismatch! "
				<< i << ": " << Rd2[i] << " != " << Ref2 << std::endl;
	}
}


int main(int argc, char **argv)
{
	VxInstanceType itype = VX_INSTANCE_TYPE_SW;
	uint32_t vpuMask = 3;

	struct Cleaner {
		VxInstance instance = VX_NULL_HANDLE;
		VxContext context = VX_NULL_HANDLE;

		~Cleaner() {
			VxResult res;
			if(context != VX_NULL_HANDLE) {
				res = vxDestroyContext(context);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy context!" << std::endl;
			}
			if(instance != VX_NULL_HANDLE) {
				res = vxDestroyInstance(instance);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy instance!" << std::endl;
			}
		}
	} cl;

	// Parse command line arguments
	if(argc > 1) {
		std::string itype_arg(argv[1]);
		if(itype_arg == "sw")
			itype = VX_INSTANCE_TYPE_SW;
		else if(itype_arg == "swmt")
			itype = VX_INSTANCE_TYPE_SW_MT;
		else if(itype_arg == "hw")
			itype = VX_INSTANCE_TYPE_HW;
		else
			std::cerr << "Invalid instance type '" << itype_arg << "'"
				<< " using default." << std::endl;
	}

	if(argc > 2)
		vpuMask = std::stoi(argv[2]);

	std::cout << "Simple test app" << std::endl
		<<   "===============" << std::endl
		<< "Instance type: " << (itype == VX_INSTANCE_TYPE_SW ? "SW" :
				itype == VX_INSTANCE_TYPE_SW_MT ? "SW_MT" : "HW") << std::endl
		<< "VPU mask:      " << vpuMask
		<< std::endl;

	VxResult res;

	// Create driver instance
	VxInstanceCreateInfo instanceCreateInfo;
	instanceCreateInfo.type = itype;

	res = vxCreateInstance(&instanceCreateInfo, &cl.instance);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create instance!\n";
		return -1;
	}

	// Look for available devices
	VxCount devicesCount = 0;
	std::vector<VxDevice> devices;
	vxEnumerateDevices(cl.instance, &devicesCount, nullptr);
	if(devicesCount) {
		devices.resize(devicesCount);
		vxEnumerateDevices(cl.instance, &devicesCount, devices.data());
		std::cout << "No.devices:    " << devicesCount << std::endl;
	} else {
		std::cerr << "No devices available!" << std::endl;
		return -1;
	}

	// Create context
	VxContextCreateInfo contextCreateInfo;
	contextCreateInfo.vpuMask = vpuMask;
	contextCreateInfo.device = devices[0];	// Use first available device

	res = vxCreateContext(&contextCreateInfo, &cl.context);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create context!" << std::endl;
		return -1;
	}

	std::cout << "===" << std::endl;

	// Run tests
	testVxV(cl.context, false);
	testVxV(cl.context, true);
	testMxV(cl.context, false);
	testMxV(cl.context, true);
	testMxM(cl.context, false);
	testMxM(cl.context, true);
	testRELU(cl.context);
	testUpdate(cl.context);

	std::cout << "===" << std::endl
		<< "Done." << std::endl;

	return 0;
}
