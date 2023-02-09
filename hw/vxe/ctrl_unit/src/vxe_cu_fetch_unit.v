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
 * VxE CU fetch unit
 */


/* Fetch unit */
module vxe_cu_fetch_unit #(
	parameter [1:0] CLIENT_ID = 0,	/* Client Id */
	parameter FETCH_DEPTH_POW2 = 4	/* Fetch FIFO depth */
)
(
	clk,
	nrst,
	/* Memory request channel */
	i_rqa_rdy,
	o_rqa,
	o_rqa_wr,
	/* Memory response channel */
	i_rss_vld,
	i_rss,
	o_rss_rd,
	i_rsd_vld,
	i_rsd,
	o_rsd_rd,
	/* Control signals */
	i_start,
	i_start_addr,
	i_stop_drain,
	o_busy,
	o_fetch_addr,
	o_fetch_data,
	o_fetch_vld,
	o_fetch_err,
	i_fetch_rd
);
/* Request FSM states */
localparam [1:0]	FSM_RQ_IDLE = 2'b00;	/* Idle */
localparam [1:0]	FSM_RQ_SEND = 2'b01;	/* Read fetch requests */
localparam [1:0]	FSM_RQ_STLL = 2'b10;	/* Stall */
/* Response FSM states */
localparam [1:0]	FSM_RS_IDLE = 2'b00;	/* Idle */
localparam [1:0]	FSM_RS_RECV = 2'b01;	/* Receive responses */
localparam [1:0]	FSM_RS_STLL = 2'b10;	/* Stall */
/* Send command FSM states */
localparam		FSM_CM_IDLE = 1'b0;	/* Idle */
localparam		FSM_CM_SEND = 1'b1;	/* Send */
/* Misc */
localparam		CMD_WORDS = 1'h1;	/* Command words */
/* Global signals */
input wire		clk;
input wire		nrst;
/* Memory request channel */
input wire		i_rqa_rdy;
output reg [43:0]	o_rqa;
output reg		o_rqa_wr;
/* Memory response channel */
input wire		i_rss_vld;
input wire [8:0]	i_rss;
output reg		o_rss_rd;
input wire		i_rsd_vld;
input wire [63:0]	i_rsd;
output reg		o_rsd_rd;
/* Control signals */
input wire		i_start;
input wire [36:0]	i_start_addr;
input wire		i_stop_drain;
output wire		o_busy;
output wire [36:0]	o_fetch_addr;
output wire [63:0]	o_fetch_data;
output wire		o_fetch_vld;
output wire		o_fetch_err;
input wire		i_fetch_rd;


reg [36:0]	fetch_addr;	/* Current fetch address */


wire [5:0]	rq_txnid;	/* Request transaction Id */
wire [43:0]	rq_txn;		/* Request Transaction info */
wire [5:0]	rs_txnid;	/* Response transaction Id */
wire		rs_rnw;		/* Read or Write response */
wire [1:0]	rs_err;		/* Error status */


/* Requests FIFO wires */
reg [36:0]	f_rq_in;
wire [36:0]	f_rq_out;
wire		f_rq_rd;
reg		f_rq_wr;
wire		f_rq_rdy;
wire		f_rq_vld;

/* Responses FIFO wires */
reg [64:0]	f_rs_in;
wire [64:0]	f_rs_out;
wire		f_rs_rd;
reg		f_rs_wr;
wire		f_rs_rdy;
wire		f_rs_vld;


/* Fetched command data valid */
wire fetch_vld = f_rq_vld && f_rs_vld;


/* Fetch unit busy condition */
assign o_busy = i_start || i_stop_drain ||
	(rq_fsm != FSM_RQ_IDLE) ||
	(rs_fsm != FSM_RS_IDLE) ||
	(scm_fsm != FSM_CM_IDLE) ||
	drain;


/* Internal FIFO interface */
assign o_fetch_addr = f_rq_out;
assign o_fetch_data = f_rs_out[63:0];
assign o_fetch_vld = fetch_vld && ~drain;
assign o_fetch_err = f_rs_out[64];
assign f_rq_rd = (i_fetch_rd || drain) && fetch_vld;
assign f_rs_rd = (i_fetch_rd || drain) && fetch_vld;


/* Requests stall condition */
wire rq_stall = ~i_rqa_rdy | ~f_rq_rdy;


