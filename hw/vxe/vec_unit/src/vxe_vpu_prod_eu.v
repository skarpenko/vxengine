/*
 * Copyright (c) 2020-2024 The VxEngine Project. All rights reserved.
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
 * VxE VPU product execution unit
 */


/* Product execution unit */
module vxe_vpu_prod_eu #(
	parameter WE_DEPTH_POW2 = 2,		/* Write enable FIFOs depth (2^WE_DEPTH_POW2) */
	parameter OP_DEPTH_POW2 = 2,		/* Operand FIFOs depth (2^WE_DEPTH_POW2) */
	/* Requests dispatcher unit */
	parameter RQD_IN_DEPTH_POW2 = 2,	/* Incoming FIFOs depth (2^IN_DEPTH_POW2) */
	parameter RQD_OUT_DEPTH_POW2 = 2,	/* Outgoing FIFOs depth (2^OUT_DEPTH_POW2) */
	/* Responses distributor unit */
	parameter RSD_IN_WE_DEPTH_POW2 = 2,	/* Incoming write enable FIFOs depth (2^IN_WE_DEPTH_POW2) */
	parameter RSD_IN_RS_DEPTH_POW2 = 3,	/* Incoming response FIFO depth (2^IN_RS_DEPTH_POW2) */
	parameter RSD_OUT_OP_DEPTH_POW2 = 2,	/* Outgoing operand FIFOs depth (2^OUT_OP_DEPTH_POW2) */
	/* FMAC scheduler unit */
	parameter FMAC_IN_OP_DEPTH_POW2 = 2	/* Incoming operand FIFOs depth (2^IN_OP_DEPTH_POW2) */
)
(
	/* Global signals */
	clk,
	nrst,
	/* Control unit interface */
	i_start,
	o_busy,
	/* LSU interface */
	i_lsu_err,
	i_lsu_rrq_rdy,
	o_lsu_rrq_wr,
	o_lsu_rrq_th,
	o_lsu_rrq_addr,
	o_lsu_rrq_arg,
	i_lsu_rrs_vld,
	o_lsu_rrs_rd,
	i_lsu_rrs_th,
	i_lsu_rrs_arg,
	i_lsu_rrs_data,
	/* Register file interface */
	o_prod_th,
	o_prod_ridx,
	o_prod_wr_en,
	o_prod_data,
	/* Register values */
	i_th0_acc,
	i_th0_vl,
	i_th0_en,
	i_th0_rs,
	i_th0_rt,
	i_th1_acc,
	i_th1_vl,
	i_th1_en,
	i_th1_rs,
	i_th1_rt,
	i_th2_acc,
	i_th2_vl,
	i_th2_en,
	i_th2_rs,
	i_th2_rt,
	i_th3_acc,
	i_th3_vl,
	i_th3_en,
	i_th3_rs,
	i_th3_rt,
	i_th4_acc,
	i_th4_vl,
	i_th4_en,
	i_th4_rs,
	i_th4_rt,
	i_th5_acc,
	i_th5_vl,
	i_th5_en,
	i_th5_rs,
	i_th5_rt,
	i_th6_acc,
	i_th6_vl,
	i_th6_en,
	i_th6_rs,
	i_th6_rt,
	i_th7_acc,
	i_th7_vl,
	i_th7_en,
	i_th7_rs,
	i_th7_rt
);
/* Global signals */
input wire		clk;
input wire		nrst;
/* Control unit interface */
input wire		i_start;
output wire		o_busy;
/* LSU interface */
input wire		i_lsu_err;
input wire		i_lsu_rrq_rdy;
output wire		o_lsu_rrq_wr;
output wire [2:0]	o_lsu_rrq_th;
output wire [36:0]	o_lsu_rrq_addr;
output wire		o_lsu_rrq_arg;
input wire		i_lsu_rrs_vld;
output wire		o_lsu_rrs_rd;
input wire [2:0]	i_lsu_rrs_th;
input wire		i_lsu_rrs_arg;
input wire [63:0]	i_lsu_rrs_data;
/* Register file interface */
output wire [2:0]	o_prod_th;
output wire [2:0]	o_prod_ridx;
output wire		o_prod_wr_en;
output wire [37:0]	o_prod_data;
/* Register values */
input wire [31:0]	i_th0_acc;
input wire [19:0]	i_th0_vl;
input wire		i_th0_en;
input wire [37:0]	i_th0_rs;
input wire [37:0]	i_th0_rt;
input wire [31:0]	i_th1_acc;
input wire [19:0]	i_th1_vl;
input wire		i_th1_en;
input wire [37:0]	i_th1_rs;
input wire [37:0]	i_th1_rt;
input wire [31:0]	i_th2_acc;
input wire [19:0]	i_th2_vl;
input wire		i_th2_en;
input wire [37:0]	i_th2_rs;
input wire [37:0]	i_th2_rt;
input wire [31:0]	i_th3_acc;
input wire [19:0]	i_th3_vl;
input wire		i_th3_en;
input wire [37:0]	i_th3_rs;
input wire [37:0]	i_th3_rt;
input wire [31:0]	i_th4_acc;
input wire [19:0]	i_th4_vl;
input wire		i_th4_en;
input wire [37:0]	i_th4_rs;
input wire [37:0]	i_th4_rt;
input wire [31:0]	i_th5_acc;
input wire [19:0]	i_th5_vl;
input wire		i_th5_en;
input wire [37:0]	i_th5_rs;
input wire [37:0]	i_th5_rt;
input wire [31:0]	i_th6_acc;
input wire [19:0]	i_th6_vl;
input wire		i_th6_en;
input wire [37:0]	i_th6_rs;
input wire [37:0]	i_th6_rt;
input wire [31:0]	i_th7_acc;
input wire [19:0]	i_th7_vl;
input wire		i_th7_en;
input wire [37:0]	i_th7_rs;
input wire [37:0]	i_th7_rt;


