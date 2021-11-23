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
 * Memory hub unit for testing (AXI4 protocol)
 */


/* Memory hub top */
module vl_axi4_mem_hub #(
	parameter M0_ID_WIDTH = 7,		/* AXI master 0 ID width */
	parameter M1_ID_WIDTH = 7,		/* AXI master 1 ID width */
	parameter MEMIF_FIFO_DEPTH_POW2 = 5	/* Memory IF FIFOs depth */
)
(
	clk,
	nrst,
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
	M1_AXI4_RREADY,
	/** CU **/
	/* Master port select */
	i_cu_m_sel,
	/* Request channel */
	o_cu_rqa_rdy,
	i_cu_rqa,
	i_cu_rqa_wr,
	/* Response channel */
	o_cu_rss_vld,
	o_cu_rss,
	i_cu_rss_rd,
	o_cu_rsd_vld,
	o_cu_rsd,
	i_cu_rsd_rd,
	/** VPU0 **/
	/* Request channel */
	o_vpu0_rqa_rdy,
	i_vpu0_rqa,
	i_vpu0_rqa_wr,
	o_vpu0_rqd_rdy,
	i_vpu0_rqd,
	i_vpu0_rqd_wr,
	/* Response channel */
	o_vpu0_rss_vld,
	o_vpu0_rss,
	i_vpu0_rss_rd,
	o_vpu0_rsd_vld,
	o_vpu0_rsd,
	i_vpu0_rsd_rd,
	/** VPU1 **/
	/* Request channel */
	o_vpu1_rqa_rdy,
	i_vpu1_rqa,
	i_vpu1_rqa_wr,
	o_vpu1_rqd_rdy,
	i_vpu1_rqd,
	i_vpu1_rqd_wr,
	/* Response channel */
	o_vpu1_rss_vld,
	o_vpu1_rss,
	i_vpu1_rss_rd,
	o_vpu1_rsd_vld,
	o_vpu1_rsd,
	i_vpu1_rsd_rd

);
/* Global signals */
input wire			clk;
input wire			nrst;
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
/** CU **/
/* Master port select */
input wire		i_cu_m_sel;
/* Request channel */
output wire		o_cu_rqa_rdy;
input wire [43:0]	i_cu_rqa;
input wire		i_cu_rqa_wr;
/* Response channel */
output wire		o_cu_rss_vld;
output wire [8:0]	o_cu_rss;
input wire		i_cu_rss_rd;
output wire		o_cu_rsd_vld;
output wire [63:0]	o_cu_rsd;
input wire		i_cu_rsd_rd;
/** VPU0 **/
/* Request channel */
output wire		o_vpu0_rqa_rdy;
input wire [43:0]	i_vpu0_rqa;
input wire		i_vpu0_rqa_wr;
output wire		o_vpu0_rqd_rdy;
input wire [71:0]	i_vpu0_rqd;
input wire		i_vpu0_rqd_wr;
/* Response channel */
output wire		o_vpu0_rss_vld;
output wire [8:0]	o_vpu0_rss;
input wire		i_vpu0_rss_rd;
output wire		o_vpu0_rsd_vld;
output wire [63:0]	o_vpu0_rsd;
input wire		i_vpu0_rsd_rd;
/** VPU1 **/
/* Request channel */
output wire		o_vpu1_rqa_rdy;
input wire [43:0]	i_vpu1_rqa;
input wire		i_vpu1_rqa_wr;
output wire		o_vpu1_rqd_rdy;
input wire [71:0]	i_vpu1_rqd;
input wire		i_vpu1_rqd_wr;
/* Response channel */
output wire		o_vpu1_rss_vld;
output wire [8:0]	o_vpu1_rss;
input wire		i_vpu1_rss_rd;
output wire		o_vpu1_rsd_vld;
output wire [63:0]	o_vpu1_rsd;
input wire		i_vpu1_rsd_rd;


/********************** INTERNAL INTERCONNECT WIRES ***************************/


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



/***************************** UNITS INSTANCES ********************************/


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
	.i_cu_m_sel(i_cu_m_sel),
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


