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
 * VxE AXI switch. Connects memory hub to AXI interface unit.
 */


/* AXI switch */
module vxe_axi_switch(
	clk,
	nrst,
	/* Incoming request from a client */
	i_m_rqa_vld,
	i_m_rqa,
	o_m_rqa_rd,
	i_m_rqd_vld,
	i_m_rqd,
	o_m_rqd_rd,
	/* Outgoing response for a client */
	i_m_rss_rdy,
	o_m_rss,
	o_m_rss_wr,
	i_m_rsd_rdy,
	o_m_rsd,
	o_m_rsd_wr,
	/* Outgoing request to AXI */
	biu_awcid,
	biu_awaddr,
	biu_awdata,
	biu_awstrb,
	biu_awvalid,
	biu_awpop,
	biu_arcid,
	biu_araddr,
	biu_arvalid,
	biu_arpop,
	/* Incoming response on AXI */
	biu_bcid,
	biu_bresp,
	biu_bready,
	biu_bpush,
	biu_rcid,
	biu_rdata,
	biu_rresp,
	biu_rready,
	biu_rpush
);
input wire		clk;
input wire		nrst;
/* Incoming request from a client */
input wire		i_m_rqa_vld;
input wire [43:0]	i_m_rqa;
output wire		o_m_rqa_rd;
input wire		i_m_rqd_vld;
input wire [71:0]	i_m_rqd;
output wire		o_m_rqd_rd;
/* Outgoing response for a client */
input wire		i_m_rss_rdy;
output wire [8:0]	o_m_rss;
output wire		o_m_rss_wr;
input wire		i_m_rsd_rdy;
output wire [63:0]	o_m_rsd;
output wire		o_m_rsd_wr;
/* Outgoing request to AXI */
output wire [5:0]	biu_awcid;
output wire [39:0]	biu_awaddr;
output wire [63:0]	biu_awdata;
output wire [7:0]	biu_awstrb;
output wire		biu_awvalid;
input wire		biu_awpop;
output wire [5:0]	biu_arcid;
output wire [39:0]	biu_araddr;
output wire		biu_arvalid;
input wire		biu_arpop;
/* Incoming response on AXI */
input wire [5:0]	biu_bcid;
input wire [1:0]	biu_bresp;
output wire		biu_bready;
input wire		biu_bpush;
input wire [5:0]	biu_rcid;
input wire [63:0]	biu_rdata;
input wire [1:0]	biu_rresp;
output wire		biu_rready;
input wire		biu_rpush;



/* Upstream unit */
vxe_axi_switch_us us_unit(
	.clk(clk),
	.nrst(nrst),
	.i_m_rqa_vld(i_m_rqa_vld),
	.i_m_rqa(i_m_rqa),
	.o_m_rqa_rd(o_m_rqa_rd),
	.i_m_rqd_vld(i_m_rqd_vld),
	.i_m_rqd(i_m_rqd),
	.o_m_rqd_rd(o_m_rqd_rd),
	.biu_awcid(biu_awcid),
	.biu_awaddr(biu_awaddr),
	.biu_awdata(biu_awdata),
	.biu_awstrb(biu_awstrb),
	.biu_awvalid(biu_awvalid),
	.biu_awpop(biu_awpop),
	.biu_arcid(biu_arcid),
	.biu_araddr(biu_araddr),
	.biu_arvalid(biu_arvalid),
	.biu_arpop(biu_arpop)
);


/* Downstream unit */
vxe_axi_switch_ds ds_unit(
	.clk(clk),
	.nrst(nrst),
	.biu_bcid(biu_bcid),
	.biu_bresp(biu_bresp),
	.biu_bready(biu_bready),
	.biu_bpush(biu_bpush),
	.biu_rcid(biu_rcid),
	.biu_rdata(biu_rdata),
	.biu_rresp(biu_rresp),
	.biu_rready(biu_rready),
	.biu_rpush(biu_rpush),
	.i_m_rss_rdy(i_m_rss_rdy),
	.o_m_rss(o_m_rss),
	.o_m_rss_wr(o_m_rss_wr),
	.i_m_rsd_rdy(i_m_rsd_rdy),
	.o_m_rsd(o_m_rsd),
	.o_m_rsd_wr(o_m_rsd_wr)
);


endmodule /* vxe_axi_switch */