genvar i, j;	/* Generator block vars */

wire rqd_busy;		/* Requests dispatcher is busy */
wire rsd_busy;		/* Responses distributor is busy */
wire fmac_busy;		/* FMAC unit is busy */
reg busy_q;

assign o_busy = rqd_busy || rsd_busy || fmac_busy || busy_q;

/* Assert busy on the next cycle */
always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		busy_q <= 1'b0;
	end
	else
	begin
		busy_q <= i_start;
	end
end



/*************** Generate instances of address generator units ****************/

generate

for(i = 0; i < 8; i = i + 1)		/* For loop for threads (0 - 7) */
begin : t_ag
	for(j = 0; j < 2; j = j + 1)	/* For loop for arguments (Rs=0, Rt=1) */
	begin : r
		wire [37:0]	vaddr;
		wire [19:0]	vlen;
		wire		venab;
		wire		incr;
		wire		valid;
		wire [36:0]	addr;
		wire [1:0]	we_mask;

		vxe_vpu_prod_eu_agen agen(
			.clk(clk),
			.nrst(nrst),
			.i_vaddr(vaddr),
			.i_vlen(vlen),
			.i_latch(venab & i_start),	/* Latch on start */
			.i_incr(incr),
			.o_valid(valid),
			.o_addr(addr),
			.o_we_mask(we_mask)
		);
	end	/* for(j, ...) */
end	/* for(i, ...) */
endgenerate


/*** Connect generated blocks ***/

