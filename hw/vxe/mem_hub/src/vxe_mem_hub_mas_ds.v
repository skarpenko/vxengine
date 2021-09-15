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
 * VxE master port downstream traffic control
 */


/* Master port downstream */
module vxe_mem_hub_mas_ds(
	clk,
	nrst,
	/* Incoming response on master port */
	i_m_rss_vld,
	i_m_rss,
	o_m_rss_rd,
	i_m_rsd_vld,
	i_m_rsd,
	o_m_rsd_rd,
	/* Outgoing response for CU */
	i_cu_rss_rdy,
	o_cu_rss,
	o_cu_rss_wr,
	i_cu_rsd_rdy,
	o_cu_rsd,
	o_cu_rsd_wr,
	/* Outgoing response for VPU0 */
	i_vpu0_rss_rdy,
	o_vpu0_rss,
	o_vpu0_rss_wr,
	i_vpu0_rsd_rdy,
	o_vpu0_rsd,
	o_vpu0_rsd_wr,
	/* Outgoing response for VPU1 */
	i_vpu1_rss_rdy,
	o_vpu1_rss,
	o_vpu1_rss_wr,
	i_vpu1_rsd_rdy,
	o_vpu1_rsd,
	o_vpu1_rsd_wr
);
`include "vxe_client_params.vh"
/* Rx FSM states */
localparam [1:0]	FSM_RX_IDLE = 2'b00;	/* Idle */
localparam [1:0]	FSM_RX_READ = 2'b01;	/* Read from Master */
localparam [1:0]	FSM_RX_STLL = 2'b10;	/* Stall */
/* Tx FSM states */
localparam		FSM_TX_IDLE = 1'b0;	/* Idle */
localparam		FSM_TX_SEND = 1'b1;	/* Send to client  */
/* Global signals */
input wire		clk;
input wire		nrst;
/* Incoming response on master port */
input wire		i_m_rss_vld;
input wire [8:0]	i_m_rss;
output reg		o_m_rss_rd;
input wire		i_m_rsd_vld;
input wire [63:0]	i_m_rsd;
output reg		o_m_rsd_rd;
/* Outgoing response for CU */
input wire		i_cu_rss_rdy;
output reg [8:0]	o_cu_rss;
output reg		o_cu_rss_wr;
input wire		i_cu_rsd_rdy;
output reg [63:0]	o_cu_rsd;
output reg		o_cu_rsd_wr;
/* Outgoing response for VPU0 */
input wire		i_vpu0_rss_rdy;
output reg [8:0]	o_vpu0_rss;
output reg		o_vpu0_rss_wr;
input wire		i_vpu0_rsd_rdy;
output reg [63:0]	o_vpu0_rsd;
output reg		o_vpu0_rsd_wr;
/* Outgoing response for VPU1 */
input wire		i_vpu1_rss_rdy;
output reg [8:0]	o_vpu1_rss;
output reg		o_vpu1_rss_wr;
input wire		i_vpu1_rsd_rdy;
output reg [63:0]	o_vpu1_rsd;
output reg		o_vpu1_rsd_wr;


/* Status FIFO for CU */
reg [8:0]	cu_rss_fifo[0:3];	/* Outgoing response status FIFO */
reg [2:0]	cu_rss_fifo_rp;		/* Read pointer */
reg [2:0]	cu_rss_fifo_wp;		/* Write pointer */
/* Previous FIFO read pointer */
wire [2:0]	cu_rss_fifo_pre_rp = cu_rss_fifo_rp - 1'b1;
/* FIFO states */
wire cu_rss_fifo_empty = (cu_rss_fifo_rp[1:0] == cu_rss_fifo_wp[1:0]) &&
	(cu_rss_fifo_rp[2] == cu_rss_fifo_wp[2]);
wire cu_rss_fifo_full = (cu_rss_fifo_rp[1:0] == cu_rss_fifo_wp[1:0]) &&
	(cu_rss_fifo_rp[2] != cu_rss_fifo_wp[2]);
wire cu_rss_fifo_pre_full = (cu_rss_fifo_pre_rp[1:0] == cu_rss_fifo_wp[1:0]) &&
	(cu_rss_fifo_pre_rp[2] != cu_rss_fifo_wp[2]);


/* Data FIFO for CU */
reg [63:0]	cu_rsd_fifo[0:3];	/* Outgoing response data FIFO */
reg [2:0]	cu_rsd_fifo_rp;		/* Read pointer */
reg [2:0]	cu_rsd_fifo_wp;		/* Write pointer */
/* FIFO states */
wire cu_rsd_fifo_empty = (cu_rsd_fifo_rp[1:0] == cu_rsd_fifo_wp[1:0]) &&
	(cu_rsd_fifo_rp[2] == cu_rsd_fifo_wp[2]);


/* Status FIFO for VPU0 */
reg [8:0]	v0_rss_fifo[0:3];	/* Outgoing response status FIFO */
reg [2:0]	v0_rss_fifo_rp;		/* Read pointer */
reg [2:0]	v0_rss_fifo_wp;		/* Write pointer */
/* Previous FIFO read pointer */
wire [2:0]	v0_rss_fifo_pre_rp = v0_rss_fifo_rp - 1'b1;
/* FIFO states */
wire v0_rss_fifo_empty = (v0_rss_fifo_rp[1:0] == v0_rss_fifo_wp[1:0]) &&
	(v0_rss_fifo_rp[2] == v0_rss_fifo_wp[2]);
wire v0_rss_fifo_full = (v0_rss_fifo_rp[1:0] == v0_rss_fifo_wp[1:0]) &&
	(v0_rss_fifo_rp[2] != v0_rss_fifo_wp[2]);
wire v0_rss_fifo_pre_full = (v0_rss_fifo_pre_rp[1:0] == v0_rss_fifo_wp[1:0]) &&
	(v0_rss_fifo_pre_rp[2] != v0_rss_fifo_wp[2]);


/* Data FIFO for VPU0 */
reg [63:0]	v0_rsd_fifo[0:3];	/* Outgoing response data FIFO */
reg [2:0]	v0_rsd_fifo_rp;		/* Read pointer */
reg [2:0]	v0_rsd_fifo_wp;		/* Write pointer */
/* FIFO states */
wire v0_rsd_fifo_empty = (v0_rsd_fifo_rp[1:0] == v0_rsd_fifo_wp[1:0]) &&
	(v0_rsd_fifo_rp[2] == v0_rsd_fifo_wp[2]);


/* Status FIFO for VPU1 */
reg [8:0]	v1_rss_fifo[0:3];	/* Outgoing response status FIFO */
reg [2:0]	v1_rss_fifo_rp;		/* Read pointer */
reg [2:0]	v1_rss_fifo_wp;		/* Write pointer */
/* Previous FIFO read pointer */
wire [2:0]	v1_rss_fifo_pre_rp = v1_rss_fifo_rp - 1'b1;
/* FIFO states */
wire v1_rss_fifo_empty = (v1_rss_fifo_rp[1:0] == v1_rss_fifo_wp[1:0]) &&
	(v1_rss_fifo_rp[2] == v1_rss_fifo_wp[2]);
wire v1_rss_fifo_full = (v1_rss_fifo_rp[1:0] == v1_rss_fifo_wp[1:0]) &&
	(v1_rss_fifo_rp[2] != v1_rss_fifo_wp[2]);
wire v1_rss_fifo_pre_full = (v1_rss_fifo_pre_rp[1:0] == v1_rss_fifo_wp[1:0]) &&
	(v1_rss_fifo_pre_rp[2] != v1_rss_fifo_wp[2]);


/* Data FIFO for VPU1 */
reg [63:0]	v1_rsd_fifo[0:3];	/* Outgoing response data FIFO */
reg [2:0]	v1_rsd_fifo_rp;		/* Read pointer */
reg [2:0]	v1_rsd_fifo_wp;		/* Write pointer */
/* FIFO states */
wire v1_rsd_fifo_empty = (v1_rsd_fifo_rp[1:0] == v1_rsd_fifo_wp[1:0]) &&
	(v1_rsd_fifo_rp[2] == v1_rsd_fifo_wp[2]);


/* Outgoing FIFO stall */
wire fifo_stall = cu_rss_fifo_full || cu_rss_fifo_pre_full ||
			v0_rss_fifo_full || v0_rss_fifo_pre_full ||
			v1_rss_fifo_full || v1_rss_fifo_pre_full;


/* Decoded response on master port */
wire [5:0]	rssm_txnid;	/* Transaction Id */
wire		rssm_rnw;	/* Read or Write transaction */
wire [1:0]	rssm_err;	/* Error status */


/* Decoded response transaction Id on master port */
wire [1:0]	txnidm_client_id;	/* Client Id (CU, VPU0, VPU1) */
wire [2:0]	txnidm_thread_id;	/* Thread Id for VPUs (0-7) */
wire		txnidm_argument;	/* Argument type (Rs/Rt) */


/* Master port data hold register */
reg [63:0]	m_data_hold_r;		/* Stored data */
reg		m_data_hold_vld;	/* Register valid flag */


/* Task: Send response status to a client */
task send_rstat;
input [1:0] client;
input [8:0] status;
begin
	case(client)
	CLNT_CU: begin
		cu_rss_fifo[cu_rss_fifo_wp[1:0]] <= status;
		cu_rss_fifo_wp <= cu_rss_fifo_wp + 1'b1;
	end
	CLNT_VPU0: begin
		v0_rss_fifo[v0_rss_fifo_wp[1:0]] <= status;
		v0_rss_fifo_wp <= v0_rss_fifo_wp + 1'b1;
	end
	CLNT_VPU1: begin
		v1_rss_fifo[v1_rss_fifo_wp[1:0]] <= status;
		v1_rss_fifo_wp <= v1_rss_fifo_wp + 1'b1;
	end
	default: begin
		/* This case should never happen */
		$display("send_rstat: wrong txnidm_client_id (%d)", client);
	end
	endcase
end
endtask

/* Task: Send response data to a client */
task send_rdata;
input [1:0] client;
input [63:0] data;
begin
	case(client)
	CLNT_CU: begin
		cu_rsd_fifo[cu_rsd_fifo_wp[1:0]] <= data;
		cu_rsd_fifo_wp <= cu_rsd_fifo_wp + 1'b1;
	end
	CLNT_VPU0: begin
		v0_rsd_fifo[v0_rsd_fifo_wp[1:0]] <= data;
		v0_rsd_fifo_wp <= v0_rsd_fifo_wp + 1'b1;
	end
	CLNT_VPU1: begin
		v1_rsd_fifo[v1_rsd_fifo_wp[1:0]] <= data;
		v1_rsd_fifo_wp <= v1_rsd_fifo_wp + 1'b1;
	end
	default: begin
		/* This case should never happen */
		$display("send_rdata: wrong txnidm_client_id (%d)", client);
	end
	endcase
end
endtask


/* RX FSM state */
reg [1:0]	rx_fsm;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		rx_fsm <= FSM_RX_IDLE;
		m_data_hold_vld <= 1'b0;
		cu_rss_fifo_wp <= 3'b000;
		cu_rsd_fifo_wp <= 3'b000;
		v0_rss_fifo_wp <= 3'b000;
		v0_rsd_fifo_wp <= 3'b000;
		v1_rss_fifo_wp <= 3'b000;
		v1_rsd_fifo_wp <= 3'b000;
		o_m_rss_rd <= 1'b0;
		o_m_rsd_rd <= 1'b0;
	end
	else if(rx_fsm == FSM_RX_READ)
	begin
		if(i_m_rss_vld)
		begin
			/* Pass response status to client */
			send_rstat(txnidm_client_id, i_m_rss);

			if(m_data_hold_vld && rssm_rnw)
			begin
				/* If response is for READ and hold register is
				 * valid then copy data from the hold register
				 * to outgoing data FIFO. Then re-enable read
				 * from data channel.
				 */
				send_rdata(txnidm_client_id, m_data_hold_r);
				m_data_hold_vld <= 1'b0;
				o_m_rsd_rd <= 1'b1;
			end
			else if(~m_data_hold_vld && ~rssm_rnw && i_m_rsd_vld)
			begin
				/* If response is for WRITE, incoming data is valid
				 * and hold register is not valid then copy data
				 * to the hold register and disable further
				 * read from data channel.
				 *
				 * It is required to keep proper order of
				 * response and data channels.
				 */
				m_data_hold_r <= i_m_rsd;
				m_data_hold_vld <= 1'b1;
				o_m_rsd_rd <= 1'b0;
			end
			else if(rssm_rnw && i_m_rsd_vld)
			begin
				/* If response is for READ and incoming data is
				 * valid then copy data to outgoing data FIFO.
				 */
				send_rdata(txnidm_client_id, i_m_rsd);
			end
			else if(rssm_rnw && ~i_m_rsd_vld)
			begin
				/* This case should never happen */
				$display("Err: rssm_rnw && ~i_m_rsd_vld");
			end
		end

		/* Determine next state */
		if(fifo_stall)
		begin
			rx_fsm <= FSM_RX_STLL;
			o_m_rss_rd <= 1'b0;
			o_m_rsd_rd <= 1'b0;
		end
	end
	else if(rx_fsm == FSM_RX_STLL)
	begin
		if(!fifo_stall)
		begin
			rx_fsm <= FSM_RX_READ;
			o_m_rss_rd <= 1'b1;
			o_m_rsd_rd <= ~m_data_hold_vld;
		end
	end
	else /* IDLE */
	begin
		if(i_m_rss_vld)
		begin
			rx_fsm <= FSM_RX_READ;
			o_m_rss_rd <= 1'b1;
			o_m_rsd_rd <= 1'b1;
		end
	end
end



/* CU status TX FSM state */
reg	cu_txs_fsm;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		cu_txs_fsm <= FSM_TX_IDLE;
		cu_rss_fifo_rp <= 3'b000;
		o_cu_rss_wr <= 1'b0;
	end
	else if(cu_txs_fsm == FSM_TX_IDLE)
	begin
		if(!cu_rss_fifo_empty)
		begin
			cu_txs_fsm <= FSM_TX_SEND;
			o_cu_rss <= cu_rss_fifo[cu_rss_fifo_rp[1:0]];
			cu_rss_fifo_rp <= cu_rss_fifo_rp + 1'b1;
			o_cu_rss_wr <= 1'b1;
		end
	end
	else if(cu_txs_fsm == FSM_TX_SEND)
	begin
		if(i_cu_rss_rdy && !cu_rss_fifo_empty)
		begin
			o_cu_rss <= cu_rss_fifo[cu_rss_fifo_rp[1:0]];
			cu_rss_fifo_rp <= cu_rss_fifo_rp + 1'b1;
		end
		else if(i_cu_rss_rdy)
		begin
			cu_txs_fsm <= FSM_TX_IDLE;
			o_cu_rss_wr <= 1'b0;
		end
	end
end



/* CU data TX FSM state */
reg	cu_txd_fsm;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		cu_txd_fsm <= FSM_TX_IDLE;
		cu_rsd_fifo_rp <= 3'b000;
		o_cu_rsd_wr <= 1'b0;
	end
	else if(cu_txd_fsm == FSM_TX_IDLE)
	begin
		if(!cu_rsd_fifo_empty)
		begin
			cu_txd_fsm <= FSM_TX_SEND;
			o_cu_rsd <= cu_rsd_fifo[cu_rsd_fifo_rp[1:0]];
			cu_rsd_fifo_rp <= cu_rsd_fifo_rp + 1'b1;
			o_cu_rsd_wr <= 1'b1;
		end
	end
	else if(cu_txd_fsm == FSM_TX_SEND)
	begin
		if(i_cu_rsd_rdy && !cu_rsd_fifo_empty)
		begin
			o_cu_rsd <= cu_rsd_fifo[cu_rsd_fifo_rp[1:0]];
			cu_rsd_fifo_rp <= cu_rsd_fifo_rp + 1'b1;
		end
		else if(i_cu_rsd_rdy)
		begin
			cu_txd_fsm <= FSM_TX_IDLE;
			o_cu_rsd_wr <= 1'b0;
		end
	end
end



/* VPU0 status TX FSM state */
reg	v0_txs_fsm;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		v0_txs_fsm <= FSM_TX_IDLE;
		v0_rss_fifo_rp <= 3'b000;
		o_vpu0_rss_wr <= 1'b0;
	end
	else if(v0_txs_fsm == FSM_TX_IDLE)
	begin
		if(!v0_rss_fifo_empty)
		begin
			v0_txs_fsm <= FSM_TX_SEND;
			o_vpu0_rss <= v0_rss_fifo[v0_rss_fifo_rp[1:0]];
			v0_rss_fifo_rp <= v0_rss_fifo_rp + 1'b1;
			o_vpu0_rss_wr <= 1'b1;
		end
	end
	else if(v0_txs_fsm == FSM_TX_SEND)
	begin
		if(i_vpu0_rss_rdy && !v0_rss_fifo_empty)
		begin
			o_vpu0_rss <= v0_rss_fifo[v0_rss_fifo_rp[1:0]];
			v0_rss_fifo_rp <= v0_rss_fifo_rp + 1'b1;
		end
		else if(i_vpu0_rss_rdy)
		begin
			v0_txs_fsm <= FSM_TX_IDLE;
			o_vpu0_rss_wr <= 1'b0;
		end
	end
end



/* VPU0 data TX FSM state */
reg	v0_txd_fsm;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		v0_txd_fsm <= FSM_TX_IDLE;
		v0_rsd_fifo_rp <= 3'b000;
		o_vpu0_rsd_wr <= 1'b0;
	end
	else if(v0_txd_fsm == FSM_TX_IDLE)
	begin
		if(!v0_rsd_fifo_empty)
		begin
			v0_txd_fsm <= FSM_TX_SEND;
			o_vpu0_rsd <= v0_rsd_fifo[v0_rsd_fifo_rp[1:0]];
			v0_rsd_fifo_rp <= v0_rsd_fifo_rp + 1'b1;
			o_vpu0_rsd_wr <= 1'b1;
		end
	end
	else if(v0_txd_fsm == FSM_TX_SEND)
	begin
		if(i_vpu0_rsd_rdy && !v0_rsd_fifo_empty)
		begin
			o_vpu0_rsd <= v0_rsd_fifo[v0_rsd_fifo_rp[1:0]];
			v0_rsd_fifo_rp <= v0_rsd_fifo_rp + 1'b1;
		end
		else if(i_vpu0_rsd_rdy)
		begin
			v0_txd_fsm <= FSM_TX_IDLE;
			o_vpu0_rsd_wr <= 1'b0;
		end
	end
end



/* VPU1 status TX FSM state */
reg	v1_txs_fsm;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		v1_txs_fsm <= FSM_TX_IDLE;
		v1_rss_fifo_rp <= 3'b000;
		o_vpu1_rss_wr <= 1'b0;
	end
	else if(v1_txs_fsm == FSM_TX_IDLE)
	begin
		if(!v1_rss_fifo_empty)
		begin
			v1_txs_fsm <= FSM_TX_SEND;
			o_vpu1_rss <= v1_rss_fifo[v1_rss_fifo_rp[1:0]];
			v1_rss_fifo_rp <= v1_rss_fifo_rp + 1'b1;
			o_vpu1_rss_wr <= 1'b1;
		end
	end
	else if(v1_txs_fsm == FSM_TX_SEND)
	begin
		if(i_vpu1_rss_rdy && !v1_rss_fifo_empty)
		begin
			o_vpu1_rss <= v1_rss_fifo[v1_rss_fifo_rp[1:0]];
			v1_rss_fifo_rp <= v1_rss_fifo_rp + 1'b1;
		end
		else if(i_vpu1_rss_rdy)
		begin
			v1_txs_fsm <= FSM_TX_IDLE;
			o_vpu1_rss_wr <= 1'b0;
		end
	end
end



/* VPU1 data TX FSM state */
reg	v1_txd_fsm;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		v1_txd_fsm <= FSM_TX_IDLE;
		v1_rsd_fifo_rp <= 3'b000;
		o_vpu1_rsd_wr <= 1'b0;
	end
	else if(v1_txd_fsm == FSM_TX_IDLE)
	begin
		if(!v1_rsd_fifo_empty)
		begin
			v1_txd_fsm <= FSM_TX_SEND;
			o_vpu1_rsd <= v1_rsd_fifo[v1_rsd_fifo_rp[1:0]];
			v1_rsd_fifo_rp <= v1_rsd_fifo_rp + 1'b1;
			o_vpu1_rsd_wr <= 1'b1;
		end
	end
	else if(v1_txd_fsm == FSM_TX_SEND)
	begin
		if(i_vpu1_rsd_rdy && !v1_rsd_fifo_empty)
		begin
			o_vpu1_rsd <= v1_rsd_fifo[v1_rsd_fifo_rp[1:0]];
			v1_rsd_fifo_rp <= v1_rsd_fifo_rp + 1'b1;
		end
		else if(i_vpu1_rsd_rdy)
		begin
			v1_txd_fsm <= FSM_TX_IDLE;
			o_vpu1_rsd_wr <= 1'b0;
		end
	end
end



/* Master port response decoder */
vxe_txnress_decoder resm_decode(
	.i_res_vec_txn(i_m_rss),
	.o_txnid(rssm_txnid),
	.o_rnw(rssm_rnw),
	.o_err(rssm_err)
);


/* Master port transaction Id decoder */
vxe_txnid_decoder txnidm_decode(
	.i_txnid(rssm_txnid),
	.o_client_id(txnidm_client_id),
	.o_thread_id(txnidm_thread_id),
	.o_argument(txnidm_argument)
);


endmodule /* vxe_mem_hub_mas_ds */
