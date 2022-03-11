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
 * VxE CU command decoder
 */


/* Command decoder */
module vxe_cu_cmd_decoder(
	/* Command word */
	i_cmd,
	/* Decode error */
	o_dec_err,
	/* Decoded command data */
	o_op,
	o_fun,
	o_pl
);
`include "vxe_client_params.vh"
`include "vxe_ctrl_unit_cmds.vh"
/* Command word */
input wire [63:0]	i_cmd;
/* Decode error */
output wire		o_dec_err;
/* Decoded command data */
output wire [4:0]	o_op;
output wire [7:0]	o_fun;
output wire [37:0]	o_pl;


assign o_op = i_cmd[63:59];	/* Opcode */
assign o_fun = i_cmd[58:51];	/* Function */
assign o_pl = i_cmd[37:0];	/* Payload */

/* Decode error */
assign o_dec_err = err_op || err_nop || err_setacc || err_setvl || err_setrs
		|| err_setrt || err_setrd || err_seten || err_prod
		|| err_store || err_sync || err_relu;


/** Decode error cases **/

/* Opcode error */
wire err_op =
	(o_op != CU_CMD_NOP) &&
	(o_op != CU_CMD_SETACC) &&
	(o_op != CU_CMD_SETVL) &&
	(o_op != CU_CMD_SETRS) &&
	(o_op != CU_CMD_SETRT) &&
	(o_op != CU_CMD_SETRD) &&
	(o_op != CU_CMD_SETEN) &&
	(o_op != CU_CMD_PROD) &&
	(o_op != CU_CMD_STORE) &&
	(o_op != CU_CMD_SYNC) &&
	(o_op != CU_CMD_RELU);


/* NOP instruction format error */
wire err_nop = (o_op == CU_CMD_NOP ? err_nop_rsvd : 1'b0);

/* SETACC instruction format error */
wire err_setacc = (o_op == CU_CMD_SETACC ? err_setacc_rsvd || err_thr_id : 1'b0);

/* SETVL instruction format error */
wire err_setvl = (o_op == CU_CMD_SETVL ? err_setvl_rsvd || err_thr_id : 1'b0);

/* SETRS instruction format error */
wire err_setrs = (o_op == CU_CMD_SETRS ? err_setrs_rsvd || err_thr_id : 1'b0);

/* SETRT instruction format error */
wire err_setrt = (o_op == CU_CMD_SETRT ? err_setrt_rsvd || err_thr_id : 1'b0);

/* SETRD instruction format error */
wire err_setrd = (o_op == CU_CMD_SETRD ? err_setrd_rsvd || err_thr_id : 1'b0);

/* SETEN instruction format error */
wire err_seten = (o_op == CU_CMD_SETEN ? err_seten_rsvd || err_thr_id : 1'b0);

/* PROD instruction format error */
wire err_prod = (o_op == CU_CMD_PROD ? err_prod_rsvd : 1'b0);

/* STORE instruction format error */
wire err_store = (o_op == CU_CMD_STORE ? err_store_rsvd : 1'b0);

/* SYNC instruction format error */
wire err_sync = (o_op == CU_CMD_SYNC ? err_sync_rsvd : 1'b0);

/* RELU instruction format error */
wire err_relu = (o_op == CU_CMD_RELU ? err_relu_rsvd || err_relu_func : 1'b0);


/* NOP reserved fields violation */
wire err_nop_rsvd = |i_cmd[58:0];

/* SETACC reserved fields violation */
wire err_setacc_rsvd = |i_cmd[50:32];

/* SETVL reserved fields violation */
wire err_setvl_rsvd = |i_cmd[50:20];

/* SETRS reserved fields violation */
wire err_setrs_rsvd = |i_cmd[50:38];

/* SETRT reserved fields violation */
wire err_setrt_rsvd = |i_cmd[50:38];

/* SETRD reserved fields violation */
wire err_setrd_rsvd = |i_cmd[50:38];

/* SETEN reserved fields violation */
wire err_seten_rsvd = |i_cmd[50:1];

/* PROD reserved fields violation */
wire err_prod_rsvd = |i_cmd[58:0];

/* STORE reserved fields violation */
wire err_store_rsvd = |i_cmd[58:0];

/* SYNC reserved fields violation */
wire err_sync_rsvd = |i_cmd[58:2];

/* RELU reserved fields violation */
wire err_relu_rsvd = |i_cmd[50:7];


/* RELU function error */
wire err_relu_func = (o_fun != CU_CMD_RELU_RELU) && (o_fun != CU_CMD_RELU_LRELU);


/* Thread Id error */
wire err_thr_id = (o_fun >= TOTAL_THR_NR);


endmodule /* vxe_cu_cmd_decoder */
