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

/* NOP - No Operation - Used for padding */
localparam [4:0] CU_CMD_NOP	= 5'b00000;

/* SYNC - Synchronize - Wait for completion of all previous operations */
localparam [4:0] CU_CMD_SYNC	= 5'b00001;

/* SETACC - Set Accumulator - Set an accumulator register per thread */
localparam [4:0] CU_CMD_SETACC	= 5'b01000;

/* SETVL - Set Vector Length - Set vector length per thread */
localparam [4:0] CU_CMD_SETVL	= 5'b01001;

/* SETEN - Set Thread Enable - Enable or disable selected thread */
localparam [4:0] CU_CMD_SETEN	= 5'b01010;

/* SETRS - Set First Operand - Set first operand vector per thread */
localparam [4:0] CU_CMD_SETRS	= 5'b01100;

/* SETRT - Set Second Operand - Set second operand vector per thread */
localparam [4:0] CU_CMD_SETRT	= 5'b01101;

/* SETRD - Set Destination - Set destination storage for result */
localparam [4:0] CU_CMD_SETRD	= 5'b01110;


/* PROD - Vector Product - Run enabled threads to compute vector product */
localparam [4:0] CU_CMD_PROD	= 5'b10000;

/* STORE - Store Result - Store result of enabled threads */
localparam [4:0] CU_CMD_STORE	= 5'b10001;

/* ACTF - Activation Function - Run activation on accumulators of enabled threads */
localparam [4:0] CU_CMD_ACTF	= 5'b10010;


/*** Activation functions (for CU_CMD_ACTF) ***/

localparam [5:0] CU_CMD_ACTF_RELU	= 6'b000000;	/* ReLU */
localparam [5:0] CU_CMD_ACTF_LRELU	= 6'b000001;	/* Leaky ReLU */
