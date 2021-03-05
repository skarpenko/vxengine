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
 * AXI4 master bus interface unit
 */

module vxe_axi4mas_biu(
	M_AXI4_ACLK,
	M_AXI4_ARESETn,
	/* AXI channels */
	M_AXI4_AWID,
	M_AXI4_AWADDR,
	M_AXI4_AWLEN,
	M_AXI4_AWSIZE,
	M_AXI4_AWBURST,
	M_AXI4_AWLOCK,
	M_AXI4_AWCACHE,
	M_AXI4_AWPROT,
	M_AXI4_AWVALID,
	M_AXI4_AWREADY,
	M_AXI4_WDATA,
	M_AXI4_WSTRB,
	M_AXI4_WLAST,
	M_AXI4_WVALID,
	M_AXI4_WREADY,
	M_AXI4_BID,
	M_AXI4_BRESP,
	M_AXI4_BVALID,
	M_AXI4_BREADY,
	M_AXI4_ARID,
	M_AXI4_ARADDR,
	M_AXI4_ARLEN,
	M_AXI4_ARSIZE,
	M_AXI4_ARBURST,
	M_AXI4_ARLOCK,
	M_AXI4_ARCACHE,
	M_AXI4_ARPROT,
	M_AXI4_ARVALID,
	M_AXI4_ARREADY,
	M_AXI4_RID,
	M_AXI4_RDATA,
	M_AXI4_RRESP,
	M_AXI4_RLAST,
	M_AXI4_RVALID,
	M_AXI4_RREADY,
	/* BIU interface */
	biu_awcid,
	biu_awaddr,
	biu_awdata,
	biu_awstrb,
	biu_awvalid,
	biu_awpop,
	biu_bcid,
	biu_bresp,
	biu_bpush,
	biu_bready,
	biu_araddr,
	biu_arcid,
	biu_arvalid,
	biu_rcid,
	biu_arpop,
	biu_rdata,
	biu_rresp,
	biu_rpush,
	biu_rready
);
parameter ADDR_WIDTH = 32;
parameter DATA_WIDTH = 32;
parameter ID_WIDTH = 8;
parameter CID_WIDTH = 8;	/* Client Id width should be <= ID_WIDTH */
/* AXI responses */
localparam [1:0] OKAY	= 2'b00;
localparam [1:0] EXOKAY	= 2'b01;
localparam [1:0] SLVERR	= 2'b10;
localparam [1:0] DECERR	= 2'b11;
/* FSM states */
localparam FSM_AXI_IDLE = 1'b0;
localparam FSM_AXI_WAIT = 1'b1;
/* AXI global signals */
input wire			M_AXI4_ACLK;
input wire			M_AXI4_ARESETn;
/* AXI write address channel */
output reg [ID_WIDTH-1:0]	M_AXI4_AWID;
output reg [ADDR_WIDTH-1:0]	M_AXI4_AWADDR;
output wire [7:0]		M_AXI4_AWLEN;
output wire [2:0]		M_AXI4_AWSIZE;
output wire [1:0]		M_AXI4_AWBURST;
output wire			M_AXI4_AWLOCK;
output wire [3:0]		M_AXI4_AWCACHE;
output wire [2:0]		M_AXI4_AWPROT;
output reg			M_AXI4_AWVALID;
input wire			M_AXI4_AWREADY;
/* AXI write data channel */
output reg [DATA_WIDTH-1:0]	M_AXI4_WDATA;
output reg [DATA_WIDTH/8-1:0]	M_AXI4_WSTRB;
output wire			M_AXI4_WLAST;
output reg			M_AXI4_WVALID;
input wire			M_AXI4_WREADY;
/* AXI write response channel */
input wire [ID_WIDTH-1:0]	M_AXI4_BID;
input wire [1:0]		M_AXI4_BRESP;
input wire			M_AXI4_BVALID;
output wire			M_AXI4_BREADY;
/* AXI read address channel */
output reg [ID_WIDTH-1:0]	M_AXI4_ARID;
output reg [ADDR_WIDTH-1:0]	M_AXI4_ARADDR;
output wire [7:0]		M_AXI4_ARLEN;
output wire [2:0]		M_AXI4_ARSIZE;
output wire [1:0]		M_AXI4_ARBURST;
output wire			M_AXI4_ARLOCK;
output wire [3:0]		M_AXI4_ARCACHE;
output wire [2:0]		M_AXI4_ARPROT;
output reg			M_AXI4_ARVALID;
input wire			M_AXI4_ARREADY;
/* AXI read data channel */
input wire [ID_WIDTH-1:0]	M_AXI4_RID;
input wire [DATA_WIDTH-1:0]	M_AXI4_RDATA;
input wire [1:0]		M_AXI4_RRESP;
input wire			M_AXI4_RLAST;
input wire			M_AXI4_RVALID;
output wire			M_AXI4_RREADY;
/* BIU interface write path */
input wire [CID_WIDTH-1:0]	biu_awcid;
input wire [ADDR_WIDTH-1:0]	biu_awaddr;
input wire [DATA_WIDTH-1:0]	biu_awdata;
input wire [DATA_WIDTH/8-1:0]	biu_awstrb;
input wire			biu_awvalid;
output reg			biu_awpop;
output reg [CID_WIDTH-1:0]	biu_bcid;
output reg [1:0]		biu_bresp;
output reg			biu_bpush;
input wire			biu_bready;
/* BIU interface read path */
input wire [CID_WIDTH-1:0]	biu_arcid;
input wire [ADDR_WIDTH-1:0]	biu_araddr;
input wire			biu_arvalid;
output reg			biu_arpop;
output reg [CID_WIDTH-1:0]	biu_rcid;
output reg [DATA_WIDTH-1:0]	biu_rdata;
output reg [1:0]		biu_rresp;
output reg			biu_rpush;
input wire			biu_rready;


