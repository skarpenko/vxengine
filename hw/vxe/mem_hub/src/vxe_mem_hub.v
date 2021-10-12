/*
 * Copyright (c) 2020-2021 The VxEngine Project. All rights reserved.
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
 * VxE memory hub
 */


/* Mem Hub */
module vxe_mem_hub(
	clk,
	nrst,
	/** CU **/
	/* Master port select */
	i_cu_m_sel,
	/* Request channel */
	i_cu_rqa_vld,
	i_cu_rqa,
	o_cu_rqa_rd,
	/* Response channel */
	i_cu_rss_rdy,
	o_cu_rss,
	o_cu_rss_wr,
	i_cu_rsd_rdy,
	o_cu_rsd,
	o_cu_rsd_wr,
	/** VPU0 **/
	/* Request channel */
	i_vpu0_rqa_vld,
	i_vpu0_rqa,
	o_vpu0_rqa_rd,
	i_vpu0_rqd_vld,
	i_vpu0_rqd,
	o_vpu0_rqd_rd,
	/* Response channel */
	i_vpu0_rss_rdy,
	o_vpu0_rss,
	o_vpu0_rss_wr,
	i_vpu0_rsd_rdy,
	o_vpu0_rsd,
	o_vpu0_rsd_wr,
	/** VPU1 **/
	/* Request channel */
	i_vpu1_rqa_vld,
	i_vpu1_rqa,
	o_vpu1_rqa_rd,
	i_vpu1_rqd_vld,
	i_vpu1_rqd,
	o_vpu1_rqd_rd,
	/* Response channel */
	i_vpu1_rss_rdy,
	o_vpu1_rss,
	o_vpu1_rss_wr,
	i_vpu1_rsd_rdy,
	o_vpu1_rsd,
	o_vpu1_rsd_wr,
	/** Master port 0 **/
	/* Request channel */
	i_m0_rqa_rdy,
	o_m0_rqa,
	o_m0_rqa_wr,
	i_m0_rqd_rdy,
	o_m0_rqd,
	o_m0_rqd_wr,
	/* Response channel */
	i_m0_rss_vld,
	i_m0_rss,
	o_m0_rss_rd,
	i_m0_rsd_vld,
	i_m0_rsd,
	o_m0_rsd_rd,
	/** Master port 1 **/
	/* Request channel */
	i_m1_rqa_rdy,
	o_m1_rqa,
	o_m1_rqa_wr,
	i_m1_rqd_rdy,
	o_m1_rqd,
	o_m1_rqd_wr,
	/* Response channel */
	i_m1_rss_vld,
	i_m1_rss,
	o_m1_rss_rd,
	i_m1_rsd_vld,
	i_m1_rsd,
	o_m1_rsd_rd
);
parameter		CU_RQ_FIFO_DEPTH_POW2 = 4;	/* CU request FIFO depth */
parameter		CU_RS_FIFO_DEPTH_POW2 = 4;	/* CU response FIFO depth */
parameter		VPU0_RQ_FIFO_DEPTH_POW2 = 4;	/* VPU0 request FIFO depth */
parameter		VPU0_RS_FIFO_DEPTH_POW2 = 4;	/* VPU0 response FIFO depth */
parameter		VPU1_RQ_FIFO_DEPTH_POW2 = 4;	/* VPU1 request FIFO depth */
parameter		VPU1_RS_FIFO_DEPTH_POW2 = 4;	/* VPU1 response FIFO depth */
/* Global signals */
input wire		clk;
input wire		nrst;
/** CU **/
/* Master port select */
input wire		i_cu_m_sel;
/* Request channel */
input wire		i_cu_rqa_vld;
input wire [43:0]	i_cu_rqa;
output wire		o_cu_rqa_rd;
/* Response channel */
input wire		i_cu_rss_rdy;
output wire [8:0]	o_cu_rss;
output wire		o_cu_rss_wr;
input wire		i_cu_rsd_rdy;
output wire [63:0]	o_cu_rsd;
output wire		o_cu_rsd_wr;
/** VPU0 **/
/* Request channel */
input wire		i_vpu0_rqa_vld;
input wire [43:0]	i_vpu0_rqa;
output wire		o_vpu0_rqa_rd;
input wire		i_vpu0_rqd_vld;
input wire [71:0]	i_vpu0_rqd;
output wire		o_vpu0_rqd_rd;
/* Response channel */
input wire		i_vpu0_rss_rdy;
output wire [8:0]	o_vpu0_rss;
output wire		o_vpu0_rss_wr;
input wire		i_vpu0_rsd_rdy;
output wire [63:0]	o_vpu0_rsd;
output wire		o_vpu0_rsd_wr;
/** VPU1 **/
/* Request channel */
input wire		i_vpu1_rqa_vld;
input wire [43:0]	i_vpu1_rqa;
output wire		o_vpu1_rqa_rd;
input wire		i_vpu1_rqd_vld;
input wire [71:0]	i_vpu1_rqd;
output wire		o_vpu1_rqd_rd;
/* Response channel */
input wire		i_vpu1_rss_rdy;
output wire [8:0]	o_vpu1_rss;
output wire		o_vpu1_rss_wr;
input wire		i_vpu1_rsd_rdy;
output wire [63:0]	o_vpu1_rsd;
output wire		o_vpu1_rsd_wr;
/** Master port 0 **/
/* Request channel */
input wire		i_m0_rqa_rdy;
output wire [43:0]	o_m0_rqa;
output wire		o_m0_rqa_wr;
input wire		i_m0_rqd_rdy;
output wire [71:0]	o_m0_rqd;
output wire		o_m0_rqd_wr;
/* Response channel */
input wire		i_m0_rss_vld;
input wire [8:0]	i_m0_rss;
output wire		o_m0_rss_rd;
input wire		i_m0_rsd_vld;
input wire [63:0]	i_m0_rsd;
output wire		o_m0_rsd_rd;
/** Master port 1 **/
/* Request channel */
input wire		i_m1_rqa_rdy;
output wire [43:0]	o_m1_rqa;
output wire		o_m1_rqa_wr;
input wire		i_m1_rqd_rdy;
output wire [71:0]	o_m1_rqd;
output wire		o_m1_rqd_wr;
/* Response channel */
input wire		i_m1_rss_vld;
input wire [8:0]	i_m1_rss;
output wire		o_m1_rss_rd;
input wire		i_m1_rsd_vld;
input wire [63:0]	i_m1_rsd;
output wire		o_m1_rsd_rd;


