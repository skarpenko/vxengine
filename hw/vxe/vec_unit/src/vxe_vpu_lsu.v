/*
 * Copyright (c) 2020-2023 The VxEngine Project. All rights reserved.
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
 * VxE VPU load-store unit
 */


/* Load-store unit */
module vxe_vpu_lsu #(
	parameter [1:0] CLIENT_ID = 0,	/* Client Id */
	parameter NR_REQ_POW2 = 7,	/* Requests on the fly (2^NR_REQ_POW2) */
	parameter RD_DEPTH_POW2 = 5,	/* Read requests FIFO depth (2^RD_DEPTH_POW2) */
	parameter WR_DEPTH_POW2 = 2,	/* Write requests FIFO depth (2^WR_DEPTH_POW2) */
	parameter RS_DEPTH_POW2 = 5	/* Read responses FIFO depth (2^RS_DEPTH_POW2) */
)
(
	clk,
	nrst,
	/* External memory request channel */
	i_rqa_rdy,
	o_rqa,
	o_rqa_wr,
	i_rqd_rdy,
	o_rqd,
	o_rqd_wr,
	/* External memory response channel */
	i_rss_vld,
	i_rss,
	o_rss_rd,
	i_rsd_vld,
	i_rsd,
	o_rsd_rd,
	/* Control interface */
	i_reinit,
	o_busy,
	o_err,
	/* Client interface */
	o_rrq_rdy,	/* Read */
	i_rrq_wr,
	i_rrq_th,
	i_rrq_addr,
	i_rrq_arg,
	o_wrq_rdy,	/* Write */
	i_wrq_wr,
	i_wrq_th,
	i_wrq_addr,
	i_wrq_wen,
	i_wrq_data,
	o_rrs_vld,	/* Read response */
	i_rrs_rd,
	o_rrs_th,
	o_rrs_arg,
	o_rrs_data
);
/* Requests arbitration FSM states */
localparam [4:0] FSM_ARB_EMPTY = 5'b00001;	/* Both req FIFOs are empty */
localparam [4:0] FSM_ARB_RDFIFO = 5'b00010;	/* Handling read requests */
localparam [4:0] FSM_ARB_WRFIFO = 5'b00100;	/* Handling write requests */
localparam [4:0] FSM_ARB_RDSTALL = 5'b01000;	/* Read requests path stall */
localparam [4:0] FSM_ARB_WRSTALL = 5'b10000;	/* Write requests path stall */
/* Tx FSM states */
localparam FSM_TX_IDLE = 1'b0;	/* Idle */
localparam FSM_TX_SEND = 1'b1;	/* Send request */
/* Rx FSM states */
localparam		FSM_RX_IDLE = 1'b0;	/* Idle */
localparam		FSM_RX_RECV = 1'b1;	/* Receive response */
/* Global signals */
input wire		clk;
input wire		nrst;
/* External memory request channel */
input wire		i_rqa_rdy;
output reg [43:0]	o_rqa;
output reg		o_rqa_wr;
input wire		i_rqd_rdy;
output reg [71:0]	o_rqd;
output reg		o_rqd_wr;
/* External memory response channel */
input wire		i_rss_vld;
input wire [8:0]	i_rss;
output reg		o_rss_rd;
input wire		i_rsd_vld;
input wire [63:0]	i_rsd;
output reg		o_rsd_rd;
/* Control interface */
input wire		i_reinit;	/* Re-enable if disabled */
output wire		o_busy;
output wire		o_err;
/* Client interface */
output wire		o_rrq_rdy;
input wire		i_rrq_wr;
input wire [2:0]	i_rrq_th;
input wire [36:0]	i_rrq_addr;
input wire		i_rrq_arg;
output wire		o_wrq_rdy;
input wire		i_wrq_wr;
input wire [2:0]	i_wrq_th;
input wire [36:0]	i_wrq_addr;
input wire [1:0]	i_wrq_wen;	/* Word enable */
input wire [63:0]	i_wrq_data;
output wire		o_rrs_vld;
input wire		i_rrs_rd;
output wire [2:0]	o_rrs_th;
output wire		o_rrs_arg;
output wire [63:0]	o_rrs_data;



