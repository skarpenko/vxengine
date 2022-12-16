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
 * Register I/O unit local parameters
 */


/* VxEngine Identification (read through ID register) */
localparam [31:0] VXENGINE_ID	= 32'hFEFE_FAFA;


/* Register indexes */
localparam [9:0] REG_ID				= 0;	/* VxE HW ID (r/o) */
localparam [9:0] REG_CTRL			= 1;	/* Control (r/w) */
localparam [9:0] REG_STATUS			= 2;	/* Status (r/o) */
localparam [9:0] REG_INTR_ACT			= 3;	/* Active interrupts (r/w) */
localparam [9:0] REG_INTR_MSK			= 4;	/* Interrupts mask (r/w) */
localparam [9:0] REG_INTR_RAW			= 5;	/* Raw interrupts (r/o) */
localparam [9:0] REG_PGM_ADDR_LO		= 6;	/* Program address /low/ (r/w) */
localparam [9:0] REG_PGM_ADDR_HI		= 7;	/* Program address /high/ (r/w) */
localparam [9:0] REG_START			= 8;	/* Start program execution (w/o) */
localparam [9:0] REG_FAULT_INSTR_ADDR_LO	= 9;	/* Faulted instr. address /low/ (r/o) */
localparam [9:0] REG_FAULT_INSTR_ADDR_HI	= 10;	/* Faulted instr. address /high/ (r/o) */
localparam [9:0] REG_FAULT_INSTR_LO		= 11;	/* Faulted instruction /low/ (r/o) */
localparam [9:0] REG_FAULT_INSTR_HI		= 12;	/* Faulted instruction /high/ (r/o) */
localparam [9:0] REG_FAULT_VPU_MASK0		= 13;	/* Faulted VPUs mask (r/o) */