/* Thread 0, Rs */
assign t_ag[0].r[0].vaddr = i_th0_rs;
assign t_ag[0].r[0].vlen = i_th0_vl;
assign t_ag[0].r[0].venab = i_th0_en;
/* Thread 0, Rt */
assign t_ag[0].r[1].vaddr = i_th0_rt;
assign t_ag[0].r[1].vlen = i_th0_vl;
assign t_ag[0].r[1].venab = i_th0_en;
/* Thread 1, Rs */
assign t_ag[1].r[0].vaddr = i_th1_rs;
assign t_ag[1].r[0].vlen = i_th1_vl;
assign t_ag[1].r[0].venab = i_th1_en;
/* Thread 1, Rt */
assign t_ag[1].r[1].vaddr = i_th1_rt;
assign t_ag[1].r[1].vlen = i_th1_vl;
assign t_ag[1].r[1].venab = i_th1_en;
/* Thread 2, Rs */
assign t_ag[2].r[0].vaddr = i_th2_rs;
assign t_ag[2].r[0].vlen = i_th2_vl;
assign t_ag[2].r[0].venab = i_th2_en;
/* Thread 2, Rt */
assign t_ag[2].r[1].vaddr = i_th2_rt;
assign t_ag[2].r[1].vlen = i_th2_vl;
assign t_ag[2].r[1].venab = i_th2_en;
/* Thread 3, Rs */
assign t_ag[3].r[0].vaddr = i_th3_rs;
assign t_ag[3].r[0].vlen = i_th3_vl;
assign t_ag[3].r[0].venab = i_th3_en;
/* Thread 3, Rt */
assign t_ag[3].r[1].vaddr = i_th3_rt;
assign t_ag[3].r[1].vlen = i_th3_vl;
assign t_ag[3].r[1].venab = i_th3_en;
/* Thread 4, Rs */
assign t_ag[4].r[0].vaddr = i_th4_rs;
assign t_ag[4].r[0].vlen = i_th4_vl;
assign t_ag[4].r[0].venab = i_th4_en;
/* Thread 4, Rt */
assign t_ag[4].r[1].vaddr = i_th4_rt;
assign t_ag[4].r[1].vlen = i_th4_vl;
assign t_ag[4].r[1].venab = i_th4_en;
/* Thread 5, Rs */
assign t_ag[5].r[0].vaddr = i_th5_rs;
assign t_ag[5].r[0].vlen = i_th5_vl;
assign t_ag[5].r[0].venab = i_th5_en;
/* Thread 5, Rt */
assign t_ag[5].r[1].vaddr = i_th5_rt;
assign t_ag[5].r[1].vlen = i_th5_vl;
assign t_ag[5].r[1].venab = i_th5_en;
/* Thread 6, Rs */
assign t_ag[6].r[0].vaddr = i_th6_rs;
assign t_ag[6].r[0].vlen = i_th6_vl;
assign t_ag[6].r[0].venab = i_th6_en;
/* Thread 6, Rt */
assign t_ag[6].r[1].vaddr = i_th6_rt;
assign t_ag[6].r[1].vlen = i_th6_vl;
assign t_ag[6].r[1].venab = i_th6_en;
/* Thread 7, Rs */
assign t_ag[7].r[0].vaddr = i_th7_rs;
assign t_ag[7].r[0].vlen = i_th7_vl;
assign t_ag[7].r[0].venab = i_th7_en;
/* Thread 7, Rt */
assign t_ag[7].r[1].vaddr = i_th7_rt;
assign t_ag[7].r[1].vlen = i_th7_vl;
assign t_ag[7].r[1].venab = i_th7_en;



/**************** Generate instances of write enable FIFOs ********************/

generate

for(i = 0; i < 8; i = i + 1)		/* For loop for threads (0 - 7) */
begin : t_we
	for(j = 0; j < 2; j = j + 1)	/* For loop for arguments (Rs=0, Rt=1) */
	begin : r
		wire [1:0]	in_mask;
		wire		wr;
		wire		rdy;
		wire [1:0]	out_mask;
		wire		rd;
		wire		vld;

		vxe_fifo #(
			.DATA_WIDTH(2),
			.DEPTH_POW2(WE_DEPTH_POW2)
		) fifo (
			.clk(clk),
			.nrst(nrst),
			.data_in(in_mask),
			.data_out(out_mask),
			.rd(rd),
			.wr(wr),
			.in_rdy(rdy),
			.out_vld(vld)
		);
	end	/* for(j, ...) */
end	/* for(i, ...) */
endgenerate



/***************** Generate instances of operand FIFOs ************************/

generate

for(i = 0; i < 8; i = i + 1)		/* For loop for threads (0 - 7) */
begin : t_op
	for(j = 0; j < 2; j = j + 1)	/* For loop for arguments (Rs=0, Rt=1) */
	begin : r
		wire [63:0]	dat_in;
		wire [31:0]	dat_out;
		wire		rd;
		wire [1:0]	wr;
		wire		rdy;
		wire		vld;

		vxe_fifo2wxw #(
			.DATA_WIDTH(32),
			.DEPTH_POW2(OP_DEPTH_POW2)
		) fifo (
			.clk(clk),
			.nrst(nrst),
			.data_in(dat_in),
			.data_out(dat_out),
			.rd(rd),
			.wr(wr),
			.in_rdy(rdy),
			.out_vld(vld)
		);
	end	/* for(j, ...) */
end	/* for(i, ...) */
endgenerate



/*************************** REQUESTS DISPATCHER ******************************/