/********************* Internal wires and registers ***************************/



/* Request and response data */
wire [5:0]	rrq_txnid;	/* Read request Id */
wire [43:0]	rrq_txn;	/* Read request info */
wire [5:0]	wrq_txnid;	/* Write request Id */
wire [43:0]	wrq_txn;	/* Write request info */
wire [71:0]	wrq_dat;	/* Write request data */
wire [5:0]	rsp_txnid;	/* Response Id */
wire		rsp_rnw;	/* Read or Write transaction */
wire [1:0]	rsp_err;	/* Error status */
wire [1:0]	rsp_cid;	/* Response client Id (not used) */
wire [2:0]	rsp_th;		/* Response thread Id */
wire		rsp_arg;	/* Response argument type (Rs/Rt) */


/* Read requests FIFO wires */
wire [43:0]	fifo_rrq_out;
wire		fifo_rrq_wr;
reg		fifo_rrq_rd;
wire		fifo_rrq_srst;
wire		fifo_rrq_full;
wire		fifo_rrq_empty1;	/* Not used */
wire		fifo_rrq_empty;


/* Write requests FIFO wires */
wire [115:0]	fifo_wrq_out;
wire		fifo_wrq_wr;
reg		fifo_wrq_rd;
wire		fifo_wrq_srst;
wire		fifo_wrq_full;
wire		fifo_wrq_empty1;	/* Not used */
wire		fifo_wrq_empty;


/* Read responses FIFO wires */
reg [67:0]	fifo_rrs_in;	/* {thread, arg, data} */
wire [67:0]	fifo_rrs_out;	/* {thread, arg, data} */
reg		fifo_rrs_wr;
wire		fifo_rrs_rd;
wire		fifo_rrs_srst;
wire		fifo_rrs_full;
wire		fifo_rrs_empty1;	/* Not used */
wire		fifo_rrs_empty;


/* Active transactions tracking */
reg [NR_REQ_POW2:0] tr_send_p;	/* Send pointer */
reg [NR_REQ_POW2:0] tr_resp_p;	/* Response pointer */
/* No transactions on the fly */
wire tr_none = (tr_send_p[NR_REQ_POW2-1:0] == tr_resp_p[NR_REQ_POW2-1:0]) &&
	(tr_send_p[NR_REQ_POW2] == tr_resp_p[NR_REQ_POW2]);
/* Maximum number of transactions on the fly reached */
wire tr_max = (tr_send_p[NR_REQ_POW2-1:0] == tr_resp_p[NR_REQ_POW2-1:0]) &&
	(tr_send_p[NR_REQ_POW2] != tr_resp_p[NR_REQ_POW2]);


/* Short FIFO for request address */
reg [43:0]	rqa_fifo[0:3];		/* Request address FIFO */
reg [2:0]	rqa_fifo_rp;		/* Read pointer */
reg [2:0]	rqa_fifo_wp;		/* Write pointer */
/* Previous FIFO read pointer */
wire [2:0]	rqa_fifo_pre_rp = rqa_fifo_rp - 1'b1;
/* FIFO states */
wire rqa_fifo_empty = (rqa_fifo_rp[1:0] == rqa_fifo_wp[1:0]) &&
	(rqa_fifo_rp[2] == rqa_fifo_wp[2]);
wire rqa_fifo_full = (rqa_fifo_rp[1:0] == rqa_fifo_wp[1:0]) &&
	(rqa_fifo_rp[2] != rqa_fifo_wp[2]);
wire rqa_fifo_pre_full = (rqa_fifo_pre_rp[1:0] == rqa_fifo_wp[1:0]) &&
	(rqa_fifo_pre_rp[2] != rqa_fifo_wp[2]);
