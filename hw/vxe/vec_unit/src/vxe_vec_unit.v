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
 * VxE vector processing unit top-level
 */


/* Vector unit */
module vxe_vec_unit #(
	parameter [1:0] CLIENT_ID = 0	/* Client Id */
)
(
	clk,
	nrst,
	/* Memory request channel */
	i_rqa_rdy,
	o_rqa,
	o_rqa_wr,
	i_rqd_rdy,
	o_rqd,
	o_rqd_wr,
	/* Memory response channel */
	i_rss_vld,
	i_rss,
	o_rss_rd,
	i_rsd_vld,
	i_rsd,
	o_rsd_rd,
	/* Control interface */
	i_start,
	o_busy,
	o_err,
	/* Command interface */
	i_cmd_sel,
	o_cmd_ack,
	i_cmd_op,
	i_cmd_th,
	i_cmd_pl
);
/* Global signals */
input wire		clk;
input wire		nrst;
/* Memory request channel */
input wire		i_rqa_rdy;
output wire [43:0]	o_rqa;
output wire		o_rqa_wr;
input wire		i_rqd_rdy;
output wire [71:0]	o_rqd;
output wire		o_rqd_wr;
/* Memory response channel */
input wire		i_rss_vld;
input wire [8:0]	i_rss;
output wire		o_rss_rd;
input wire		i_rsd_vld;
input wire [63:0]	i_rsd;
output wire		o_rsd_rd;
/* Control interface */
input wire		i_start;
output wire		o_busy;
output wire		o_err;
/* Command interface */
input wire		i_cmd_sel;
output wire		o_cmd_ack;
input wire [4:0]	i_cmd_op;
input wire [2:0]	i_cmd_th;
input wire [47:0]	i_cmd_pl;



/**************************** Internal wiring *********************************/


/*** Command queue and dispatch ***/
wire		cmdq_busy;
wire		cmdq_vld;
wire		cmdq_rd;
wire [4:0]	cmdq_op;
wire [2:0]	cmdq_th;
wire [47:0]	cmdq_pl;

wire		cmdd_busy;
wire		cmdd_regu_disp;
wire		cmdd_regu_done;
wire		cmdd_prod_disp;
wire		cmdd_prod_done;
wire		cmdd_stor_disp;
wire		cmdd_stor_done;
wire		cmdd_actf_disp;
wire		cmdd_actf_done;
wire [4:0]	cmdd_fu_cmd_op;
wire [2:0]	cmdd_fu_cmd_th;
wire [47:0]	cmdd_fu_cmd_pl;
wire		cmdd_regu_cmd;
wire		cmdd_prod_cmd;
wire		cmdd_stor_cmd;	/* Not used */
wire		cmdd_actf_cmd;


/*** LSU ***/
wire		lsu_reinit = i_start;
wire		lsu_busy;
wire		lsu_err;
wire		lsu_rrq_rdy;
wire		lsu_rrq_wr;
wire [2:0]	lsu_rrq_th;
wire [36:0]	lsu_rrq_addr;
wire		lsu_rrq_arg;
wire		lsu_wrq_rdy;
wire		lsu_wrq_wr;
wire [2:0]	lsu_wrq_th;
wire [36:0]	lsu_wrq_addr;
wire [1:0]	lsu_wrq_wen;
wire [63:0]	lsu_wrq_data;
wire		lsu_rrs_vld;
wire		lsu_rrs_rd;
wire [2:0]	lsu_rrs_th;
wire		lsu_rrs_arg;
wire [63:0]	lsu_rrs_data;


/*** Activation function ***/
wire		act_ecu_eu_start;
wire		act_ecu_eu_busy;
wire		act_ecu_leaky;
wire [6:0]	act_ecu_expd;

wire		act_eu_start;
wire		act_eu_busy;
wire		act_eu;
wire [6:0]	act_eu_expd;


/*** Product ***/
wire		prod_ecu_eu_start;
wire		prod_ecu_eu_busy;

wire		prod_eu_start;
wire		prod_eu_busy;


/*** Store ***/
wire		stor_ecu_eu_start;
wire		stor_ecu_eu_busy;

input wire	stor_eu_start;
output wire	stor_eu_busy;


