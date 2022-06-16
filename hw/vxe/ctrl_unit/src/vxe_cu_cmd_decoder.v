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
	/* Decoded command control signals */
	o_cu_cmd,
	o_cu_nop,
	o_cu_sync,
	o_cu_sync_stop,
	o_cu_sync_intr,
	o_vpu_cmd,
	o_vpu_mask,
	o_vpu_op,
	o_vpu_th,
	o_vpu_pl
);
parameter VPUS_NR = 2;		/* Number of VPUs*/
parameter VERIFY_FMT = 1;	/* Verify commands format */
`include "vxe_ctrl_unit_cmds.vh"
/* Command word */
input wire [63:0]		i_cmd;
/* Decode error */
output wire			o_dec_err;
/* Decoded command control signals */
output reg			o_cu_cmd;
output reg			o_cu_nop;
output reg			o_cu_sync;
output reg			o_cu_sync_stop;
output reg			o_cu_sync_intr;
output reg			o_vpu_cmd;
output reg [VPUS_NR-1:0]	o_vpu_mask;
output reg [4:0]		o_vpu_op;
output reg [2:0]		o_vpu_th;
output reg [47:0]		o_vpu_pl;


/* Generic command fields */
wire [4:0] op = i_cmd[63:59];	/* Opcode */
wire [7:0] dst = i_cmd[58:51];	/* Destination */
wire [2:0] zero = i_cmd[50:48];	/* Always zero */
wire [47:0] pl = i_cmd[47:0];	/* Payload */

/* Command class */
wire cu_cmd = ~|op[4:2];
wire vpu_cmd = |op[4:2];

/* VPU command attributes */
wire vpu_bcast = op[4];			/* Broadcast sub-class */
wire vpu_bcast_en = ~dst[0];		/* Broadcast enabled */
wire [4:0] vpu_no = dst[7:3];		/* Destination VPU number */
wire [2:0] vpu_th = dst[2:0];		/* VPU thread number */
wire vpu_vld = (vpu_no < VPUS_NR);	/* Destination VPU is valid */

/* Payload pre-decoding */
wire [5:0] vpu_actf = pl[47:42];	/* Activation function type */


/** Decode error cases **/

/* Opcode error */
wire err_op =
	(op != CU_CMD_NOP) &&
	(op != CU_CMD_SETACC) &&
	(op != CU_CMD_SETVL) &&
	(op != CU_CMD_SETRS) &&
	(op != CU_CMD_SETRT) &&
	(op != CU_CMD_SETRD) &&
	(op != CU_CMD_SETEN) &&
	(op != CU_CMD_PROD) &&
	(op != CU_CMD_STORE) &&
	(op != CU_CMD_SYNC) &&
	(op != CU_CMD_ACTF);


/* Activation function error */
reg err_actf;
always @(*)
begin
	if(op == CU_CMD_ACTF)
	begin
		case(vpu_actf)
		CU_CMD_ACTF_RELU, CU_CMD_ACTF_LRELU: err_actf = 1'b0;
		default: err_actf = 1'b1;
		endcase
	end
	else
		err_actf = 1'b0;
end


/* Format violation */
wire err_fmt = (VERIFY_FMT != 0 ? err_fmt_q : 1'b0);
reg err_fmt_q;
wire inv_zero = |zero;	/* Zero field is non-zero */

always @(*)
begin
	err_fmt_q = 1'b0;

	if(VERIFY_FMT != 0)
	begin
		case(op)
		CU_CMD_NOP,
		CU_CMD_SYNC:	err_fmt_q = |dst || inv_zero;
		CU_CMD_SETACC,
		CU_CMD_SETVL,
		CU_CMD_SETRS,
		CU_CMD_SETRT,
		CU_CMD_SETRD,
		CU_CMD_SETEN:	err_fmt_q = inv_zero;
		CU_CMD_PROD,
		CU_CMD_STORE,
		CU_CMD_ACTF:	err_fmt_q = (vpu_bcast_en ? |dst : |dst[2:1])
					|| inv_zero;
		default: err_fmt_q = 1'b0;
		endcase
	end
end


/* Payload format violation */
wire err_pl_fmt = (VERIFY_FMT != 0 ? err_pl_fmt_q : 1'b0);
reg err_pl_fmt_q;

always @(*)
begin
	err_pl_fmt_q = 1'b0;

	if(VERIFY_FMT != 0)
	begin
		case(op)
		CU_CMD_NOP,
		CU_CMD_PROD,
		CU_CMD_STORE:	err_pl_fmt_q = |pl[47:0];
		CU_CMD_SYNC:	err_pl_fmt_q = |pl[47:2];
		CU_CMD_SETACC:	err_pl_fmt_q = |pl[47:32];
		CU_CMD_SETVL:	err_pl_fmt_q = |pl[47:20];
		CU_CMD_SETRS,
		CU_CMD_SETRT,
		CU_CMD_SETRD:	err_pl_fmt_q = |pl[47:38];
		CU_CMD_SETEN:	err_pl_fmt_q = |pl[47:1];
		CU_CMD_ACTF: begin
			case(vpu_actf)
			CU_CMD_ACTF_RELU:	err_pl_fmt_q = |pl[41:0];
			CU_CMD_ACTF_LRELU:	err_pl_fmt_q = |pl[41:7];
			default:		err_pl_fmt_q = 1'b1;
			endcase
		end
		default: err_pl_fmt_q = 1'b0;
		endcase
	end
end


/* Decode error */
assign o_dec_err = err_op || err_actf || err_fmt || err_pl_fmt
	|| (vpu_cmd && ~vpu_vld);


/* Outputs */
always @(*)
begin
	o_cu_cmd = cu_cmd;
	o_cu_nop = ~op[0];
	o_cu_sync = op[0];
	o_cu_sync_stop = pl[0];
	o_cu_sync_intr = pl[1];

	o_vpu_cmd = vpu_cmd;
	o_vpu_op = op;
	o_vpu_th = vpu_th;
	o_vpu_pl = pl;

	o_vpu_mask = {(VPUS_NR){1'b0}};
	if(vpu_bcast && vpu_bcast_en)
		o_vpu_mask = {(VPUS_NR){1'b1}};
	else
		o_vpu_mask[vpu_no[$clog2(VPUS_NR)-1:0]] = 1'b1;
end


endmodule /* vxe_cu_cmd_decoder */
