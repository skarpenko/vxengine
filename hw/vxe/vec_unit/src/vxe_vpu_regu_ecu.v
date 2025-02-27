/*
 * Copyright (c) 2020-2025 The VxEngine Project. All rights reserved.
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
 * VxE VPU register update execution control unit
 */


/* Register update unit */
module vxe_vpu_regu_ecu(
	clk,
	nrst,
	/* Dispatch interface */
	i_disp,
	o_done,
	i_cmd_op,
	i_cmd_th,
	i_cmd_pl,
	/* Register file interface */
	o_th,
	o_ridx,
	o_wr_en,
	o_data
);
`include "vxe_ctrl_unit_cmds.vh"
`include "vxe_vpu_regidx_params.vh"
/* Global signals */
input wire		clk;
input wire		nrst;
/* Dispatch interface */
input wire		i_disp;
output reg		o_done;
input wire [4:0]	i_cmd_op;
input wire [2:0]	i_cmd_th;
input wire [47:0]	i_cmd_pl;
/* Register file interface */
output wire [2:0]	o_th;
output reg [2:0]	o_ridx;
output reg		o_wr_en;
output wire [37:0]	o_data;


/* Assign outputs */
assign o_th = i_cmd_th;
assign o_data = i_cmd_pl[37:0];


/* Pick destination register */
always @(*)
begin
	case(i_cmd_op)
	CU_CMD_SETACC: begin
		o_ridx = VPU_REG_IDX_ACC;
	end
	CU_CMD_SETVL: begin
		o_ridx = VPU_REG_IDX_VL;
	end
	CU_CMD_SETEN: begin
		o_ridx = VPU_REG_IDX_EN;
	end
	CU_CMD_SETRS: begin
		o_ridx = VPU_REG_IDX_RS;
	end
	CU_CMD_SETRT: begin
		o_ridx = VPU_REG_IDX_RT;
	end
	CU_CMD_SETRD: begin
		o_ridx = VPU_REG_IDX_RD;
	end
	default: begin
		o_ridx = VPU_REG_IDX_IGN;
		if(i_disp)
			$display("Wrong register index!\n");
	end
	endcase
end


/* Main logic */
always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		o_wr_en <= 1'b0;
		o_done <= 1'b0;
	end
	else
	begin
		o_done <= 1'b0;
		o_wr_en <= 1'b0;

		if(i_disp)
		begin
			o_done <= 1'b1;
			o_wr_en <= 1'b1;
		end
	end
end


endmodule /* vxe_vpu_regu_ecu */
