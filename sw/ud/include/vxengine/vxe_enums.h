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
 * Enumerations used by API
 */

#ifndef __VXENGINE_H__
# error "Do not include this header directly! Include vxengine.h instead."
#endif


typedef enum VxInstanceType {
	VX_INSTANCE_TYPE_HW,		/* Use hardware */
	VX_INSTANCE_TYPE_SW,		/* Use software emulation */
	VX_INSTANCE_TYPE_SW_MT		/* Use multithreaded software emulation */
} VxInstanceType;


typedef enum VxResult {
	VX_SUCCESS = 0,
	VX_NOT_READY = 1,
	VX_ERROR_UNKNOWN = 2,
	VX_ERROR_INVALID = 3,
	VX_ERROR_NO_DEVICE = 4,
	VX_ERROR_NO_MEMORY = 5,
	VX_ERROR_NO_PERMISSION = 6,
	VX_ERROR_NO_ACCESS = 7,
	VX_ERROR_NO_RESOURCE = 8,
	VX_ERROR_MMAP_FAILED = 9
} VxResult;


typedef enum VxPipelineSpecialOpType {
	VX_PIPELINE_SPECIAL_OPTYPE_RELU = 0,	/* ReLU */
	VX_PIPELINE_SPECIAL_OPTYPE_LRELU = 1	/* Leaky ReLU */
} VxPipelineSpecialOpType;


typedef enum VxPipelineStageType {
	VX_PIPELINE_STAGE_TYPE_VXV = 0,		/* Vextor-vector dot product */
	VX_PIPELINE_STAGE_TYPE_MXV = 1,		/* Matrix-vector product */
	VX_PIPELINE_STAGE_TYPE_MXM = 2		/* Matrix-matrix product */
} VxPipelineStageType;