/* Request FSM state */
reg [1:0]	rq_fsm;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		rq_fsm <= FSM_RQ_IDLE;
		o_rqa_wr <= 1'b0;
		f_rq_wr <= 1'b0;
	end
	else if(rq_fsm == FSM_RQ_SEND)
	begin
		if(rq_stall)
		begin
			if(i_rqa_rdy)
				o_rqa_wr <= 1'b0;
			if(f_rq_rdy)
				f_rq_wr <= 1'b0;
			rq_fsm <= FSM_RQ_STLL;
		end
		else
		begin
			f_rq_in <= fetch_addr;
			o_rqa <= rq_txn;
			fetch_addr <= fetch_addr + CMD_WORDS;

			if(drain)
			begin
				f_rq_wr <= 1'b0;
				o_rqa_wr <= 1'b0;
				rq_fsm <= FSM_RQ_IDLE;
			end
		end

	end
	else if(rq_fsm == FSM_RQ_STLL)
	begin
		if(i_rqa_rdy)
			o_rqa_wr <= 1'b0;
		if(f_rq_rdy)
			f_rq_wr <= 1'b0;

		if(~rq_stall)
		begin
			f_rq_in <= fetch_addr;
			o_rqa <= rq_txn;
			f_rq_wr <= 1'b1;
			o_rqa_wr <= 1'b1;
			fetch_addr <= fetch_addr + CMD_WORDS;
			rq_fsm <= FSM_RQ_SEND;
		end
	end
	else	/* FSM_RQ_IDLE */
	begin
		fetch_addr <= i_start_addr;

		if(i_start && ~drain)
		begin
			f_rq_in <= fetch_addr;
			o_rqa <= rq_txn;
			f_rq_wr <= 1'b1;
			o_rqa_wr <= 1'b1;
			fetch_addr <= fetch_addr + CMD_WORDS;
			rq_fsm <= FSM_RQ_SEND;
		end
	end
end



/* Responses intermediate FIFO */
reg [8:0]	rss_fifo[0:3];	/* Incoming responses FIFO */
reg [2:0]	rss_fifo_rp;	/* Read pointer */
reg [2:0]	rss_fifo_wp;	/* Write pointer */
/* Previous FIFO read pointer */
wire [2:0]	rss_fifo_pre_rp = rss_fifo_rp - 1'b1;
/* FIFO states */
wire rss_fifo_empty = (rss_fifo_rp[1:0] == rss_fifo_wp[1:0]) &&
	(rss_fifo_rp[2] == rss_fifo_wp[2]);
wire rss_fifo_full = (rss_fifo_rp[1:0] == rss_fifo_wp[1:0]) &&
	(rss_fifo_rp[2] != rss_fifo_wp[2]);
wire rss_fifo_pre_full = (rss_fifo_pre_rp[1:0] == rss_fifo_wp[1:0]) &&
	(rss_fifo_pre_rp[2] != rss_fifo_wp[2]);


/* Response data intermediate FIFO */
reg [63:0]	rsd_fifo[0:3];	/* Incoming response data FIFO */
reg [2:0]	rsd_fifo_rp;	/* Read pointer */
reg [2:0]	rsd_fifo_wp;	/* Write pointer */
/* FIFO states */
wire rsd_fifo_empty = (rsd_fifo_rp[1:0] == rsd_fifo_wp[1:0]) &&
	(rsd_fifo_rp[2] == rsd_fifo_wp[2]);


/* Response FIFO stall condition */
wire rs_fifo_stall = rss_fifo_full || rss_fifo_pre_full;