/** Internal interconnect wires **/

/* CU -> M0 */
wire		w_cu_m0_rqa_rdy;
wire [43:0]	w_cu_m0_rqa;
wire		w_cu_m0_rqa_wr;
wire		w_cu_m0_rss_vld;
wire [8:0]	w_cu_m0_rss;
wire		w_cu_m0_rss_rd;
wire		w_cu_m0_rsd_vld;
wire [63:0]	w_cu_m0_rsd;
wire		w_cu_m0_rsd_rd;

/* M0 -> CU */
wire		w_m0_cu_rqa_vld;
wire [43:0]	w_m0_cu_rqa;
wire		w_m0_cu_rqa_rd;
wire		w_m0_cu_rss_rdy;
wire [8:0]	w_m0_cu_rss;
wire		w_m0_cu_rss_wr;
wire		w_m0_cu_rsd_rdy;
wire [63:0]	w_m0_cu_rsd;
wire		w_m0_cu_rsd_wr;

/* CU -> M1 */
wire		w_cu_m1_rqa_rdy;
wire [43:0]	w_cu_m1_rqa;
wire		w_cu_m1_rqa_wr;
wire		w_cu_m1_rss_vld;
wire [8:0]	w_cu_m1_rss;
wire		w_cu_m1_rss_rd;
wire		w_cu_m1_rsd_vld;
wire [63:0]	w_cu_m1_rsd;
wire		w_cu_m1_rsd_rd;

/* M1 -> CU */
wire		w_m1_cu_rqa_vld;
wire [43:0]	w_m1_cu_rqa;
wire		w_m1_cu_rqa_rd;
wire		w_m1_cu_rss_rdy;
wire [8:0]	w_m1_cu_rss;
wire		w_m1_cu_rss_wr;
wire		w_m1_cu_rsd_rdy;
wire [63:0]	w_m1_cu_rsd;
wire		w_m1_cu_rsd_wr;

/* VPU0 -> M0 */
wire		w_vpu0_m0_rqa_rdy;
wire [43:0]	w_vpu0_m0_rqa;
wire		w_vpu0_m0_rqa_wr;
wire		w_vpu0_m0_rqd_rdy;
wire [71:0]	w_vpu0_m0_rqd;
wire		w_vpu0_m0_rqd_wr;
wire		w_vpu0_m0_rss_vld;
wire [8:0]	w_vpu0_m0_rss;
wire		w_vpu0_m0_rss_rd;
wire		w_vpu0_m0_rsd_vld;
wire [63:0]	w_vpu0_m0_rsd;
wire		w_vpu0_m0_rsd_rd;

/* M0 -> VPU0 */
wire		w_m0_vpu0_rqa_vld;
wire [43:0]	w_m0_vpu0_rqa;
wire		w_m0_vpu0_rqa_rd;
wire		w_m0_vpu0_rqd_vld;
wire [71:0]	w_m0_vpu0_rqd;
wire		w_m0_vpu0_rqd_rd;
wire		w_m0_vpu0_rss_rdy;
wire [8:0]	w_m0_vpu0_rss;
wire		w_m0_vpu0_rss_wr;
wire		w_m0_vpu0_rsd_rdy;
wire [63:0]	w_m0_vpu0_rsd;
wire		w_m0_vpu0_rsd_wr;

/* VPU0 -> M1 */
wire		w_vpu0_m1_rqa_rdy;
wire [43:0]	w_vpu0_m1_rqa;
wire		w_vpu0_m1_rqa_wr;
wire		w_vpu0_m1_rqd_rdy;
wire [71:0]	w_vpu0_m1_rqd;
wire		w_vpu0_m1_rqd_wr;
wire		w_vpu0_m1_rss_vld;
wire [8:0]	w_vpu0_m1_rss;
wire		w_vpu0_m1_rss_rd;
wire		w_vpu0_m1_rsd_vld;
wire [63:0]	w_vpu0_m1_rsd;
wire		w_vpu0_m1_rsd_rd;

