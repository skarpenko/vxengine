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
 * Benchmark application
 */

#include <cstdint>
#include <cstring>
#include <unistd.h>
#include <iostream>
#include <iomanip>
#include <stdexcept>
#include <vector>
#include <vxengine/vxengine.h>


uint64_t timestamp_ns()
{
	struct timespec ts;
	clock_gettime(CLOCK_MONOTONIC, &ts);
	return (static_cast<uint64_t>(ts.tv_sec) * 1000000000ULL) + ts.tv_nsec;
}


void print_help()
{
	std::cout << "Arguments:" << std::endl
		<< "  -vl <num>          sets vectors length;" << std::endl
		<< "  -nv <num>          number of vector products to compute;" << std::endl
		<< "  -np <num>          number of different vector pairs;" << std::endl
		<< "  -st <num>          time to cooldown before run;" << std::endl
		<< "  -be [sw|swmt|hw]   backend to use (sw emul, sw emul mt, hardware);" << std::endl
		<< "  -vm [1-3]          VPU mask;" << std::endl
		<< "  -d                 enable debug mode." << std::endl
		<< std::endl;
}


int main(int argc, char **argv)
{
	const uint32_t MAX_VEC_LEN = 1048575;		// Maximum vector length that the hardware supports
	const uint32_t MAX_NUM_VOP = 100000;		// Maximum number of vector products to run
	const uint32_t MAX_VEC_PAIRS = 50;		// Maximum number of vector pairs
	uint32_t vec_len = 1000000;			// -vl : vectors length
	uint32_t num_vop = 100;				// -nv : number of vector products
	uint32_t num_vecp = 20;				// -np : number of vector pairs
	unsigned sleep_time = 10;			// -st : time to cooldown before run
	VxInstanceType itype = VX_INSTANCE_TYPE_SW;	// -be : backend to use
	uint32_t vpu_mask = 3;				// -vm : VPU mask
	bool debug = false;				// -d  : debug mode


	// Print welcome
	std::cout << "VxE benchmark" << std::endl
		<< "=============" << std::endl
		<< std::endl << "Use -h for help." << std::endl
		<< std::endl;


	// Parse command line
	for(int i = 1; i < argc; ++i) {
		int arg = i;
		try {
			if(!strcmp(argv[i], "-vl")) {
				++i;
				if(i == argc)
					throw std::runtime_error("");
				uint32_t v = static_cast<uint32_t>(std::stoi(std::string(argv[i])));
				if(v > MAX_VEC_LEN) {
					std::cerr << "Invalid '-vl' argument value, must be [0.."
						<< MAX_VEC_LEN << "]." << std::endl;
					return -1;
				}
				vec_len = v;
			} else if(!strcmp(argv[i], "-nv")) {
				++i;
				if(i == argc)
					throw std::runtime_error("");
				uint32_t v = static_cast<uint32_t>(std::stoi(std::string(argv[i])));
				if(v > MAX_NUM_VOP) {
					std::cerr << "Invalid '-nv' argument value, must be [0.."
						<< MAX_NUM_VOP << "]." << std::endl;
					return -1;
				}
				num_vop = v;
			} else if(!strcmp(argv[i], "-np")) {
				++i;
				if(i == argc)
					throw std::runtime_error("");
				uint32_t v = static_cast<uint32_t>(std::stoi(std::string(argv[i])));
				if(v == 0 || v > MAX_VEC_PAIRS) {
					std::cerr << "Invalid '-np' argument value, must be [1.."
						<< MAX_VEC_PAIRS << "]." << std::endl;
					return -1;
				}
				num_vecp = v;
			} else if(!strcmp(argv[i], "-st")) {
				++i;
				if(i == argc)
					throw std::runtime_error("");
				sleep_time = static_cast<unsigned>(std::stoi(std::string(argv[i])));
			} else if(!strcmp(argv[i], "-be")) {
				++i;
				if(i == argc)
					throw std::runtime_error("");
				if(!strcmp(argv[i], "sw")) {
					itype = VX_INSTANCE_TYPE_SW;
				} else if(!strcmp(argv[i], "swmt")) {
					itype = VX_INSTANCE_TYPE_SW_MT;
				} else if(!strcmp(argv[i], "hw")) {
					itype = VX_INSTANCE_TYPE_HW;
				} else {
					std::cerr << "Invalid value for '-be' argument: '"
						<< argv[i] << "'." << std::endl;
					return -1;
				}
			} else if(!strcmp(argv[i], "-vm")) {
				++i;
				if(i == argc)
					throw std::runtime_error("");
				uint32_t v = static_cast<uint32_t>(std::stoi(std::string(argv[i])));
				vpu_mask = v & 3;
				if(vpu_mask == 0) {
					std::cerr << "VPU mask cannot be 0, set to default." << std::endl;
					vpu_mask = 3;
				}
			} else if(!strcmp(argv[i], "-d")) {
				debug = true;
			} else if(!strcmp(argv[i], "-h")) {
				print_help();
				return 0;
			} else {
				std::cerr << "Invalid argument: " << argv[i] << "." << std::endl;
				return -1;
			}
		}
		catch(const std::exception& e)
		{
			std::cerr << "Missing or invalid value for '"
				<< argv[arg] << "' argument!" << std::endl;
			return -1;
		}
	}


	// Print current settings
	std::cout << "Parameters:" << std::endl
		<< " > Vectors length : " << vec_len << std::endl
		<< " > Products number: " << num_vop << std::endl
		<< " > Vector pairs   : " << num_vecp << std::endl
		<< " > Cooldown (sec) : " << sleep_time << std::endl
		<< " > Backend        : " << (itype == VX_INSTANCE_TYPE_SW ? "SW" :
			itype == VX_INSTANCE_TYPE_HW ? "HW" : "SW_MT") << std::endl
		<< " > VPU mask       : " << vpu_mask << std::endl
		<< " > Debug mode     : " << (debug ? "Enabled" : "Disabled") << std::endl
		<< std::endl;


	/// Setup test environment ///


	struct Cleaner {
		VxBuffer Rs[MAX_VEC_PAIRS];
		VxBuffer Rt[MAX_VEC_PAIRS];
		VxBuffer Rd = VX_NULL_HANDLE;
		VxPipeline Pipe = VX_NULL_HANDLE;
		VxInstance instance = VX_NULL_HANDLE;
		VxContext context = VX_NULL_HANDLE;

		Cleaner() {
			for(uint32_t i = 0; i < MAX_VEC_PAIRS; ++i) {
				Rs[i] = VX_NULL_HANDLE;
				Rt[i] = VX_NULL_HANDLE;
			}
		}

		~Cleaner() {
			VxResult res;
			if(Pipe != VX_NULL_HANDLE) {
				res = vxDestroyPipeline(Pipe);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy pipeline!" << std::endl;
			}
			for(uint32_t i = 0; i < MAX_VEC_PAIRS; ++i) {
				if(Rs[i] != VX_NULL_HANDLE) {
					res = vxDestroyBuffer(Rs[i]);
					if(res != VX_SUCCESS)
						std::cerr << "Failed to destroy Rs" << i << " buffer!" << std::endl;
				}
				if(Rt[i] != VX_NULL_HANDLE) {
					res = vxDestroyBuffer(Rt[i]);
					if(res != VX_SUCCESS)
						std::cerr << "Failed to destroy Rt" << i << " buffer!" << std::endl;
				}
			}
			if(Rd != VX_NULL_HANDLE) {
				res = vxDestroyBuffer(Rd);
				if(res != VX_SUCCESS)
					std::cerr << "Failed to destroy Rd buffer!" << std::endl;
			}
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
		std::cout << "Devices found: " << devicesCount << std::endl;
	} else {
		std::cerr << "No devices available!" << std::endl;
		return -1;
	}

	// Create context
	VxContextCreateInfo contextCreateInfo;
	contextCreateInfo.vpuMask = vpu_mask;
	contextCreateInfo.device = devices[0];	// Use first available device

	res = vxCreateContext(&contextCreateInfo, &cl.context);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create context!" << std::endl;
		return -1;
	}

	// Create buffers
	VxBufferCreateInfo bufferCreateInfo;
	bufferCreateInfo.context = cl.context;
	bufferCreateInfo.cols = vec_len;
	bufferCreateInfo.rows = 1;
	bufferCreateInfo.map = VX_TRUE;

	VxFloat *Rs[num_vecp], *Rt[num_vecp], *Rd;
	VxFloat Ref;	// Reference value

	for(uint32_t i = 0; i < num_vecp; ++i) {
		res = vxCreateBuffer(&bufferCreateInfo, &cl.Rs[i], &Rs[i]);
		if(res != VX_SUCCESS) {
			std::cerr << "Failed to create Rs" << i << " buffer!" << std::endl;
			return -1;
		}

		res = vxCreateBuffer(&bufferCreateInfo, &cl.Rt[i], &Rt[i]);
		if(res != VX_SUCCESS) {
			std::cerr << "Failed to create Rt" << i << " buffer!" << std::endl;
			return -1;
		}
	}
	bufferCreateInfo.cols = num_vop;	// Rd contains results for each product operation

	res = vxCreateBuffer(&bufferCreateInfo, &cl.Rd, &Rd);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create Rd buffer!" << std::endl;
		return -1;
	}

	// Generate input data and reference value
	Ref = 0.0f;
	for(uint32_t i = 0; i < vec_len; ++i) {
		Rs[0][i] = (float)(i + 1);
		Rt[0][i] = 1.0f / (float)(i + 1);
		Ref += Rs[0][i] * Rt[0][i];
	}
	for(uint32_t i = 1; i < num_vecp; ++i) {
		memcpy(&Rs[i][0], &Rs[0][0], vec_len * sizeof(VxFloat));
		memcpy(&Rt[i][0], &Rt[0][0], vec_len * sizeof(VxFloat));
	}

	// Create pipeline
	std::vector<VxVectorDesc> RsDesc;
	std::vector<VxVectorDesc> RtDesc;
	std::vector<VxVectorDesc> RdDesc;
	std::vector<VxBias> Biases;
	for(uint32_t i = 0; i < num_vop; ++i) {
		VxVectorDesc d;
		// Rs
		d.buffer = cl.Rs[i % num_vecp];
		d.offset = 0;
		d.length = vec_len;
		RsDesc.push_back(d);
		// Rt
		d.buffer = cl.Rt[i % num_vecp];
		d.offset = 0;
		d.length = vec_len;
		RtDesc.push_back(d);
		// Rd
		d.buffer = cl.Rd;
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
	pipelineCreateInfo.context = cl.context;
	pipelineCreateInfo.nStages = 1;
	pipelineCreateInfo.ppStages = &stg;

	res = vxCreatePipeline(&pipelineCreateInfo, &cl.Pipe);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to create pipeline!" << std::endl;
		return -1;
	}

	std::cout << "Sleep for " << sleep_time << " sec. before run..." << std::endl;
	sleep(sleep_time);
	std::cout << "...Go!" << std::endl;

	uint64_t start_time = timestamp_ns();

	// Run pipeline
	VxFence f;
	res = vxPipelineRun(cl.Pipe, &f);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to run pipeline!" << std::endl;
		return -1;
	}

	// Wait for completion
	res = vxFenceWait(cl.Pipe, f);
	if(res != VX_SUCCESS) {
		std::cerr << "Failed to wait for fence!" << std::endl;
		return -1;
	}

	uint64_t end_time = timestamp_ns();

	// Calculate results
	uint64_t total_time = end_time - start_time;
	uint64_t total_flop = 2 * vec_len * num_vop;	// 2 ops for acc += v1 * v2

	double flops = 1E9 * static_cast<double>(total_flop) / static_cast<double>(total_time);
	double mflops = flops / 1E6;
	double gflops = flops / 1E9;

	// Verify result
	bool all_match = true;
	for(uint32_t i = 0; i < num_vop; ++i) {
		if(Rd[i] != Ref) {
			all_match = false;
			if(debug)
				std::cerr << "Result mismatch! "
					<< i << ": " << Rd[i] << " != " << Ref << std::endl;
			else
				break;
		}
	}

	// Print results
	std::cout << std::endl << std::string(23, '=') << std::endl
		<< "Result check: " << (all_match ? "MATCH" : "MISMATCH! :(") << std::endl
		<< std::endl
		<< "Measured performance:" << std::endl
		<< "  " << std::fixed << std::setprecision(2) << flops << " FLOPS" << std::endl
		<< "  " << std::fixed << std::setprecision(2) << mflops << " MFLOPS" << std::endl
		<< "  " << std::fixed << std::setprecision(2) << gflops << " GFLOPS" << std::endl
		<< std::string(23, '=') << std::endl
		<< "All done." << std::endl
		<< std::endl;

	return 0;
}
