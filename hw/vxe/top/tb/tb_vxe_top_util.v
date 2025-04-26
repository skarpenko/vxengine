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
 * Testbench for VxEngine top-level: utility units
 */


/* AXI4 read endpoint node */
module axi4_read_endpoint #(
	parameter ID_WIDTH = 7,			/* AXI ID width */
	parameter CU_PGM_IMAGE = "file.hex",	/* CU program image */
	parameter CU_PGM_SIZE_POW2 = 8		/* CU program size (power of 2) */
)
(
	clk,
	nrst,
	/* AXI4 Slave: read channels */
	AXI4_ARID,
	AXI4_ARADDR,
	AXI4_ARLEN,
	AXI4_ARSIZE,
	AXI4_ARBURST,
	AXI4_ARLOCK,
	AXI4_ARCACHE,
	AXI4_ARPROT,
	AXI4_ARVALID,
	AXI4_ARREADY,
	AXI4_RID,
	AXI4_RDATA,
	AXI4_RRESP,
	AXI4_RLAST,
	AXI4_RVALID,
	AXI4_RREADY
);
`include "vxe_client_params.vh"
localparam			FD_POW2 = 6;	/* FIFO depth (power of two) */
/* Global signals */
input wire			clk;
input wire			nrst;
/* AXI4 Slave: read channels */
input wire [ID_WIDTH-1:0]	AXI4_ARID;
input wire [39:0]		AXI4_ARADDR;
input wire [7:0]		AXI4_ARLEN;
input wire [2:0]		AXI4_ARSIZE;
input wire [1:0]		AXI4_ARBURST;
input wire			AXI4_ARLOCK;
input wire [3:0]		AXI4_ARCACHE;
input wire [2:0]		AXI4_ARPROT;
input wire			AXI4_ARVALID;
output wire			AXI4_ARREADY;
output reg [ID_WIDTH-1:0]	AXI4_RID;
output reg [63:0]		AXI4_RDATA;
output reg [1:0]		AXI4_RRESP;
output wire			AXI4_RLAST;
output reg			AXI4_RVALID;
input wire			AXI4_RREADY;


/* CU program */
reg [63:0]			cu_pgm_mem[0:2**CU_PGM_SIZE_POW2-1];	/* Program mem */
reg [CU_PGM_SIZE_POW2-1:0]	cu_pgm_pc;				/* Program counter */
/* CU client ID */
wire [ID_WIDTH-1:0]		CU_ID = { {(ID_WIDTH-2){1'b0}}, CLNT_CU };


initial
	$readmemh(CU_PGM_IMAGE, cu_pgm_mem);


/*** Requests FIFO ***/
reg [ID_WIDTH-1:0]	rq_fifo_id[0:2**FD_POW2-1];
reg [39:0]		rq_fifo_addr[0:2**FD_POW2-1];
reg [FD_POW2:0]		rq_fifo_rp;	/* Read pointer */
reg [FD_POW2:0]		rq_fifo_wp;	/* Write pointer */
/* Previous FIFO read pointer */
wire [FD_POW2:0]	rq_fifo_pre_rp = rq_fifo_rp - 1'b1;
/* FIFO states */
wire rq_fifo_empty = (rq_fifo_rp[FD_POW2] == rq_fifo_wp[FD_POW2]) &&
	(rq_fifo_rp[FD_POW2-1:0] == rq_fifo_wp[FD_POW2-1:0]);
wire rq_fifo_full = (rq_fifo_rp[FD_POW2] != rq_fifo_wp[FD_POW2]) &&
	(rq_fifo_rp[FD_POW2-1:0] == rq_fifo_wp[FD_POW2-1:0]);
wire rq_fifo_pre_full = (rq_fifo_pre_rp[FD_POW2] != rq_fifo_wp[FD_POW2]) &&
	(rq_fifo_pre_rp[FD_POW2-1:0] == rq_fifo_wp[FD_POW2-1:0]);
/* FIFO stall */
wire rq_fifo_stall = rq_fifo_full || rq_fifo_pre_full;

/* Ready state */
assign AXI4_ARREADY = ~rq_fifo_stall;

assign AXI4_RLAST = 1'b1;	/* Always last response */


/* Read requests FSM */
always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		rq_fifo_wp <= {(FD_POW2+1){1'b0}};
	end
	else if(AXI4_ARVALID)
	begin
		rq_fifo_id[rq_fifo_wp[FD_POW2-1:0]] <= AXI4_ARID;
		rq_fifo_addr[rq_fifo_wp[FD_POW2-1:0]] <= AXI4_ARADDR;
		rq_fifo_wp <= rq_fifo_wp + 1'b1;
	end
end


/* Send responses FSM */
reg fsm_send_state;
always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		AXI4_RVALID <= 1'b0;
		rq_fifo_rp <= {(FD_POW2+1){1'b0}};
		cu_pgm_pc <= {(CU_PGM_SIZE_POW2+1){1'b0}};
		fsm_send_state <= 1'b0;
	end
	else if(!fsm_send_state)
	begin
		if(!rq_fifo_empty)
		begin
			AXI4_RID <= rq_fifo_id[rq_fifo_rp[FD_POW2-1:0]];
			AXI4_RRESP <= 2'b00;

			/* Reply with next instruction to Control Unit only */
			if(rq_fifo_id[rq_fifo_rp[FD_POW2-1:0]] == CU_ID)
			begin
				AXI4_RDATA <= cu_pgm_mem[cu_pgm_pc];
				cu_pgm_pc <= cu_pgm_pc + 1'b1;
			end
			else
				AXI4_RDATA <= 64'h0;
			AXI4_RVALID <= 1'b1;

			rq_fifo_rp <= rq_fifo_rp + 1'b1;
			fsm_send_state <= 1'b1;
		end
	end
	else if(fsm_send_state)
	begin
		if(!rq_fifo_empty && AXI4_RREADY)
		begin
			AXI4_RID <= rq_fifo_id[rq_fifo_rp[FD_POW2-1:0]];
			AXI4_RRESP <= 2'b00;

			/* Reply with next instruction to Control Unit only */
			if(rq_fifo_id[rq_fifo_rp[FD_POW2-1:0]] == CU_ID)
			begin
				AXI4_RDATA <= cu_pgm_mem[cu_pgm_pc];
				cu_pgm_pc <= cu_pgm_pc + 1'b1;
			end
			else
				AXI4_RDATA <= 64'h0;
			rq_fifo_rp <= rq_fifo_rp + 1'b1;
		end
		else if(AXI4_RREADY)
		begin
			AXI4_RVALID <= 1'b0;
			fsm_send_state <= 1'b0;
		end
	end
end


endmodule /* axi4_read_endpoint */


/******************************************************************************/


/* AXI4 write endpoint node */
module axi4_write_endpoint #(
	parameter ID_WIDTH = 7	/* AXI ID width */
)
(
	clk,
	nrst,
	/* AXI4 Slave: write channels */
	AXI4_AWID,
	AXI4_AWADDR,
	AXI4_AWLEN,
	AXI4_AWSIZE,
	AXI4_AWBURST,
	AXI4_AWLOCK,
	AXI4_AWCACHE,
	AXI4_AWPROT,
	AXI4_AWVALID,
	AXI4_AWREADY,
	AXI4_WDATA,
	AXI4_WSTRB,
	AXI4_WLAST,
	AXI4_WVALID,
	AXI4_WREADY,
	AXI4_BID,
	AXI4_BRESP,
	AXI4_BVALID,
	AXI4_BREADY
);
localparam			FD_POW2 = 6;	/* FIFO depth (power of two) */
/* Global signals */
input wire			clk;
input wire			nrst;
/* AXI4 Slave: write channels */
input wire [ID_WIDTH-1:0]	AXI4_AWID;
input wire [39:0]		AXI4_AWADDR;
input wire [7:0]		AXI4_AWLEN;
input wire [2:0]		AXI4_AWSIZE;
input wire [1:0]		AXI4_AWBURST;
input wire			AXI4_AWLOCK;
input wire [3:0]		AXI4_AWCACHE;
input wire [2:0]		AXI4_AWPROT;
input wire			AXI4_AWVALID;
output wire			AXI4_AWREADY;
input wire [63:0]		AXI4_WDATA;
input wire [7:0]		AXI4_WSTRB;
input wire			AXI4_WLAST;
input wire			AXI4_WVALID;
output wire			AXI4_WREADY;
output reg [ID_WIDTH-1:0]	AXI4_BID;
output reg [1:0]		AXI4_BRESP;
output reg			AXI4_BVALID;
input wire			AXI4_BREADY;


/*** Requests FIFO ***/
reg [ID_WIDTH-1:0]	rq_fifo_id[0:2**FD_POW2-1];
reg [39:0]		rq_fifo_addr[0:2**FD_POW2-1];
reg [FD_POW2:0]		rq_fifo_rp;	/* Read pointer */
reg [FD_POW2:0]		rq_fifo_wp;	/* Write pointer */
/* Previous FIFO read pointer */
wire [FD_POW2:0]	rq_fifo_pre_rp = rq_fifo_rp - 1'b1;
/* FIFO states */
wire rq_fifo_empty = (rq_fifo_rp[FD_POW2] == rq_fifo_wp[FD_POW2]) &&
	(rq_fifo_rp[FD_POW2-1:0] == rq_fifo_wp[FD_POW2-1:0]);
wire rq_fifo_full = (rq_fifo_rp[FD_POW2] != rq_fifo_wp[FD_POW2]) &&
	(rq_fifo_rp[FD_POW2-1:0] == rq_fifo_wp[FD_POW2-1:0]);
wire rq_fifo_pre_full = (rq_fifo_pre_rp[FD_POW2] != rq_fifo_wp[FD_POW2]) &&
	(rq_fifo_pre_rp[FD_POW2-1:0] == rq_fifo_wp[FD_POW2-1:0]);
/* FIFO stall */
wire rq_fifo_stall = rq_fifo_full || rq_fifo_pre_full;

/* Ready state */
assign AXI4_AWREADY = ~rq_fifo_stall;
assign AXI4_WREADY =  ~rq_fifo_stall;


/* Read requests FSM */
always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		rq_fifo_wp <= {(FD_POW2+1){1'b0}};
	end
	else if(AXI4_AWVALID)
	begin
		rq_fifo_id[rq_fifo_wp[FD_POW2-1:0]] <= AXI4_AWID;
		rq_fifo_addr[rq_fifo_wp[FD_POW2-1:0]] <= AXI4_AWADDR;
		rq_fifo_wp <= rq_fifo_wp + 1'b1;
	end
end


/* Send responses FSM */
reg fsm_send_state;
always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		AXI4_BVALID <= 1'b0;
		rq_fifo_rp <= {(FD_POW2+1){1'b0}};
		fsm_send_state <= 1'b0;
	end
	else if(!fsm_send_state)
	begin
		if(!rq_fifo_empty)
		begin
			AXI4_BID <= rq_fifo_id[rq_fifo_rp[FD_POW2-1:0]];
			AXI4_BRESP <= 2'b00;
			AXI4_BVALID <= 1'b1;
			rq_fifo_rp <= rq_fifo_rp + 1'b1;
			fsm_send_state <= 1'b1;
		end
	end
	else if(fsm_send_state)
	begin
		if(!rq_fifo_empty && AXI4_BREADY)
		begin
			AXI4_BID <= rq_fifo_id[rq_fifo_rp[FD_POW2-1:0]];
			AXI4_BRESP <= 2'b00;
			rq_fifo_rp <= rq_fifo_rp + 1'b1;
		end
		else if(AXI4_BREADY)
		begin
			AXI4_BVALID <= 1'b0;
			fsm_send_state <= 1'b0;
		end
	end
end


endmodule /* axi4_write_endpoint */