/* Returns burst size signal value */
function [2:0] bsz_log2;
input [31:0] data_width;
begin
	data_width = data_width - 1;
	for (bsz_log2 = 0; data_width > 0; bsz_log2 = bsz_log2 + 1)
	begin
		data_width = data_width >> 1;
	end
end
endfunction


/******************************** WRITE PATH **********************************/


assign M_AXI4_AWLEN = 8'h00;			/* Burst length is always 1 */
assign M_AXI4_AWSIZE = bsz_log2(DATA_WIDTH);	/* Burst size = data bus width */
assign M_AXI4_AWBURST = 2'b00;			/* Burst type is fixed */
assign M_AXI4_AWLOCK = 1'b0;			/* Lock type is normal */
assign M_AXI4_AWCACHE = 4'h0;			/* Device non-bufferable */
assign M_AXI4_AWPROT = 3'b010;			/* Unprivileged, non-secure, data access */
assign M_AXI4_WLAST = 1'b1;			/* Always last */


/* Write request channel FSM state */
reg awfsm_state;

/* Request */
always @(posedge M_AXI4_ACLK or negedge M_AXI4_ARESETn)
begin
	if(!M_AXI4_ARESETn)
	begin
		M_AXI4_AWVALID <= 1'b0;
		M_AXI4_WVALID <= 1'b0;
		biu_awpop <= 1'b0;
		awfsm_state <= FSM_AXI_IDLE;
	end
	else if(awfsm_state == FSM_AXI_IDLE)
	begin
		M_AXI4_AWVALID <= 1'b0;
		M_AXI4_WVALID <= 1'b0;
		biu_awpop <= 1'b0;

		if(biu_awvalid)
		begin
			M_AXI4_AWID <= { {(ID_WIDTH-CID_WIDTH){1'b0}}, biu_awcid };
			M_AXI4_AWADDR <= biu_awaddr;
			M_AXI4_AWVALID <= 1'b1;
			M_AXI4_WDATA <= biu_awdata;
			M_AXI4_WSTRB <= biu_awstrb;
			M_AXI4_WVALID <= 1'b1;
			biu_awpop <= 1'b1;
			if(!M_AXI4_AWREADY || !M_AXI4_WREADY)
				awfsm_state <= FSM_AXI_WAIT;
		end
	end
	else if(awfsm_state == FSM_AXI_WAIT)
	begin
		biu_awpop <= 1'b0;

		if(M_AXI4_AWREADY)
			M_AXI4_AWVALID <= 1'b0;

		if(M_AXI4_WREADY)
			M_AXI4_WVALID <= 1'b0;

		if(M_AXI4_AWREADY && M_AXI4_WREADY)
			awfsm_state <= FSM_AXI_IDLE;
	end
end


assign M_AXI4_BREADY = biu_bready;

/* Response */
always @(posedge M_AXI4_ACLK or negedge M_AXI4_ARESETn)
begin
	if(!M_AXI4_ARESETn)
	begin
		biu_bpush <= 1'b0;
	end
	else if(M_AXI4_BVALID && biu_bready)
	begin
		biu_bcid <= M_AXI4_BID[CID_WIDTH-1:0];
		biu_bresp <= M_AXI4_BRESP;
		biu_bpush <= 1'b1;
	end
	else
		biu_bpush <= 1'b0;
end


/******************************** READ PATH ***********************************/

assign M_AXI4_ARLEN = 8'h00;			/* Burst length is always 1 */
assign M_AXI4_ARSIZE = bsz_log2(DATA_WIDTH);	/* Burst size = data bus width */
assign M_AXI4_ARBURST = 2'b00;			/* Burst type is fixed */
assign M_AXI4_ARLOCK = 1'b0;			/* Lock type is normal */
assign M_AXI4_ARCACHE = 4'h0;			/* Device non-bufferable */
assign M_AXI4_ARPROT = 3'b010;			/* Unprivileged, non-secure, data access */


/* Read request channel FSM state */
reg arfsm_state;

/* Request */
always @(posedge M_AXI4_ACLK or negedge M_AXI4_ARESETn)
begin
	if(!M_AXI4_ARESETn)
	begin
		M_AXI4_ARVALID <= 1'b0;
		biu_arpop <= 1'b0;
		arfsm_state <= FSM_AXI_IDLE;
	end
	else if(arfsm_state == FSM_AXI_IDLE)
	begin
		M_AXI4_ARVALID <= 1'b0;
		biu_arpop <= 1'b0;

		if(biu_arvalid)
		begin
			M_AXI4_ARID <= { {(ID_WIDTH-CID_WIDTH){1'b0}}, biu_arcid };
			M_AXI4_ARADDR <= biu_araddr;
			M_AXI4_ARVALID <= 1'b1;
			biu_arpop <= 1'b1;
			if(!M_AXI4_ARREADY)
				arfsm_state <= FSM_AXI_WAIT;
		end
	end
	else if(arfsm_state == FSM_AXI_WAIT)
	begin
		biu_arpop <= 1'b0;

		if(M_AXI4_ARREADY)
			arfsm_state <= FSM_AXI_IDLE;
	end
end


assign M_AXI4_RREADY = biu_rready;

/* Response */
always @(posedge M_AXI4_ACLK or negedge M_AXI4_ARESETn)
begin
	if(!M_AXI4_ARESETn)
	begin
		biu_rpush <= 1'b0;
	end
	else if(M_AXI4_RVALID && biu_rready)
	begin
		biu_rcid <= M_AXI4_RID[CID_WIDTH-1:0];
		biu_rdata <= M_AXI4_RDATA;
		biu_rresp <= M_AXI4_RRESP;
		biu_rpush <= 1'b1;
	end
	else
		biu_rpush <= 1'b0;
end


endmodule /* vxe_axi4mas_biu */
