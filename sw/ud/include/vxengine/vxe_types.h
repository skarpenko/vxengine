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
 * Basic types used by API
 */

#ifndef __VXENGINE_H__
# error "Do not include this header directly! Include vxengine.h instead."
#endif


#define VX_DEFINE_HANDLE(object)	\
	typedef struct object##_HANDLE* object
#define VX_NULL_HANDLE	(0)

typedef uint32_t VxBool;
#define VX_TRUE		(1)
#define VX_FALSE	(0)

typedef uint32_t VxOffset;
typedef uint32_t VxSize;
typedef uint32_t VxCount;
typedef uint32_t VxVPUMask;
typedef float VxFloat;

VX_DEFINE_HANDLE(VxInstance);
VX_DEFINE_HANDLE(VxDevice);
VX_DEFINE_HANDLE(VxContext);
VX_DEFINE_HANDLE(VxBuffer);
VX_DEFINE_HANDLE(VxPipeline);

typedef uint64_t VxFence;
