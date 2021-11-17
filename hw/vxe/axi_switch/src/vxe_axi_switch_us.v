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
 * VxE AXI switch upstream unit.
 */


/* AXI switch upstream */
module vxe_axi_switch_us(
	clk,
	nrst,
	/* Incoming request */
	i_m_rqa_vld,
	i_m_rqa,
	o_m_rqa_rd,
	i_m_rqd_vld,
	i_m_rqd,
	o_m_rqd_rd,
	/* Outgoing request */
	biu_awcid,
	biu_awaddr,
	biu_awdata,
	biu_awstrb,
	biu_awvalid,
	biu_awpop,
	biu_arcid,
	biu_araddr,
	biu_arvalid,
	biu_arpop
);
/* Rx FSM states */
localparam [1:0]	FSM_RX_IDLE = 2'b00;	/* Idle */
localparam [1:0]	FSM_RX_RECV = 2'b01;	/* Receive */
localparam [1:0]	FSM_RX_STLL = 2'b10;	/* Stall */
/* Global signals */
input wire		clk;
input wire		nrst;
/* Incoming request */
input wire		i_m_rqa_vld;
input wire [43:0]	i_m_rqa;
output reg		o_m_rqa_rd;
input wire		i_m_rqd_vld;
input wire [71:0]	i_m_rqd;
output reg		o_m_rqd_rd;
/* Outgoing request */
output reg [5:0]	biu_awcid;
output reg [39:0]	biu_awaddr;
output reg [63:0]	biu_awdata;
output reg [7:0]	biu_awstrb;
output wire		biu_awvalid;
input wire		biu_awpop;
output reg [5:0]	biu_arcid;
output reg [39:0]	biu_araddr;
output wire		biu_arvalid;
input wire		biu_arpop;



/* Write requests address FIFO */
reg [42:0]	wr_addr_fifo[0:3];	/* Address FIFO */
reg [2:0]	wr_addr_fifo_rp;	/* Read pointer */
reg [2:0]	wr_addr_fifo_wp;	/* Write pointer */
/* Previous FIFO read pointer */
wire [2:0]	wr_addr_fifo_pre_rp = wr_addr_fifo_rp - 1'b1;
/* FIFO states */
wire wr_addr_fifo_empty = (wr_addr_fifo_rp[1:0] == wr_addr_fifo_wp[1:0]) &&
	(wr_addr_fifo_rp[2] == wr_addr_fifo_wp[2]);
wire wr_addr_fifo_full = (wr_addr_fifo_rp[1:0] == wr_addr_fifo_wp[1:0]) &&
	(wr_addr_fifo_rp[2] != wr_addr_fifo_wp[2]);
wire wr_addr_fifo_pre_full = (wr_addr_fifo_pre_rp[1:0] == wr_addr_fifo_wp[1:0]) &&
	(wr_addr_fifo_pre_rp[2] != wr_addr_fifo_wp[2]);


/* Write requests data FIFO */
reg [71:0]	wr_data_fifo[0:3];	/* Data FIFO */
reg [2:0]	wr_data_fifo_rp;	/* Read pointer */
reg [2:0]	wr_data_fifo_wp;	/* Write pointer */
/* Previous FIFO read pointer */
wire [2:0]	wr_data_fifo_pre_rp = wr_data_fifo_rp - 1'b1;
/* FIFO states */
wire wr_data_fifo_empty = (wr_data_fifo_rp[1:0] == wr_data_fifo_wp[1:0]) &&
	(wr_data_fifo_rp[2] == wr_data_fifo_wp[2]);
wire wr_data_fifo_full = (wr_data_fifo_rp[1:0] == wr_data_fifo_wp[1:0]) &&
	(wr_data_fifo_rp[2] != wr_data_fifo_wp[2]);
wire wr_data_fifo_pre_full = (wr_data_fifo_pre_rp[1:0] == wr_data_fifo_wp[1:0]) &&
	(wr_data_fifo_pre_rp[2] != wr_data_fifo_wp[2]);


/* Read requests address FIFO */
reg [42:0]	rd_addr_fifo[0:3];	/* Address FIFO */
reg [2:0]	rd_addr_fifo_rp;	/* Read pointer */
reg [2:0]	rd_addr_fifo_wp;	/* Write pointer */
/* Previous FIFO read pointer */
wire [2:0]	rd_addr_fifo_pre_rp = rd_addr_fifo_rp - 1'b1;
/* FIFO states */
wire rd_addr_fifo_empty = (rd_addr_fifo_rp[1:0] == rd_addr_fifo_wp[1:0]) &&
	(rd_addr_fifo_rp[2] == rd_addr_fifo_wp[2]);
wire rd_addr_fifo_full = (rd_addr_fifo_rp[1:0] == rd_addr_fifo_wp[1:0]) &&
	(rd_addr_fifo_rp[2] != rd_addr_fifo_wp[2]);
