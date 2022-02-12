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
 * VxE AXI switch downstream unit.
 */


/* AXI switch downstream */
module vxe_axi_switch_ds(
	clk,
	nrst,
	/* Incoming response */
	biu_bcid,
	biu_bresp,
	biu_bready,
	biu_bpush,
	biu_rcid,
	biu_rdata,
	biu_rresp,
	biu_rready,
	biu_rpush,
	/* Outgoing response */
	i_m_rss_rdy,
	o_m_rss,
	o_m_rss_wr,
	i_m_rsd_rdy,
	o_m_rsd,
	o_m_rsd_wr
);
/* FSM states */
localparam [3:0]	FSM_IDLE = 4'b0000;	/* Idle */
localparam [3:0]	FSM_DSRD = 4'b0001;	/* Downstream read response */
localparam [3:0]	FSM_DSWR = 4'b0010;	/* Downstream write response */
localparam [3:0]	FSM_STLR = 4'b0100;	/* Read resp. downstream stall */
localparam [3:0]	FSM_STLW = 4'b1000;	/* Write resp. downstream stall */
/* Global signals */
input wire		clk;
input wire		nrst;
/* Incoming response */
input wire [5:0]	biu_bcid;
input wire [1:0]	biu_bresp;
output wire		biu_bready;
input wire		biu_bpush;
input wire [5:0]	biu_rcid;
input wire [63:0]	biu_rdata;
input wire [1:0]	biu_rresp;
output wire		biu_rready;
input wire		biu_rpush;
/* Outgoing response */
input wire		i_m_rss_rdy;
output reg [8:0]	o_m_rss;
output reg		o_m_rss_wr;
input wire		i_m_rsd_rdy;
output reg [63:0]	o_m_rsd;
output reg		o_m_rsd_wr;



/* Write responses FIFO */
reg [7:0]	wr_resp_fifo[0:3];	/* Response FIFO */
reg [2:0]	wr_resp_fifo_rp;	/* Read pointer */
reg [2:0]	wr_resp_fifo_wp;	/* Write pointer */
/* Previous FIFO read pointer */
wire [2:0]	wr_resp_fifo_pre_rp = wr_resp_fifo_rp - 1'b1;
/* FIFO states */
wire wr_resp_fifo_empty = (wr_resp_fifo_rp[1:0] == wr_resp_fifo_wp[1:0]) &&
	(wr_resp_fifo_rp[2] == wr_resp_fifo_wp[2]);
wire wr_resp_fifo_full = (wr_resp_fifo_rp[1:0] == wr_resp_fifo_wp[1:0]) &&
	(wr_resp_fifo_rp[2] != wr_resp_fifo_wp[2]);
wire wr_resp_fifo_pre_full = (wr_resp_fifo_pre_rp[1:0] == wr_resp_fifo_wp[1:0]) &&
	(wr_resp_fifo_pre_rp[2] != wr_resp_fifo_wp[2]);


/* Read responses FIFO */
reg [71:0]	rd_resp_fifo[0:3];	/* Response FIFO */
reg [2:0]	rd_resp_fifo_rp;	/* Read pointer */
reg [2:0]	rd_resp_fifo_wp;	/* Write pointer */
/* Previous FIFO read pointer */
wire [2:0]	rd_resp_fifo_pre_rp = rd_resp_fifo_rp - 1'b1;
/* FIFO states */
wire rd_resp_fifo_empty = (rd_resp_fifo_rp[1:0] == rd_resp_fifo_wp[1:0]) &&
	(rd_resp_fifo_rp[2] == rd_resp_fifo_wp[2]);
wire rd_resp_fifo_full = (rd_resp_fifo_rp[1:0] == rd_resp_fifo_wp[1:0]) &&
	(rd_resp_fifo_rp[2] != rd_resp_fifo_wp[2]);
wire rd_resp_fifo_pre_full = (rd_resp_fifo_pre_rp[1:0] == rd_resp_fifo_wp[1:0]) &&
	(rd_resp_fifo_pre_rp[2] != rd_resp_fifo_wp[2]);


