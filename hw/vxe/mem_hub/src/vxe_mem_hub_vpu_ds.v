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
 * VxE VPU downstream traffic control
 */


/* VPU downstream */
module vxe_mem_hub_vpu_ds(
	clk,
	nrst,
	/* Incoming response on Master 0 */
	i_m0_rss_vld,
	i_m0_rss,
	o_m0_rss_rd,
	i_m0_rsd_vld,
	i_m0_rsd,
	o_m0_rsd_rd,
	/* Incoming response on Master 1 */
	i_m1_rss_vld,
	i_m1_rss,
	o_m1_rss_rd,
	i_m1_rsd_vld,
	i_m1_rsd,
	o_m1_rsd_rd,
	/* Outgoing response */
	i_rss_rdy,
	o_rss,
	o_rss_wr,
	i_rsd_rdy,
	o_rsd,
	o_rsd_wr
);
/* Rx FSM states */
localparam [1:0]	FSM_RX_IDLE = 2'b00;	/* Idle */
localparam [1:0]	FSM_RX_RDM0 = 2'b01;	/* Read from Master 0 */
localparam [1:0]	FSM_RX_RDM1 = 2'b10;	/* Read from Master 1 */
localparam [1:0]	FSM_RX_STLL = 2'b11;	/* Stall */
/* Tx FSM states */
localparam		FSM_TX_IDLE = 1'b0;	/* Idle */
localparam		FSM_TX_SEND = 1'b1;	/* Send to client  */
/* Global signals */
input wire		clk;
input wire		nrst;
/* Incoming response on Master 0 */
input wire		i_m0_rss_vld;
input wire [8:0]	i_m0_rss;
output reg		o_m0_rss_rd;
input wire		i_m0_rsd_vld;
input wire [63:0]	i_m0_rsd;
output reg		o_m0_rsd_rd;
/* Incoming response on Master 1 */
input wire		i_m1_rss_vld;
input wire [8:0]	i_m1_rss;
output reg		o_m1_rss_rd;
input wire		i_m1_rsd_vld;
input wire [63:0]	i_m1_rsd;
output reg		o_m1_rsd_rd;
/* Outgoing response */
input wire		i_rss_rdy;
output reg [8:0]	o_rss;
output reg		o_rss_wr;
input wire		i_rsd_rdy;
output reg [63:0]	o_rsd;
output reg		o_rsd_wr;


/* Status FIFO */
reg [8:0]	rss_fifo[0:3];		/* Incoming response status FIFO */
reg [2:0]	rss_fifo_rp;		/* Read pointer */
reg [2:0]	rss_fifo_wp;		/* Write pointer */
/* Previous FIFO read pointer */
wire [2:0]	rss_fifo_pre_rp = rss_fifo_rp - 1'b1;
/* FIFO states */
wire rss_fifo_empty = (rss_fifo_rp[1:0] == rss_fifo_wp[1:0]) &&
	(rss_fifo_rp[2] == rss_fifo_wp[2]);
wire rss_fifo_full = (rss_fifo_rp[1:0] == rss_fifo_wp[1:0]) &&
	(rss_fifo_rp[2] != rss_fifo_wp[2]);
wire rss_fifo_pre_full = (rss_fifo_pre_rp[1:0] == rss_fifo_wp[1:0]) &&
	(rss_fifo_pre_rp[2] != rss_fifo_wp[2]);


/* Data FIFO */
reg [63:0]	rsd_fifo[0:3];		/* Incoming response data FIFO */
reg [2:0]	rsd_fifo_rp;		/* Read pointer */
reg [2:0]	rsd_fifo_wp;		/* Write pointer */
/* FIFO states */
wire rsd_fifo_empty = (rsd_fifo_rp[1:0] == rsd_fifo_wp[1:0]) &&
	(rsd_fifo_rp[2] == rsd_fifo_wp[2]);


/* Outgoing FIFO stall */
wire fifo_stall = rss_fifo_full || rss_fifo_pre_full;


/* Decoded response on master 0 */
wire [5:0]	rssm0_txnid;	/* Transaction Id */
wire		rssm0_rnw;	/* Read or Write transaction */
wire [1:0]	rssm0_err;	/* Error status */


/* Decoded response on master 1 */
wire [5:0]	rssm1_txnid;	/* Transaction Id */
wire		rssm1_rnw;	/* Read or Write transaction */
wire [1:0]	rssm1_err;	/* Error status */


/* Master 0 data hold register */
reg [63:0]	m0_data_hold_r;		/* Stored data */
reg		m0_data_hold_vld;	/* Register valid flag */


/* Master 1 data hold register */
reg [63:0]	m1_data_hold_r;		/* Stored data */
reg		m1_data_hold_vld;	/* Register valid flag */



