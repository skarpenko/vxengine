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
 * VxEngine top-level
 */


/* VxE top */
module vxe_top #(
	parameter S0_ID_WIDTH = 7,		/* AXI slave 0 ID width */
	parameter M0_ID_WIDTH = 7,		/* AXI master 0 ID width */
	parameter M1_ID_WIDTH = 7,		/* AXI master 1 ID width */
	parameter MEMIF_FIFO_DEPTH_POW2 = 5	/* Memory IF FIFOs depth */
)
(
	clk,
	nrst,
	/* Interrupt output */
	o_intr,
	/* AXI4 Slave */
	S0_AXI4_AWID,
	S0_AXI4_AWADDR,
	S0_AXI4_AWLEN,
	S0_AXI4_AWSIZE,
	S0_AXI4_AWBURST,
	S0_AXI4_AWLOCK,
	S0_AXI4_AWCACHE,
	S0_AXI4_AWPROT,
	S0_AXI4_AWVALID,
	S0_AXI4_AWREADY,
	S0_AXI4_WDATA,
	S0_AXI4_WSTRB,
	S0_AXI4_WLAST,
	S0_AXI4_WVALID,
	S0_AXI4_WREADY,
	S0_AXI4_BID,
	S0_AXI4_BRESP,
	S0_AXI4_BVALID,
	S0_AXI4_BREADY,
	S0_AXI4_ARID,
	S0_AXI4_ARADDR,
	S0_AXI4_ARLEN,
	S0_AXI4_ARSIZE,
	S0_AXI4_ARBURST,
	S0_AXI4_ARLOCK,
	S0_AXI4_ARCACHE,
	S0_AXI4_ARPROT,
	S0_AXI4_ARVALID,
	S0_AXI4_ARREADY,
	S0_AXI4_RID,
	S0_AXI4_RDATA,
	S0_AXI4_RRESP,
	S0_AXI4_RLAST,
	S0_AXI4_RVALID,
	S0_AXI4_RREADY,
	/* AXI4 Master 0 */
	M0_AXI4_AWID,
	M0_AXI4_AWADDR,
	M0_AXI4_AWLEN,
	M0_AXI4_AWSIZE,
	M0_AXI4_AWBURST,
	M0_AXI4_AWLOCK,
	M0_AXI4_AWCACHE,
	M0_AXI4_AWPROT,
	M0_AXI4_AWVALID,
	M0_AXI4_AWREADY,
	M0_AXI4_WDATA,
	M0_AXI4_WSTRB,
	M0_AXI4_WLAST,
	M0_AXI4_WVALID,
	M0_AXI4_WREADY,
	M0_AXI4_BID,
	M0_AXI4_BRESP,
	M0_AXI4_BVALID,
	M0_AXI4_BREADY,
	M0_AXI4_ARID,
	M0_AXI4_ARADDR,
	M0_AXI4_ARLEN,
	M0_AXI4_ARSIZE,
	M0_AXI4_ARBURST,
	M0_AXI4_ARLOCK,
	M0_AXI4_ARCACHE,
	M0_AXI4_ARPROT,
	M0_AXI4_ARVALID,
	M0_AXI4_ARREADY,
	M0_AXI4_RID,
	M0_AXI4_RDATA,
	M0_AXI4_RRESP,
	M0_AXI4_RLAST,
	M0_AXI4_RVALID,
	M0_AXI4_RREADY,
	/* AXI4 Master 1 */
	M1_AXI4_AWID,
	M1_AXI4_AWADDR,
	M1_AXI4_AWLEN,
	M1_AXI4_AWSIZE,
	M1_AXI4_AWBURST,
	M1_AXI4_AWLOCK,
	M1_AXI4_AWCACHE,
	M1_AXI4_AWPROT,
	M1_AXI4_AWVALID,
	M1_AXI4_AWREADY,
	M1_AXI4_WDATA,
	M1_AXI4_WSTRB,
	M1_AXI4_WLAST,
	M1_AXI4_WVALID,
	M1_AXI4_WREADY,
	M1_AXI4_BID,
	M1_AXI4_BRESP,
	M1_AXI4_BVALID,
	M1_AXI4_BREADY,
	M1_AXI4_ARID,
	M1_AXI4_ARADDR,
	M1_AXI4_ARLEN,
	M1_AXI4_ARSIZE,
	M1_AXI4_ARBURST,
	M1_AXI4_ARLOCK,
	M1_AXI4_ARCACHE,
	M1_AXI4_ARPROT,
	M1_AXI4_ARVALID,
	M1_AXI4_ARREADY,
	M1_AXI4_RID,
	M1_AXI4_RDATA,
	M1_AXI4_RRESP,
	M1_AXI4_RLAST,
	M1_AXI4_RVALID,
	M1_AXI4_RREADY
);
`include "vxe_client_params.vh"
/* Global signals */
input wire			clk;
input wire			nrst;
/* Interrupt output */
output wire			o_intr;
/* AXI4 Slave */
input wire [S0_ID_WIDTH-1:0]	S0_AXI4_AWID;
input wire [11:0]		S0_AXI4_AWADDR;
input wire [7:0]		S0_AXI4_AWLEN;
input wire [2:0]		S0_AXI4_AWSIZE;
input wire [1:0]		S0_AXI4_AWBURST;
input wire			S0_AXI4_AWLOCK;
input wire [3:0]		S0_AXI4_AWCACHE;
input wire [2:0]		S0_AXI4_AWPROT;
input wire			S0_AXI4_AWVALID;
output wire			S0_AXI4_AWREADY;
input wire [31:0]		S0_AXI4_WDATA;
input wire [3:0]		S0_AXI4_WSTRB;
input wire			S0_AXI4_WLAST;
input wire			S0_AXI4_WVALID;
output wire			S0_AXI4_WREADY;
output wire [S0_ID_WIDTH-1:0]	S0_AXI4_BID;
output wire [1:0]		S0_AXI4_BRESP;
output wire			S0_AXI4_BVALID;
input wire			S0_AXI4_BREADY;
input wire [S0_ID_WIDTH-1:0]	S0_AXI4_ARID;
input wire [11:0]		S0_AXI4_ARADDR;
input wire [7:0]		S0_AXI4_ARLEN;
input wire [2:0]		S0_AXI4_ARSIZE;
input wire [1:0]		S0_AXI4_ARBURST;
input wire			S0_AXI4_ARLOCK;
input wire [3:0]		S0_AXI4_ARCACHE;
input wire [2:0]		S0_AXI4_ARPROT;
input wire			S0_AXI4_ARVALID;
output wire			S0_AXI4_ARREADY;
output wire [S0_ID_WIDTH-1:0]	S0_AXI4_RID;
output wire [31:0]		S0_AXI4_RDATA;
output wire [1:0]		S0_AXI4_RRESP;
output wire			S0_AXI4_RLAST;
output wire			S0_AXI4_RVALID;
input wire			S0_AXI4_RREADY;
/* AXI4 Master 0 */
output wire [M0_ID_WIDTH-1:0]	M0_AXI4_AWID;
output wire [39:0]		M0_AXI4_AWADDR;
output wire [7:0]		M0_AXI4_AWLEN;
output wire [2:0]		M0_AXI4_AWSIZE;
output wire [1:0]		M0_AXI4_AWBURST;
output wire			M0_AXI4_AWLOCK;
output wire [3:0]		M0_AXI4_AWCACHE;
output wire [2:0]		M0_AXI4_AWPROT;
output wire			M0_AXI4_AWVALID;
input wire			M0_AXI4_AWREADY;
output wire [63:0]		M0_AXI4_WDATA;
output wire [7:0]		M0_AXI4_WSTRB;
output wire			M0_AXI4_WLAST;
output wire			M0_AXI4_WVALID;
input wire			M0_AXI4_WREADY;
input wire [M0_ID_WIDTH-1:0]	M0_AXI4_BID;
input wire [1:0]		M0_AXI4_BRESP;
input wire			M0_AXI4_BVALID;
output wire			M0_AXI4_BREADY;
output wire [M0_ID_WIDTH-1:0]	M0_AXI4_ARID;
output wire [39:0]		M0_AXI4_ARADDR;
output wire [7:0]		M0_AXI4_ARLEN;
output wire [2:0]		M0_AXI4_ARSIZE;
output wire [1:0]		M0_AXI4_ARBURST;
output wire			M0_AXI4_ARLOCK;
output wire [3:0]		M0_AXI4_ARCACHE;
output wire [2:0]		M0_AXI4_ARPROT;
output wire			M0_AXI4_ARVALID;
input wire			M0_AXI4_ARREADY;
input wire [M0_ID_WIDTH-1:0]	M0_AXI4_RID;
input wire [63:0]		M0_AXI4_RDATA;
input wire [1:0]		M0_AXI4_RRESP;
input wire			M0_AXI4_RLAST;
input wire			M0_AXI4_RVALID;
output wire			M0_AXI4_RREADY;
/* AXI4 Master 1 */
output wire [M1_ID_WIDTH-1:0]	M1_AXI4_AWID;
output wire [39:0]		M1_AXI4_AWADDR;
output wire [7:0]		M1_AXI4_AWLEN;
output wire [2:0]		M1_AXI4_AWSIZE;
output wire [1:0]		M1_AXI4_AWBURST;
output wire			M1_AXI4_AWLOCK;
output wire [3:0]		M1_AXI4_AWCACHE;
output wire [2:0]		M1_AXI4_AWPROT;
output wire			M1_AXI4_AWVALID;
input wire			M1_AXI4_AWREADY;
output wire [63:0]		M1_AXI4_WDATA;
output wire [7:0]		M1_AXI4_WSTRB;
output wire			M1_AXI4_WLAST;
output wire			M1_AXI4_WVALID;
input wire			M1_AXI4_WREADY;
input wire [M1_ID_WIDTH-1:0]	M1_AXI4_BID;
input wire [1:0]		M1_AXI4_BRESP;
input wire			M1_AXI4_BVALID;
output wire			M1_AXI4_BREADY;
output wire [M1_ID_WIDTH-1:0]	M1_AXI4_ARID;
output wire [39:0]		M1_AXI4_ARADDR;
output wire [7:0]		M1_AXI4_ARLEN;
output wire [2:0]		M1_AXI4_ARSIZE;
output wire [1:0]		M1_AXI4_ARBURST;
output wire			M1_AXI4_ARLOCK;
output wire [3:0]		M1_AXI4_ARCACHE;
output wire [2:0]		M1_AXI4_ARPROT;
output wire			M1_AXI4_ARVALID;
input wire			M1_AXI4_ARREADY;
input wire [M1_ID_WIDTH-1:0]	M1_AXI4_RID;
input wire [63:0]		M1_AXI4_RDATA;
input wire [1:0]		M1_AXI4_RRESP;
input wire			M1_AXI4_RLAST;
input wire			M1_AXI4_RVALID;
output wire			M1_AXI4_RREADY;


/********************** INTERNAL INTERCONNECT WIRES ***************************/


/*** AXI4 Slave / Register IO ***/

/* BIU interface write path */
wire [11:0]	s0_rio_biu_waddr;
wire		s0_rio_biu_wenable;
wire [31:0]	s0_rio_biu_wdata;
wire [3:0]	s0_rio_biu_wben;	/* Not used */
wire		s0_rio_biu_waccept;
wire		s0_rio_biu_werror;
/* BIU interface read path */
wire [11:0]	s0_rio_biu_raddr;
wire		s0_rio_biu_renable;
wire [31:0]	s0_rio_biu_rdata;
wire		s0_rio_biu_raccept;
wire		s0_rio_biu_rerror;


/*** AXI4 master 0 / AXI4 switch 0 ***/

/* BIU interface write path */
wire [5:0]	m0_sw0_biu_awcid;
wire [39:0]	m0_sw0_biu_awaddr;
wire [63:0]	m0_sw0_biu_awdata;
wire [7:0]	m0_sw0_biu_awstrb;
wire		m0_sw0_biu_awvalid;
wire		m0_sw0_biu_awpop;
wire [5:0]	m0_sw0_biu_bcid;
wire [1:0]	m0_sw0_biu_bresp;
wire		m0_sw0_biu_bready;
wire		m0_sw0_biu_bpush;
/* BIU interface read path */
wire [5:0]	m0_sw0_biu_arcid;
wire [39:0]	m0_sw0_biu_araddr;
wire		m0_sw0_biu_arvalid;
wire		m0_sw0_biu_arpop;
wire [5:0]	m0_sw0_biu_rcid;
wire [63:0]	m0_sw0_biu_rdata;
wire [1:0]	m0_sw0_biu_rresp;
wire		m0_sw0_biu_rready;
wire		m0_sw0_biu_rpush;
/* Incoming request from a client */
wire		sw0_mh_rqa_vld;
wire [43:0]	sw0_mh_rqa;
wire		sw0_mh_rqa_rd;
wire		sw0_mh_rqd_vld;
wire [71:0]	sw0_mh_rqd;
wire		sw0_mh_rqd_rd;
/* Outgoing response for a client */
wire		sw0_mh_rss_rdy;
wire [8:0]	sw0_mh_rss;
wire		sw0_mh_rss_wr;
wire		sw0_mh_rsd_rdy;
wire [63:0]	sw0_mh_rsd;
wire		sw0_mh_rsd_wr;


/*** AXI4 master 1 / AXI4 switch 1 ***/

/* BIU interface write path */
wire [5:0]	m1_sw1_biu_awcid;
wire [39:0]	m1_sw1_biu_awaddr;
wire [63:0]	m1_sw1_biu_awdata;
wire [7:0]	m1_sw1_biu_awstrb;
wire		m1_sw1_biu_awvalid;
wire		m1_sw1_biu_awpop;
wire [5:0]	m1_sw1_biu_bcid;
wire [1:0]	m1_sw1_biu_bresp;
wire		m1_sw1_biu_bready;
wire		m1_sw1_biu_bpush;
/* BIU interface read path */
wire [5:0]	m1_sw1_biu_arcid;
wire [39:0]	m1_sw1_biu_araddr;
wire		m1_sw1_biu_arvalid;
wire		m1_sw1_biu_arpop;
wire [5:0]	m1_sw1_biu_rcid;
wire [63:0]	m1_sw1_biu_rdata;
wire [1:0]	m1_sw1_biu_rresp;
wire		m1_sw1_biu_rready;
wire		m1_sw1_biu_rpush;
/* Incoming request from a client */
wire		sw1_mh_rqa_vld;
wire [43:0]	sw1_mh_rqa;
wire		sw1_mh_rqa_rd;
wire		sw1_mh_rqd_vld;
wire [71:0]	sw1_mh_rqd;
wire		sw1_mh_rqd_rd;
/* Outgoing response for a client */
wire		sw1_mh_rss_rdy;
wire [8:0]	sw1_mh_rss;
wire		sw1_mh_rss_wr;
wire		sw1_mh_rsd_rdy;
wire [63:0]	sw1_mh_rsd;
wire		sw1_mh_rsd_wr;


/*** RegIO interface signals ***/

/* CU interface */
wire [36:0]	rio_cu_pgm_addr;
wire		rio_cu_start;
/* Interrupt unit interface */
wire [3:0]	rio_intu_raw;
wire [3:0]	rio_intu_act;
wire [3:0]	rio_intu_msk;
wire		rio_intu_ack_vld;
wire [3:0]	rio_intu_ack;
wire		rio_mh_cu_mas_sel;


/*** CU interface signals ***/

/* Status */
wire		cu_busy;
wire		cu_intr_vld;
wire [3:0]	cu_intr;
wire [36:0]	cu_last_instr_addr;
wire [63:0]	cu_last_instr_data;
wire [1:0]	cu_vpu_fault;
/* Request channel */
wire		cu_mh_rqa_rdy;
wire [43:0]	cu_mh_rqa;
wire		cu_mh_rqa_wr;
/* Response channel */
wire		cu_mh_rss_vld;
wire [8:0]	cu_mh_rss;
wire		cu_mh_rss_rd;
wire		cu_mh_rsd_vld;
wire [63:0]	cu_mh_rsd;
wire		cu_mh_rsd_rd;
/* CU-VPU0 interface */
wire		cu_vpu0_busy;
wire		cu_vpu0_err;
wire		cu_vpu0_cmd_sel;
wire		cu_vpu0_cmd_ack;
wire [4:0]	cu_vpu0_cmd_op;
wire [2:0]	cu_vpu0_cmd_th;
wire [47:0]	cu_vpu0_cmd_pl;
/* CU-VPU1 interface */
wire		cu_vpu1_busy;
wire		cu_vpu1_err;
wire		cu_vpu1_cmd_sel;
wire		cu_vpu1_cmd_ack;
wire [4:0]	cu_vpu1_cmd_op;
wire [2:0]	cu_vpu1_cmd_th;
wire [47:0]	cu_vpu1_cmd_pl;


/*** VPU0 interface signals ***/

/* Request channel */
wire		vpu0_mh_rqa_rdy;
wire [43:0]	vpu0_mh_rqa;
wire		vpu0_mh_rqa_wr;
wire		vpu0_mh_rqd_rdy;
wire [71:0]	vpu0_mh_rqd;
wire		vpu0_mh_rqd_wr;
/* Response channel */
wire		vpu0_mh_rss_vld;
wire [8:0]	vpu0_mh_rss;
wire		vpu0_mh_rss_rd;
wire		vpu0_mh_rsd_vld;
wire [63:0]	vpu0_mh_rsd;
wire		vpu0_mh_rsd_rd;


/*** VPU1 interface signals ***/

/* Request channel */
wire		vpu1_mh_rqa_rdy;
wire [43:0]	vpu1_mh_rqa;
wire		vpu1_mh_rqa_wr;
wire		vpu1_mh_rqd_rdy;
wire [71:0]	vpu1_mh_rqd;
wire		vpu1_mh_rqd_wr;
/* Response channel */
wire		vpu1_mh_rss_vld;
wire [8:0]	vpu1_mh_rss;
wire		vpu1_mh_rss_rd;
wire		vpu1_mh_rsd_vld;
wire [63:0]	vpu1_mh_rsd;
wire		vpu1_mh_rsd_rd;


/*** Memory hub interface signals ***/

/** CU **/
/* Request channel */
wire		mh_cu_rqa_vld;
wire [43:0]	mh_cu_rqa;
wire		mh_cu_rqa_rd;
/* Response channel */
wire		mh_cu_rss_rdy;
wire [8:0]	mh_cu_rss;
wire		mh_cu_rss_wr;
wire		mh_cu_rsd_rdy;
wire [63:0]	mh_cu_rsd;
wire		mh_cu_rsd_wr;
/** VPU0 **/
/* Request channel */
wire		mh_vpu0_rqa_vld;
wire [43:0]	mh_vpu0_rqa;
wire		mh_vpu0_rqa_rd;
wire		mh_vpu0_rqd_vld;
wire [71:0]	mh_vpu0_rqd;
wire		mh_vpu0_rqd_rd;
/* Response channel */
wire		mh_vpu0_rss_rdy;
wire [8:0]	mh_vpu0_rss;
wire		mh_vpu0_rss_wr;
wire		mh_vpu0_rsd_rdy;
wire [63:0]	mh_vpu0_rsd;
wire		mh_vpu0_rsd_wr;
/** VPU1 **/
/* Request channel */
wire		mh_vpu1_rqa_vld;
wire [43:0]	mh_vpu1_rqa;
wire		mh_vpu1_rqa_rd;
wire		mh_vpu1_rqd_vld;
wire [71:0]	mh_vpu1_rqd;
wire		mh_vpu1_rqd_rd;
/* Response channel */
wire		mh_vpu1_rss_rdy;
wire [8:0]	mh_vpu1_rss;
wire		mh_vpu1_rss_wr;
wire		mh_vpu1_rsd_rdy;
wire [63:0]	mh_vpu1_rsd;
wire		mh_vpu1_rsd_wr;
/** Master port 0 **/
/* Request channel */
wire		mh_sw0_rqa_rdy;
wire [43:0]	mh_sw0_rqa;
wire		mh_sw0_rqa_wr;
wire		mh_sw0_rqd_rdy;
wire [71:0]	mh_sw0_rqd;
wire		mh_sw0_rqd_wr;
/* Response channel */
wire		mh_sw0_rss_vld;
wire [8:0]	mh_sw0_rss;
wire		mh_sw0_rss_rd;
wire		mh_sw0_rsd_vld;
wire [63:0]	mh_sw0_rsd;
wire		mh_sw0_rsd_rd;
/** Master port 1 **/
/* Request channel */
wire		mh_sw1_rqa_rdy;
wire [43:0]	mh_sw1_rqa;
wire		mh_sw1_rqa_wr;
wire		mh_sw1_rqd_rdy;
wire [71:0]	mh_sw1_rqd;
wire		mh_sw1_rqd_wr;
/* Response channel */
wire		mh_sw1_rss_vld;
wire [8:0]	mh_sw1_rss;
wire		mh_sw1_rss_rd;
wire		mh_sw1_rsd_vld;
wire [63:0]	mh_sw1_rsd;
wire		mh_sw1_rsd_rd;



/*********************** VXENGINE UNITS INSTANCES *****************************/

/* AXI4 slave BIU */
vxe_axi4slv_biu #(
	.ADDR_WIDTH(12),
	.DATA_WIDTH(32),
	.ID_WIDTH(S0_ID_WIDTH)
) axi4_slave0_biu (
	.S_AXI4_ACLK(clk),
	.S_AXI4_ARESETn(nrst),
	/* AXI channels */
	.S_AXI4_AWID(S0_AXI4_AWID),
	.S_AXI4_AWADDR(S0_AXI4_AWADDR),
	.S_AXI4_AWLEN(S0_AXI4_AWLEN),
	.S_AXI4_AWSIZE(S0_AXI4_AWSIZE),
	.S_AXI4_AWBURST(S0_AXI4_AWBURST),
	.S_AXI4_AWLOCK(S0_AXI4_AWLOCK),
	.S_AXI4_AWCACHE(S0_AXI4_AWCACHE),
	.S_AXI4_AWPROT(S0_AXI4_AWPROT),
	.S_AXI4_AWVALID(S0_AXI4_AWVALID),
	.S_AXI4_AWREADY(S0_AXI4_AWREADY),
	.S_AXI4_WDATA(S0_AXI4_WDATA),
	.S_AXI4_WSTRB(S0_AXI4_WSTRB),
	.S_AXI4_WLAST(S0_AXI4_WLAST),
	.S_AXI4_WVALID(S0_AXI4_WVALID),
	.S_AXI4_WREADY(S0_AXI4_WREADY),
	.S_AXI4_BID(S0_AXI4_BID),
	.S_AXI4_BRESP(S0_AXI4_BRESP),
	.S_AXI4_BVALID(S0_AXI4_BVALID),
	.S_AXI4_BREADY(S0_AXI4_BREADY),
	.S_AXI4_ARID(S0_AXI4_ARID),
	.S_AXI4_ARADDR(S0_AXI4_ARADDR),
	.S_AXI4_ARLEN(S0_AXI4_ARLEN),
	.S_AXI4_ARSIZE(S0_AXI4_ARSIZE),
	.S_AXI4_ARBURST(S0_AXI4_ARBURST),
	.S_AXI4_ARLOCK(S0_AXI4_ARLOCK),
	.S_AXI4_ARCACHE(S0_AXI4_ARCACHE),
	.S_AXI4_ARPROT(S0_AXI4_ARPROT),
	.S_AXI4_ARVALID(S0_AXI4_ARVALID),
	.S_AXI4_ARREADY(S0_AXI4_ARREADY),
	.S_AXI4_RID(S0_AXI4_RID),
	.S_AXI4_RDATA(S0_AXI4_RDATA),
	.S_AXI4_RRESP(S0_AXI4_RRESP),
	.S_AXI4_RLAST(S0_AXI4_RLAST),
	.S_AXI4_RVALID(S0_AXI4_RVALID),
	.S_AXI4_RREADY(S0_AXI4_RREADY),
	/* BIU interface */
	.biu_waddr(s0_rio_biu_waddr),
	.biu_wenable(s0_rio_biu_wenable),
	.biu_wdata(s0_rio_biu_wdata),
	.biu_wben(s0_rio_biu_wben),
	.biu_waccept(s0_rio_biu_waccept),
	.biu_werror(s0_rio_biu_werror),
	.biu_raddr(s0_rio_biu_raddr),
	.biu_renable(s0_rio_biu_renable),
	.biu_rdata(s0_rio_biu_rdata),
	.biu_raccept(s0_rio_biu_raccept),
	.biu_rerror(s0_rio_biu_rerror)
);


/* AXI4 master 0 BIU */
vxe_axi4mas_biu #(
	.ADDR_WIDTH(40),
	.DATA_WIDTH(64),
	.ID_WIDTH(M0_ID_WIDTH),
	.CID_WIDTH(6)
) axi4_master0_biu (
	.M_AXI4_ACLK(clk),
	.M_AXI4_ARESETn(nrst),
	/* AXI channels */
	.M_AXI4_AWID(M0_AXI4_AWID),
	.M_AXI4_AWADDR(M0_AXI4_AWADDR),
	.M_AXI4_AWLEN(M0_AXI4_AWLEN),
	.M_AXI4_AWSIZE(M0_AXI4_AWSIZE),
	.M_AXI4_AWBURST(M0_AXI4_AWBURST),
	.M_AXI4_AWLOCK(M0_AXI4_AWLOCK),
	.M_AXI4_AWCACHE(M0_AXI4_AWCACHE),
	.M_AXI4_AWPROT(M0_AXI4_AWPROT),
	.M_AXI4_AWVALID(M0_AXI4_AWVALID),
	.M_AXI4_AWREADY(M0_AXI4_AWREADY),
	.M_AXI4_WDATA(M0_AXI4_WDATA),
	.M_AXI4_WSTRB(M0_AXI4_WSTRB),
	.M_AXI4_WLAST(M0_AXI4_WLAST),
	.M_AXI4_WVALID(M0_AXI4_WVALID),
	.M_AXI4_WREADY(M0_AXI4_WREADY),
	.M_AXI4_BID(M0_AXI4_BID),
	.M_AXI4_BRESP(M0_AXI4_BRESP),
	.M_AXI4_BVALID(M0_AXI4_BVALID),
	.M_AXI4_BREADY(M0_AXI4_BREADY),
	.M_AXI4_ARID(M0_AXI4_ARID),
	.M_AXI4_ARADDR(M0_AXI4_ARADDR),
	.M_AXI4_ARLEN(M0_AXI4_ARLEN),
	.M_AXI4_ARSIZE(M0_AXI4_ARSIZE),
	.M_AXI4_ARBURST(M0_AXI4_ARBURST),
	.M_AXI4_ARLOCK(M0_AXI4_ARLOCK),
	.M_AXI4_ARCACHE(M0_AXI4_ARCACHE),
	.M_AXI4_ARPROT(M0_AXI4_ARPROT),
	.M_AXI4_ARVALID(M0_AXI4_ARVALID),
	.M_AXI4_ARREADY(M0_AXI4_ARREADY),
	.M_AXI4_RID(M0_AXI4_RID),
	.M_AXI4_RDATA(M0_AXI4_RDATA),
	.M_AXI4_RRESP(M0_AXI4_RRESP),
	.M_AXI4_RLAST(M0_AXI4_RLAST),
	.M_AXI4_RVALID(M0_AXI4_RVALID),
	.M_AXI4_RREADY(M0_AXI4_RREADY),
	/* BIU interface */
	.biu_awcid(m0_sw0_biu_awcid),
	.biu_awaddr(m0_sw0_biu_awaddr),
	.biu_awdata(m0_sw0_biu_awdata),
	.biu_awstrb(m0_sw0_biu_awstrb),
	.biu_awvalid(m0_sw0_biu_awvalid),
	.biu_awpop(m0_sw0_biu_awpop),
	.biu_bcid(m0_sw0_biu_bcid),
	.biu_bresp(m0_sw0_biu_bresp),
	.biu_bready(m0_sw0_biu_bready),
	.biu_bpush(m0_sw0_biu_bpush),
	.biu_arcid(m0_sw0_biu_arcid),
	.biu_araddr(m0_sw0_biu_araddr),
	.biu_arvalid(m0_sw0_biu_arvalid),
	.biu_arpop(m0_sw0_biu_arpop),
	.biu_rcid(m0_sw0_biu_rcid),
	.biu_rdata(m0_sw0_biu_rdata),
	.biu_rresp(m0_sw0_biu_rresp),
	.biu_rready(m0_sw0_biu_rready),
	.biu_rpush(m0_sw0_biu_rpush)
);


/* AXI4 master 1 BIU */
vxe_axi4mas_biu #(
	.ADDR_WIDTH(40),
	.DATA_WIDTH(64),
	.ID_WIDTH(M1_ID_WIDTH),
	.CID_WIDTH(6)
) axi4_master1_biu (
	.M_AXI4_ACLK(clk),
	.M_AXI4_ARESETn(nrst),
	/* AXI channels */
	.M_AXI4_AWID(M1_AXI4_AWID),
	.M_AXI4_AWADDR(M1_AXI4_AWADDR),
	.M_AXI4_AWLEN(M1_AXI4_AWLEN),
	.M_AXI4_AWSIZE(M1_AXI4_AWSIZE),
	.M_AXI4_AWBURST(M1_AXI4_AWBURST),
	.M_AXI4_AWLOCK(M1_AXI4_AWLOCK),
	.M_AXI4_AWCACHE(M1_AXI4_AWCACHE),
	.M_AXI4_AWPROT(M1_AXI4_AWPROT),
	.M_AXI4_AWVALID(M1_AXI4_AWVALID),
	.M_AXI4_AWREADY(M1_AXI4_AWREADY),
	.M_AXI4_WDATA(M1_AXI4_WDATA),
	.M_AXI4_WSTRB(M1_AXI4_WSTRB),
	.M_AXI4_WLAST(M1_AXI4_WLAST),
	.M_AXI4_WVALID(M1_AXI4_WVALID),
	.M_AXI4_WREADY(M1_AXI4_WREADY),
	.M_AXI4_BID(M1_AXI4_BID),
	.M_AXI4_BRESP(M1_AXI4_BRESP),
	.M_AXI4_BVALID(M1_AXI4_BVALID),
	.M_AXI4_BREADY(M1_AXI4_BREADY),
	.M_AXI4_ARID(M1_AXI4_ARID),
	.M_AXI4_ARADDR(M1_AXI4_ARADDR),
	.M_AXI4_ARLEN(M1_AXI4_ARLEN),
	.M_AXI4_ARSIZE(M1_AXI4_ARSIZE),
	.M_AXI4_ARBURST(M1_AXI4_ARBURST),
	.M_AXI4_ARLOCK(M1_AXI4_ARLOCK),
	.M_AXI4_ARCACHE(M1_AXI4_ARCACHE),
	.M_AXI4_ARPROT(M1_AXI4_ARPROT),
	.M_AXI4_ARVALID(M1_AXI4_ARVALID),
	.M_AXI4_ARREADY(M1_AXI4_ARREADY),
	.M_AXI4_RID(M1_AXI4_RID),
	.M_AXI4_RDATA(M1_AXI4_RDATA),
	.M_AXI4_RRESP(M1_AXI4_RRESP),
	.M_AXI4_RLAST(M1_AXI4_RLAST),
	.M_AXI4_RVALID(M1_AXI4_RVALID),
	.M_AXI4_RREADY(M1_AXI4_RREADY),
	/* BIU interface */
	.biu_awcid(m1_sw1_biu_awcid),
	.biu_awaddr(m1_sw1_biu_awaddr),
	.biu_awdata(m1_sw1_biu_awdata),
	.biu_awstrb(m1_sw1_biu_awstrb),
	.biu_awvalid(m1_sw1_biu_awvalid),
	.biu_awpop(m1_sw1_biu_awpop),
	.biu_bcid(m1_sw1_biu_bcid),
	.biu_bresp(m1_sw1_biu_bresp),
	.biu_bready(m1_sw1_biu_bready),
	.biu_bpush(m1_sw1_biu_bpush),
	.biu_arcid(m1_sw1_biu_arcid),
	.biu_araddr(m1_sw1_biu_araddr),
	.biu_arvalid(m1_sw1_biu_arvalid),
	.biu_arpop(m1_sw1_biu_arpop),
	.biu_rcid(m1_sw1_biu_rcid),
	.biu_rdata(m1_sw1_biu_rdata),
	.biu_rresp(m1_sw1_biu_rresp),
	.biu_rready(m1_sw1_biu_rready),
	.biu_rpush(m1_sw1_biu_rpush)
);


/* AXI4 switch 0 unit */
vxe_axi_switch axi_switch0(
	.clk(clk),
	.nrst(nrst),
	/* Incoming request from a client */
	.i_m_rqa_vld(sw0_mh_rqa_vld),
	.i_m_rqa(sw0_mh_rqa),
	.o_m_rqa_rd(sw0_mh_rqa_rd),
	.i_m_rqd_vld(sw0_mh_rqd_vld),
	.i_m_rqd(sw0_mh_rqd),
	.o_m_rqd_rd(sw0_mh_rqd_rd),
	/* Outgoing response for a client */
	.i_m_rss_rdy(sw0_mh_rss_rdy),
	.o_m_rss(sw0_mh_rss),
	.o_m_rss_wr(sw0_mh_rss_wr),
	.i_m_rsd_rdy(sw0_mh_rsd_rdy),
	.o_m_rsd(sw0_mh_rsd),
	.o_m_rsd_wr(sw0_mh_rsd_wr),
	/* Outgoing request to AXI */
	.biu_awcid(m0_sw0_biu_awcid),
	.biu_awaddr(m0_sw0_biu_awaddr),
	.biu_awdata(m0_sw0_biu_awdata),
	.biu_awstrb(m0_sw0_biu_awstrb),
	.biu_awvalid(m0_sw0_biu_awvalid),
	.biu_awpop(m0_sw0_biu_awpop),
	.biu_arcid(m0_sw0_biu_arcid),
	.biu_araddr(m0_sw0_biu_araddr),
	.biu_arvalid(m0_sw0_biu_arvalid),
	.biu_arpop(m0_sw0_biu_arpop),
	/* Incoming response on AXI */
	.biu_bcid(m0_sw0_biu_bcid),
	.biu_bresp(m0_sw0_biu_bresp),
	.biu_bready(m0_sw0_biu_bready),
	.biu_bpush(m0_sw0_biu_bpush),
	.biu_rcid(m0_sw0_biu_rcid),
	.biu_rdata(m0_sw0_biu_rdata),
	.biu_rresp(m0_sw0_biu_rresp),
	.biu_rready(m0_sw0_biu_rready),
	.biu_rpush(m0_sw0_biu_rpush)
);


/* AXI4 switch 1 unit */
vxe_axi_switch axi_switch1(
	.clk(clk),
	.nrst(nrst),
	/* Incoming request from a client */
	.i_m_rqa_vld(sw1_mh_rqa_vld),
	.i_m_rqa(sw1_mh_rqa),
	.o_m_rqa_rd(sw1_mh_rqa_rd),
	.i_m_rqd_vld(sw1_mh_rqd_vld),
	.i_m_rqd(sw1_mh_rqd),
	.o_m_rqd_rd(sw1_mh_rqd_rd),
	/* Outgoing response for a client */
	.i_m_rss_rdy(sw1_mh_rss_rdy),
	.o_m_rss(sw1_mh_rss),
	.o_m_rss_wr(sw1_mh_rss_wr),
	.i_m_rsd_rdy(sw1_mh_rsd_rdy),
	.o_m_rsd(sw1_mh_rsd),
	.o_m_rsd_wr(sw1_mh_rsd_wr),
	/* Outgoing request to AXI */
	.biu_awcid(m1_sw1_biu_awcid),
	.biu_awaddr(m1_sw1_biu_awaddr),
	.biu_awdata(m1_sw1_biu_awdata),
	.biu_awstrb(m1_sw1_biu_awstrb),
	.biu_awvalid(m1_sw1_biu_awvalid),
	.biu_awpop(m1_sw1_biu_awpop),
	.biu_arcid(m1_sw1_biu_arcid),
	.biu_araddr(m1_sw1_biu_araddr),
	.biu_arvalid(m1_sw1_biu_arvalid),
	.biu_arpop(m1_sw1_biu_arpop),
	/* Incoming response on AXI */
	.biu_bcid(m1_sw1_biu_bcid),
	.biu_bresp(m1_sw1_biu_bresp),
	.biu_bready(m1_sw1_biu_bready),
	.biu_bpush(m1_sw1_biu_bpush),
	.biu_rcid(m1_sw1_biu_rcid),
	.biu_rdata(m1_sw1_biu_rdata),
	.biu_rresp(m1_sw1_biu_rresp),
	.biu_rready(m1_sw1_biu_rready),
	.biu_rpush(m1_sw1_biu_rpush)
);


/* RegIO unit */
vxe_regio regio(
	.clk(clk),
	.nrst(nrst),
	/* Bus interface signals */
	.i_wreg_idx(s0_rio_biu_waddr[11:2]),	/* Register is 32-bit wide, use index */
	.i_wdata(s0_rio_biu_wdata),
	.i_wenable(s0_rio_biu_wenable),
	.o_waccept(s0_rio_biu_waccept),
	.o_werror(s0_rio_biu_werror),
	.i_rreg_idx(s0_rio_biu_raddr[11:2]),	/* Register is 32-bit wide, use index */
	.o_rdata(s0_rio_biu_rdata),
	.i_renable(s0_rio_biu_renable),
	.o_raccept(s0_rio_biu_raccept),
	.o_rerror(s0_rio_biu_rerror),
	/* CU interface signals */
	.i_cu_busy(cu_busy),
	.i_cu_last_instr_addr(cu_last_instr_addr),
	.i_cu_last_instr_data(cu_last_instr_data),
	.i_vpu_fault(cu_vpu_fault),
	.o_cu_pgm_addr(rio_cu_pgm_addr),
	.o_cu_start(rio_cu_start),
	/* Interrupt unit interface signals */
	.i_intu_raw(rio_intu_raw),
	.i_intu_act(rio_intu_act),
	.o_intu_msk(rio_intu_msk),
	.o_intu_ack_vld(rio_intu_ack_vld),
	.o_intu_ack(rio_intu_ack),
	/* Memory hub interface signals */
	.o_cu_mas_sel(rio_mh_cu_mas_sel)
);


/* Memory hub unit */
vxe_mem_hub #(
	.CU_RQ_FIFO_DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2),
	.CU_RS_FIFO_DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2),
	.VPU0_RQ_FIFO_DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2),
	.VPU0_RS_FIFO_DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2),
	.VPU1_RQ_FIFO_DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2),
	.VPU1_RS_FIFO_DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) mem_hub (
	.clk(clk),
	.nrst(nrst),
	/** CU **/
	/* Master port select */
	.i_cu_m_sel(rio_mh_cu_mas_sel),
	/* Request channel */
	.i_cu_rqa_vld(mh_cu_rqa_vld),
	.i_cu_rqa(mh_cu_rqa),
	.o_cu_rqa_rd(mh_cu_rqa_rd),
	/* Response channel */
	.i_cu_rss_rdy(mh_cu_rss_rdy),
	.o_cu_rss(mh_cu_rss),
	.o_cu_rss_wr(mh_cu_rss_wr),
	.i_cu_rsd_rdy(mh_cu_rsd_rdy),
	.o_cu_rsd(mh_cu_rsd),
	.o_cu_rsd_wr(mh_cu_rsd_wr),
	/** VPU0 **/
	/* Request channel */
	.i_vpu0_rqa_vld(mh_vpu0_rqa_vld),
	.i_vpu0_rqa(mh_vpu0_rqa),
	.o_vpu0_rqa_rd(mh_vpu0_rqa_rd),
	.i_vpu0_rqd_vld(mh_vpu0_rqd_vld),
	.i_vpu0_rqd(mh_vpu0_rqd),
	.o_vpu0_rqd_rd(mh_vpu0_rqd_rd),
	/* Response channel */
	.i_vpu0_rss_rdy(mh_vpu0_rss_rdy),
	.o_vpu0_rss(mh_vpu0_rss),
	.o_vpu0_rss_wr(mh_vpu0_rss_wr),
	.i_vpu0_rsd_rdy(mh_vpu0_rsd_rdy),
	.o_vpu0_rsd(mh_vpu0_rsd),
	.o_vpu0_rsd_wr(mh_vpu0_rsd_wr),
	/** VPU1 **/
	/* Request channel */
	.i_vpu1_rqa_vld(mh_vpu1_rqa_vld),
	.i_vpu1_rqa(mh_vpu1_rqa),
	.o_vpu1_rqa_rd(mh_vpu1_rqa_rd),
	.i_vpu1_rqd_vld(mh_vpu1_rqd_vld),
	.i_vpu1_rqd(mh_vpu1_rqd),
	.o_vpu1_rqd_rd(mh_vpu1_rqd_rd),
	/* Response channel */
	.i_vpu1_rss_rdy(mh_vpu1_rss_rdy),
	.o_vpu1_rss(mh_vpu1_rss),
	.o_vpu1_rss_wr(mh_vpu1_rss_wr),
	.i_vpu1_rsd_rdy(mh_vpu1_rsd_rdy),
	.o_vpu1_rsd(mh_vpu1_rsd),
	.o_vpu1_rsd_wr(mh_vpu1_rsd_wr),
	/** Master port 0 **/
	/* Request channel */
	.i_m0_rqa_rdy(mh_sw0_rqa_rdy),
	.o_m0_rqa(mh_sw0_rqa),
	.o_m0_rqa_wr(mh_sw0_rqa_wr),
	.i_m0_rqd_rdy(mh_sw0_rqd_rdy),
	.o_m0_rqd(mh_sw0_rqd),
	.o_m0_rqd_wr(mh_sw0_rqd_wr),
	/* Response channel */
	.i_m0_rss_vld(mh_sw0_rss_vld),
	.i_m0_rss(mh_sw0_rss),
	.o_m0_rss_rd(mh_sw0_rss_rd),
	.i_m0_rsd_vld(mh_sw0_rsd_vld),
	.i_m0_rsd(mh_sw0_rsd),
	.o_m0_rsd_rd(mh_sw0_rsd_rd),
	/** Master port 1 **/
	/* Request channel */
	.i_m1_rqa_rdy(mh_sw1_rqa_rdy),
	.o_m1_rqa(mh_sw1_rqa),
	.o_m1_rqa_wr(mh_sw1_rqa_wr),
	.i_m1_rqd_rdy(mh_sw1_rqd_rdy),
	.o_m1_rqd(mh_sw1_rqd),
	.o_m1_rqd_wr(mh_sw1_rqd_wr),
	/* Response channel */
	.i_m1_rss_vld(mh_sw1_rss_vld),
	.i_m1_rss(mh_sw1_rss),
	.o_m1_rss_rd(mh_sw1_rss_rd),
	.i_m1_rsd_vld(mh_sw1_rsd_vld),
	.i_m1_rsd(mh_sw1_rsd),
	.o_m1_rsd_rd(mh_sw1_rsd_rd)
);


/* Interrupt unit */
vxe_intr_unit #(
	.NR_INT(4)
) intr_unit (
	.clk(clk),
	.nrst(nrst),
	/* CU interface signals */
	.i_cu_intr_vld(cu_intr_vld),
	.i_cu_intr(cu_intr),
	/* RegIO interface signals */
	.i_rio_mask(rio_intu_msk),
	.o_rio_raw(rio_intu_raw),
	.o_rio_active(rio_intu_act),
	.i_rio_ack_en(rio_intu_ack_vld),
	.i_rio_ack(rio_intu_ack),
	/* Interrupt line */
	.o_intr(o_intr)
);


/* Control unit */
vxe_ctrl_unit #(
	.CLIENT_ID(CLNT_CU)
) ctrl_unit(
	.clk(clk),
	.nrst(nrst),
	/* Memory request channel */
	.i_rqa_rdy(cu_mh_rqa_rdy),
	.o_rqa(cu_mh_rqa),
	.o_rqa_wr(cu_mh_rqa_wr),
	/* Memory response channel */
	.i_rss_vld(cu_mh_rss_vld),
	.i_rss(cu_mh_rss),
	.o_rss_rd(cu_mh_rss_rd),
	.i_rsd_vld(cu_mh_rsd_vld),
	.i_rsd(cu_mh_rsd),
	.o_rsd_rd(cu_mh_rsd_rd),
	/* Control signals */
	.i_start(rio_cu_start),
	.o_busy(cu_busy),
	.i_pgm_addr(rio_cu_pgm_addr),
	/* Interrupts and faults state */
	.o_intr_vld(cu_intr_vld),
	.o_intr(cu_intr),
	.o_last_instr_addr(cu_last_instr_addr),
	.o_last_instr_data(cu_last_instr_data),
	.o_vpu_fault(cu_vpu_fault),
	/* VPU0 interface */
	.i_vpu0_busy(cu_vpu0_busy),
	.i_vpu0_err(cu_vpu0_err),
	.o_vpu0_cmd_sel(cu_vpu0_cmd_sel),
	.i_vpu0_cmd_ack(cu_vpu0_cmd_ack),
	.o_vpu0_cmd_op(cu_vpu0_cmd_op),
	.o_vpu0_cmd_th(cu_vpu0_cmd_th),
	.o_vpu0_cmd_pl(cu_vpu0_cmd_pl),
	/* VPU1 interface */
	.i_vpu1_busy(cu_vpu1_busy),
	.i_vpu1_err(cu_vpu1_err),
	.o_vpu1_cmd_sel(cu_vpu1_cmd_sel),
	.i_vpu1_cmd_ack(cu_vpu1_cmd_ack),
	.o_vpu1_cmd_op(cu_vpu1_cmd_op),
	.o_vpu1_cmd_th(cu_vpu1_cmd_th),
	.o_vpu1_cmd_pl(cu_vpu1_cmd_pl)
);


/* Vector unit 0 */
vxe_vec_unit #(
	.CLIENT_ID(CLNT_VPU0)
) vec_unit0(
	.clk(clk),
	.nrst(nrst),
	/* Memory request channel */
	.i_rqa_rdy(vpu0_mh_rqa_rdy),
	.o_rqa(vpu0_mh_rqa),
	.o_rqa_wr(vpu0_mh_rqa_wr),
	.i_rqd_rdy(vpu0_mh_rqd_rdy),
	.o_rqd(vpu0_mh_rqd),
	.o_rqd_wr(vpu0_mh_rqd_wr),
	/* Memory response channel */
	.i_rss_vld(vpu0_mh_rss_vld),
	.i_rss(vpu0_mh_rss),
	.o_rss_rd(vpu0_mh_rss_rd),
	.i_rsd_vld(vpu0_mh_rsd_vld),
	.i_rsd(vpu0_mh_rsd),
	.o_rsd_rd(vpu0_mh_rsd_rd),
	/* Control interface */
	.i_start(rio_cu_start),
	.o_busy(cu_vpu0_busy),
	.o_err(cu_vpu0_err),
	/* Command interface */
	.i_cmd_sel(cu_vpu0_cmd_sel),
	.o_cmd_ack(cu_vpu0_cmd_ack),
	.i_cmd_op(cu_vpu0_cmd_op),
	.i_cmd_th(cu_vpu0_cmd_th),
	.i_cmd_pl(cu_vpu0_cmd_pl)
);


/* Vector unit 1 */
vxe_vec_unit #(
	.CLIENT_ID(CLNT_VPU1)
) vec_unit1(
	.clk(clk),
	.nrst(nrst),
	/* Memory request channel */
	.i_rqa_rdy(vpu1_mh_rqa_rdy),
	.o_rqa(vpu1_mh_rqa),
	.o_rqa_wr(vpu1_mh_rqa_wr),
	.i_rqd_rdy(vpu1_mh_rqd_rdy),
	.o_rqd(vpu1_mh_rqd),
	.o_rqd_wr(vpu1_mh_rqd_wr),
	/* Memory response channel */
	.i_rss_vld(vpu1_mh_rss_vld),
	.i_rss(vpu1_mh_rss),
	.o_rss_rd(vpu1_mh_rss_rd),
	.i_rsd_vld(vpu1_mh_rsd_vld),
	.i_rsd(vpu1_mh_rsd),
	.o_rsd_rd(vpu1_mh_rsd_rd),
	/* Control interface */
	.i_start(rio_cu_start),
	.o_busy(cu_vpu1_busy),
	.o_err(cu_vpu1_err),
	/* Command interface */
	.i_cmd_sel(cu_vpu1_cmd_sel),
	.o_cmd_ack(cu_vpu1_cmd_ack),
	.i_cmd_op(cu_vpu1_cmd_op),
	.i_cmd_th(cu_vpu1_cmd_th),
	.i_cmd_pl(cu_vpu1_cmd_pl)
);


/* CU request FIFO (address channel) */
vxe_fifo #(
	.DATA_WIDTH(44),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_cu_rqa (
	.clk(clk),
	.nrst(nrst),
	.data_in(cu_mh_rqa),
	.data_out(mh_cu_rqa),
	.rd(mh_cu_rqa_rd),
	.wr(cu_mh_rqa_wr),
	.in_rdy(cu_mh_rqa_rdy),
	.out_vld(mh_cu_rqa_vld)
);


/* CU response FIFO (status channel) */
vxe_fifo #(
	.DATA_WIDTH(9),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_cu_rss (
	.clk(clk),
	.nrst(nrst),
	.data_in(mh_cu_rss),
	.data_out(cu_mh_rss),
	.rd(cu_mh_rss_rd),
	.wr(mh_cu_rss_wr),
	.in_rdy(mh_cu_rss_rdy),
	.out_vld(cu_mh_rss_vld)
);


/* CU response FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(64),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_cu_rsd (
	.clk(clk),
	.nrst(nrst),
	.data_in(mh_cu_rsd),
	.data_out(cu_mh_rsd),
	.rd(cu_mh_rsd_rd),
	.wr(mh_cu_rsd_wr),
	.in_rdy(mh_cu_rsd_rdy),
	.out_vld(cu_mh_rsd_vld)
);


/* VPU0 request FIFO (address channel) */
vxe_fifo #(
	.DATA_WIDTH(44),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_vpu0_rqa (
	.clk(clk),
	.nrst(nrst),
	.data_in(vpu0_mh_rqa),
	.data_out(mh_vpu0_rqa),
	.rd(mh_vpu0_rqa_rd),
	.wr(vpu0_mh_rqa_wr),
	.in_rdy(vpu0_mh_rqa_rdy),
	.out_vld(mh_vpu0_rqa_vld)
);


/* VPU0 request FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(72),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_vpu0_rqd (
	.clk(clk),
	.nrst(nrst),
	.data_in(vpu0_mh_rqd),
	.data_out(mh_vpu0_rqd),
	.rd(mh_vpu0_rqd_rd),
	.wr(vpu0_mh_rqd_wr),
	.in_rdy(vpu0_mh_rqd_rdy),
	.out_vld(mh_vpu0_rqd_vld)
);


/* VPU0 response FIFO (status channel) */
vxe_fifo #(
	.DATA_WIDTH(9),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_vpu0_rss (
	.clk(clk),
	.nrst(nrst),
	.data_in(mh_vpu0_rss),
	.data_out(vpu0_mh_rss),
	.rd(vpu0_mh_rss_rd),
	.wr(mh_vpu0_rss_wr),
	.in_rdy(mh_vpu0_rss_rdy),
	.out_vld(vpu0_mh_rss_vld)
);


/* VPU0 response FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(64),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_vpu0_rsd (
	.clk(clk),
	.nrst(nrst),
	.data_in(mh_vpu0_rsd),
	.data_out(vpu0_mh_rsd),
	.rd(vpu0_mh_rsd_rd),
	.wr(mh_vpu0_rsd_wr),
	.in_rdy(mh_vpu0_rsd_rdy),
	.out_vld(vpu0_mh_rsd_vld)
);


/* VPU1 request FIFO (address channel) */
vxe_fifo #(
	.DATA_WIDTH(44),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_vpu1_rqa (
	.clk(clk),
	.nrst(nrst),
	.data_in(vpu1_mh_rqa),
	.data_out(mh_vpu1_rqa),
	.rd(mh_vpu1_rqa_rd),
	.wr(vpu1_mh_rqa_wr),
	.in_rdy(vpu1_mh_rqa_rdy),
	.out_vld(mh_vpu1_rqa_vld)
);


/* VPU1 request FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(72),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_vpu1_rqd (
	.clk(clk),
	.nrst(nrst),
	.data_in(vpu1_mh_rqd),
	.data_out(mh_vpu1_rqd),
	.rd(mh_vpu1_rqd_rd),
	.wr(vpu1_mh_rqd_wr),
	.in_rdy(vpu1_mh_rqd_rdy),
	.out_vld(mh_vpu1_rqd_vld)
);


/* VPU1 response FIFO (status channel) */
vxe_fifo #(
	.DATA_WIDTH(9),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_vpu1_rss (
	.clk(clk),
	.nrst(nrst),
	.data_in(mh_vpu1_rss),
	.data_out(vpu1_mh_rss),
	.rd(vpu1_mh_rss_rd),
	.wr(mh_vpu1_rss_wr),
	.in_rdy(mh_vpu1_rss_rdy),
	.out_vld(vpu1_mh_rss_vld)
);


/* VPU1 response FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(64),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_vpu1_rsd (
	.clk(clk),
	.nrst(nrst),
	.data_in(mh_vpu1_rsd),
	.data_out(vpu1_mh_rsd),
	.rd(vpu1_mh_rsd_rd),
	.wr(mh_vpu1_rsd_wr),
	.in_rdy(mh_vpu1_rsd_rdy),
	.out_vld(vpu1_mh_rsd_vld)
);


/* AXI switch 0 request FIFO (address channel) */
vxe_fifo #(
	.DATA_WIDTH(44),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_sw0_rqa (
	.clk(clk),
	.nrst(nrst),
	.data_in(mh_sw0_rqa),
	.data_out(sw0_mh_rqa),
	.rd(sw0_mh_rqa_rd),
	.wr(mh_sw0_rqa_wr),
	.in_rdy(mh_sw0_rqa_rdy),
	.out_vld(sw0_mh_rqa_vld)
);


/* AXI switch 0 request FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(72),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_sw0_rqd (
	.clk(clk),
	.nrst(nrst),
	.data_in(mh_sw0_rqd),
	.data_out(sw0_mh_rqd),
	.rd(sw0_mh_rqd_rd),
	.wr(mh_sw0_rqd_wr),
	.in_rdy(mh_sw0_rqd_rdy),
	.out_vld(sw0_mh_rqd_vld)
);


/* AXI switch 0 response FIFO (status channel) */
vxe_fifo #(
	.DATA_WIDTH(9),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_sw0_rss (
	.clk(clk),
	.nrst(nrst),
	.data_in(sw0_mh_rss),
	.data_out(mh_sw0_rss),
	.rd(mh_sw0_rss_rd),
	.wr(sw0_mh_rss_wr),
	.in_rdy(sw0_mh_rss_rdy),
	.out_vld(mh_sw0_rss_vld)
);


/* AXI switch 0 response FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(64),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_sw0_rsd (
	.clk(clk),
	.nrst(nrst),
	.data_in(sw0_mh_rsd),
	.data_out(mh_sw0_rsd),
	.rd(mh_sw0_rsd_rd),
	.wr(sw0_mh_rsd_wr),
	.in_rdy(sw0_mh_rsd_rdy),
	.out_vld(mh_sw0_rsd_vld)
);


/* AXI switch 1 request FIFO (address channel) */
vxe_fifo #(
	.DATA_WIDTH(44),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_sw1_rqa (
	.clk(clk),
	.nrst(nrst),
	.data_in(mh_sw1_rqa),
	.data_out(sw1_mh_rqa),
	.rd(sw1_mh_rqa_rd),
	.wr(mh_sw1_rqa_wr),
	.in_rdy(mh_sw1_rqa_rdy),
	.out_vld(sw1_mh_rqa_vld)
);


/* AXI switch 1 request FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(72),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_sw1_rqd (
	.clk(clk),
	.nrst(nrst),
	.data_in(mh_sw1_rqd),
	.data_out(sw1_mh_rqd),
	.rd(sw1_mh_rqd_rd),
	.wr(mh_sw1_rqd_wr),
	.in_rdy(mh_sw1_rqd_rdy),
	.out_vld(sw1_mh_rqd_vld)
);


/* AXI switch 1 response FIFO (status channel) */
vxe_fifo #(
	.DATA_WIDTH(9),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_sw1_rss (
	.clk(clk),
	.nrst(nrst),
	.data_in(sw1_mh_rss),
	.data_out(mh_sw1_rss),
	.rd(mh_sw1_rss_rd),
	.wr(sw1_mh_rss_wr),
	.in_rdy(sw1_mh_rss_rdy),
	.out_vld(mh_sw1_rss_vld)
);


/* AXI switch 1 response FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(64),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_sw1_rsd (
	.clk(clk),
	.nrst(nrst),
	.data_in(sw1_mh_rsd),
	.data_out(mh_sw1_rsd),
	.rd(mh_sw1_rsd_rd),
	.wr(sw1_mh_rsd_wr),
	.in_rdy(sw1_mh_rsd_rdy),
	.out_vld(mh_sw1_rsd_vld)
);


endmodule /* vxe_top */