/* CU request FIFO (address channel) */
vxe_fifo #(
	.DATA_WIDTH(44),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_cu_rqa (
	.clk(clk),
	.nrst(nrst),
	.data_in(i_cu_rqa),
	.data_out(mh_cu_rqa),
	.rd(mh_cu_rqa_rd),
	.wr(i_cu_rqa_wr),
	.in_rdy(o_cu_rqa_rdy),
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
	.data_out(o_cu_rss),
	.rd(i_cu_rss_rd),
	.wr(mh_cu_rss_wr),
	.in_rdy(mh_cu_rss_rdy),
	.out_vld(o_cu_rss_vld)
);


/* CU response FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(64),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_cu_rsd (
	.clk(clk),
	.nrst(nrst),
	.data_in(mh_cu_rsd),
	.data_out(o_cu_rsd),
	.rd(i_cu_rsd_rd),
	.wr(mh_cu_rsd_wr),
	.in_rdy(mh_cu_rsd_rdy),
	.out_vld(o_cu_rsd_vld)
);


/* VPU0 request FIFO (address channel) */
vxe_fifo #(
	.DATA_WIDTH(44),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_vpu0_rqa (
	.clk(clk),
	.nrst(nrst),
	.data_in(i_vpu0_rqa),
	.data_out(mh_vpu0_rqa),
	.rd(mh_vpu0_rqa_rd),
	.wr(i_vpu0_rqa_wr),
	.in_rdy(o_vpu0_rqa_rdy),
	.out_vld(mh_vpu0_rqa_vld)
);


/* VPU0 request FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(72),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_vpu0_rqd (
	.clk(clk),
	.nrst(nrst),
	.data_in(i_vpu0_rqd),
	.data_out(mh_vpu0_rqd),
	.rd(mh_vpu0_rqd_rd),
	.wr(i_vpu0_rqd_wr),
	.in_rdy(o_vpu0_rqd_rdy),
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
	.data_out(o_vpu0_rss),
	.rd(i_vpu0_rss_rd),
	.wr(mh_vpu0_rss_wr),
	.in_rdy(mh_vpu0_rss_rdy),
	.out_vld(o_vpu0_rss_vld)
);


/* VPU0 response FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(64),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_vpu0_rsd (
	.clk(clk),
	.nrst(nrst),
	.data_in(mh_vpu0_rsd),
	.data_out(o_vpu0_rsd),
	.rd(i_vpu0_rsd_rd),
	.wr(mh_vpu0_rsd_wr),
	.in_rdy(mh_vpu0_rsd_rdy),
	.out_vld(o_vpu0_rsd_vld)
);


/* VPU1 request FIFO (address channel) */
vxe_fifo #(
	.DATA_WIDTH(44),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_vpu1_rqa (
	.clk(clk),
	.nrst(nrst),
	.data_in(i_vpu1_rqa),
	.data_out(mh_vpu1_rqa),
	.rd(mh_vpu1_rqa_rd),
	.wr(i_vpu1_rqa_wr),
	.in_rdy(o_vpu1_rqa_rdy),
	.out_vld(mh_vpu1_rqa_vld)
);


/* VPU1 request FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(72),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_vpu1_rqd (
	.clk(clk),
	.nrst(nrst),
	.data_in(i_vpu1_rqd),
	.data_out(mh_vpu1_rqd),
	.rd(mh_vpu1_rqd_rd),
	.wr(i_vpu1_rqd_wr),
	.in_rdy(o_vpu1_rqd_rdy),
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
	.data_out(o_vpu1_rss),
	.rd(i_vpu1_rss_rd),
	.wr(mh_vpu1_rss_wr),
	.in_rdy(mh_vpu1_rss_rdy),
	.out_vld(o_vpu1_rss_vld)
);


/* VPU1 response FIFO (data channel) */
vxe_fifo #(
	.DATA_WIDTH(64),
	.DEPTH_POW2(MEMIF_FIFO_DEPTH_POW2)
) fifo_vpu1_rsd (
	.clk(clk),
	.nrst(nrst),
	.data_in(mh_vpu1_rsd),
	.data_out(o_vpu1_rsd),
	.rd(i_vpu1_rsd_rd),
	.wr(mh_vpu1_rsd_wr),
	.in_rdy(mh_vpu1_rsd_rdy),
	.out_vld(o_vpu1_rsd_vld)
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


endmodule /* vl_axi4_mem_hub */