/* M1 -> VPU0 */
wire		w_m1_vpu0_rqa_vld;
wire [43:0]	w_m1_vpu0_rqa;
wire		w_m1_vpu0_rqa_rd;
wire		w_m1_vpu0_rqd_vld;
wire [71:0]	w_m1_vpu0_rqd;
wire		w_m1_vpu0_rqd_rd;
wire		w_m1_vpu0_rss_rdy;
wire [8:0]	w_m1_vpu0_rss;
wire		w_m1_vpu0_rss_wr;
wire		w_m1_vpu0_rsd_rdy;
wire [63:0]	w_m1_vpu0_rsd;
wire		w_m1_vpu0_rsd_wr;

/* VPU1 -> M0 */
wire		w_vpu1_m0_rqa_rdy;
wire [43:0]	w_vpu1_m0_rqa;
wire		w_vpu1_m0_rqa_wr;
wire		w_vpu1_m0_rqd_rdy;
wire [71:0]	w_vpu1_m0_rqd;
wire		w_vpu1_m0_rqd_wr;
wire		w_vpu1_m0_rss_vld;
wire [8:0]	w_vpu1_m0_rss;
wire		w_vpu1_m0_rss_rd;
wire		w_vpu1_m0_rsd_vld;
wire [63:0]	w_vpu1_m0_rsd;
wire		w_vpu1_m0_rsd_rd;

/* M0 -> VPU1 */
wire		w_m0_vpu1_rqa_vld;
wire [43:0]	w_m0_vpu1_rqa;
wire		w_m0_vpu1_rqa_rd;
wire		w_m0_vpu1_rqd_vld;
wire [71:0]	w_m0_vpu1_rqd;
wire		w_m0_vpu1_rqd_rd;
wire		w_m0_vpu1_rss_rdy;
wire [8:0]	w_m0_vpu1_rss;
wire		w_m0_vpu1_rss_wr;
wire		w_m0_vpu1_rsd_rdy;
wire [63:0]	w_m0_vpu1_rsd;
wire		w_m0_vpu1_rsd_wr;

/* VPU1 -> M1 */
wire		w_vpu1_m1_rqa_rdy;
wire [43:0]	w_vpu1_m1_rqa;
wire		w_vpu1_m1_rqa_wr;
wire		w_vpu1_m1_rqd_rdy;
wire [71:0]	w_vpu1_m1_rqd;
wire		w_vpu1_m1_rqd_wr;
wire		w_vpu1_m1_rss_vld;
wire [8:0]	w_vpu1_m1_rss;
wire		w_vpu1_m1_rss_rd;
wire		w_vpu1_m1_rsd_vld;
wire [63:0]	w_vpu1_m1_rsd;
wire		w_vpu1_m1_rsd_rd;

/* M1 -> VPU1 */
wire		w_m1_vpu1_rqa_vld;
wire [43:0]	w_m1_vpu1_rqa;
wire		w_m1_vpu1_rqa_rd;
wire		w_m1_vpu1_rqd_vld;
wire [71:0]	w_m1_vpu1_rqd;
wire		w_m1_vpu1_rqd_rd;
wire		w_m1_vpu1_rss_rdy;
wire [8:0]	w_m1_vpu1_rss;
wire		w_m1_vpu1_rss_wr;
wire		w_m1_vpu1_rsd_rdy;
wire [63:0]	w_m1_vpu1_rsd;
wire		w_m1_vpu1_rsd_wr;


/* CU-M0 request FIFO (address channel) */
vxe_fifo #(
	.DATA_WIDTH(44),
	.DEPTH_POW2(CU_RQ_FIFO_DEPTH_POW2)
) fifo_cu_m0_rqa (
	.clk(clk),
	.nrst(nrst),
	.data_in(w_cu_m0_rqa),
	.data_out(w_m0_cu_rqa),
	.rd(w_m0_cu_rqa_rd),
	.wr(w_cu_m0_rqa_wr),
	.in_rdy(w_cu_m0_rqa_rdy),
	.out_vld(w_m0_cu_rqa_vld)
);

/* CU-M0 response FIFO (status channel) */
vxe_fifo #(
	.DATA_WIDTH(9),
	.DEPTH_POW2(CU_RS_FIFO_DEPTH_POW2)
) fifo_cu_m0_rss (
	.clk(clk),
	.nrst(nrst),
	.data_in(w_m0_cu_rss),
	.data_out(w_cu_m0_rss),
	.rd(w_cu_m0_rss_rd),
	.wr(w_m0_cu_rss_wr),
	.in_rdy(w_m0_cu_rss_rdy),
	.out_vld(w_cu_m0_rss_vld)
);

/* CU-M0 response FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(64),
	.DEPTH_POW2(CU_RS_FIFO_DEPTH_POW2)
) fifo_cu_m0_rsd (
	.clk(clk),
	.nrst(nrst),
	.data_in(w_m0_cu_rsd),
	.data_out(w_cu_m0_rsd),
	.rd(w_cu_m0_rsd_rd),
	.wr(w_m0_cu_rsd_wr),
	.in_rdy(w_m0_cu_rsd_rdy),
	.out_vld(w_cu_m0_rsd_vld)
);

/* CU-M1 request FIFO (address channel) */
vxe_fifo #(
	.DATA_WIDTH(44),
	.DEPTH_POW2(CU_RQ_FIFO_DEPTH_POW2)
) fifo_cu_m1_rqa (
	.clk(clk),
	.nrst(nrst),
	.data_in(w_cu_m1_rqa),
	.data_out(w_m1_cu_rqa),
	.rd(w_m1_cu_rqa_rd),
	.wr(w_cu_m1_rqa_wr),
	.in_rdy(w_cu_m1_rqa_rdy),
	.out_vld(w_m1_cu_rqa_vld)
);

