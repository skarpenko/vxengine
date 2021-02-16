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
 * AXI4 slave bus interface unit
 */

module vxe_axi4slv_biu(
	S_AXI4_ACLK,
	S_AXI4_ARESETn,
	/* AXI channels */
	S_AXI4_AWID,
	S_AXI4_AWADDR,
	S_AXI4_AWLEN,
	S_AXI4_AWSIZE,
	S_AXI4_AWBURST,
	S_AXI4_AWLOCK,
	S_AXI4_AWPROT,
	S_AXI4_AWVALID,
	S_AXI4_AWREADY,
	S_AXI4_WDATA,
	S_AXI4_WSTRB,
	S_AXI4_WLAST,
	S_AXI4_WVALID,
	S_AXI4_WREADY,
	S_AXI4_BID,
	S_AXI4_BRESP,
	S_AXI4_BVALID,
	S_AXI4_BREADY,
	S_AXI4_ARID,
	S_AXI4_ARADDR,
	S_AXI4_ARLEN,
	S_AXI4_ARSIZE,
	S_AXI4_ARBURST,
	S_AXI4_ARLOCK,
	S_AXI4_ARPROT,
	S_AXI4_ARVALID,
	S_AXI4_ARREADY,
	S_AXI4_RID,
	S_AXI4_RDATA,
	S_AXI4_RRESP,
	S_AXI4_RLAST,
	S_AXI4_RVALID,
	S_AXI4_RREADY,
	/* BIU interface */
	biu_waddr,
	biu_wenable,
	biu_wdata,
	biu_wben,
	biu_waccept,
	biu_werror,
	biu_raddr,
	biu_renable,
	biu_rdata,
	biu_raccept,
	biu_rerror
);
parameter ADDR_WIDTH = 32;
parameter DATA_WIDTH = 32;
parameter ID_WIDTH = 8;
/* AXI responses */
localparam [1:0] OKAY	= 2'b00;
localparam [1:0] EXOKAY	= 2'b01;
localparam [1:0] SLVERR	= 2'b10;
localparam [1:0] DECERR	= 2'b11;
/* AXI global signals */
input wire			S_AXI4_ACLK;
input wire			S_AXI4_ARESETn;
/* AXI write address channel */
input wire [ID_WIDTH-1:0]	S_AXI4_AWID;
input wire [ADDR_WIDTH-1:0]	S_AXI4_AWADDR;
input wire [7:0]		S_AXI4_AWLEN;
input wire [2:0]		S_AXI4_AWSIZE;
input wire [1:0]		S_AXI4_AWBURST;
input wire			S_AXI4_AWLOCK;
input wire [2:0]		S_AXI4_AWPROT;
input wire			S_AXI4_AWVALID;
output wire			S_AXI4_AWREADY;
/* AXI write data channel */
input wire [DATA_WIDTH-1:0]	S_AXI4_WDATA;
input wire [DATA_WIDTH/8-1:0]	S_AXI4_WSTRB;
input wire			S_AXI4_WLAST;
input wire			S_AXI4_WVALID;
output wire			S_AXI4_WREADY;
/* AXI write response channel */
output wire [ID_WIDTH-1:0]	S_AXI4_BID;
output wire [1:0]		S_AXI4_BRESP;
output wire			S_AXI4_BVALID;
input wire			S_AXI4_BREADY;
/* AXI read address channel */
input wire [ID_WIDTH-1:0]	S_AXI4_ARID;
input wire [ADDR_WIDTH-1:0]	S_AXI4_ARADDR;
input wire [7:0]		S_AXI4_ARLEN;
input wire [2:0]		S_AXI4_ARSIZE;
input wire [1:0]		S_AXI4_ARBURST;
input wire			S_AXI4_ARLOCK;
input wire [2:0]		S_AXI4_ARPROT;
input wire			S_AXI4_ARVALID;
output wire			S_AXI4_ARREADY;
/* AXI read data channel */
output wire [ID_WIDTH-1:0]	S_AXI4_RID;
output wire [DATA_WIDTH-1:0]	S_AXI4_RDATA;
output wire [1:0]		S_AXI4_RRESP;
output wire			S_AXI4_RLAST;
output wire			S_AXI4_RVALID;
input wire			S_AXI4_RREADY;
/* BIU interface write path */
output wire [ADDR_WIDTH-1:0]	biu_waddr;
output wire			biu_wenable;
output wire [DATA_WIDTH-1:0]	biu_wdata;
output wire [DATA_WIDTH/8-1:0]	biu_wben;
input wire			biu_waccept;
input wire			biu_werror;
/* BIU interface read path */
output wire [ADDR_WIDTH-1:0]	biu_raddr;
output wire			biu_renable;
input wire [DATA_WIDTH-1:0]	biu_rdata;
input wire			biu_raccept;
input wire			biu_rerror;