wire rd_addr_fifo_pre_full = (rd_addr_fifo_pre_rp[1:0] == rd_addr_fifo_wp[1:0]) &&
	(rd_addr_fifo_pre_rp[2] != rd_addr_fifo_wp[2]);


/* Outgoing FIFOs stall */
wire fifo_stall = wr_addr_fifo_full || wr_addr_fifo_pre_full ||
	wr_data_fifo_full || wr_data_fifo_pre_full ||
	rd_addr_fifo_full || rd_addr_fifo_pre_full;


/* Decoded request info */
wire [5:0]	rqa_txnid;	/* Transaction Id */
wire		rqa_rnw;	/* Read or Write transaction */
wire [36:0]	rqa_addr;	/* Upper 37-bits of 40-bit address */


/* Requests ready condition */
assign biu_awvalid = !wr_addr_fifo_empty && !wr_data_fifo_empty;	/* WR */
assign biu_arvalid = !rd_addr_fifo_empty;				/* RD */



/** Requests Rx FSM **/

reg [1:0]	rx_state;	/* Rx FSM state */

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		wr_addr_fifo_wp <= 3'b000;
		wr_data_fifo_wp <= 3'b000;
		rd_addr_fifo_wp <= 3'b000;
		o_m_rqa_rd <= 1'b0;
		o_m_rqd_rd <= 1'b0;
		rx_state <= FSM_RX_IDLE;
	end
	else if(rx_state == FSM_RX_IDLE)
	begin
		rx_state <= FSM_RX_RECV;
		o_m_rqa_rd <= 1'b1;
		o_m_rqd_rd <= 1'b1;
	end
	else if(rx_state == FSM_RX_RECV)
	begin
		if(i_m_rqa_vld && rqa_rnw)
		begin
			/* Read request */
			rd_addr_fifo[rd_addr_fifo_wp[1:0]] <= { rqa_txnid, rqa_addr };
			rd_addr_fifo_wp <= rd_addr_fifo_wp + 1'b1;
		end
		else if(i_m_rqa_vld && !rqa_rnw)
		begin
			/* Write request */
			wr_addr_fifo[wr_addr_fifo_wp[1:0]] <= { rqa_txnid, rqa_addr };
			wr_addr_fifo_wp <= wr_addr_fifo_wp + 1'b1;
		end

		if(i_m_rqd_vld)
		begin
			/* Write request data */
			wr_data_fifo[wr_data_fifo_wp[1:0]] <= i_m_rqd;
			wr_data_fifo_wp <= wr_data_fifo_wp + 1'b1;
		end

		if(fifo_stall)
		begin
			rx_state <= FSM_RX_STLL;
			o_m_rqa_rd <= 1'b0;
			o_m_rqd_rd <= 1'b0;
		end
	end
	else if(rx_state == FSM_RX_STLL)
	begin
		if(!fifo_stall)
		begin
			rx_state <= FSM_RX_RECV;
			o_m_rqa_rd <= 1'b1;
			o_m_rqd_rd <= 1'b1;
		end
	end
end



/** Write requests upstream **/

wire [5:0]	rq_awcid = wr_addr_fifo[wr_addr_fifo_rp[1:0]][42:37];
wire [36:0]	rq_awaddr = wr_addr_fifo[wr_addr_fifo_rp[1:0]][36:0];
wire [63:0]	rq_awdata;
wire [7:0]	rq_awstrb;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		wr_addr_fifo_rp <= 3'b000;
		wr_data_fifo_rp <= 3'b000;
	end
	else if(biu_awpop && biu_awvalid)
	begin
		biu_awcid <= rq_awcid;
		biu_awaddr <= { rq_awaddr, 3'b000 };
		biu_awdata <= rq_awdata;
		biu_awstrb <= rq_awstrb;
		wr_addr_fifo_rp <= wr_addr_fifo_rp + 1'b1;
		wr_data_fifo_rp <= wr_data_fifo_rp + 1'b1;
	end
end

/* Data decoder */
vxe_txnreqd_decoder wr_data_dec(
	.i_req_vec_dat(wr_data_fifo[wr_data_fifo_rp[1:0]]),
	.o_data(rq_awdata),
	.o_ben(rq_awstrb)
);



/** Read requests upstream **/

wire [5:0]	rq_arcid = rd_addr_fifo[rd_addr_fifo_rp[1:0]][42:37];
wire [36:0]	rq_araddr = rd_addr_fifo[rd_addr_fifo_rp[1:0]][36:0];

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		rd_addr_fifo_rp <= 3'b000;
	end
	else if(biu_arpop && biu_arvalid)
	begin
		biu_arcid <= rq_arcid;
		biu_araddr <= { rq_araddr, 3'b000 };
		rd_addr_fifo_rp <= rd_addr_fifo_rp + 1'b1;
	end
end



/* Request decoder */
vxe_txnreqa_decoder reqa_decode(
	.i_req_vec_txn(i_m_rqa),
	.o_txnid(rqa_txnid),
	.o_rnw(rqa_rnw),
	.o_addr(rqa_addr)
);


endmodule /* vxe_axi_switch_us */