/* Requests dispatcher unit */
vxe_vpu_prod_eu_rq_disp #(
	.IN_DEPTH_POW2(RQD_IN_DEPTH_POW2),
	.OUT_DEPTH_POW2(RQD_OUT_DEPTH_POW2)
) rq_disp (
	.clk(clk),
	.nrst(nrst),
	.i_err_flush(i_lsu_err),
	.o_busy(rqd_busy),
	.i_rs0_valid(t_ag[0].r[0].valid),
	.i_rs0_addr(t_ag[0].r[0].addr),
	.i_rs0_we_mask(t_ag[0].r[0].we_mask),
	.o_rs0_incr(t_ag[0].r[0].incr),
	.i_rt0_valid(t_ag[0].r[1].valid),
	.i_rt0_addr(t_ag[0].r[1].addr),
	.i_rt0_we_mask(t_ag[0].r[1].we_mask),
	.o_rt0_incr(t_ag[0].r[1].incr),
	.i_rs1_valid(t_ag[1].r[0].valid),
	.i_rs1_addr(t_ag[1].r[0].addr),
	.i_rs1_we_mask(t_ag[1].r[0].we_mask),
	.o_rs1_incr(t_ag[1].r[0].incr),
	.i_rt1_valid(t_ag[1].r[1].valid),
	.i_rt1_addr(t_ag[1].r[1].addr),
	.i_rt1_we_mask(t_ag[1].r[1].we_mask),
	.o_rt1_incr(t_ag[1].r[1].incr),
	.i_rs2_valid(t_ag[2].r[0].valid),
	.i_rs2_addr(t_ag[2].r[0].addr),
	.i_rs2_we_mask(t_ag[2].r[0].we_mask),
	.o_rs2_incr(t_ag[2].r[0].incr),
	.i_rt2_valid(t_ag[2].r[1].valid),
	.i_rt2_addr(t_ag[2].r[1].addr),
	.i_rt2_we_mask(t_ag[2].r[1].we_mask),
	.o_rt2_incr(t_ag[2].r[1].incr),
	.i_rs3_valid(t_ag[3].r[0].valid),
	.i_rs3_addr(t_ag[3].r[0].addr),
	.i_rs3_we_mask(t_ag[3].r[0].we_mask),
	.o_rs3_incr(t_ag[3].r[0].incr),
	.i_rt3_valid(t_ag[3].r[1].valid),
	.i_rt3_addr(t_ag[3].r[1].addr),
	.i_rt3_we_mask(t_ag[3].r[1].we_mask),
	.o_rt3_incr(t_ag[3].r[1].incr),
	.i_rs4_valid(t_ag[4].r[0].valid),
	.i_rs4_addr(t_ag[4].r[0].addr),
	.i_rs4_we_mask(t_ag[4].r[0].we_mask),
	.o_rs4_incr(t_ag[4].r[0].incr),
	.i_rt4_valid(t_ag[4].r[1].valid),
	.i_rt4_addr(t_ag[4].r[1].addr),
	.i_rt4_we_mask(t_ag[4].r[1].we_mask),
	.o_rt4_incr(t_ag[4].r[1].incr),
	.i_rs5_valid(t_ag[5].r[0].valid),
	.i_rs5_addr(t_ag[5].r[0].addr),
	.i_rs5_we_mask(t_ag[5].r[0].we_mask),
	.o_rs5_incr(t_ag[5].r[0].incr),
	.i_rt5_valid(t_ag[5].r[1].valid),
	.i_rt5_addr(t_ag[5].r[1].addr),
	.i_rt5_we_mask(t_ag[5].r[1].we_mask),
	.o_rt5_incr(t_ag[5].r[1].incr),
	.i_rs6_valid(t_ag[6].r[0].valid),
	.i_rs6_addr(t_ag[6].r[0].addr),
	.i_rs6_we_mask(t_ag[6].r[0].we_mask),
	.o_rs6_incr(t_ag[6].r[0].incr),
	.i_rt6_valid(t_ag[6].r[1].valid),
	.i_rt6_addr(t_ag[6].r[1].addr),
	.i_rt6_we_mask(t_ag[6].r[1].we_mask),
	.o_rt6_incr(t_ag[6].r[1].incr),
	.i_rs7_valid(t_ag[7].r[0].valid),
	.i_rs7_addr(t_ag[7].r[0].addr),
	.i_rs7_we_mask(t_ag[7].r[0].we_mask),
	.o_rs7_incr(t_ag[7].r[0].incr),
	.i_rt7_valid(t_ag[7].r[1].valid),
	.i_rt7_addr(t_ag[7].r[1].addr),
	.i_rt7_we_mask(t_ag[7].r[1].we_mask),
	.o_rt7_incr(t_ag[7].r[1].incr),
	.o_rrq_rs0_we_mask(t_we[0].r[0].in_mask),
	.o_rrq_rs0_we_wr(t_we[0].r[0].wr),
	.i_rrq_rs0_we_rdy(t_we[0].r[0].rdy),
	.o_rrq_rt0_we_mask(t_we[0].r[1].in_mask),
	.o_rrq_rt0_we_wr(t_we[0].r[1].wr),
	.i_rrq_rt0_we_rdy(t_we[0].r[1].rdy),
	.o_rrq_rs1_we_mask(t_we[1].r[0].in_mask),
	.o_rrq_rs1_we_wr(t_we[1].r[0].wr),
	.i_rrq_rs1_we_rdy(t_we[1].r[0].rdy),
	.o_rrq_rt1_we_mask(t_we[1].r[1].in_mask),
	.o_rrq_rt1_we_wr(t_we[1].r[1].wr),
	.i_rrq_rt1_we_rdy(t_we[1].r[1].rdy),
	.o_rrq_rs2_we_mask(t_we[2].r[0].in_mask),
	.o_rrq_rs2_we_wr(t_we[2].r[0].wr),
	.i_rrq_rs2_we_rdy(t_we[2].r[0].rdy),
	.o_rrq_rt2_we_mask(t_we[2].r[1].in_mask),
	.o_rrq_rt2_we_wr(t_we[2].r[1].wr),
	.i_rrq_rt2_we_rdy(t_we[2].r[1].rdy),
	.o_rrq_rs3_we_mask(t_we[3].r[0].in_mask),
	.o_rrq_rs3_we_wr(t_we[3].r[0].wr),
	.i_rrq_rs3_we_rdy(t_we[3].r[0].rdy),
	.o_rrq_rt3_we_mask(t_we[3].r[1].in_mask),
	.o_rrq_rt3_we_wr(t_we[3].r[1].wr),
	.i_rrq_rt3_we_rdy(t_we[3].r[1].rdy),
	.o_rrq_rs4_we_mask(t_we[4].r[0].in_mask),
	.o_rrq_rs4_we_wr(t_we[4].r[0].wr),
	.i_rrq_rs4_we_rdy(t_we[4].r[0].rdy),
	.o_rrq_rt4_we_mask(t_we[4].r[1].in_mask),
	.o_rrq_rt4_we_wr(t_we[4].r[1].wr),
	.i_rrq_rt4_we_rdy(t_we[4].r[1].rdy),
	.o_rrq_rs5_we_mask(t_we[5].r[0].in_mask),
	.o_rrq_rs5_we_wr(t_we[5].r[0].wr),
	.i_rrq_rs5_we_rdy(t_we[5].r[0].rdy),
	.o_rrq_rt5_we_mask(t_we[5].r[1].in_mask),
	.o_rrq_rt5_we_wr(t_we[5].r[1].wr),
	.i_rrq_rt5_we_rdy(t_we[5].r[1].rdy),
	.o_rrq_rs6_we_mask(t_we[6].r[0].in_mask),
	.o_rrq_rs6_we_wr(t_we[6].r[0].wr),
	.i_rrq_rs6_we_rdy(t_we[6].r[0].rdy),
	.o_rrq_rt6_we_mask(t_we[6].r[1].in_mask),
	.o_rrq_rt6_we_wr(t_we[6].r[1].wr),
	.i_rrq_rt6_we_rdy(t_we[6].r[1].rdy),
	.o_rrq_rs7_we_mask(t_we[7].r[0].in_mask),
	.o_rrq_rs7_we_wr(t_we[7].r[0].wr),
	.i_rrq_rs7_we_rdy(t_we[7].r[0].rdy),
	.o_rrq_rt7_we_mask(t_we[7].r[1].in_mask),
	.o_rrq_rt7_we_wr(t_we[7].r[1].wr),
	.i_rrq_rt7_we_rdy(t_we[7].r[1].rdy),
	.i_rrq_rdy(i_lsu_rrq_rdy),
	.o_rrq_wr(o_lsu_rrq_wr),
	.o_rrq_th(o_lsu_rrq_th),
	.o_rrq_addr(o_lsu_rrq_addr),
	.o_rrq_arg(o_lsu_rrq_arg)
);