/* Response FSM state */
reg [1:0]	rs_fsm;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		o_rss_rd <= 1'b0;
		o_rsd_rd <= 1'b0;
		rss_fifo_wp <= 3'b000;
		rsd_fifo_wp <= 3'b000;
		rs_fsm <= FSM_RS_IDLE;
	end
	else if(rs_fsm == FSM_RS_RECV)
	begin
		if(i_rss_vld)
		begin
			rss_fifo[rss_fifo_wp[1:0]] <= i_rss;
			rss_fifo_wp <= rss_fifo_wp + 1'b1;

			rsd_fifo[rsd_fifo_wp[1:0]] <= i_rsd;
			rsd_fifo_wp <= rsd_fifo_wp + 1'b1;
		end

		if(rs_fifo_stall)
		begin
			o_rss_rd <= 1'b0;
			o_rsd_rd <= 1'b0;
			rs_fsm <= FSM_RS_STLL;
		end

		if(!f_rq_vld)
		begin
			o_rss_rd <= 1'b0;
			o_rsd_rd <= 1'b0;
			rs_fsm <= FSM_RS_IDLE;
		end
	end
	else if(rs_fsm == FSM_RS_STLL)
	begin
		if(!rs_fifo_stall)
		begin
			o_rss_rd <= 1'b1;
			o_rsd_rd <= 1'b1;
			rs_fsm <= FSM_RS_RECV;
		end
	end
	else	/* FSM_RS_IDLE */
	begin
		if(f_rq_vld)
		begin
			o_rss_rd <= 1'b1;
			o_rsd_rd <= 1'b1;
			rs_fsm <= FSM_RS_RECV;
		end
	end
end


/* Send command FSM state */
reg	scm_fsm;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		scm_fsm <= FSM_CM_IDLE;
		rss_fifo_rp <= 3'b000;
		rsd_fifo_rp <= 3'b000;
		f_rs_wr <= 1'b0;
	end
	else if(scm_fsm == FSM_CM_IDLE)
	begin
		if(!rss_fifo_empty)
		begin
			/*            Err     Command word */
			f_rs_in <= { |rs_err, rsd_fifo[rsd_fifo_rp[1:0]] };
			rss_fifo_rp <= rss_fifo_rp + 1'b1;
			rsd_fifo_rp <= rsd_fifo_rp + 1'b1;
			f_rs_wr <= 1'b1;
			scm_fsm <= FSM_CM_SEND;
		end
	end
	else if(scm_fsm == FSM_CM_SEND)
	begin
		if(f_rs_rdy && !rss_fifo_empty)
		begin
			/*            Err     Command word */
			f_rs_in <= { |rs_err, rsd_fifo[rsd_fifo_rp[1:0]] };
			rss_fifo_rp <= rss_fifo_rp + 1'b1;
			rsd_fifo_rp <= rsd_fifo_rp + 1'b1;
		end
		else if(f_rs_rdy)
		begin
			f_rs_wr <= 1'b0;
			scm_fsm <= FSM_CM_IDLE;
		end
	end
end


/* Stop and drain FSM state */
reg	drain;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		drain <= 1'b0;
	end
	else if(drain)
	begin
		if(!f_rq_vld && !f_rs_vld)
			drain <= 1'b0;
	end
	else if(i_stop_drain)
	begin
		drain <= 1'b1;
	end
end



/* Transaction Id coder */
vxe_txnid_coder txnid_coder(
	.i_client_id(CLIENT_ID),
	.i_thread_id(3'b0),
	.i_argument(1'b0),
	.o_txnid(rq_txnid)
);


/* Request coder */
vxe_txnreqa_coder req_coder(
	.i_txnid(rq_txnid),
	.i_rnw(1'b1),
	.i_addr(fetch_addr),
	.o_req_vec_txn(rq_txn)
);


/* Response decoder */
vxe_txnress_decoder res_decoder(
	.i_res_vec_txn(rss_fifo[rss_fifo_rp[1:0]]),
	.o_txnid(rs_txnid),
	.o_rnw(rs_rnw),
	.o_err(rs_err)
);


/* FIFO for sent requests */
vxe_fifo #(
	.DATA_WIDTH(37),
	.DEPTH_POW2(FETCH_DEPTH_POW2)
) rq_fifo (
	.clk(clk),
	.nrst(nrst),
	.data_in(f_rq_in),
	.data_out(f_rq_out),
	.rd(f_rq_rd),
	.wr(f_rq_wr),
	.in_rdy(f_rq_rdy),
	.out_vld(f_rq_vld)
);


/* FIFO for received responses */
vxe_fifo #(
	.DATA_WIDTH(65),
	.DEPTH_POW2(FETCH_DEPTH_POW2)
) rs_fifo (
	.clk(clk),
	.nrst(nrst),
	.data_in(f_rs_in),
	.data_out(f_rs_out),
	.rd(f_rs_rd),
	.wr(f_rs_wr),
	.in_rdy(f_rs_rdy),
	.out_vld(f_rs_vld)
);


endmodule /* vxe_cu_fetch_unit */
