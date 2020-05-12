/*
 * Copyright (c) 2020 The VxEngine Project. All rights reserved.
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
 * AXI4-Lite bus interface unit
 */

module axi4_lite_biu(
	S_AXI_ACLK,
	S_AXI_ARESETn,
	/* AXI channels */
	S_AXI_AWADDR,
	S_AXI_AWPROT,
	S_AXI_AWVALID,
	S_AXI_AWREADY,
	S_AXI_WDATA,
	S_AXI_WSTRB,
	S_AXI_WVALID,
	S_AXI_WREADY,
	S_AXI_BRESP,
	S_AXI_BVALID,
	S_AXI_BREADY,
	S_AXI_ARADDR,
	S_AXI_ARPROT,
	S_AXI_ARVALID,
	S_AXI_ARREADY,
	S_AXI_RDATA,
	S_AXI_RRESP,
	S_AXI_RVALID,
	S_AXI_RREADY,
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
/* AXI responses */
localparam [1:0] OKAY	= 2'b00;
localparam [1:0] EXOKAY	= 2'b01;	/* Is not supported by AXI4-Lite */
localparam [1:0] SLVERR	= 2'b10;
localparam [1:0] DECERR	= 2'b11;
/* AXI global signals */
input wire			S_AXI_ACLK;
input wire			S_AXI_ARESETn;
/* AXI write address channel */
input wire [ADDR_WIDTH-1:0]	S_AXI_AWADDR;
input wire [2:0]		S_AXI_AWPROT;
input wire			S_AXI_AWVALID;
output wire			S_AXI_AWREADY;
/* AXI write data channel */
input wire [DATA_WIDTH-1:0]	S_AXI_WDATA;
input wire [DATA_WIDTH/8-1:0]	S_AXI_WSTRB;
input wire			S_AXI_WVALID;
output wire			S_AXI_WREADY;
/* AXI write response channel */
output wire [1:0]		S_AXI_BRESP;
output wire			S_AXI_BVALID;
input wire			S_AXI_BREADY;
/* AXI read address channel */
input wire [ADDR_WIDTH-1:0]	S_AXI_ARADDR;
input wire [2:0]		S_AXI_ARPROT;
input wire			S_AXI_ARVALID;
output wire			S_AXI_ARREADY;
/* AXI read data channel */
output wire [DATA_WIDTH-1:0]	S_AXI_RDATA;
output wire [1:0]		S_AXI_RRESP;
output wire			S_AXI_RVALID;
input wire			S_AXI_RREADY;
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

reg [ADDR_WIDTH-1:0]	awaddr_q;
reg			awvalid_q;
reg [DATA_WIDTH-1:0]	wdata_q;
reg [DATA_WIDTH/8-1:0]	wstrb_q;
reg			wvalid_q;
reg [1:0]		bresp_q;
reg			bvalid_q;


assign S_AXI_AWREADY = ~awvalid_q;
assign S_AXI_WREADY = ~wvalid_q;
assign S_AXI_BRESP = bresp_q;
assign S_AXI_BVALID = bvalid_q;

assign biu_waddr = awaddr_q;
assign biu_wenable = awvalid_q && wvalid_q;
assign biu_wdata = wdata_q;
assign biu_wben = wstrb_q;

/* Request */ 
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETn)
begin
	if(!S_AXI_ARESETn)
	begin
		awvalid_q <= 1'b0;
		wvalid_q <= 1'b0;
	end
	else
	begin
		if(S_AXI_AWVALID && ~awvalid_q)
		begin
			awaddr_q <= S_AXI_AWADDR;
			awvalid_q <= 1'b1;
		end

		if(S_AXI_WVALID && ~wvalid_q)
		begin
			wdata_q <= S_AXI_WDATA;
			wstrb_q <= S_AXI_WSTRB;
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
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETn)
begin
	if(!S_AXI_ARESETn)
	begin
		bvalid_q <= 1'b0;
	end
	else
	begin
		if(awvalid_q && wvalid_q && biu_waccept)
		begin
			bresp_q <= biu_werror ? SLVERR : OKAY;
			bvalid_q <= 1'b1;
		end

		if(S_AXI_BREADY && bvalid_q)
		begin
			bvalid_q <= 1'b0;
		end
	end
end


/******************************** READ PATH ***********************************/

reg [ADDR_WIDTH-1:0]	araddr_q;
reg			arvalid_q;
reg [DATA_WIDTH-1:0]	rdata_q;
reg [1:0]		rresp_q;
reg			rvalid_q;

assign S_AXI_ARREADY = ~arvalid_q;
assign S_AXI_RDATA = rdata_q;
assign S_AXI_RRESP = rresp_q;
assign S_AXI_RVALID = rvalid_q;

assign biu_raddr = araddr_q;
assign biu_renable = arvalid_q;


/* Request */
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETn)
begin
	if(!S_AXI_ARESETn)
	begin
		arvalid_q <= 1'b0;
	end
	else
	begin
		if(S_AXI_ARVALID && ~arvalid_q)
		begin
			araddr_q <= S_AXI_ARADDR;
			arvalid_q <= 1'b1;
		end

		if(arvalid_q && biu_raccept)
		begin
			arvalid_q <= 1'b0;
		end
	end
end


/* Response */
always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETn)
begin
	if(!S_AXI_ARESETn)
	begin
		rvalid_q <= 1'b0;
	end
	else
	begin
		if(arvalid_q && biu_raccept)
		begin
			rdata_q <= biu_rdata;
			rresp_q <= biu_rerror ? SLVERR : OKAY;
			rvalid_q <= 1'b1;
		end

		if(S_AXI_RREADY && rvalid_q)
		begin
			rvalid_q <= 1'b0;
		end
	end
end


endmodule /* axi4_lite_biu */