/* Request FIFO stall */
wire rqa_fifo_stall = rqa_fifo_full || rqa_fifo_pre_full;


/* Short FIFO for request data */
reg [71:0]	rqd_fifo[0:3];		/* Request data FIFO */
reg [2:0]	rqd_fifo_rp;		/* Read pointer */
reg [2:0]	rqd_fifo_wp;		/* Write pointer */
/* FIFO states */
wire rqd_fifo_empty = (rqd_fifo_rp[1:0] == rqd_fifo_wp[1:0]) &&
	(rqd_fifo_rp[2] == rqd_fifo_wp[2]);


/* Short FIFO for response status */
reg [8:0]	rss_fifo[0:3];		/* Response status FIFO */
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
/* Response FIFO stall */
wire rss_fifo_stall = rss_fifo_full || rss_fifo_pre_full;


/* Short FIFO for response data */
reg [63:0]	rsd_fifo[0:3];		/* Response data FIFO */
reg [2:0]	rsd_fifo_rp;		/* Read pointer */
reg [2:0]	rsd_fifo_wp;		/* Write pointer */
/* FIFO states */
wire rsd_fifo_empty = (rsd_fifo_rp[1:0] == rsd_fifo_wp[1:0]) &&
	(rsd_fifo_rp[2] == rsd_fifo_wp[2]);


/* Response error and disabled state */
wire		resp_err = (|rsp_err && !rss_fifo_empty);	/* Response error */
reg		disabled_q;
wire		disabled = (disabled_q || resp_err);


/* Wire connections */
assign o_busy = !tr_none || !rqa_fifo_empty || !rss_fifo_empty ||
		!fifo_rrq_empty || !fifo_wrq_empty || !fifo_rrs_empty;
assign o_err = resp_err;
assign o_rrq_rdy = !disabled ? !fifo_rrq_full : 1'b1;
assign o_wrq_rdy = !disabled ? !fifo_wrq_full : 1'b1;
assign fifo_rrq_wr = !disabled ? i_rrq_wr : 1'b0;
assign fifo_rrq_srst = disabled;
assign fifo_wrq_wr = !disabled ? i_wrq_wr : 1'b0;
assign fifo_wrq_srst = disabled;
assign o_rrs_vld = !fifo_rrs_empty;
assign { o_rrs_th, o_rrs_arg, o_rrs_data } = fifo_rrs_out;
assign fifo_rrs_rd = i_rrs_rd;
assign fifo_rrs_srst = 1'b0;



/****************************** Control FSMs **********************************/