/************************** RESPONSES DISTRIBUTOR *****************************/

/* Responses distributor unit */
vxe_vpu_prod_eu_rs_dist #(
	.IN_WE_DEPTH_POW2(RSD_IN_WE_DEPTH_POW2),
	.IN_RS_DEPTH_POW2(RSD_IN_RS_DEPTH_POW2),
	.OUT_OP_DEPTH_POW2(RSD_OUT_OP_DEPTH_POW2)
) rs_dist (
	.clk(clk),
	.nrst(nrst),
	.i_err_flush(i_lsu_err),
	.o_busy(rsd_busy),
	.i_rrs_vld(i_lsu_rrs_vld),
	.o_rrs_rd(o_lsu_rrs_rd),
	.i_rrs_th(i_lsu_rrs_th),
	.i_rrs_arg(i_lsu_rrs_arg),
	.i_rrs_data(i_lsu_rrs_data),
	.i_rrs_rs0_we_mask(t_we[0].r[0].out_mask),
	.o_rrs_rs0_we_rd(t_we[0].r[0].rd),
	.i_rrs_rs0_we_vld(t_we[0].r[0].vld),
	.i_rrs_rt0_we_mask(t_we[0].r[1].out_mask),
	.o_rrs_rt0_we_rd(t_we[0].r[1].rd),
	.i_rrs_rt0_we_vld(t_we[0].r[1].vld),
	.i_rrs_rs1_we_mask(t_we[1].r[0].out_mask),
	.o_rrs_rs1_we_rd(t_we[1].r[0].rd),
	.i_rrs_rs1_we_vld(t_we[1].r[0].vld),
	.i_rrs_rt1_we_mask(t_we[1].r[1].out_mask),
	.o_rrs_rt1_we_rd(t_we[1].r[1].rd),
	.i_rrs_rt1_we_vld(t_we[1].r[1].vld),
	.i_rrs_rs2_we_mask(t_we[2].r[0].out_mask),
	.o_rrs_rs2_we_rd(t_we[2].r[0].rd),
	.i_rrs_rs2_we_vld(t_we[2].r[0].vld),
	.i_rrs_rt2_we_mask(t_we[2].r[1].out_mask),
	.o_rrs_rt2_we_rd(t_we[2].r[1].rd),
	.i_rrs_rt2_we_vld(t_we[2].r[1].vld),
	.i_rrs_rs3_we_mask(t_we[3].r[0].out_mask),
	.o_rrs_rs3_we_rd(t_we[3].r[0].rd),
	.i_rrs_rs3_we_vld(t_we[3].r[0].vld),
	.i_rrs_rt3_we_mask(t_we[3].r[1].out_mask),
	.o_rrs_rt3_we_rd(t_we[3].r[1].rd),
	.i_rrs_rt3_we_vld(t_we[3].r[1].vld),
	.i_rrs_rs4_we_mask(t_we[4].r[0].out_mask),
	.o_rrs_rs4_we_rd(t_we[4].r[0].rd),
	.i_rrs_rs4_we_vld(t_we[4].r[0].vld),
	.i_rrs_rt4_we_mask(t_we[4].r[1].out_mask),
	.o_rrs_rt4_we_rd(t_we[4].r[1].rd),
	.i_rrs_rt4_we_vld(t_we[4].r[1].vld),
	.i_rrs_rs5_we_mask(t_we[5].r[0].out_mask),
	.o_rrs_rs5_we_rd(t_we[5].r[0].rd),
	.i_rrs_rs5_we_vld(t_we[5].r[0].vld),
	.i_rrs_rt5_we_mask(t_we[5].r[1].out_mask),
	.o_rrs_rt5_we_rd(t_we[5].r[1].rd),
	.i_rrs_rt5_we_vld(t_we[5].r[1].vld),
	.i_rrs_rs6_we_mask(t_we[6].r[0].out_mask),
	.o_rrs_rs6_we_rd(t_we[6].r[0].rd),
	.i_rrs_rs6_we_vld(t_we[6].r[0].vld),
	.i_rrs_rt6_we_mask(t_we[6].r[1].out_mask),
	.o_rrs_rt6_we_rd(t_we[6].r[1].rd),
	.i_rrs_rt6_we_vld(t_we[6].r[1].vld),
	.i_rrs_rs7_we_mask(t_we[7].r[0].out_mask),
	.o_rrs_rs7_we_rd(t_we[7].r[0].rd),
	.i_rrs_rs7_we_vld(t_we[7].r[0].vld),
	.i_rrs_rt7_we_mask(t_we[7].r[1].out_mask),
	.o_rrs_rt7_we_rd(t_we[7].r[1].rd),
	.i_rrs_rt7_we_vld(t_we[7].r[1].vld),
	.o_f21_rs0_opd_data(t_op[0].r[0].dat_in),
	.o_f21_rs0_opd_wr(t_op[0].r[0].wr),
	.i_f21_rs0_opd_rdy(t_op[0].r[0].rdy),
	.o_f21_rt0_opd_data(t_op[0].r[1].dat_in),
	.o_f21_rt0_opd_wr(t_op[0].r[1].wr),
	.i_f21_rt0_opd_rdy(t_op[0].r[1].rdy),
	.o_f21_rs1_opd_data(t_op[1].r[0].dat_in),
	.o_f21_rs1_opd_wr(t_op[1].r[0].wr),
	.i_f21_rs1_opd_rdy(t_op[1].r[0].rdy),
	.o_f21_rt1_opd_data(t_op[1].r[1].dat_in),
	.o_f21_rt1_opd_wr(t_op[1].r[1].wr),
	.i_f21_rt1_opd_rdy(t_op[1].r[1].rdy),
	.o_f21_rs2_opd_data(t_op[2].r[0].dat_in),
	.o_f21_rs2_opd_wr(t_op[2].r[0].wr),
	.i_f21_rs2_opd_rdy(t_op[2].r[0].rdy),
	.o_f21_rt2_opd_data(t_op[2].r[1].dat_in),
	.o_f21_rt2_opd_wr(t_op[2].r[1].wr),
	.i_f21_rt2_opd_rdy(t_op[2].r[1].rdy),
	.o_f21_rs3_opd_data(t_op[3].r[0].dat_in),
	.o_f21_rs3_opd_wr(t_op[3].r[0].wr),
	.i_f21_rs3_opd_rdy(t_op[3].r[0].rdy),
	.o_f21_rt3_opd_data(t_op[3].r[1].dat_in),
	.o_f21_rt3_opd_wr(t_op[3].r[1].wr),
	.i_f21_rt3_opd_rdy(t_op[3].r[1].rdy),
	.o_f21_rs4_opd_data(t_op[4].r[0].dat_in),
	.o_f21_rs4_opd_wr(t_op[4].r[0].wr),
	.i_f21_rs4_opd_rdy(t_op[4].r[0].rdy),
	.o_f21_rt4_opd_data(t_op[4].r[1].dat_in),
	.o_f21_rt4_opd_wr(t_op[4].r[1].wr),
	.i_f21_rt4_opd_rdy(t_op[4].r[1].rdy),
	.o_f21_rs5_opd_data(t_op[5].r[0].dat_in),
	.o_f21_rs5_opd_wr(t_op[5].r[0].wr),
	.i_f21_rs5_opd_rdy(t_op[5].r[0].rdy),
	.o_f21_rt5_opd_data(t_op[5].r[1].dat_in),
	.o_f21_rt5_opd_wr(t_op[5].r[1].wr),
	.i_f21_rt5_opd_rdy(t_op[5].r[1].rdy),
	.o_f21_rs6_opd_data(t_op[6].r[0].dat_in),
	.o_f21_rs6_opd_wr(t_op[6].r[0].wr),
	.i_f21_rs6_opd_rdy(t_op[6].r[0].rdy),
	.o_f21_rt6_opd_data(t_op[6].r[1].dat_in),
	.o_f21_rt6_opd_wr(t_op[6].r[1].wr),
	.i_f21_rt6_opd_rdy(t_op[6].r[1].rdy),
	.o_f21_rs7_opd_data(t_op[7].r[0].dat_in),
	.o_f21_rs7_opd_wr(t_op[7].r[0].wr),
	.i_f21_rs7_opd_rdy(t_op[7].r[0].rdy),
	.o_f21_rt7_opd_data(t_op[7].r[1].dat_in),
	.o_f21_rt7_opd_wr(t_op[7].r[1].wr),
	.i_f21_rt7_opd_rdy(t_op[7].r[1].rdy)
);