/** Register file ***/
wire [2:0]	rf_regu_th;
wire [2:0]	rf_regu_ridx;
wire		rf_regu_wr_en;
wire [37:0]	rf_regu_data;
wire [2:0]	rf_prod_th;
wire [2:0]	rf_prod_ridx;
wire		rf_prod_wr_en;
wire [37:0]	rf_prod_data;
wire [2:0]	rf_actf_th;
wire [2:0]	rf_actf_ridx;
wire		rf_actf_wr_en;
wire [37:0]	rf_actf_data;
wire [31:0]	rf_th0_acc;
wire [19:0]	rf_th0_vl;
wire		rf_th0_en;
wire [37:0]	rf_th0_rs;
wire [37:0]	rf_th0_rt;
wire [37:0]	rf_th0_rd;
wire [31:0]	rf_th1_acc;
wire [19:0]	rf_th1_vl;
wire		rf_th1_en;
wire [37:0]	rf_th1_rs;
wire [37:0]	rf_th1_rt;
wire [37:0]	rf_th1_rd;
wire [31:0]	rf_th2_acc;
wire [19:0]	rf_th2_vl;
wire		rf_th2_en;
wire [37:0]	rf_th2_rs;
wire [37:0]	rf_th2_rt;
wire [37:0]	rf_th2_rd;
wire [31:0]	rf_th3_acc;
wire [19:0]	rf_th3_vl;
wire		rf_th3_en;
wire [37:0]	rf_th3_rs;
wire [37:0]	rf_th3_rt;
wire [37:0]	rf_th3_rd;
wire [31:0]	rf_th4_acc;
wire [19:0]	rf_th4_vl;
wire		rf_th4_en;
wire [37:0]	rf_th4_rs;
wire [37:0]	rf_th4_rt;
wire [37:0]	rf_th4_rd;
wire [31:0]	rf_th5_acc;
wire [19:0]	rf_th5_vl;
wire		rf_th5_en;
wire [37:0]	rf_th5_rs;
wire [37:0]	rf_th5_rt;
wire [37:0]	rf_th5_rd;
wire [31:0]	rf_th6_acc;
wire [19:0]	rf_th6_vl;
wire		rf_th6_en;
wire [37:0]	rf_th6_rs;
wire [37:0]	rf_th6_rt;
wire [37:0]	rf_th6_rd;
wire [31:0]	rf_th7_acc;
wire [19:0]	rf_th7_vl;
wire		rf_th7_en;
wire [37:0]	rf_th7_rs;
wire [37:0]	rf_th7_rt;
wire [37:0]	rf_th7_rd;

assign o_busy = cmdq_busy || cmdd_busy;
assign o_err = lsu_err;



/**************************** Block instances *********************************/


/*** Command queue ***/
vxe_vpu_cmd_queue #(
	.DEPTH_POW2(4)	/* Internal FIFO depth = 2^DEPTH_POW2 */
) cmd_queue (
	.clk(clk),
	.nrst(nrst),
	/* Control interface */
	.i_enable(i_start),
	.i_disable(lsu_err),
	.o_busy(cmdq_busy),
	/* Ingoing commands interface */
	.i_cmd_sel(i_cmd_sel),
	.o_cmd_ack(o_cmd_ack),
	.i_cmd_op(i_cmd_op),
	.i_cmd_th(i_cmd_th),
	.i_cmd_pl(i_cmd_pl),
	/* Outgoing commands interface */
	.o_vld(cmdq_vld),
	.i_rd(cmdq_rd),
	.o_op(cmdq_op),
	.o_th(cmdq_th),
	.o_pl(cmdq_pl)
);