/* Requests arbitration FSM states */
reg [4:0] fsm_rqarb_state;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		fsm_rqarb_state <= FSM_ARB_EMPTY;
		rqa_fifo_wp <= 3'b000;
		rqd_fifo_wp <= 3'b000;
	end
	else if(!disabled)
	begin
		case(fsm_rqarb_state)
		FSM_ARB_EMPTY: begin
			if(!fifo_wrq_empty && !rqa_fifo_full)
			begin
				fifo_wrq_rd <= 1'b1;
				fsm_rqarb_state <= FSM_ARB_WRFIFO;
			end
			else if(!fifo_rrq_empty && !rqa_fifo_full)
			begin
				fifo_rrq_rd <= 1'b1;
				fsm_rqarb_state <= FSM_ARB_RDFIFO;
			end
		end
		FSM_ARB_RDFIFO: begin
			if(!fifo_rrq_empty)
			begin
				rqa_fifo[rqa_fifo_wp[1:0]] <= fifo_rrq_out;
				rqa_fifo_wp <= rqa_fifo_wp + 1'b1;

				if(rqa_fifo_stall)
				begin
					fifo_rrq_rd <= 1'b0;
					fsm_rqarb_state <= FSM_ARB_RDSTALL;
				end
			end
			else
			begin
				fifo_rrq_rd <= 1'b0;
				fsm_rqarb_state <= FSM_ARB_EMPTY;
			end

		end
		FSM_ARB_WRFIFO: begin
			if(!fifo_wrq_empty)
			begin
				rqa_fifo[rqa_fifo_wp[1:0]] <= fifo_wrq_out[115:72];
				rqd_fifo[rqd_fifo_wp[1:0]] <= fifo_wrq_out[71:0];

				rqa_fifo_wp <= rqa_fifo_wp + 1'b1;
				rqd_fifo_wp <= rqd_fifo_wp + 1'b1;

				if(rqa_fifo_stall)
				begin
					fifo_wrq_rd <= 1'b0;
					fsm_rqarb_state <= FSM_ARB_WRSTALL;
				end
			end
			else
			begin
				fifo_wrq_rd <= 1'b0;
				fsm_rqarb_state <= FSM_ARB_EMPTY;
			end
		end
		FSM_ARB_RDSTALL: begin
			if(!rqa_fifo_stall)
			begin
				if(!fifo_rrq_empty)
				begin
					fifo_rrq_rd <= 1'b1;
					fsm_rqarb_state <= FSM_ARB_RDFIFO;
				end
				else if(!fifo_wrq_empty)
				begin
					fifo_wrq_rd <= 1'b1;
					fsm_rqarb_state <= FSM_ARB_WRFIFO;
				end
				else
					fsm_rqarb_state <= FSM_ARB_EMPTY;
			end
		end
		FSM_ARB_WRSTALL: begin
			if(!rqa_fifo_stall)
			begin
				if(!fifo_wrq_empty)
				begin
					fifo_wrq_rd <= 1'b1;
					fsm_rqarb_state <= FSM_ARB_WRFIFO;
				end
				else if(!fifo_rrq_empty)
				begin
					fifo_rrq_rd <= 1'b1;
					fsm_rqarb_state <= FSM_ARB_RDFIFO;
				end
				else
					fsm_rqarb_state <= FSM_ARB_EMPTY;
			end
		end
		default: $display("Wrong fsm_rqarb_state value!\n");
		endcase
	end
end


/* Responses handling FSM */
always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		disabled_q <= 1'b0;
		rss_fifo_rp <= 3'b000;
		rsd_fifo_rp <= 3'b000;
		fifo_rrs_wr <= 1'b0;
	end
	else if(i_reinit)
	begin
		disabled_q <= 1'b0;
	end
	else if(disabled)
	begin
		/* Drop all incoming data */
		rss_fifo_rp <= rss_fifo_wp;
		rsd_fifo_rp <= rsd_fifo_wp;
		disabled_q <= 1'b1;
		fifo_rrs_wr <= 1'b0;
	end
	else if(!rss_fifo_empty && !fifo_rrs_full)
	begin
		rss_fifo_rp <= rss_fifo_rp + 1'b1;
		fifo_rrs_wr <= 1'b0;

		/* Read response */
		if(rsp_rnw)
		begin
			fifo_rrs_in <= { rsp_th, rsp_arg, rsd_fifo[rsd_fifo_rp[1:0]] };
			fifo_rrs_wr <= 1'b1;
			rsd_fifo_rp <= rsd_fifo_rp + 1'b1;
		end
	end
	else
		fifo_rrs_wr <= 1'b0;
end


