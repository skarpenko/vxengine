/*
 * Copyright (c) 2020-2022 The VxEngine Project. All rights reserved.
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
 * Interrupt local parameters
 */


/* Interrupt masks */
localparam [3:0] INTR_MSK_COMPLETED	= 4'b0001;	/* Job done */
localparam [3:0] INTR_MSK_ERR_FETCH	= 4'b0010;	/* Fetch error */
localparam [3:0] INTR_MSK_ERR_INSTR	= 4'b0100;	/* Instruction decode error */
localparam [3:0] INTR_MSK_ERR_DATA	= 4'b1000;	/* Data load error */


/* Interrupt indexes */
localparam [1:0] INTR_IDX_COMPLETED	= 2'b00;
localparam [1:0] INTR_IDX_ERR_FETCH	= 2'b01;
localparam [1:0] INTR_IDX_ERR_INSTR	= 2'b10;
localparam [1:0] INTR_IDX_ERR_DATA	= 2'b11;