/*** Command dispatch unit ***/
vxe_vpu_cmd_dispatch cmd_disp_unit(
	.clk(clk),
	.nrst(nrst),
	/* Command queue interface */
	.i_vld(cmdq_vld),
	.o_rd(cmdq_rd),
	.i_op(cmdq_op),
	.i_th(cmdq_th),
	.i_pl(cmdq_pl),
	/* Status */
	.o_busy(cmdd_busy),
	/* Functional units interface */
	.regu_disp(cmdd_regu_disp),
	.regu_done(cmdd_regu_done),
	.prod_disp(cmdd_prod_disp),
	.prod_done(cmdd_prod_done),
	.stor_disp(cmdd_stor_disp),
	.stor_done(cmdd_stor_done),
	.actf_disp(cmdd_actf_disp),
	.actf_done(cmdd_actf_done),
	.fu_cmd_op(cmdd_fu_cmd_op),
	.fu_cmd_th(cmdd_fu_cmd_th),
	.fu_cmd_pl(cmdd_fu_cmd_pl),
	/* Datapath MUX control */
	.regu_cmd(cmdd_regu_cmd),
	.prod_cmd(cmdd_prod_cmd),
	.stor_cmd(cmdd_stor_cmd),
	.actf_cmd(cmdd_actf_cmd)
);


/*** Load-store unit ***/
vxe_vpu_lsu #(
	.CLIENT_ID(CLIENT_ID),	/* Client Id */
	.NR_REQ_POW2(7),	/* Requests on the fly (2^NR_REQ_POW2) */
	.RD_DEPTH_POW2(5),	/* Read requests FIFO depth (2^RD_DEPTH_POW2) */
	.WR_DEPTH_POW2(2),	/* Write requests FIFO depth (2^WR_DEPTH_POW2) */
	.RS_DEPTH_POW2(5)	/* Read responses FIFO depth (2^RS_DEPTH_POW2) */
) lsu (
	.clk(clk),
	.nrst(nrst),
	/* External memory request channel */
	.i_rqa_rdy(i_rqa_rdy),
	.o_rqa(o_rqa),
	.o_rqa_wr(o_rqa_wr),
	.i_rqd_rdy(i_rqd_rdy),
	.o_rqd(o_rqd),
	.o_rqd_wr(o_rqd_wr),
	/* External memory response channel */
	.i_rss_vld(i_rss_vld),
	.i_rss(i_rss),
	.o_rss_rd(o_rss_rd),
	.i_rsd_vld(i_rsd_vld),
	.i_rsd(i_rsd),
	.o_rsd_rd(o_rsd_rd),
	/* Control interface */
	.i_reinit(lsu_reinit),
	.o_busy(lsu_busy),
	.o_err(lsu_err),
	/* Client interface */
	.o_rrq_rdy(lsu_rrq_rdy),	/* Read */
	.i_rrq_wr(lsu_rrq_wr),
	.i_rrq_th(lsu_rrq_th),
	.i_rrq_addr(lsu_rrq_addr),
	.i_rrq_arg(lsu_rrq_arg),
	.o_wrq_rdy(lsu_wrq_rdy),	/* Write */
	.i_wrq_wr(lsu_wrq_wr),
	.i_wrq_th(lsu_wrq_th),
	.i_wrq_addr(lsu_wrq_addr),
	.i_wrq_wen(lsu_wrq_wen),
	.i_wrq_data(lsu_wrq_data),
	.o_rrs_vld(lsu_rrs_vld),	/* Read response */
	.i_rrs_rd(lsu_rrs_rd),
	.o_rrs_th(lsu_rrs_th),
	.o_rrs_arg(lsu_rrs_arg),
	.o_rrs_data(lsu_rrs_data)
);


/*** Activation function execution control unit ***/
vxe_vpu_actf_ecu actf_ecu(
	.clk(clk),
	.nrst(nrst),
	/* Dispatch interface */
	.i_disp(cmdd_actf_disp),
	.o_done(cmdd_actf_done),
	.i_cmd_op(cmdd_fu_cmd_op),
	.i_cmd_th(cmdd_fu_cmd_th),
	.i_cmd_pl(cmdd_fu_cmd_pl),
	/* Execution unit interface */
	.o_eu_start(act_ecu_eu_start),
	.i_eu_busy(act_ecu_eu_busy),
	.o_leaky(act_ecu_leaky),
	.o_expd(act_ecu_expd)
);