/******************************** WRITE PATH **********************************/

reg [ID_WIDTH-1:0]	awid_q;
reg [ADDR_WIDTH-1:0]	awaddr_q;
reg			awlock_q;
reg			awvalid_q;
reg [DATA_WIDTH-1:0]	wdata_q;
reg [DATA_WIDTH/8-1:0]	wstrb_q;
reg			wvalid_q;
reg [ID_WIDTH-1:0]	bid_q;
reg [1:0]		bresp_q;
reg			bvalid_q;


assign S_AXI4_AWREADY = ~awvalid_q;
assign S_AXI4_WREADY = ~wvalid_q;
assign S_AXI4_BID = bid_q;
assign S_AXI4_BRESP = bresp_q;
assign S_AXI4_BVALID = bvalid_q;

assign biu_waddr = awaddr_q;
assign biu_wenable = awvalid_q && wvalid_q;
assign biu_wdata = wdata_q;
assign biu_wben = wstrb_q;

/* Request */ 
always @(posedge S_AXI4_ACLK or negedge S_AXI4_ARESETn)
begin
	if(!S_AXI4_ARESETn)
	begin
		awvalid_q <= 1'b0;
		wvalid_q <= 1'b0;
	end
	else
	begin
		if(S_AXI4_AWVALID && ~awvalid_q)
		begin
			awid_q <= S_AXI4_AWID;
			awaddr_q <= S_AXI4_AWADDR;
			awlock_q <= S_AXI4_AWLOCK;
			awvalid_q <= 1'b1;
		end

		if(S_AXI4_WVALID && ~wvalid_q)
		begin
			wdata_q <= S_AXI4_WDATA;
			wstrb_q <= S_AXI4_WSTRB;
			wvalid_q <= 1'b1;
		end

		if(awvalid_q && wvalid_q && biu_waccept)
		begin
			awvalid_q <= 1'b0;
			wvalid_q <= 1'b0;
		end
	end
end


/* Response */
always @(posedge S_AXI4_ACLK or negedge S_AXI4_ARESETn)
begin
	if(!S_AXI4_ARESETn)
	begin
		bvalid_q <= 1'b0;
	end
	else
	begin
		if(awvalid_q && wvalid_q && biu_waccept)
		begin
			bid_q <= awid_q;
			bresp_q <= biu_werror ? SLVERR :
				(awlock_q ? EXOKAY : OKAY);
			bvalid_q <= 1'b1;
		end

		if(S_AXI4_BREADY && bvalid_q)
		begin
			bvalid_q <= 1'b0;
		end
	end
end


/******************************** READ PATH ***********************************/

reg [ID_WIDTH-1:0]	arid_q;
reg [ADDR_WIDTH-1:0]	araddr_q;
reg			arlock_q;
reg			arvalid_q;
reg [DATA_WIDTH-1:0]	rdata_q;
reg [ID_WIDTH-1:0]	rid_q;
reg [1:0]		rresp_q;
reg			rvalid_q;

assign S_AXI4_ARREADY = ~arvalid_q;
assign S_AXI4_RDATA = rdata_q;
assign S_AXI4_RID = rid_q;
assign S_AXI4_RRESP = rresp_q;
assign S_AXI4_RLAST = 1'b1;
assign S_AXI4_RVALID = rvalid_q;

assign biu_raddr = araddr_q;
assign biu_renable = arvalid_q;


/* Request */
always @(posedge S_AXI4_ACLK or negedge S_AXI4_ARESETn)
begin
	if(!S_AXI4_ARESETn)
	begin
		arvalid_q <= 1'b0;
	end
	else
	begin
		if(S_AXI4_ARVALID && ~arvalid_q)
		begin
			arid_q <= S_AXI4_ARID;
			araddr_q <= S_AXI4_ARADDR;
			arlock_q <= S_AXI4_ARLOCK;
			arvalid_q <= 1'b1;
		end

		if(arvalid_q && biu_raccept)
		begin
			arvalid_q <= 1'b0;
		end
	end
end


/* Response */
always @(posedge S_AXI4_ACLK or negedge S_AXI4_ARESETn)
begin
	if(!S_AXI4_ARESETn)
	begin
		rvalid_q <= 1'b0;
	end
	else
	begin
		if(arvalid_q && biu_raccept)
		begin
			rid_q <= arid_q;
			rdata_q <= biu_rdata;
			rresp_q <= biu_rerror ? SLVERR :
				(arlock_q ? EXOKAY : OKAY);
			rvalid_q <= 1'b1;
		end

		if(S_AXI4_RREADY && rvalid_q)
		begin
			rvalid_q <= 1'b0;
		end
	end
end


endmodule /* vxe_axi4slv_biu */