/* CU-M1 response FIFO (status channel) */
vxe_fifo #(
	.DATA_WIDTH(9),
	.DEPTH_POW2(CU_RS_FIFO_DEPTH_POW2)
) fifo_cu_m1_rss (
	.clk(clk),
	.nrst(nrst),
	.data_in(w_m1_cu_rss),
	.data_out(w_cu_m1_rss),
	.rd(w_cu_m1_rss_rd),
	.wr(w_m1_cu_rss_wr),
	.in_rdy(w_m1_cu_rss_rdy),
	.out_vld(w_cu_m1_rss_vld)
);

/* CU-M1 response FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(64),
	.DEPTH_POW2(CU_RS_FIFO_DEPTH_POW2)
) fifo_cu_m1_rsd (
	.clk(clk),
	.nrst(nrst),
	.data_in(w_m1_cu_rsd),
	.data_out(w_cu_m1_rsd),
	.rd(w_cu_m1_rsd_rd),
	.wr(w_m1_cu_rsd_wr),
	.in_rdy(w_m1_cu_rsd_rdy),
	.out_vld(w_cu_m1_rsd_vld)
);

/* VPU0-M0 request FIFO (address channel) */
vxe_fifo #(
	.DATA_WIDTH(44),
	.DEPTH_POW2(VPU0_RQ_FIFO_DEPTH_POW2)
) fifo_vpu0_m0_rqa (
	.clk(clk),
	.nrst(nrst),
	.data_in(w_vpu0_m0_rqa),
	.data_out(w_m0_vpu0_rqa),
	.rd(w_m0_vpu0_rqa_rd),
	.wr(w_vpu0_m0_rqa_wr),
	.in_rdy(w_vpu0_m0_rqa_rdy),
	.out_vld(w_m0_vpu0_rqa_vld)
);

/* VPU0-M0 request FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(72),
	.DEPTH_POW2(VPU0_RQ_FIFO_DEPTH_POW2)
) fifo_vpu0_m0_rqd (
	.clk(clk),
	.nrst(nrst),
	.data_in(w_vpu0_m0_rqd),
	.data_out(w_m0_vpu0_rqd),
	.rd(w_m0_vpu0_rqd_rd),
	.wr(w_vpu0_m0_rqd_wr),
	.in_rdy(w_vpu0_m0_rqd_rdy),
	.out_vld(w_m0_vpu0_rqd_vld)
);

/* VPU0-M0 response FIFO (status channel) */
vxe_fifo #(
	.DATA_WIDTH(9),
	.DEPTH_POW2(VPU0_RS_FIFO_DEPTH_POW2)
) fifo_vpu0_m0_rss (
	.clk(clk),
	.nrst(nrst),
	.data_in(w_m0_vpu0_rss),
	.data_out(w_vpu0_m0_rss),
	.rd(w_vpu0_m0_rss_rd),
	.wr(w_m0_vpu0_rss_wr),
	.in_rdy(w_m0_vpu0_rss_rdy),
	.out_vld(w_vpu0_m0_rss_vld)
);

/* VPU0-M0 response FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(64),
	.DEPTH_POW2(VPU0_RS_FIFO_DEPTH_POW2)
) fifo_vpu0_m0_rsd (
	.clk(clk),
	.nrst(nrst),
	.data_in(w_m0_vpu0_rsd),
	.data_out(w_vpu0_m0_rsd),
	.rd(w_vpu0_m0_rsd_rd),
	.wr(w_m0_vpu0_rsd_wr),
	.in_rdy(w_m0_vpu0_rsd_rdy),
	.out_vld(w_vpu0_m0_rsd_vld)
);

/* VPU0-M1 request FIFO (address channel) */
vxe_fifo #(
	.DATA_WIDTH(44),
	.DEPTH_POW2(VPU0_RQ_FIFO_DEPTH_POW2)
) fifo_vpu0_m1_rqa (
	.clk(clk),
	.nrst(nrst),
	.data_in(w_vpu0_m1_rqa),
	.data_out(w_m1_vpu0_rqa),
	.rd(w_m1_vpu0_rqa_rd),
	.wr(w_vpu0_m1_rqa_wr),
	.in_rdy(w_vpu0_m1_rqa_rdy),
	.out_vld(w_m1_vpu0_rqa_vld)
);