/*** Activation function execution unit ***/
vxe_vpu_actf_eu actf_eu(
	.clk(clk),
	.nrst(nrst),
	/* Control unit interface */
	.i_start(act_ecu_eu_start),
	.o_busy(act_ecu_eu_busy),
	.i_leaky(act_ecu_leaky),
	.i_expd(act_ecu_expd),
	/* Register file interface */
	.o_th(rf_actf_th),
	.o_ridx(rf_actf_ridx),
	.o_wr_en(rf_actf_wr_en),
	.o_data(rf_actf_data),
	/* Register values */
	.i_th0_acc(rf_th0_acc),
	.i_th0_en(rf_th0_en),
	.i_th1_acc(rf_th1_acc),
	.i_th1_en(rf_th1_en),
	.i_th2_acc(rf_th2_acc),
	.i_th2_en(rf_th2_en),
	.i_th3_acc(rf_th3_acc),
	.i_th3_en(rf_th3_en),
	.i_th4_acc(rf_th4_acc),
	.i_th4_en(rf_th4_en),
	.i_th5_acc(rf_th5_acc),
	.i_th5_en(rf_th5_en),
	.i_th6_acc(rf_th6_acc),
	.i_th6_en(rf_th6_en),
	.i_th7_acc(rf_th7_acc),
	.i_th7_en(rf_th7_en)
);


/*** Product execution control unit ***/
vxe_vpu_prod_ecu prod_ecu(
	.clk(clk),
	.nrst(nrst),
	/* Dispatch interface */
	.i_disp(cmdd_prod_disp),
	.o_done(cmdd_prod_done),
	.i_cmd_op(cmdd_fu_cmd_op),
	.i_cmd_th(cmdd_fu_cmd_th),
	.i_cmd_pl(cmdd_fu_cmd_pl),
	/* Execution unit interface */
	.o_eu_start(prod_ecu_eu_start),
	.i_eu_busy(prod_ecu_eu_busy)
);


/*** Product execution unit ***/
vxe_vpu_prod_eu #(
	.WE_DEPTH_POW2(2),		/* Write enable FIFOs depth (2^WE_DEPTH_POW2) */
	.OP_DEPTH_POW2(2),		/* Operand FIFOs depth (2^WE_DEPTH_POW2) */
	/* Requests dispatcher unit */
	.RQD_IN_DEPTH_POW2(2),		/* Incoming FIFOs depth (2^IN_DEPTH_POW2) */
	.RQD_OUT_DEPTH_POW2(2),		/* Outgoing FIFOs depth (2^OUT_DEPTH_POW2) */
	/* Responses distributor unit */
	.RSD_IN_WE_DEPTH_POW2(2),	/* Incoming write enable FIFOs depth (2^IN_WE_DEPTH_POW2) */
	.RSD_IN_RS_DEPTH_POW2(3),	/* Incoming response FIFO depth (2^IN_RS_DEPTH_POW2) */
	.RSD_OUT_OP_DEPTH_POW2(2),	/* Outgoing operand FIFOs depth (2^OUT_OP_DEPTH_POW2) */
	/* FMAC scheduler unit */
	.FMAC_IN_OP_DEPTH_POW2(2)	/* Incoming operand FIFOs depth (2^IN_OP_DEPTH_POW2) */
) prod_eu (
	/* Global signals */
	.clk(clk),
	.nrst(nrst),
	/* Control unit interface */
	.i_start(prod_ecu_eu_start),
	.o_busy(prod_ecu_eu_busy),
	/* LSU interface */
	.i_lsu_err(lsu_err),
	.i_lsu_rrq_rdy(lsu_rrq_rdy),
	.o_lsu_rrq_wr(lsu_rrq_wr),
	.o_lsu_rrq_th(lsu_rrq_th),
	.o_lsu_rrq_addr(lsu_rrq_addr),
	.o_lsu_rrq_arg(lsu_rrq_arg),
	.i_lsu_rrs_vld(lsu_rrs_vld),
	.o_lsu_rrs_rd(lsu_rrs_rd),
	.i_lsu_rrs_th(lsu_rrs_th),
	.i_lsu_rrs_arg(lsu_rrs_arg),
	.i_lsu_rrs_data(lsu_rrs_data),
	/* Register file interface */
	.o_prod_th(rf_prod_th),
	.o_prod_ridx(rf_prod_ridx),
	.o_prod_wr_en(rf_prod_wr_en),
	.o_prod_data(rf_prod_data),
	/* Register values */
	.i_th0_acc(rf_th0_acc),
	.i_th0_vl(rf_th0_vl),
	.i_th0_en(rf_th0_en),
	.i_th0_rs(rf_th0_rs),
	.i_th0_rt(rf_th0_rt),
	.i_th1_acc(rf_th1_acc),
	.i_th1_vl(rf_th1_vl),
	.i_th1_en(rf_th1_en),
	.i_th1_rs(rf_th1_rs),
	.i_th1_rt(rf_th1_rt),
	.i_th2_acc(rf_th2_acc),
	.i_th2_vl(rf_th2_vl),
	.i_th2_en(rf_th2_en),
	.i_th2_rs(rf_th2_rs),
	.i_th2_rt(rf_th2_rt),
	.i_th3_acc(rf_th3_acc),
	.i_th3_vl(rf_th3_vl),
	.i_th3_en(rf_th3_en),
	.i_th3_rs(rf_th3_rs),
	.i_th3_rt(rf_th3_rt),
	.i_th4_acc(rf_th4_acc),
	.i_th4_vl(rf_th4_vl),
	.i_th4_en(rf_th4_en),
	.i_th4_rs(rf_th4_rs),
	.i_th4_rt(rf_th4_rt),
	.i_th5_acc(rf_th5_acc),
	.i_th5_vl(rf_th5_vl),
	.i_th5_en(rf_th5_en),
	.i_th5_rs(rf_th5_rs),
	.i_th5_rt(rf_th5_rt),
	.i_th6_acc(rf_th6_acc),
	.i_th6_vl(rf_th6_vl),
	.i_th6_en(rf_th6_en),
	.i_th6_rs(rf_th6_rs),
	.i_th6_rt(rf_th6_rt),
	.i_th7_acc(rf_th7_acc),
	.i_th7_vl(rf_th7_vl),
	.i_th7_en(rf_th7_en),
	.i_th7_rs(rf_th7_rs),
	.i_th7_rt(rf_th7_rt)
);