/* RX FSM state */
reg [1:0]	rx_fsm;
reg [1:0]	stall_s;	/* State when stall was detected */

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		rx_fsm <= FSM_RX_IDLE;
		m0_data_hold_vld <= 1'b0;
		m1_data_hold_vld <= 1'b0;
		rss_fifo_wp <= 3'b000;
		rsd_fifo_wp <= 3'b000;
		o_m0_rss_rd <= 1'b0;
		o_m0_rsd_rd <= 1'b0;
		o_m1_rss_rd <= 1'b0;
		o_m1_rsd_rd <= 1'b0;
	end
	else if(rx_fsm == FSM_RX_RDM0)
	begin
		if(i_m0_rss_vld)
		begin
			/* Copy response to outgoing FIFO */
			rss_fifo[rss_fifo_wp[1:0]] <= i_m0_rss;
			rss_fifo_wp <= rss_fifo_wp + 1'b1;

			if(m0_data_hold_vld && rssm0_rnw)
			begin
				/* If response is for READ and hold register is
				 * valid then copy data from the hold register
				 * to outgoing data FIFO. Then re-enable read
				 * from data channel.
				 */
				rsd_fifo[rsd_fifo_wp[1:0]] <= m0_data_hold_r;
				rsd_fifo_wp <= rsd_fifo_wp + 1'b1;
				m0_data_hold_vld <= 1'b0;
				o_m0_rsd_rd <= 1'b1;
			end
			else if(~m0_data_hold_vld && ~rssm0_rnw && i_m0_rsd_vld)
			begin
				/* If response is for WRITE, incoming data is valid
				 * and hold register is not valid then copy data
				 * to the hold register and disable further
				 * read from data channel.
				 *
				 * It is required to keep proper order of
				 * response and data channels.
				 */
				m0_data_hold_r <= i_m0_rsd;
				m0_data_hold_vld <= 1'b1;
				o_m0_rsd_rd <= 1'b0;
			end
			else if(rssm0_rnw && i_m0_rsd_vld)
			begin
				/* If response is for READ and incoming data is
				 * valid then copy data to outgoing data FIFO.
				 */
				rsd_fifo[rsd_fifo_wp[1:0]] <= i_m0_rsd;
				rsd_fifo_wp <= rsd_fifo_wp + 1'b1;
			end
			else if(rssm0_rnw && ~i_m0_rsd_vld)
			begin
				/* This case should never happen */
				$display("Err: rssm0_rnw && ~i_m0_rsd_vld");
			end
		end


		/* Determine next state */
		if(fifo_stall)
		begin
			rx_fsm <= FSM_RX_STLL;
			stall_s <= rx_fsm;
			o_m0_rss_rd <= 1'b0;
			o_m0_rsd_rd <= 1'b0;
		end
		else if(i_m1_rss_vld)
		begin
			rx_fsm <= FSM_RX_RDM1;
			o_m0_rss_rd <= 1'b0;
			o_m0_rsd_rd <= 1'b0;
			o_m1_rss_rd <= 1'b1;
			o_m1_rsd_rd <= ~m1_data_hold_vld;
		end
	end
	else if(rx_fsm == FSM_RX_RDM1)
	begin
		if(i_m1_rss_vld)
		begin
			/* Copy response to outgoing FIFO */
			rss_fifo[rss_fifo_wp[1:0]] <= i_m1_rss;
			rss_fifo_wp <= rss_fifo_wp + 1'b1;

			if(m1_data_hold_vld && rssm1_rnw)
			begin
				/* If response is for READ and hold register is
				 * valid then copy data from the hold register
				 * to outgoing data FIFO. Then re-enable read
				 * from data channel.
				 */
				rsd_fifo[rsd_fifo_wp[1:0]] <= m1_data_hold_r;
				rsd_fifo_wp <= rsd_fifo_wp + 1'b1;
				m1_data_hold_vld <= 1'b0;
				o_m1_rsd_rd <= 1'b1;
			end
			else if(~m1_data_hold_vld && ~rssm1_rnw && i_m1_rsd_vld)
			begin
				/* If response is for WRITE, incoming data is valid
				 * and hold register is not valid then copy data
				 * to the hold register and disable further
				 * read from data channel.
				 *
				 * It is required to keep proper order of
				 * response and data channels.
				 */
				m1_data_hold_r <= i_m1_rsd;
				m1_data_hold_vld <= 1'b1;
				o_m1_rsd_rd <= 1'b0;
			end
			else if(rssm1_rnw && i_m1_rsd_vld)
			begin
				/* If response is for READ and incoming data is
				 * valid then copy data to outgoing data FIFO.
				 */
				rsd_fifo[rsd_fifo_wp[1:0]] <= i_m1_rsd;
				rsd_fifo_wp <= rsd_fifo_wp + 1'b1;
			end
			else if(rssm1_rnw && ~i_m1_rsd_vld)
			begin
				/* This case should never happen */
				$display("Err: rssm1_rnw && ~i_m1_rsd_vld");
			end
		end


		/* Determine next state */
		if(fifo_stall)
		begin
			rx_fsm <= FSM_RX_STLL;
			stall_s <= rx_fsm;
			o_m1_rss_rd <= 1'b0;
			o_m1_rsd_rd <= 1'b0;
		end
		else if(i_m0_rss_vld)
		begin
			rx_fsm <= FSM_RX_RDM0;
			o_m1_rss_rd <= 1'b0;
			o_m1_rsd_rd <= 1'b0;
			o_m0_rss_rd <= 1'b1;
			o_m0_rsd_rd <= ~m0_data_hold_vld;
		end
	end
	else if(rx_fsm == FSM_RX_STLL)
	begin
		if(!fifo_stall)
		begin
			rx_fsm <= FSM_RX_IDLE;

			/* Recover from the stall. Check port readiness in
			 * round robin order.
			 */
			if(stall_s == FSM_RX_RDM0)
			begin
				if(i_m1_rss_vld)
				begin
					rx_fsm <= FSM_RX_RDM1;
					o_m1_rss_rd <= 1'b1;
					o_m1_rsd_rd <= ~m1_data_hold_vld;
				end
				else if(i_m0_rss_vld)
				begin
					rx_fsm <= FSM_RX_RDM0;
					o_m0_rss_rd <= 1'b1;
					o_m0_rsd_rd <= ~m0_data_hold_vld;
				end
			end
			else if(stall_s == FSM_RX_RDM1)
			begin
				if(i_m0_rss_vld)
				begin
					rx_fsm <= FSM_RX_RDM0;
					o_m0_rss_rd <= 1'b1;
					o_m0_rsd_rd <= ~m0_data_hold_vld;
				end
				else if(i_m1_rss_vld)
				begin
					rx_fsm <= FSM_RX_RDM1;
					o_m1_rss_rd <= 1'b1;
					o_m1_rsd_rd <= ~m1_data_hold_vld;
				end
			end
			else
			begin
				/* Should not happen */
				$display("Err: stall_s else");
			end
		end
	end
	else /* IDLE */
	begin
		if(i_m0_rss_vld)
		begin
			o_m0_rss_rd <= 1'b1;
			o_m0_rsd_rd <= 1'b1;
			rx_fsm <= FSM_RX_RDM0;
		end
		else if(i_m1_rss_vld)
		begin
			o_m1_rss_rd <= 1'b1;
			o_m1_rsd_rd <= 1'b1;
			rx_fsm <= FSM_RX_RDM1;
		end
	end