/* VPU0-M1 request FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(72),
	.DEPTH_POW2(VPU0_RQ_FIFO_DEPTH_POW2)
) fifo_vpu0_m1_rqd (
	.clk(clk),
	.nrst(nrst),
	.data_in(w_vpu0_m1_rqd),
	.data_out(w_m1_vpu0_rqd),
	.rd(w_m1_vpu0_rqd_rd),
	.wr(w_vpu0_m1_rqd_wr),
	.in_rdy(w_vpu0_m1_rqd_rdy),
	.out_vld(w_m1_vpu0_rqd_vld)
);

/* VPU0-M1 response FIFO (status channel) */
vxe_fifo #(
	.DATA_WIDTH(9),
	.DEPTH_POW2(VPU0_RS_FIFO_DEPTH_POW2)
) fifo_vpu0_m1_rss (
	.clk(clk),
	.nrst(nrst),
	.data_in(w_m1_vpu0_rss),
	.data_out(w_vpu0_m1_rss),
	.rd(w_vpu0_m1_rss_rd),
	.wr(w_m1_vpu0_rss_wr),
	.in_rdy(w_m1_vpu0_rss_rdy),
	.out_vld(w_vpu0_m1_rss_vld)
);

/* VPU0-M1 response FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(64),
	.DEPTH_POW2(VPU0_RS_FIFO_DEPTH_POW2)
) fifo_vpu0_m1_rsd (
	.clk(clk),
	.nrst(nrst),
	.data_in(w_m1_vpu0_rsd),
	.data_out(w_vpu0_m1_rsd),
	.rd(w_vpu0_m1_rsd_rd),
	.wr(w_m1_vpu0_rsd_wr),
	.in_rdy(w_m1_vpu0_rsd_rdy),
	.out_vld(w_vpu0_m1_rsd_vld)
);

/* VPU1-M0 request FIFO (address channel) */
vxe_fifo #(
	.DATA_WIDTH(44),
	.DEPTH_POW2(VPU1_RQ_FIFO_DEPTH_POW2)
) fifo_vpu1_m0_rqa (
	.clk(clk),
	.nrst(nrst),
	.data_in(w_vpu1_m0_rqa),
	.data_out(w_m0_vpu1_rqa),
	.rd(w_m0_vpu1_rqa_rd),
	.wr(w_vpu1_m0_rqa_wr),
	.in_rdy(w_vpu1_m0_rqa_rdy),
	.out_vld(w_m0_vpu1_rqa_vld)
);

/* VPU1-M0 request FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(72),
	.DEPTH_POW2(VPU1_RQ_FIFO_DEPTH_POW2)
) fifo_vpu1_m0_rqd (
	.clk(clk),
	.nrst(nrst),
	.data_in(w_vpu1_m0_rqd),
	.data_out(w_m0_vpu1_rqd),
	.rd(w_m0_vpu1_rqd_rd),
	.wr(w_vpu1_m0_rqd_wr),
	.in_rdy(w_vpu1_m0_rqd_rdy),
	.out_vld(w_m0_vpu1_rqd_vld)
);

/* VPU1-M0 response FIFO (status channel) */
vxe_fifo #(
	.DATA_WIDTH(9),
	.DEPTH_POW2(VPU1_RS_FIFO_DEPTH_POW2)
) fifo_vpu1_m0_rss (
	.clk(clk),
	.nrst(nrst),
	.data_in(w_m0_vpu1_rss),
	.data_out(w_vpu1_m0_rss),
	.rd(w_vpu1_m0_rss_rd),
	.wr(w_m0_vpu1_rss_wr),
	.in_rdy(w_m0_vpu1_rss_rdy),
	.out_vld(w_vpu1_m0_rss_vld)
);

/* VPU1-M0 response FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(64),
	.DEPTH_POW2(VPU1_RS_FIFO_DEPTH_POW2)
) fifo_vpu1_m0_rsd (
	.clk(clk),
	.nrst(nrst),
	.data_in(w_m0_vpu1_rsd),
	.data_out(w_vpu1_m0_rsd),
	.rd(w_vpu1_m0_rsd_rd),
	.wr(w_m0_vpu1_rsd_wr),
	.in_rdy(w_m0_vpu1_rsd_rdy),
	.out_vld(w_vpu1_m0_rsd_vld)
);

/* VPU1-M1 request FIFO (address channel) */
vxe_fifo #(
	.DATA_WIDTH(44),
	.DEPTH_POW2(VPU1_RQ_FIFO_DEPTH_POW2)
) fifo_vpu1_m1_rqa (
	.clk(clk),
	.nrst(nrst),
	.data_in(w_vpu1_m1_rqa),
	.data_out(w_m1_vpu1_rqa),
	.rd(w_m1_vpu1_rqa_rd),
	.wr(w_vpu1_m1_rqa_wr),
	.in_rdy(w_vpu1_m1_rqa_rdy),
	.out_vld(w_m1_vpu1_rqa_vld)
);

/* VPU1-M1 request FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(72),
	.DEPTH_POW2(VPU1_RQ_FIFO_DEPTH_POW2)
) fifo_vpu1_m1_rqd (
	.clk(clk),
	.nrst(nrst),
	.data_in(w_vpu1_m1_rqd),
	.data_out(w_m1_vpu1_rqd),
	.rd(w_m1_vpu1_rqd_rd),
	.wr(w_vpu1_m1_rqd_wr),
	.in_rdy(w_vpu1_m1_rqd_rdy),
	.out_vld(w_m1_vpu1_rqd_vld)
);

/* VPU1-M1 response FIFO (status channel) */
vxe_fifo #(
	.DATA_WIDTH(9),
	.DEPTH_POW2(VPU1_RS_FIFO_DEPTH_POW2)
) fifo_vpu1_m1_rss (
	.clk(clk),
	.nrst(nrst),
	.data_in(w_m1_vpu1_rss),
	.data_out(w_vpu1_m1_rss),
	.rd(w_vpu1_m1_rss_rd),
	.wr(w_m1_vpu1_rss_wr),
	.in_rdy(w_m1_vpu1_rss_rdy),
	.out_vld(w_vpu1_m1_rss_vld)
);