/* Tx address FSM */
reg fsm_txa_state;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		fsm_txa_state <= FSM_TX_IDLE;
		rqa_fifo_rp <= 3'b000;
		o_rqa_wr <= 1'b0;
		tr_send_p <= {(NR_REQ_POW2+1){1'b0}};
	end
	else if(fsm_txa_state == FSM_TX_IDLE)
	begin
		if(!rqa_fifo_empty && !tr_max)
		begin
			fsm_txa_state <= FSM_TX_SEND;
			o_rqa <= rqa_fifo[rqa_fifo_rp[1:0]];
			rqa_fifo_rp <= rqa_fifo_rp + 1'b1;
			tr_send_p <= tr_send_p + 1'b1;
			o_rqa_wr <= 1'b1;
		end
	end
	else if(fsm_txa_state == FSM_TX_SEND)
	begin
		if(i_rqa_rdy && !rqa_fifo_empty && !tr_max)
		begin
			o_rqa <= rqa_fifo[rqa_fifo_rp[1:0]];
			rqa_fifo_rp <= rqa_fifo_rp + 1'b1;
			tr_send_p <= tr_send_p + 1'b1;
		end
		else if(i_rqa_rdy)
		begin
			fsm_txa_state <= FSM_TX_IDLE;
			o_rqa_wr <= 1'b0;
		end
	end
end


/* Tx data FSM */
reg fsm_txd_state;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		fsm_txd_state <= FSM_TX_IDLE;
		rqd_fifo_rp <= 3'b000;
		o_rqd_wr <= 1'b0;
	end
	else if(fsm_txd_state == FSM_TX_IDLE)
	begin
		if(!rqd_fifo_empty && !tr_max)
		begin
			fsm_txd_state <= FSM_TX_SEND;
			o_rqd <= rqd_fifo[rqd_fifo_rp[1:0]];
			rqd_fifo_rp <= rqd_fifo_rp + 1'b1;
			o_rqd_wr <= 1'b1;
		end
	end
	else if(fsm_txd_state == FSM_TX_SEND)
	begin
		if(i_rqd_rdy && !rqd_fifo_empty && !tr_max)
		begin
			o_rqd <= rqd_fifo[rqd_fifo_rp[1:0]];
			rqd_fifo_rp <= rqd_fifo_rp + 1'b1;
		end
		else if(i_rqd_rdy)
		begin
			fsm_txd_state <= FSM_TX_IDLE;
			o_rqd_wr <= 1'b0;
		end
	end
end


/* Rx status FSM */
reg fsm_rxs_state;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		fsm_rxs_state <= FSM_RX_IDLE;
		rss_fifo_wp <= 3'b000;
		o_rss_rd <= 1'b0;
		tr_resp_p <= {(NR_REQ_POW2+1){1'b0}};
	end
	else if(fsm_rxs_state == FSM_RX_IDLE)
	begin
		if(!rss_fifo_stall)
		begin
			fsm_rxs_state <= FSM_RX_RECV;
			o_rss_rd <= 1'b1;
		end
	end
	else if(fsm_rxs_state == FSM_RX_RECV)
	begin
		if(i_rss_vld && tr_none)
		begin
			$display("Response status is valid but no transactions on the fly!");
		end
		else if(i_rss_vld)
		begin
			rss_fifo[rss_fifo_wp[1:0]] <= i_rss;
			rss_fifo_wp <= rss_fifo_wp + 1'b1;
			tr_resp_p <= tr_resp_p + 1'b1;
		end

		if(rss_fifo_stall)
		begin
			fsm_rxs_state <= FSM_RX_IDLE;
			o_rss_rd <= 1'b0;
		end

	end
end


/* Rx data FSM */
reg fsm_rxd_state;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		fsm_rxd_state <= FSM_RX_IDLE;
		rsd_fifo_wp <= 3'b000;
		o_rsd_rd <= 1'b0;
	end
	else if(fsm_rxd_state == FSM_RX_IDLE)
	begin
		if(!rss_fifo_stall)
		begin
			fsm_rxd_state <= FSM_RX_RECV;
			o_rsd_rd <= 1'b1;
		end
	end
	else if(fsm_rxd_state == FSM_RX_RECV)
	begin
		if(i_rsd_vld && tr_none)
		begin
			$display("Response data is valid but no transactions on the fly!");
		end
		else if(i_rsd_vld)
		begin
			rsd_fifo[rsd_fifo_wp[1:0]] <= i_rsd;
			rsd_fifo_wp <= rsd_fifo_wp + 1'b1;
		end

		if(rss_fifo_stall)
		begin
			fsm_rxd_state <= FSM_RX_IDLE;
			o_rsd_rd <= 1'b0;
		end
	end
end



/******************************* Unit instances *******************************/



/* Read request Id coder */
vxe_txnid_coder rd_txnid_coder(
	.i_client_id(CLIENT_ID),
	.i_thread_id(i_rrq_th),
	.i_argument(i_rrq_arg),
	.o_txnid(rrq_txnid)
);

/* Read request coder */
vxe_txnreqa_coder rd_txn_req_coder(
	.i_txnid(rrq_txnid),
	.i_rnw(1'b1),
	.i_addr(i_rrq_addr),
	.o_req_vec_txn(rrq_txn)
);

/* Write request Id coder */
vxe_txnid_coder wr_txnid_coder(
	.i_client_id(CLIENT_ID),
	.i_thread_id(i_wrq_th),
	.i_argument(1'b0),	/* Ignored */
	.o_txnid(wrq_txnid)
);

/* Write request coder */
vxe_txnreq_coder wr_txn_req_coder(
	.i_txnid(wrq_txnid),
	.i_rnw(1'b0),
	.i_addr(i_wrq_addr),
	.i_data(i_wrq_data),
	.i_ben({ i_wrq_wen[1] ? 4'b1111 : 4'b000, i_wrq_wen[0] ? 4'b1111 : 4'b000 }),
	.o_req_vec_txn(wrq_txn),
	.o_req_vec_dat(wrq_dat)
);

/* Response Id decoder */
vxe_txnid_decoder resp_txnid_decoder(
	.i_txnid(rsp_txnid),
	.o_client_id(rsp_cid),
	.o_thread_id(rsp_th),
	.o_argument(rsp_arg)
);

/* Response decoder */
vxe_txnress_decoder resp_txn_decoder(
	.i_res_vec_txn(rss_fifo[rss_fifo_rp[1:0]]),
	.o_txnid(rsp_txnid),
	.o_rnw(rsp_rnw),
	.o_err(rsp_err)
);

/* Read requests FIFO */
vxe_fifo_2 #(
	.DATA_WIDTH(44),
	.DEPTH_POW2(RD_DEPTH_POW2),
	.USE_EMPTY1(0)
) rrq_fifo (
	.clk(clk),
	.nrst(nrst),
	.data_in(rrq_txn),
	.data_out(fifo_rrq_out),
	.wr(fifo_rrq_wr),
	.rd(fifo_rrq_rd),
	.srst(fifo_rrq_srst),
	.full(fifo_rrq_full),
	.empty1(fifo_rrq_empty1),
	.empty(fifo_rrq_empty)
);

/* Write requests FIFO */
vxe_fifo_2 #(
	.DATA_WIDTH(116),
	.DEPTH_POW2(WR_DEPTH_POW2),
	.USE_EMPTY1(0)
) wrq_fifo (
	.clk(clk),
	.nrst(nrst),
	.data_in( { wrq_txn, wrq_dat} ),
	.data_out(fifo_wrq_out),
	.wr(fifo_wrq_wr),
	.rd(fifo_wrq_rd),
	.srst(fifo_wrq_srst),
	.full(fifo_wrq_full),
	.empty1(fifo_wrq_empty1),
	.empty(fifo_wrq_empty)
);

/* Read responses FIFO */
vxe_fifo_2 #(
	.DATA_WIDTH(68),
	.DEPTH_POW2(RS_DEPTH_POW2),
	.USE_EMPTY1(0)
) rrs_fifo (
	.clk(clk),
	.nrst(nrst),
	.data_in(fifo_rrs_in),
	.data_out(fifo_rrs_out),
	.wr(fifo_rrs_wr),
	.rd(fifo_rrs_rd),
	.srst(fifo_rrs_srst),
	.full(fifo_rrs_full),
	.empty1(fifo_rrs_empty1),
	.empty(fifo_rrs_empty)
);


endmodule /* vxe_vpu_lsu */
