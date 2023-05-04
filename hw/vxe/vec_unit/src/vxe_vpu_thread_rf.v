/*
 * Copyright (c) 2020-2023 The VxEngine Project. All rights reserved.
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
 * VxE VPU thread register file
 */


/* Thread register file */
module vxe_vpu_thread_rf(
	clk,
	nrst,
	/* RF write interface */
	ridx,
	wr_en,
	data,
	/* Register values */
	out_acc,
	out_vl,
	out_en,
	out_rs,
	out_rt,
	out_rd
);
`include "vxe_vpu_regidx_params.vh"
/* Global signals */
input wire		clk;
input wire		nrst;
/* RF write interface */
input wire [2:0]	ridx;
input wire		wr_en;
input wire [37:0]	data;
/* Register values */
output wire [31:0]	out_acc;
output wire [19:0]	out_vl;
output wire		out_en;
output wire [37:0]	out_rs;
output wire [37:0]	out_rt;
output wire [37:0]	out_rd;


/* Register write enables */
reg reg_acc_wr;
reg reg_vl_wr;
reg reg_en_wr;
reg reg_rs_wr;
reg reg_rt_wr;
reg reg_rd_wr;


/* Register MUX */
always @(*)
begin
	case(ridx)
	VPU_REG_IDX_ACC: begin
		reg_acc_wr = wr_en;
		reg_vl_wr = 1'b0;
		reg_en_wr = 1'b0;
		reg_rs_wr = 1'b0;
		reg_rt_wr = 1'b0;
		reg_rd_wr = 1'b0;
	end
	VPU_REG_IDX_VL: begin
		reg_acc_wr = 1'b0;
		reg_vl_wr = wr_en;
		reg_en_wr = 1'b0;
		reg_rs_wr = 1'b0;
		reg_rt_wr = 1'b0;
		reg_rd_wr = 1'b0;
	end
	VPU_REG_IDX_EN: begin
		reg_acc_wr = 1'b0;
		reg_vl_wr = 1'b0;
		reg_en_wr = wr_en;
		reg_rs_wr = 1'b0;
		reg_rt_wr = 1'b0;
		reg_rd_wr = 1'b0;
	end
	VPU_REG_IDX_RS: begin
		reg_acc_wr = 1'b0;
		reg_vl_wr = 1'b0;
		reg_en_wr = 1'b0;
		reg_rs_wr = wr_en;
		reg_rt_wr = 1'b0;
		reg_rd_wr = 1'b0;
	end
	VPU_REG_IDX_RT: begin
		reg_acc_wr = 1'b0;
		reg_vl_wr = 1'b0;
		reg_en_wr = 1'b0;
		reg_rs_wr = 1'b0;
		reg_rt_wr = wr_en;
		reg_rd_wr = 1'b0;
	end
	VPU_REG_IDX_RD: begin
		reg_acc_wr = 1'b0;
		reg_vl_wr = 1'b0;
		reg_en_wr = 1'b0;
		reg_rs_wr = 1'b0;
		reg_rt_wr = 1'b0;
		reg_rd_wr = wr_en;
	end
	default: begin
		reg_acc_wr = 1'b0;
		reg_vl_wr = 1'b0;
		reg_en_wr = 1'b0;
		reg_rs_wr = 1'b0;
		reg_rt_wr = 1'b0;
		reg_rd_wr = 1'b0;
	end
	endcase
end


/* Accumulator */
vxe_reg #( .DATA_WIDTH(32) ) reg_acc
(
	.clk(clk),
	.wr_en(reg_acc_wr),
	.data_in(data[31:0]),
	.data_out(out_acc)
);

/* Vector length */
vxe_reg #( .DATA_WIDTH(20) ) reg_vl
(
	.clk(clk),
	.wr_en(reg_vl_wr),
	.data_in(data[19:0]),
	.data_out(out_vl)
);

/* Thread enable */
vxe_reg_rst #( .DATA_WIDTH(1), .RST_VALUE(0) ) reg_en
(
	.clk(clk),
	.nrst(nrst),
	.wr_en(reg_en_wr),
	.data_in(data[0]),
	.data_out(out_en)
);

/* Source operand 1 */
vxe_reg #( .DATA_WIDTH(38) ) reg_rs
(
	.clk(clk),
	.wr_en(reg_rs_wr),
	.data_in(data[37:0]),
	.data_out(out_rs)
);

/* Source operand 2 */
vxe_reg #( .DATA_WIDTH(38) ) reg_rt
(
	.clk(clk),
	.wr_en(reg_rt_wr),
	.data_in(data[37:0]),
	.data_out(out_rt)
);

/* Result destination */
vxe_reg #( .DATA_WIDTH(38) ) reg_rd
(
	.clk(clk),
	.wr_en(reg_rd_wr),
	.data_in(data[37:0]),
	.data_out(out_rd)
);


endmodule /* vxe_vpu_thread_rf */