/* VPU1-M1 response FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(64),
	.DEPTH_POW2(VPU1_RS_FIFO_DEPTH_POW2)
) fifo_vpu1_m1_rsd (
	.clk(clk),
	.nrst(nrst),
	.data_in(w_m1_vpu1_rsd),
	.data_out(w_vpu1_m1_rsd),
	.rd(w_vpu1_m1_rsd_rd),
	.wr(w_m1_vpu1_rsd_wr),
	.in_rdy(w_m1_vpu1_rsd_rdy),
	.out_vld(w_vpu1_m1_rsd_vld)
);



/* CU upstream unit */
vxe_mem_hub_cu_us cu_us(
	.clk(clk),
	.nrst(nrst),
	.i_m_sel(i_cu_m_sel),
	.i_rqa_vld(i_cu_rqa_vld),
	.i_rqa(i_cu_rqa),
	.o_rqa_rd(o_cu_rqa_rd),
	.i_m0_rqa_rdy(w_cu_m0_rqa_rdy),
	.o_m0_rqa(w_cu_m0_rqa),
	.o_m0_rqa_wr(w_cu_m0_rqa_wr),
	.i_m1_rqa_rdy(w_cu_m1_rqa_rdy),
	.o_m1_rqa(w_cu_m1_rqa),
	.o_m1_rqa_wr(w_cu_m1_rqa_wr)
);

/* CU downstream unit */
vxe_mem_hub_cu_ds cu_ds(
	.clk(clk),
	.nrst(nrst),
	.i_m_sel(i_cu_m_sel),
	.i_rss_rdy(i_cu_rss_rdy),
	.o_rss(o_cu_rss),
	.o_rss_wr(o_cu_rss_wr),
	.i_rsd_rdy(i_cu_rsd_rdy),
	.o_rsd(o_cu_rsd),
	.o_rsd_wr(o_cu_rsd_wr),
	.i_m0_rss_vld(w_cu_m0_rss_vld),
	.i_m0_rss(w_cu_m0_rss),
	.o_m0_rss_rd(w_cu_m0_rss_rd),
	.i_m0_rsd_vld(w_cu_m0_rsd_vld),
	.i_m0_rsd(w_cu_m0_rsd),
	.o_m0_rsd_rd(w_cu_m0_rsd_rd),
	.i_m1_rss_vld(w_cu_m1_rss_vld),
	.i_m1_rss(w_cu_m1_rss),
	.o_m1_rss_rd(w_cu_m1_rss_rd),
	.i_m1_rsd_vld(w_cu_m1_rsd_vld),
	.i_m1_rsd(w_cu_m1_rsd),
	.o_m1_rsd_rd(w_cu_m1_rsd_rd)
);


/* VPU0 upstream unit */
vxe_mem_hub_vpu_us vpu0_us(
	.clk(clk),
	.nrst(nrst),
	.i_rqa_vld(i_vpu0_rqa_vld),
	.i_rqa(i_vpu0_rqa),
	.o_rqa_rd(o_vpu0_rqa_rd),
	.i_rqd_vld(i_vpu0_rqd_vld),
	.i_rqd(i_vpu0_rqd),
	.o_rqd_rd(o_vpu0_rqd_rd),
	.i_m0_rqa_rdy(w_vpu0_m0_rqa_rdy),
	.o_m0_rqa(w_vpu0_m0_rqa),
	.o_m0_rqa_wr(w_vpu0_m0_rqa_wr),
	.i_m0_rqd_rdy(w_vpu0_m0_rqd_rdy),
	.o_m0_rqd(w_vpu0_m0_rqd),
	.o_m0_rqd_wr(w_vpu0_m0_rqd_wr),
	.i_m1_rqa_rdy(w_vpu0_m1_rqa_rdy),
	.o_m1_rqa(w_vpu0_m1_rqa),
	.o_m1_rqa_wr(w_vpu0_m1_rqa_wr),
	.i_m1_rqd_rdy(w_vpu0_m1_rqd_rdy),
	.o_m1_rqd(w_vpu0_m1_rqd),
	.o_m1_rqd_wr(w_vpu0_m1_rqd_wr)
);

/* VPU0 downstream unit */
vxe_mem_hub_vpu_ds vpu0_ds(
	.clk(clk),
	.nrst(nrst),
	.i_m0_rss_vld(w_vpu0_m0_rss_vld),
	.i_m0_rss(w_vpu0_m0_rss),
	.o_m0_rss_rd(w_vpu0_m0_rss_rd),
	.i_m0_rsd_vld(w_vpu0_m0_rsd_vld),
	.i_m0_rsd(w_vpu0_m0_rsd),
	.o_m0_rsd_rd(w_vpu0_m0_rsd_rd),
	.i_m1_rss_vld(w_vpu0_m1_rss_vld),
	.i_m1_rss(w_vpu0_m1_rss),
	.o_m1_rss_rd(w_vpu0_m1_rss_rd),
	.i_m1_rsd_vld(w_vpu0_m1_rsd_vld),
	.i_m1_rsd(w_vpu0_m1_rsd),
	.o_m1_rsd_rd(w_vpu0_m1_rsd_rd),
	.i_rss_rdy(i_vpu0_rss_rdy),
	.o_rss(o_vpu0_rss),
	.o_rss_wr(o_vpu0_rss_wr),
	.i_rsd_rdy(i_vpu0_rsd_rdy),
	.o_rsd(o_vpu0_rsd),
	.o_rsd_wr(o_vpu0_rsd_wr)
);