end



/* Status TX FSM state */
reg	txs_fsm;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		txs_fsm <= FSM_TX_IDLE;
		rss_fifo_rp <= 3'b000;
		o_rss_wr <= 1'b0;
	end
	else if(txs_fsm == FSM_TX_IDLE)
	begin
		if(!rss_fifo_empty)
		begin
			txs_fsm <= FSM_TX_SEND;
			o_rss <= rss_fifo[rss_fifo_rp[1:0]];
			rss_fifo_rp <= rss_fifo_rp + 1'b1;
			o_rss_wr <= 1'b1;
		end
	end
	else if(txs_fsm == FSM_TX_SEND)
	begin
		if(i_rss_rdy && !rss_fifo_empty)
		begin
			o_rss <= rss_fifo[rss_fifo_rp[1:0]];
			rss_fifo_rp <= rss_fifo_rp + 1'b1;
		end
		else if(i_rss_rdy)
		begin
			txs_fsm <= FSM_TX_IDLE;
			o_rss_wr <= 1'b0;
		end
	end
end



/* Data TX FSM state */
reg	txd_fsm;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		txd_fsm <= FSM_TX_IDLE;
		rsd_fifo_rp <= 3'b000;
		o_rsd_wr <= 1'b0;
	end
	else if(txd_fsm == FSM_TX_IDLE)
	begin
		if(!rsd_fifo_empty)
		begin
			txd_fsm <= FSM_TX_SEND;
			o_rsd <= rsd_fifo[rsd_fifo_rp[1:0]];
			rsd_fifo_rp <= rsd_fifo_rp + 1'b1;
			o_rsd_wr <= 1'b1;
		end
	end
	else if(txd_fsm == FSM_TX_SEND)
	begin
		if(i_rsd_rdy && !rsd_fifo_empty)
		begin
			o_rsd <= rsd_fifo[rsd_fifo_rp[1:0]];
			rsd_fifo_rp <= rsd_fifo_rp + 1'b1;
		end
		else if(i_rsd_rdy)
		begin
			txd_fsm <= FSM_TX_IDLE;
			o_rsd_wr <= 1'b0;
		end
	end
end



/* Master 0 response decoder */
vxe_txnress_decoder resm0_decode(
	.i_res_vec_txn(i_m0_rss),
	.o_txnid(rssm0_txnid),
	.o_rnw(rssm0_rnw),
	.o_err(rssm0_err)
);


/* Master 1 response decoder */
vxe_txnress_decoder resm1_decode(
	.i_res_vec_txn(i_m1_rss),
	.o_txnid(rssm1_txnid),
	.o_rnw(rssm1_rnw),
	.o_err(rssm1_err)
);


endmodule /* vxe_mem_hub_vpu_ds */
