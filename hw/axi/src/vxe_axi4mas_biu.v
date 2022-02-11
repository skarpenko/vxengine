/*
 * Copyright (c) 2020-2022 The VxEngine Project. All rights reserved.
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
	biu_bready,
	biu_bpush,
	biu_arcid,
	biu_araddr,
	biu_arvalid,
	biu_arpop,
	biu_rcid,
	biu_rdata,
	biu_rresp,
	biu_rready,
	biu_rpush
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
localparam [2:0] FSM_IDLE = 3'b001;
localparam [2:0] FSM_SEND = 3'b010;
localparam [2:0] FSM_WAIT = 3'b100;
localparam [2:0] FSM_READ = 3'b010;
localparam [2:0] FSM_STALL = 3'b100;
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
input wire			biu_bready;
output reg			biu_bpush;
/* BIU interface read path */
input wire [CID_WIDTH-1:0]	biu_arcid;
input wire [ADDR_WIDTH-1:0]	biu_araddr;
input wire			biu_arvalid;
output reg			biu_arpop;
output reg [CID_WIDTH-1:0]	biu_rcid;
output reg [DATA_WIDTH-1:0]	biu_rdata;
output reg [1:0]		biu_rresp;
input wire			biu_rready;
output reg			biu_rpush;


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
reg [2:0] awfsm_state;

reg [(CID_WIDTH+ADDR_WIDTH+DATA_WIDTH+
	DATA_WIDTH/8)-1:0] awfifo[0:3];	/* Incoming write requests FIFO */
reg [2:0] awrp;				/* Read pointer */
reg [2:0] awwp;				/* Write pointer */
wire [2:0] awrp1 = awrp - 1'b1;		/* Read pointer - 1 */
/* FIFO states */
wire awfull = (awrp[1:0] == awwp[1:0]) && (awrp[2] != awwp[2]);
wire awempty = (awrp[1:0] == awwp[1:0]) && (awrp[2] == awwp[2]);
wire awalmost_full = (awrp1[1:0] == awwp[1:0]) && (awrp1[2] != awwp[2]);
wire awfifo_stall = awfull || awalmost_full;


/* Receive write request into FIFO */
always @(posedge M_AXI4_ACLK or negedge M_AXI4_ARESETn)
begin
	if(!M_AXI4_ARESETn)
	begin
		awwp <= 3'b000;
		biu_awpop <= 1'b0;
		awfsm_state <= FSM_IDLE;
	end
	else if(awfsm_state == FSM_READ)
	begin
		if(biu_awvalid)
		begin
			awfifo[awwp[1:0]] <= { biu_awcid, biu_awaddr, biu_awdata,
						biu_awstrb };
			awwp <= awwp + 1'b1;

			if(awfifo_stall)
			begin
				biu_awpop <= 1'b0;
				awfsm_state <= FSM_WAIT;
			end
		end
	end
	else if(awfsm_state == FSM_WAIT)
	begin
		if(~awfifo_stall)
		begin
			biu_awpop <= 1'b1;
			awfsm_state <= FSM_READ;
		end
	end
	else	/* IDLE */
	begin
		if(biu_awvalid)
		begin
			biu_awpop <= 1'b1;
			awfsm_state <= FSM_READ;
		end
	end
end


wire [CID_WIDTH-1:0]	w_awcid;
wire [ADDR_WIDTH-1:0]	w_awaddr;
wire [DATA_WIDTH-1:0]	w_awdata;
wire [DATA_WIDTH/8-1:0]	w_awstrb;
assign { w_awcid, w_awaddr, w_awdata, w_awstrb } = awfifo[awrp[1:0]];

reg awsend;	/* Send to AXI */
reg awwait;	/* Wait for slave ready */