/* VPU1 upstream unit */
vxe_mem_hub_vpu_us vpu1_us(
	.clk(clk),
	.nrst(nrst),
	.i_rqa_vld(i_vpu1_rqa_vld),
	.i_rqa(i_vpu1_rqa),
	.o_rqa_rd(o_vpu1_rqa_rd),
	.i_rqd_vld(i_vpu1_rqd_vld),
	.i_rqd(i_vpu1_rqd),
	.o_rqd_rd(o_vpu1_rqd_rd),
	.i_m0_rqa_rdy(w_vpu1_m0_rqa_rdy),
	.o_m0_rqa(w_vpu1_m0_rqa),
	.o_m0_rqa_wr(w_vpu1_m0_rqa_wr),
	.i_m0_rqd_rdy(w_vpu1_m0_rqd_rdy),
	.o_m0_rqd(w_vpu1_m0_rqd),
	.o_m0_rqd_wr(w_vpu1_m0_rqd_wr),
	.i_m1_rqa_rdy(w_vpu1_m1_rqa_rdy),
	.o_m1_rqa(w_vpu1_m1_rqa),
	.o_m1_rqa_wr(w_vpu1_m1_rqa_wr),
	.i_m1_rqd_rdy(w_vpu1_m1_rqd_rdy),
	.o_m1_rqd(w_vpu1_m1_rqd),
	.o_m1_rqd_wr(w_vpu1_m1_rqd_wr)
);

/* VPU1 downstream unit */
vxe_mem_hub_vpu_ds vpu1_ds(
	.clk(clk),
	.nrst(nrst),
	.i_m0_rss_vld(w_vpu1_m0_rss_vld),
	.i_m0_rss(w_vpu1_m0_rss),
	.o_m0_rss_rd(w_vpu1_m0_rss_rd),
	.i_m0_rsd_vld(w_vpu1_m0_rsd_vld),
	.i_m0_rsd(w_vpu1_m0_rsd),
	.o_m0_rsd_rd(w_vpu1_m0_rsd_rd),
	.i_m1_rss_vld(w_vpu1_m1_rss_vld),
	.i_m1_rss(w_vpu1_m1_rss),
	.o_m1_rss_rd(w_vpu1_m1_rss_rd),
	.i_m1_rsd_vld(w_vpu1_m1_rsd_vld),
	.i_m1_rsd(w_vpu1_m1_rsd),
	.o_m1_rsd_rd(w_vpu1_m1_rsd_rd),
	.i_rss_rdy(i_vpu1_rss_rdy),
	.o_rss(o_vpu1_rss),
	.o_rss_wr(o_vpu1_rss_wr),
	.i_rsd_rdy(i_vpu1_rsd_rdy),
	.o_rsd(o_vpu1_rsd),
	.o_rsd_wr(o_vpu1_rsd_wr)
);


/* Master 0 upstream unit */
vxe_mem_hub_mas_us mas0_us(
	.clk(clk),
	.nrst(nrst),
	.i_cu_rqa_vld(w_m0_cu_rqa_vld),
	.i_cu_rqa(w_m0_cu_rqa),
	.o_cu_rqa_rd(w_m0_cu_rqa_rd),
	.i_vpu0_rqa_vld(w_m0_vpu0_rqa_vld),
	.i_vpu0_rqa(w_m0_vpu0_rqa),
	.o_vpu0_rqa_rd(w_m0_vpu0_rqa_rd),
	.i_vpu0_rqd_vld(w_m0_vpu0_rqd_vld),
	.i_vpu0_rqd(w_m0_vpu0_rqd),
	.o_vpu0_rqd_rd(w_m0_vpu0_rqd_rd),
	.i_vpu1_rqa_vld(w_m0_vpu1_rqa_vld),
	.i_vpu1_rqa(w_m0_vpu1_rqa),
	.o_vpu1_rqa_rd(w_m0_vpu1_rqa_rd),
	.i_vpu1_rqd_vld(w_m0_vpu1_rqd_vld),
	.i_vpu1_rqd(w_m0_vpu1_rqd),
	.o_vpu1_rqd_rd(w_m0_vpu1_rqd_rd),
	.i_m_rqa_rdy(i_m0_rqa_rdy),
	.o_m_rqa(o_m0_rqa),
	.o_m_rqa_wr(o_m0_rqa_wr),
	.i_m_rqd_rdy(i_m0_rqd_rdy),
	.o_m_rqd(o_m0_rqd),
	.o_m_rqd_wr(o_m0_rqd_wr)
);

