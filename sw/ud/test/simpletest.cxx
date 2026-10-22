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
#include <iostream>
#include <vector>
#include <string>
#include <vxengine/vxengine.h>


void testVxV(VxContext context)
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
	}

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

	VxFence f;
	res = vxPipelineRun(cl.Pipe, &f);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to run pipeline!" << std::endl;
		return;
	}

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

	// Run tests
	testVxV(cl.context);


	return 0;
}