/* Incoming write responses FIFO stall */
wire wr_fifo_stall = wr_resp_fifo_full || wr_resp_fifo_pre_full;

/* Incoming read responses FIFO stall */
wire rd_fifo_stall = rd_resp_fifo_full || rd_resp_fifo_pre_full;


/* Ready to accept conditions */
assign biu_bready = !wr_fifo_stall;
assign biu_rready = !rd_fifo_stall;



/** Responses downstream **/

wire [8:0]	wr_resp_stat;	/* Write response status */
wire [8:0]	rd_resp_stat;	/* Read response status */
wire [63:0]	rd_resp_data;	/* Read response data */


/* Downstream FSM state */
reg [3:0] ds_fsm_state;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		wr_resp_fifo_rp <= 3'b000;
		rd_resp_fifo_rp <= 3'b000;
		o_m_rss_wr <= 1'b0;
		o_m_rsd_wr <= 1'b0;
		ds_fsm_state <= FSM_IDLE;
	end
	else if(ds_fsm_state == FSM_DSRD)	/* Downstream read responses */
	begin
		if(i_m_rss_rdy && i_m_rsd_rdy && !wr_resp_fifo_empty)
		begin
			o_m_rss <= wr_resp_stat;
			o_m_rss_wr <= 1'b1;
			o_m_rsd_wr <= 1'b0;
			wr_resp_fifo_rp <= wr_resp_fifo_rp + 1'b1;
			ds_fsm_state <= FSM_DSWR;
		end
		else if(i_m_rss_rdy && i_m_rsd_rdy && !rd_resp_fifo_empty)
		begin
			o_m_rss <= rd_resp_stat;
			o_m_rsd <= rd_resp_data;
			rd_resp_fifo_rp <= rd_resp_fifo_rp + 1'b1;
		end
		else if(i_m_rss_rdy && i_m_rsd_rdy)
		begin
			o_m_rss_wr <= 1'b0;
			o_m_rsd_wr <= 1'b0;
			ds_fsm_state <= FSM_IDLE;
		end
		else
		begin
			if(i_m_rss_rdy)
				o_m_rss_wr <= 1'b0;

			if(i_m_rsd_rdy)
				o_m_rsd_wr <= 1'b0;

			ds_fsm_state <= FSM_STLR;
		end
	end
	else if(ds_fsm_state == FSM_DSWR)	/* Downstream write responses */
	begin
		if(i_m_rss_rdy && !rd_resp_fifo_empty)
		begin
			o_m_rss <= rd_resp_stat;
			o_m_rsd <= rd_resp_data;
			o_m_rss_wr <= 1'b1;
			o_m_rsd_wr <= 1'b1;
			rd_resp_fifo_rp <= rd_resp_fifo_rp + 1'b1;
			ds_fsm_state <= FSM_DSRD;
		end
		else if(i_m_rss_rdy && !wr_resp_fifo_empty)
		begin
			o_m_rss <= wr_resp_stat;
			wr_resp_fifo_rp <= wr_resp_fifo_rp + 1'b1;
		end
		else if(i_m_rss_rdy)
		begin
			o_m_rss_wr <= 1'b0;
			ds_fsm_state <= FSM_IDLE;
		end
		else
		begin
			ds_fsm_state <= FSM_STLW;
		end
	end
	else if(ds_fsm_state == FSM_STLR)	/* Read responses downstream stall */
	begin
		if(i_m_rss_rdy && i_m_rsd_rdy)
		begin
			o_m_rss_wr <= 1'b0;
			o_m_rsd_wr <= 1'b0;

			if(!wr_resp_fifo_empty)	/* Favor write responses */
			begin
				o_m_rss <= wr_resp_stat;
				o_m_rss_wr <= 1'b1;
				wr_resp_fifo_rp <= wr_resp_fifo_rp + 1'b1;
				ds_fsm_state <= FSM_DSWR;
			end
			else if(!rd_resp_fifo_empty)
			begin
				o_m_rss <= rd_resp_stat;
				o_m_rsd <= rd_resp_data;
				o_m_rss_wr <= 1'b1;
				o_m_rsd_wr <= 1'b1;
				rd_resp_fifo_rp <= rd_resp_fifo_rp + 1'b1;
				ds_fsm_state <= FSM_DSRD;
			end
			else
			begin
				ds_fsm_state <= FSM_IDLE;
			end
		end
		else if(i_m_rss_rdy)
		begin
			o_m_rss_wr <= 1'b0;
		end
		else if(i_m_rsd_rdy)
		begin
			o_m_rsd_wr <= 1'b0;
		end
	end
	else if(ds_fsm_state == FSM_STLW)	/* Write responses downstream stall */
	begin
		if(i_m_rss_rdy)
		begin
			o_m_rss_wr <= 1'b0;

			if(!rd_resp_fifo_empty)	/* Favor read responses */
			begin
				o_m_rss <= rd_resp_stat;
				o_m_rsd <= rd_resp_data;
				o_m_rss_wr <= 1'b1;
				o_m_rsd_wr <= 1'b1;
				rd_resp_fifo_rp <= rd_resp_fifo_rp + 1'b1;
				ds_fsm_state <= FSM_DSRD;
			end
			else if(!wr_resp_fifo_empty)
			begin
				o_m_rss <= wr_resp_stat;
				o_m_rss_wr <= 1'b1;
				wr_resp_fifo_rp <= wr_resp_fifo_rp + 1'b1;
				ds_fsm_state <= FSM_DSWR;
			end
			else
			begin
				ds_fsm_state <= FSM_IDLE;
			end
		end
	end
	else	/* IDLE */
	begin
		if(!rd_resp_fifo_empty)
		begin
			o_m_rss <= rd_resp_stat;
			o_m_rsd <= rd_resp_data;
			o_m_rss_wr <= 1'b1;
			o_m_rsd_wr <= 1'b1;
			rd_resp_fifo_rp <= rd_resp_fifo_rp + 1'b1;
			ds_fsm_state <= FSM_DSRD;
		end
		else if(!wr_resp_fifo_empty)
		begin
			o_m_rss <= wr_resp_stat;
			o_m_rss_wr <= 1'b1;
			wr_resp_fifo_rp <= wr_resp_fifo_rp + 1'b1;
			ds_fsm_state <= FSM_DSWR;
		end
	end