/*** Register update unit ***/
vxe_vpu_regu_ecu regu(
	.clk(clk),
	.nrst(nrst),
	/* Dispatch interface */
	.i_disp(cmdd_regu_disp),
	.o_done(cmdd_regu_done),
	.i_cmd_op(cmdd_fu_cmd_op),
	.i_cmd_th(cmdd_fu_cmd_th),
	.i_cmd_pl(cmdd_fu_cmd_pl),
	/* Register file interface */
	.o_th(rf_regu_th),
	.o_ridx(rf_regu_ridx),
	.o_wr_en(rf_regu_wr_en),
	.o_data(rf_regu_data)
);


/*** Store execution control unit ***/
vxe_vpu_stor_ecu stor_ecu(
	.clk(clk),
	.nrst(nrst),
	/* Dispatch interface */
	.i_disp(cmdd_stor_disp),
	.o_done(cmdd_stor_done),
	.i_cmd_op(cmdd_fu_cmd_op),
	.i_cmd_th(cmdd_fu_cmd_th),
	.i_cmd_pl(cmdd_fu_cmd_pl),
	/* Execution unit interface */
	.o_eu_start(stor_ecu_eu_start),
	.i_eu_busy(stor_ecu_eu_busy)
);


/*** Store execution unit ***/
vxe_vpu_stor_eu stor_eu(
	.clk(clk),
	.nrst(nrst),
	/* Control unit interface */
	.i_start(stor_ecu_eu_start),
	.o_busy(stor_ecu_eu_busy),
	/* LSU interface */
	.i_lsu_wrq_rdy(lsu_wrq_rdy),
	.o_lsu_wrq_wr(lsu_wrq_wr),
	.o_lsu_wrq_th(lsu_wrq_th),
	.o_lsu_wrq_addr(lsu_wrq_addr),
	.o_lsu_wrq_wen(lsu_wrq_wen),
	.o_lsu_wrq_data(lsu_wrq_data),
	/* Register values */
	.i_th0_acc(rf_th0_acc),
	.i_th0_en(rf_th0_en),
	.i_th0_rd(rf_th0_rd),
	.i_th1_acc(rf_th1_acc),
	.i_th1_en(rf_th1_en),
	.i_th1_rd(rf_th1_rd),
	.i_th2_acc(rf_th2_acc),
	.i_th2_en(rf_th2_en),
	.i_th2_rd(rf_th2_rd),
	.i_th3_acc(rf_th3_acc),
	.i_th3_en(rf_th3_en),
	.i_th3_rd(rf_th3_rd),
	.i_th4_acc(rf_th4_acc),
	.i_th4_en(rf_th4_en),
	.i_th4_rd(rf_th4_rd),
	.i_th5_acc(rf_th5_acc),
	.i_th5_en(rf_th5_en),
	.i_th5_rd(rf_th5_rd),
	.i_th6_acc(rf_th6_acc),
	.i_th6_en(rf_th6_en),
	.i_th6_rd(rf_th6_rd),
	.i_th7_acc(rf_th7_acc),
	.i_th7_en(rf_th7_en),
	.i_th7_rd(rf_th7_rd)
);


