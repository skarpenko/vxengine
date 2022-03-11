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
 * Control unit command codes
 */


/*** Commands ***/

/* NOP - No Operation - used for padding */
localparam [4:0] CU_CMD_NOP	= 5'h00;

/* SETACC - Set Accumulator - Set an accumulator register per thread */
localparam [4:0] CU_CMD_SETACC	= 5'h08;

/* SETVL - Set Vector Length - Set vector length per thread */
localparam [4:0] CU_CMD_SETVL	= 5'h09;

/* SETRS - Set First Operand - Set first operand vector per thread */
localparam [4:0] CU_CMD_SETRS	= 5'h0C;

/* SETRT - Set Second Operand - Set second operand vector per thread */
localparam [4:0] CU_CMD_SETRT	= 5'h0D;

/* SETRD - Set Destination - Set destination storage for result */
localparam [4:0] CU_CMD_SETRD	= 5'h0E;

/* SETEN - Set Thread Enable - Enable or disable selected thread */
localparam [4:0] CU_CMD_SETEN	= 5'h0A;

/* PROD - Vector Product - Run enabled threads to compute vector product */
localparam [4:0] CU_CMD_PROD	= 5'h01;

/* STORE - Store Result - Store result of enabled threads */
localparam [4:0] CU_CMD_STORE	= 5'h10;

/* SYNC - Synchronize - Wait for completion of all previous operations */
localparam [4:0] CU_CMD_SYNC	= 5'h18;

/* RELU - ReLU activation - Run ReLU on accumulators of enabled threads */
localparam [4:0] CU_CMD_RELU	= 5'h02;


/*** ReLU activation functions (for CU_CMD_RELU) ***/

localparam [7:0] CU_CMD_RELU_RELU	= 8'h00;	/* ReLU */
localparam [7:0] CU_CMD_RELU_LRELU	= 8'h01;	/* Leaky ReLU */
