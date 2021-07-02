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
 * VxE VPU upstream traffic control
 */


/* VPU upstream */
module vxe_mem_hub_vpu_us(
	clk,
	nrst,
	/* Incoming request */
	i_rqa_vld,
	i_rqa,
	o_rqa_rd,
	i_rqd_vld,
	i_rqd,
	o_rqd_rd,
	/* Route to Master 0 */
	i_m0_rqa_rdy,
	o_m0_rqa,
	o_m0_rqa_wr,
	i_m0_rqd_rdy,
	o_m0_rqd,
	o_m0_rqd_wr,
	/* Route to Master 1 */
	i_m1_rqa_rdy,
	o_m1_rqa,
	o_m1_rqa_wr,
	i_m1_rqd_rdy,
	o_m1_rqd,
	o_m1_rqd_wr
);
`include "vxe_client_params.vh"
/* Rx FSM states */
localparam [1:0]	FSM_RX_IDLE = 2'b00;	/* Idle */
localparam [1:0]	FSM_RX_RDAD = 2'b01;	/* Read address and data */
localparam [1:0]	FSM_RX_RDAX = 2'b10;	/* Read address only */
localparam [1:0]	FSM_RX_STLL = 2'b11;	/* Stall state */
/* Tx FSM states */
localparam		FSM_TX_IDLE = 1'b0;	/* Idle */
localparam		FSM_TX_SEND = 1'b1;	/* Send to port  */
/* Global signals */
input wire		clk;
input wire		nrst;
/* Incoming request */
input wire		i_rqa_vld;
input wire [43:0]	i_rqa;
output reg		o_rqa_rd;
input wire		i_rqd_vld;
input wire [71:0]	i_rqd;
output reg		o_rqd_rd;
/* Route to Master 0 */
input wire		i_m0_rqa_rdy;
output reg [43:0]	o_m0_rqa;
output reg		o_m0_rqa_wr;
input wire		i_m0_rqd_rdy;
output reg [71:0]	o_m0_rqd;
output reg		o_m0_rqd_wr;
/* Route to Master 1 */
input wire		i_m1_rqa_rdy;
output reg [43:0]	o_m1_rqa;
output reg		o_m1_rqa_wr;
input wire		i_m1_rqd_rdy;
output reg [71:0]	o_m1_rqd;
output reg		o_m1_rqd_wr;


/* Returns destination master port */
function [0:0] get_mport;
input [0:0] rnw;
input [0:0] arg;
input [1:0] client;
begin
	/* VPU loads depend on argument type, stores depend on VPU number */
	if(rnw == 1'b1)
	begin
		get_mport = arg; /* (arg == 1'b0 ? 1'b0 : 1'b1); */
	end
	else
	begin
		get_mport = (client == CLNT_VPU0 ? 1'b0 : 1'b1);
	end
end
endfunction


wire [5:0]	rqa_txnid;	/* Transaction Id */
wire		rqa_rnw;	/* Read or Write transaction */
wire [36:0]	rqa_addr;	/* Upper 37-bits of 40-bit address */
wire [1:0]	rqa_client_id;	/* Client Id (VPU0, VPU1) */
wire [2:0]	rqa_thread_id;	/* Thread Id for VPUs (0-7) */
wire		rqa_argument;	/* Argument type (Rs/Rt) */

/* Destination master (0 or 1) */
wire mport = get_mport(rqa_rnw, rqa_argument, rqa_client_id);

/* Outgoing FIFO stall */
wire fifo_stall = m0_rqa_fifo_full || m1_rqa_fifo_full ||
	m0_rqa_fifo_pre_full || m1_rqa_fifo_pre_full;


reg [1:0]	rx_state;	/* Rx FSM state */
reg [1:0]	rcvr_state;	/* Recovery state (after stall) */
reg [71:0]	data_q;		/* Temporary storage */

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		m0_rqa_fifo_wp <= 3'b000;
		m0_rqd_fifo_wp <= 3'b000;
		m1_rqa_fifo_wp <= 3'b000;
		m1_rqd_fifo_wp <= 3'b000;
		o_rqa_rd <= 1'b0;
		o_rqd_rd <= 1'b0;
		rx_state <= FSM_RX_IDLE;
	end
	else if(rx_state == FSM_RX_IDLE)
	begin
		rx_state <= FSM_RX_RDAD;
		o_rqa_rd <= 1'b1;
		o_rqd_rd <= 1'b1;
	end
	else if(rx_state == FSM_RX_RDAD)
	begin
		if(i_rqa_vld)
		begin
			if(mport == 1'b0)
			begin
				m0_rqa_fifo[m0_rqa_fifo_wp[1:0]] <= i_rqa;
				m0_rqa_fifo_wp <= m0_rqa_fifo_wp + 1'b1;
			end
			else
			begin
				m1_rqa_fifo[m1_rqa_fifo_wp[1:0]] <= i_rqa;
				m1_rqa_fifo_wp <= m1_rqa_fifo_wp + 1'b1;
			end
		end

		if(i_rqd_vld && !rqa_rnw)
		begin
			if(mport == 1'b0)
			begin
				m0_rqd_fifo[m0_rqd_fifo_wp[1:0]] <= i_rqd;
				m0_rqd_fifo_wp <= m0_rqd_fifo_wp + 1'b1;
			end
			else
			begin
				m1_rqd_fifo[m1_rqd_fifo_wp[1:0]] <= i_rqd;
				m1_rqd_fifo_wp <= m1_rqd_fifo_wp + 1'b1;
			end
		end
		else if(i_rqd_vld && rqa_rnw)
		begin
			o_rqd_rd <= 1'b0;
			data_q <= i_rqd;
		end

		/*
		 * Note: if i_rqd_vld=1 but i_rqa is a read request then
		 * contents of i_rqd and reading of data stopped until write
		 * request is fetched from i_rqa. So write request and its data
		 * can be properly routed to a corresponding master.
		 */

		/* Next state */
		if(i_rqd_vld && rqa_rnw && !fifo_stall)
		begin
			rx_state <= FSM_RX_RDAX;
		end
		else if(i_rqd_vld && rqa_rnw && fifo_stall)
		begin
			rcvr_state <= FSM_RX_RDAX;
			rx_state <= FSM_RX_STLL;
		end
		else if(fifo_stall)
		begin
			rcvr_state <= FSM_RX_RDAD;
			rx_state <= FSM_RX_STLL;
			o_rqa_rd <= 1'b0;
			o_rqd_rd <= 1'b0;
		end
	end
	else if(rx_state == FSM_RX_RDAX)
	begin
		if(i_rqa_vld)
		begin
			if(mport == 1'b0)
			begin
				m0_rqa_fifo[m0_rqa_fifo_wp[1:0]] <= i_rqa;
				m0_rqa_fifo_wp <= m0_rqa_fifo_wp + 1'b1;
			end
			else
			begin
				m1_rqa_fifo[m1_rqa_fifo_wp[1:0]] <= i_rqa;
				m1_rqa_fifo_wp <= m1_rqa_fifo_wp + 1'b1;
			end
		end

		if(i_rqa_vld && !rqa_rnw)
		begin
			if(mport == 1'b0)
			begin
				m0_rqd_fifo[m0_rqd_fifo_wp[1:0]] <= data_q;
				m0_rqd_fifo_wp <= m0_rqd_fifo_wp + 1'b1;
			end
			else
			begin
				m1_rqd_fifo[m1_rqd_fifo_wp[1:0]] <= data_q;
				m1_rqd_fifo_wp <= m1_rqd_fifo_wp + 1'b1;
			end
		end

		/* Next state */
		if(i_rqa_vld && !rqa_rnw && !fifo_stall)
		begin
			rx_state <= FSM_RX_RDAD;
			o_rqa_rd <= 1'b1;
			o_rqd_rd <= 1'b1;
		end
		else if(i_rqa_vld && !rqa_rnw && fifo_stall)
		begin
			rcvr_state <= FSM_RX_RDAD;
			rx_state <= FSM_RX_STLL;
			o_rqa_rd <= 1'b0;
		end
		else if(i_rqa_vld && rqa_rnw && fifo_stall)
		begin
			rcvr_state <= FSM_RX_RDAX;
			rx_state <= FSM_RX_STLL;
			o_rqa_rd <= 1'b0;
		end
	end
	else if(rx_state == FSM_RX_STLL)
	begin
		if(!fifo_stall)
		begin
			rx_state <= rcvr_state;
			if(rcvr_state == FSM_RX_RDAD)
			begin
				o_rqa_rd <= 1'b1;
				o_rqd_rd <= 1'b1;
			end
			else
				o_rqa_rd <= 1'b1;
		end
	end
end


/* Request decoder */
vxe_txnreqa_decoder reqa_decode(
	.i_req_vec_txn(i_rqa),
	.o_txnid(rqa_txnid),
	.o_rnw(rqa_rnw),
	.o_addr(rqa_addr)
);


/* Transaction Id decoder */
vxe_txnid_decoder reqa_txnid_decode(
	.i_txnid(rqa_txnid),
	.o_client_id(rqa_client_id),
	.o_thread_id(rqa_thread_id),
	.o_argument(rqa_argument)
);



/** Requests for master 0 **/

/* Address FIFO */
reg [43:0]	m0_rqa_fifo[0:3];	/* Incoming request address FIFO */
reg [2:0]	m0_rqa_fifo_rp;		/* Read pointer */
reg [2:0]	m0_rqa_fifo_wp;		/* Write pointer */
/* Previous FIFO read pointer */
wire [2:0]	m0_rqa_fifo_pre_rp = m0_rqa_fifo_rp - 1'b1;
/* FIFO states */
wire m0_rqa_fifo_empty = (m0_rqa_fifo_rp[1:0] == m0_rqa_fifo_wp[1:0]) &&
	(m0_rqa_fifo_rp[2] == m0_rqa_fifo_wp[2]);
wire m0_rqa_fifo_full = (m0_rqa_fifo_rp[1:0] == m0_rqa_fifo_wp[1:0]) &&
	(m0_rqa_fifo_rp[2] != m0_rqa_fifo_wp[2]);
wire m0_rqa_fifo_pre_full = (m0_rqa_fifo_pre_rp[1:0] == m0_rqa_fifo_wp[1:0]) &&
	(m0_rqa_fifo_pre_rp[2] != m0_rqa_fifo_wp[2]);


reg	m0_txa_state;	/* Master0 address Tx FSM state */

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		m0_txa_state <= FSM_TX_IDLE;
		m0_rqa_fifo_rp <= 3'b000;
		o_m0_rqa_wr <= 1'b0;
	end
	else if(m0_txa_state == FSM_TX_IDLE)
	begin
		if(!m0_rqa_fifo_empty)
		begin
			m0_txa_state <= FSM_TX_SEND;
			o_m0_rqa <= m0_rqa_fifo[m0_rqa_fifo_rp[1:0]];
			m0_rqa_fifo_rp <= m0_rqa_fifo_rp + 1'b1;
			o_m0_rqa_wr <= 1'b1;
		end
	end
	else if(m0_txa_state == FSM_TX_SEND)
	begin
		if(i_m0_rqa_rdy && !m0_rqa_fifo_empty)
		begin
			o_m0_rqa <= m0_rqa_fifo[m0_rqa_fifo_rp[1:0]];
			m0_rqa_fifo_rp <= m0_rqa_fifo_rp + 1'b1;
		end
		else if(i_m0_rqa_rdy)
		begin
			m0_txa_state <= FSM_TX_IDLE;
			o_m0_rqa_wr <= 1'b0;
		end
	end
end


/* Data FIFO */
reg [71:0]	m0_rqd_fifo[0:3];	/* Incoming request data FIFO */
reg [2:0]	m0_rqd_fifo_rp;		/* Read pointer */
reg [2:0]	m0_rqd_fifo_wp;		/* Write pointer */
/* FIFO states */
wire m0_rqd_fifo_empty = (m0_rqd_fifo_rp[1:0] == m0_rqd_fifo_wp[1:0]) &&
	(m0_rqd_fifo_rp[2] == m0_rqd_fifo_wp[2]);


reg	m0_txd_state;	/* Master0 data Tx FSM state */

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		m0_txd_state <= FSM_TX_IDLE;
		m0_rqd_fifo_rp <= 3'b000;
		o_m0_rqd_wr <= 1'b0;
	end
	else if(m0_txd_state == FSM_TX_IDLE)
	begin
		if(!m0_rqd_fifo_empty)
		begin
			m0_txd_state <= FSM_TX_SEND;
			o_m0_rqd <= m0_rqd_fifo[m0_rqd_fifo_rp[1:0]];
			m0_rqd_fifo_rp <= m0_rqd_fifo_rp + 1'b1;
			o_m0_rqd_wr <= 1'b1;
		end
	end
	else if(m0_txd_state == FSM_TX_SEND)
	begin
		if(i_m0_rqd_rdy && !m0_rqd_fifo_empty)
		begin
			o_m0_rqd <= m0_rqd_fifo[m0_rqd_fifo_rp[1:0]];
			m0_rqd_fifo_rp <= m0_rqd_fifo_rp + 1'b1;
		end
		else if(i_m0_rqd_rdy)
		begin
			m0_txd_state <= FSM_TX_IDLE;
			o_m0_rqd_wr <= 1'b0;
		end
	end
end



/** Requests for master 1 **/

/* Address FIFO */
reg [43:0]	m1_rqa_fifo[0:3];	/* Incoming request address FIFO */
reg [2:0]	m1_rqa_fifo_rp;		/* Read pointer */
reg [2:0]	m1_rqa_fifo_wp;		/* Write pointer */
/* Previous FIFO read pointer */
wire [2:0]	m1_rqa_fifo_pre_rp = m1_rqa_fifo_rp - 1'b1;
/* FIFO states */
wire m1_rqa_fifo_empty = (m1_rqa_fifo_rp[1:0] == m1_rqa_fifo_wp[1:0]) &&
	(m1_rqa_fifo_rp[2] == m1_rqa_fifo_wp[2]);
wire m1_rqa_fifo_full = (m1_rqa_fifo_rp[1:0] == m1_rqa_fifo_wp[1:0]) &&
	(m1_rqa_fifo_rp[2] != m1_rqa_fifo_wp[2]);
wire m1_rqa_fifo_pre_full = (m1_rqa_fifo_pre_rp[1:0] == m1_rqa_fifo_wp[1:0]) &&
	(m1_rqa_fifo_pre_rp[2] != m1_rqa_fifo_wp[2]);


reg	m1_txa_state;	/* Master1 address Tx FSM state */

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		m1_txa_state <= FSM_TX_IDLE;
		m1_rqa_fifo_rp <= 3'b000;
		o_m1_rqa_wr <= 1'b0;
	end
	else if(m1_txa_state == FSM_TX_IDLE)
	begin
		if(!m1_rqa_fifo_empty)
		begin
			m1_txa_state <= FSM_TX_SEND;
			o_m1_rqa <= m1_rqa_fifo[m1_rqa_fifo_rp[1:0]];
			m1_rqa_fifo_rp <= m1_rqa_fifo_rp + 1'b1;
			o_m1_rqa_wr <= 1'b1;
		end
	end
	else if(m1_txa_state == FSM_TX_SEND)
	begin
		if(i_m1_rqa_rdy && !m1_rqa_fifo_empty)
		begin
			o_m1_rqa <= m1_rqa_fifo[m1_rqa_fifo_rp[1:0]];
			m1_rqa_fifo_rp <= m1_rqa_fifo_rp + 1'b1;
		end
		else if(i_m1_rqa_rdy)
		begin
			m1_txa_state <= FSM_TX_IDLE;
			o_m1_rqa_wr <= 1'b0;
		end
	end
end


/* Data FIFO */
reg [71:0]	m1_rqd_fifo[0:3];	/* Incoming request data FIFO */
reg [2:0]	m1_rqd_fifo_rp;		/* Read pointer */
reg [2:0]	m1_rqd_fifo_wp;		/* Write pointer */
/* FIFO states */
wire m1_rqd_fifo_empty = (m1_rqd_fifo_rp[1:0] == m1_rqd_fifo_wp[1:0]) &&
	(m1_rqd_fifo_rp[2] == m1_rqd_fifo_wp[2]);
wire m1_rqd_fifo_full = (m1_rqd_fifo_rp[1:0] == m1_rqd_fifo_wp[1:0]) &&
	(m1_rqd_fifo_rp[2] != m1_rqd_fifo_wp[2]);


reg	m1_txd_state;	/* Master1 data Tx FSM state */

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		m1_txd_state <= FSM_TX_IDLE;
		m1_rqd_fifo_rp <= 3'b000;
		o_m1_rqd_wr <= 1'b0;
	end
	else if(m1_txd_state == FSM_TX_IDLE)
	begin
		if(!m1_rqd_fifo_empty)
		begin
			m1_txd_state <= FSM_TX_SEND;
			o_m1_rqd <= m1_rqd_fifo[m1_rqd_fifo_rp[1:0]];
			m1_rqd_fifo_rp <= m1_rqd_fifo_rp + 1'b1;
			o_m1_rqd_wr <= 1'b1;
		end
	end
	else if(m1_txd_state == FSM_TX_SEND)
	begin
		if(i_m1_rqd_rdy && !m1_rqd_fifo_empty)
		begin
			o_m1_rqd <= m1_rqd_fifo[m1_rqd_fifo_rp[1:0]];
			m1_rqd_fifo_rp <= m1_rqd_fifo_rp + 1'b1;
		end
		else if(i_m1_rqd_rdy)
		begin
			m1_txd_state <= FSM_TX_IDLE;
			o_m1_rqd_wr <= 1'b0;
		end
	end
end


endmodule /* vxe_mem_hub_vpu_us */