end

/* Write responses coder */
vxe_txnress_coder wr_resp_coder(
	.i_txnid(wr_resp_fifo[wr_resp_fifo_rp[1:0]][7:2]),
	.i_rnw(1'b0),
	.i_err(wr_resp_fifo[wr_resp_fifo_rp[1:0]][1:0]),
	.o_res_vec_txn(wr_resp_stat)
);

/* Read responses coder */
vxe_txnress_coder rd_resp_coder(
	.i_txnid(rd_resp_fifo[rd_resp_fifo_rp[1:0]][71:66]),
	.i_rnw(1'b1),
	.i_err(rd_resp_fifo[rd_resp_fifo_rp[1:0]][65:64]),
	.o_res_vec_txn(rd_resp_stat)
);

assign rd_resp_data = rd_resp_fifo[rd_resp_fifo_rp[1:0]][63:0];



/** Receive write responses **/

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		wr_resp_fifo_wp <= 3'b000;
	end
	else if(biu_bpush && biu_bready)
	begin
		wr_resp_fifo[wr_resp_fifo_wp[1:0]] <= { biu_bcid, biu_bresp };
		wr_resp_fifo_wp <= wr_resp_fifo_wp + 1'b1;
	end
end



/** Receive read responses **/

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		rd_resp_fifo_wp <= 3'b000;
	end
	else if(biu_rpush && biu_rready)
	begin
		rd_resp_fifo[rd_resp_fifo_wp[1:0]] <= { biu_rcid, biu_rresp, biu_rdata };
		rd_resp_fifo_wp <= rd_resp_fifo_wp + 1'b1;
	end
end


endmodule /* vxe_axi_switch_ds */
