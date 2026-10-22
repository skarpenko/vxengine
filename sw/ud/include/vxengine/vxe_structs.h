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
 * Structures used by API
 */

#ifndef __VXENGINE_H__
# error "Do not include this header directly! Include vxengine.h instead."
#endif


/* Instance info */
typedef struct VxInstanceCreateInfo {
	VxInstanceType type;		/* Instance type (HW/SW_EMU) */
} VxInstanceCreateInfo;


/* Context info */
typedef struct VxContextCreateInfo {
	VxDevice device;		/* Device to use */
	uint32_t vpuMask;		/* Enabled VPUs mask (0 - default) */
} VxContextCreateInfo;


/* Buffer info */
typedef struct VxBufferCreateInfo {
	VxContext context;		/* Context */
	VxSize rows;			/* Number of rows */
	VxSize cols;			/* Number of cols */
	VxBool map;			/* Map buffer after creation */
} VxBufferCreateInfo;


/* Vector descriptor */
typedef struct VxVectorDesc {
	VxBuffer buffer;		/* Buffer that contains vector data */
	VxOffset offset;		/* Offset within a buffer (in elements, not bytes) */
	VxSize length;			/* Vector length */
} VxVectorDesc;


/* Matrix descriptor */
typedef struct VxMatrixDesc {
	VxBuffer buffer;		/* Buffer that contains vector data */
	VxOffset offset;		/* Offset within a buffer (in elements, not bytes) */
	VxSize rows;			/* Number of rows */
	VxSize cols;			/* Number of cols */
} VxMatrixDesc;


/* Bias values */
typedef struct VxBias {
	VxFloat *pValue;		/* Pointer to bias values */
	VxSize rows;			/* Number of rows */
	VxSize cols;			/* Number of cols */
} VxBias;


/* Pipeline special operation base */
typedef struct VxPipelineSpecialOp {
	VxPipelineSpecialOpType opType;
} VxPipelineSpecialOp;


/* Pipeline special operation - ReLU */
typedef struct VxPipelineSpecialOpReLU {
	VxPipelineSpecialOp base;
} VxPipelineSpecialOpReLU;


/* Pipeline special operation - Leaky ReLU */
typedef struct VxPipelineSpecialOpLReLU {
	VxPipelineSpecialOp base;
	int negExpD;
} VxPipelineSpecialOpLReLU;


/* Pipeline stage base */
typedef struct VxPipelineStage {
	VxPipelineStageType stageType;
} VxPipelineStage;


/* Pipeline stage - VxV */
typedef struct VxPipelineStageVxV {
	VxPipelineStage base;			/* Base structure */
	VxSize nDescriptors;			/* Number of descriptors */
	const VxVectorDesc *pSrc1;		/* Source operands 1  */
	const VxVectorDesc *pSrc2;		/* Source operands 2 */
	const VxVectorDesc *pDst;		/* Destinations */
	const VxBias *pBias;			/* (Optional) Bias values */
	const VxPipelineSpecialOp *pSpecialOp;	/* (Optional) Special operation */
} VxPipelineStageVxV;


/* Pipeline stage - MxV */
typedef struct VxPipelineStageMxV {
	VxPipelineStage base;			/* Base structure */
	VxSize nDescriptors;			/* Number of descriptors */
	const VxMatrixDesc *pSrc1;		/* Source matrix operands 1  */
	const VxVectorDesc *pSrc2;		/* Source vector operands 2 */
	const VxVectorDesc *pDst;		/* Destination vectors */
	const VxBias *pBias;			/* (Optional) Bias values */
	const VxPipelineSpecialOp *pSpecialOp;	/* (Optional) Special operation */
} VxPipelineStageMxV;


/* Pipeline stage - MxM */
typedef struct VxPipelineStageMxM {
	VxPipelineStage base;			/* Base structure */
	VxSize nDescriptors;			/* Number of descriptors */
	const VxMatrixDesc *pSrc1;		/* Source matrix operands 1  */
	const VxMatrixDesc *pSrc2_T;		/* Source transposed matrix operands 2  */
	const VxMatrixDesc *pDst;		/* Destination matrices */
	const VxBias *pBias;			/* (Optional) Bias values */
	const VxPipelineSpecialOp *pSpecialOp;	/* (Optional) Special operation */
} VxPipelineStageMxM;


/* Pipeline info */
typedef struct VxPipelineCreateInfo {
	VxContext context;			/* Context */
	VxSize nStages;				/* Number of stages */
	const VxPipelineStage* const *ppStages;	/* Stages list */
} VxPipelineCreateInfo;