/* Master 0 downstream unit */
vxe_mem_hub_mas_ds mas0_ds(
	.clk(clk),
	.nrst(nrst),
	.i_m_rss_vld(i_m0_rss_vld),
	.i_m_rss(i_m0_rss),
	.o_m_rss_rd(o_m0_rss_rd),
	.i_m_rsd_vld(i_m0_rsd_vld),
	.i_m_rsd(i_m0_rsd),
	.o_m_rsd_rd(o_m0_rsd_rd),
	.i_cu_rss_rdy(w_m0_cu_rss_rdy),
	.o_cu_rss(w_m0_cu_rss),
	.o_cu_rss_wr(w_m0_cu_rss_wr),
	.i_cu_rsd_rdy(w_m0_cu_rsd_rdy),
	.o_cu_rsd(w_m0_cu_rsd),
	.o_cu_rsd_wr(w_m0_cu_rsd_wr),
	.i_vpu0_rss_rdy(w_m0_vpu0_rss_rdy),
	.o_vpu0_rss(w_m0_vpu0_rss),
	.o_vpu0_rss_wr(w_m0_vpu0_rss_wr),
	.i_vpu0_rsd_rdy(w_m0_vpu0_rsd_rdy),
	.o_vpu0_rsd(w_m0_vpu0_rsd),
	.o_vpu0_rsd_wr(w_m0_vpu0_rsd_wr),
	.i_vpu1_rss_rdy(w_m0_vpu1_rss_rdy),
	.o_vpu1_rss(w_m0_vpu1_rss),
	.o_vpu1_rss_wr(w_m0_vpu1_rss_wr),
	.i_vpu1_rsd_rdy(w_m0_vpu1_rsd_rdy),
	.o_vpu1_rsd(w_m0_vpu1_rsd),
	.o_vpu1_rsd_wr(w_m0_vpu1_rsd_wr)
);

/* Master 1 upstream unit */
vxe_mem_hub_mas_us mas1_us(
	.clk(clk),
	.nrst(nrst),
	.i_cu_rqa_vld(w_m1_cu_rqa_vld),
	.i_cu_rqa(w_m1_cu_rqa),
	.o_cu_rqa_rd(w_m1_cu_rqa_rd),
	.i_vpu0_rqa_vld(w_m1_vpu0_rqa_vld),
	.i_vpu0_rqa(w_m1_vpu0_rqa),
	.o_vpu0_rqa_rd(w_m1_vpu0_rqa_rd),
	.i_vpu0_rqd_vld(w_m1_vpu0_rqd_vld),
	.i_vpu0_rqd(w_m1_vpu0_rqd),
	.o_vpu0_rqd_rd(w_m1_vpu0_rqd_rd),
	.i_vpu1_rqa_vld(w_m1_vpu1_rqa_vld),
	.i_vpu1_rqa(w_m1_vpu1_rqa),
	.o_vpu1_rqa_rd(w_m1_vpu1_rqa_rd),
	.i_vpu1_rqd_vld(w_m1_vpu1_rqd_vld),
	.i_vpu1_rqd(w_m1_vpu1_rqd),
	.o_vpu1_rqd_rd(w_m1_vpu1_rqd_rd),
	.i_m_rqa_rdy(i_m1_rqa_rdy),
	.o_m_rqa(o_m1_rqa),
	.o_m_rqa_wr(o_m1_rqa_wr),
	.i_m_rqd_rdy(i_m1_rqd_rdy),
	.o_m_rqd(o_m1_rqd),
	.o_m_rqd_wr(o_m1_rqd_wr)
);

/* Master 1 downstream unit */
vxe_mem_hub_mas_ds mas1_ds(
	.clk(clk),
	.nrst(nrst),
	.i_m_rss_vld(i_m1_rss_vld),
	.i_m_rss(i_m1_rss),
	.o_m_rss_rd(o_m1_rss_rd),
	.i_m_rsd_vld(i_m1_rsd_vld),
	.i_m_rsd(i_m1_rsd),
	.o_m_rsd_rd(o_m1_rsd_rd),
	.i_cu_rss_rdy(w_m1_cu_rss_rdy),
	.o_cu_rss(w_m1_cu_rss),
	.o_cu_rss_wr(w_m1_cu_rss_wr),
	.i_cu_rsd_rdy(w_m1_cu_rsd_rdy),
	.o_cu_rsd(w_m1_cu_rsd),
	.o_cu_rsd_wr(w_m1_cu_rsd_wr),
	.i_vpu0_rss_rdy(w_m1_vpu0_rss_rdy),
	.o_vpu0_rss(w_m1_vpu0_rss),
	.o_vpu0_rss_wr(w_m1_vpu0_rss_wr),
	.i_vpu0_rsd_rdy(w_m1_vpu0_rsd_rdy),
	.o_vpu0_rsd(w_m1_vpu0_rsd),
	.o_vpu0_rsd_wr(w_m1_vpu0_rsd_wr),
	.i_vpu1_rss_rdy(w_m1_vpu1_rss_rdy),
	.o_vpu1_rss(w_m1_vpu1_rss),
	.o_vpu1_rss_wr(w_m1_vpu1_rss_wr),
	.i_vpu1_rsd_rdy(w_m1_vpu1_rsd_rdy),
	.o_vpu1_rsd(w_m1_vpu1_rsd),
	.o_vpu1_rsd_wr(w_m1_vpu1_rsd_wr)
);


endmodule /* vxe_mem_hub */