/***************************** FMAC SCHEDULER *********************************/

/* FMAC scheduler unit */
vxe_vpu_prod_eu_fmac #(
	.IN_OP_DEPTH_POW2(FMAC_IN_OP_DEPTH_POW2)
) fmac_sched (
	.clk(clk),
	.nrst(nrst),
	.i_err_flush(i_lsu_err),
	.o_busy(fmac_busy),
	.i_rs0_opd_data(t_op[0].r[0].dat_out),
	.o_rs0_opd_rd(t_op[0].r[0].rd),
	.i_rs0_opd_vld(t_op[0].r[0].vld),
	.i_rt0_opd_data(t_op[0].r[1].dat_out),
	.o_rt0_opd_rd(t_op[0].r[1].rd),
	.i_rt0_opd_vld(t_op[0].r[1].vld),
	.i_rs1_opd_data(t_op[1].r[0].dat_out),
	.o_rs1_opd_rd(t_op[1].r[0].rd),
	.i_rs1_opd_vld(t_op[1].r[0].vld),
	.i_rt1_opd_data(t_op[1].r[1].dat_out),
	.o_rt1_opd_rd(t_op[1].r[1].rd),
	.i_rt1_opd_vld(t_op[1].r[1].vld),
	.i_rs2_opd_data(t_op[2].r[0].dat_out),
	.o_rs2_opd_rd(t_op[2].r[0].rd),
	.i_rs2_opd_vld(t_op[2].r[0].vld),
	.i_rt2_opd_data(t_op[2].r[1].dat_out),
	.o_rt2_opd_rd(t_op[2].r[1].rd),
	.i_rt2_opd_vld(t_op[2].r[1].vld),
	.i_rs3_opd_data(t_op[3].r[0].dat_out),
	.o_rs3_opd_rd(t_op[3].r[0].rd),
	.i_rs3_opd_vld(t_op[3].r[0].vld),
	.i_rt3_opd_data(t_op[3].r[1].dat_out),
	.o_rt3_opd_rd(t_op[3].r[1].rd),
	.i_rt3_opd_vld(t_op[3].r[1].vld),
	.i_rs4_opd_data(t_op[4].r[0].dat_out),
	.o_rs4_opd_rd(t_op[4].r[0].rd),
	.i_rs4_opd_vld(t_op[4].r[0].vld),
	.i_rt4_opd_data(t_op[4].r[1].dat_out),
	.o_rt4_opd_rd(t_op[4].r[1].rd),
	.i_rt4_opd_vld(t_op[4].r[1].vld),
	.i_rs5_opd_data(t_op[5].r[0].dat_out),
	.o_rs5_opd_rd(t_op[5].r[0].rd),
	.i_rs5_opd_vld(t_op[5].r[0].vld),
	.i_rt5_opd_data(t_op[5].r[1].dat_out),
	.o_rt5_opd_rd(t_op[5].r[1].rd),
	.i_rt5_opd_vld(t_op[5].r[1].vld),
	.i_rs6_opd_data(t_op[6].r[0].dat_out),
	.o_rs6_opd_rd(t_op[6].r[0].rd),
	.i_rs6_opd_vld(t_op[6].r[0].vld),
	.i_rt6_opd_data(t_op[6].r[1].dat_out),
	.o_rt6_opd_rd(t_op[6].r[1].rd),
	.i_rt6_opd_vld(t_op[6].r[1].vld),
	.i_rs7_opd_data(t_op[7].r[0].dat_out),
	.o_rs7_opd_rd(t_op[7].r[0].rd),
	.i_rs7_opd_vld(t_op[7].r[0].vld),
	.i_rt7_opd_data(t_op[7].r[1].dat_out),
	.o_rt7_opd_rd(t_op[7].r[1].rd),
	.i_rt7_opd_vld(t_op[7].r[1].vld),
	.i_th0_acc(i_th0_acc),
	.i_th1_acc(i_th1_acc),
	.i_th2_acc(i_th2_acc),
	.i_th3_acc(i_th3_acc),
	.i_th4_acc(i_th4_acc),
	.i_th5_acc(i_th5_acc),
	.i_th6_acc(i_th6_acc),
	.i_th7_acc(i_th7_acc),
	.o_prod_th(o_prod_th),
	.o_prod_ridx(o_prod_ridx),
	.o_prod_wr_en(o_prod_wr_en),
	.o_prod_data(o_prod_data)
);


endmodule /* vxe_vpu_prod_eu */