/*** Register file ***/
vxe_vpu_rf rf(
	.clk(clk),
	.nrst(nrst),
	/* RF write interface */
	.i_regu_cmd(cmdd_regu_cmd),
	.i_regu_th(rf_regu_th),
	.i_regu_ridx(rf_regu_ridx),
	.i_regu_wr_en(rf_regu_wr_en),
	.i_regu_data(rf_regu_data),
	.i_prod_cmd(cmdd_prod_cmd),
	.i_prod_th(rf_prod_th),
	.i_prod_ridx(rf_prod_ridx),
	.i_prod_wr_en(rf_prod_wr_en),
	.i_prod_data(rf_prod_data),
	.i_actf_cmd(cmdd_actf_cmd),
	.i_actf_th(rf_actf_th),
	.i_actf_ridx(rf_actf_ridx),
	.i_actf_wr_en(rf_actf_wr_en),
	.i_actf_data(rf_actf_data),
	/* Register values */
	.out_th0_acc(rf_th0_acc),
	.out_th0_vl(rf_th0_vl),
	.out_th0_en(rf_th0_en),
	.out_th0_rs(rf_th0_rs),
	.out_th0_rt(rf_th0_rt),
	.out_th0_rd(rf_th0_rd),
	.out_th1_acc(rf_th1_acc),
	.out_th1_vl(rf_th1_vl),
	.out_th1_en(rf_th1_en),
	.out_th1_rs(rf_th1_rs),
	.out_th1_rt(rf_th1_rt),
	.out_th1_rd(rf_th1_rd),
	.out_th2_acc(rf_th2_acc),
	.out_th2_vl(rf_th2_vl),
	.out_th2_en(rf_th2_en),
	.out_th2_rs(rf_th2_rs),
	.out_th2_rt(rf_th2_rt),
	.out_th2_rd(rf_th2_rd),
	.out_th3_acc(rf_th3_acc),
	.out_th3_vl(rf_th3_vl),
	.out_th3_en(rf_th3_en),
	.out_th3_rs(rf_th3_rs),
	.out_th3_rt(rf_th3_rt),
	.out_th3_rd(rf_th3_rd),
	.out_th4_acc(rf_th4_acc),
	.out_th4_vl(rf_th4_vl),
	.out_th4_en(rf_th4_en),
	.out_th4_rs(rf_th4_rs),
	.out_th4_rt(rf_th4_rt),
	.out_th4_rd(rf_th4_rd),
	.out_th5_acc(rf_th5_acc),
	.out_th5_vl(rf_th5_vl),
	.out_th5_en(rf_th5_en),
	.out_th5_rs(rf_th5_rs),
	.out_th5_rt(rf_th5_rt),
	.out_th5_rd(rf_th5_rd),
	.out_th6_acc(rf_th6_acc),
	.out_th6_vl(rf_th6_vl),
	.out_th6_en(rf_th6_en),
	.out_th6_rs(rf_th6_rs),
	.out_th6_rt(rf_th6_rt),
	.out_th6_rd(rf_th6_rd),
	.out_th7_acc(rf_th7_acc),
	.out_th7_vl(rf_th7_vl),
	.out_th7_en(rf_th7_en),
	.out_th7_rs(rf_th7_rs),
	.out_th7_rt(rf_th7_rt),
	.out_th7_rd(rf_th7_rd)
);


endmodule /* vxe_vec_unit */