/* Send write request to AXI */
always @(posedge M_AXI4_ACLK or negedge M_AXI4_ARESETn)
begin
	if(!M_AXI4_ARESETn)
	begin
		awrp <= 3'b000;
		awsend <= 1'b0;
		awwait <= 1'b0;
		M_AXI4_AWVALID <= 1'b0;
		M_AXI4_WVALID <= 1'b0;
	end
	else if(~awsend)
	begin
		if(~awempty)
		begin
			M_AXI4_AWID <= { {(ID_WIDTH-CID_WIDTH){1'b0}}, w_awcid };
			M_AXI4_AWADDR <= w_awaddr;
			M_AXI4_AWVALID <= 1'b1;
			M_AXI4_WDATA <= w_awdata;
			M_AXI4_WSTRB <= w_awstrb;
			M_AXI4_WVALID <= 1'b1;

			awrp <= awrp + 1'b1;

			awsend <= 1'b1;
		end
	end
	else if(awsend)
	begin
		if(M_AXI4_AWREADY && M_AXI4_WREADY && ~awwait)
		begin
			M_AXI4_AWID <= { {(ID_WIDTH-CID_WIDTH){1'b0}}, w_awcid };
			M_AXI4_AWADDR <= w_awaddr;
			M_AXI4_WDATA <= w_awdata;
			M_AXI4_WSTRB <= w_awstrb;

			if(awempty)
			begin
				M_AXI4_AWVALID <= 1'b0;
				M_AXI4_WVALID <= 1'b0;
				awsend <= 1'b0;
			end
			else
				awrp <= awrp + 1'b1;
		end
		else
		begin
			awwait <= 1'b1;

			if(M_AXI4_AWREADY)
			begin
				M_AXI4_AWVALID <= 1'b0;
				if(~M_AXI4_WVALID)
				begin
					awsend <= 1'b0;
					awwait <= 1'b0;
				end
			end

			if(M_AXI4_WREADY)
			begin
				M_AXI4_WVALID <= 1'b0;
				if(~M_AXI4_AWVALID)
				begin
					awsend <= 1'b0;
					awwait <= 1'b0;
				end
			end
		end
	end
end


/* Response */
assign M_AXI4_BREADY = ~bfull && ~balmost_full;

reg [(CID_WIDTH+2)-1:0] bfifo[0:3];	/* Incoming response data FIFO */
reg [2:0] brp;				/* Read pointer */
reg [2:0] bwp;				/* Write pointer */
reg bblock;				/* Block incoming responses */
wire [2:0] brp1 = brp - 1'b1;		/* Read pointer - 1 */
/* FIFO states */
wire bfull = (brp[1:0] == bwp[1:0]) && (brp[2] != bwp[2]);
wire bempty = (brp[1:0] == bwp[1:0]) && (brp[2] == bwp[2]);
wire balmost_full = (brp1[1:0] == bwp[1:0]) && (brp1[2] != bwp[2]);


always @(posedge M_AXI4_ACLK or negedge M_AXI4_ARESETn)
begin
	if(!M_AXI4_ARESETn)
	begin
		bwp <= 3'b000;
		bblock <= 1'b0;
	end
	else if(!bblock)
	begin
		if(M_AXI4_BVALID && ~bfull)
		begin
			bfifo[bwp[1:0]] <= { M_AXI4_BID[CID_WIDTH-1:0],
				M_AXI4_BRESP };
			bwp <= bwp + 1'b1;
		end
		bblock <= ~M_AXI4_BREADY;
	end
	else
	begin
		if(M_AXI4_BREADY)
			bblock <= 1'b0;
	end
end

always @(posedge M_AXI4_ACLK or negedge M_AXI4_ARESETn)
begin
	if(!M_AXI4_ARESETn)
	begin
		brp <= 3'b000;
		biu_bpush <= 1'b0;
	end
	else if(~bempty && biu_bready)
	begin
		{ biu_bcid, biu_bresp } <= bfifo[brp[1:0]];
		biu_bpush <= 1'b1;
		brp <= brp + 1'b1;
	end
	else if(biu_bready)
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
reg [2:0] arfsm_state;

reg [(CID_WIDTH+ADDR_WIDTH)-1:0] arfifo[0:3];	/* Incoming read requests FIFO */
reg [2:0] arrp;					/* Read pointer */
reg [2:0] arwp;					/* Write pointer */
wire [2:0] arrp1 = arrp - 1'b1;			/* Read pointer - 1 */
/* FIFO states */
wire arfull = (arrp[1:0] == arwp[1:0]) && (arrp[2] != arwp[2]);
wire arempty = (arrp[1:0] == arwp[1:0]) && (arrp[2] == arwp[2]);
wire aralmost_full = (arrp1[1:0] == arwp[1:0]) && (arrp1[2] != arwp[2]);
wire arfifo_stall = arfull || aralmost_full;


/* Receive read request into FIFO */
always @(posedge M_AXI4_ACLK or negedge M_AXI4_ARESETn)
begin
	if(!M_AXI4_ARESETn)
	begin
		arwp <= 3'b000;
		biu_arpop <= 1'b0;
		arfsm_state <= FSM_IDLE;
	end
	else if(arfsm_state == FSM_READ)
	begin
		if(biu_arvalid)
		begin
			arfifo[arwp[1:0]] <= { biu_arcid, biu_araddr };
			arwp <= arwp + 1'b1;

			if(arfifo_stall)
			begin
				biu_arpop <= 1'b0;
				arfsm_state <= FSM_WAIT;
			end
		end
	end
	else if(arfsm_state == FSM_WAIT)
	begin
		if(~arfifo_stall)
		begin
			biu_arpop <= 1'b1;
			arfsm_state <= FSM_READ;
		end
	end
	else	/* IDLE */
	begin
		if(biu_arvalid)
		begin
			biu_arpop <= 1'b1;
			arfsm_state <= FSM_READ;
		end
	end
end


wire [CID_WIDTH-1:0]	w_arcid;
wire [ADDR_WIDTH-1:0]	w_araddr;
assign { w_arcid, w_araddr } = arfifo[arrp[1:0]];

reg arsend;	/* Send to AXI */
reg arwait;	/* Wait for slave ready */


/* Send read request to AXI */
always @(posedge M_AXI4_ACLK or negedge M_AXI4_ARESETn)
begin
	if(!M_AXI4_ARESETn)
	begin
		arrp <= 3'b000;
		arsend <= 1'b0;
		arwait <= 1'b0;
		M_AXI4_ARVALID <= 1'b0;
	end
	else if(~arsend)
	begin
		if(~arempty)
		begin
			M_AXI4_ARID <= { {(ID_WIDTH-CID_WIDTH){1'b0}}, w_arcid };
			M_AXI4_ARADDR <= w_araddr;
			M_AXI4_ARVALID <= 1'b1;

			arrp <= arrp + 1'b1;

			arsend <= 1'b1;
		end
	end
	else if(arsend)
	begin
		if(M_AXI4_ARREADY && ~arwait)
		begin
			M_AXI4_ARID <= { {(ID_WIDTH-CID_WIDTH){1'b0}}, w_arcid };
			M_AXI4_ARADDR <= w_araddr;

			if(arempty)
			begin
				M_AXI4_ARVALID <= 1'b0;
				arsend <= 1'b0;
			end
			else
				arrp <= arrp + 1'b1;
		end
		else
		begin
			arwait <= 1'b1;

			if(M_AXI4_ARREADY)
			begin
				M_AXI4_ARVALID <= 1'b0;
				arsend <= 1'b0;
				arwait <= 1'b0;
			end

		end
	end
end


/* Response */
assign M_AXI4_RREADY = ~rfull && ~ralmost_full;

reg [(CID_WIDTH+DATA_WIDTH+2)-1:0] rfifo[0:3];	/* Incoming response data FIFO */
reg [2:0] rrp;					/* Read pointer */
reg [2:0] rwp;					/* Write pointer */
reg rblock;					/* Block incoming responses */
wire [2:0] rrp1 = rrp - 1'b1;			/* Read pointer - 1 */
/* FIFO states */
wire rfull = (rrp[1:0] == rwp[1:0]) && (rrp[2] != rwp[2]);
wire rempty = (rrp[1:0] == rwp[1:0]) && (rrp[2] == rwp[2]);
wire ralmost_full = (rrp1[1:0] == rwp[1:0]) && (rrp1[2] != rwp[2]);


always @(posedge M_AXI4_ACLK or negedge M_AXI4_ARESETn)
begin
	if(!M_AXI4_ARESETn)
	begin
		rwp <= 3'b000;
		rblock <= 1'b0;
	end
	else if(!rblock)
	begin
		if(M_AXI4_RVALID && ~rfull)
		begin
			rfifo[rwp[1:0]] <= { M_AXI4_RID[CID_WIDTH-1:0],
				M_AXI4_RDATA, M_AXI4_RRESP };
			rwp <= rwp + 1'b1;
		end
		rblock <= ~M_AXI4_RREADY;
	end
	else
	begin
		if(M_AXI4_RREADY)
			rblock <= 1'b0;
	end
end

always @(posedge M_AXI4_ACLK or negedge M_AXI4_ARESETn)
begin
	if(!M_AXI4_ARESETn)
	begin
		rrp <= 3'b000;
		biu_rpush <= 1'b0;
	end
	else if(~rempty && biu_rready)
	begin
		{ biu_rcid, biu_rdata, biu_rresp } <= rfifo[rrp[1:0]];
		biu_rpush <= 1'b1;
		rrp <= rrp + 1'b1;
	end
	else if(biu_rready)
		biu_rpush <= 1'b0;
end


endmodule /* vxe_axi4mas_biu */
