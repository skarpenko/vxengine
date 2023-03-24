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
 * Testbench for VxE VPU load-store unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_vpu_lsu();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;
	/* External memory request channel */
	wire		rqa_vld;
	wire [43:0]	rqa;
	reg		rqa_rd;
	wire		fifo_rqa_rdy;
	wire [43:0]	fifo_rqa;
	wire		fifo_rqa_wr;
	wire		rqd_vld;
	wire [71:0]	rqd;
	reg		rqd_rd;
	wire		fifo_rqd_rdy;
	wire [71:0]	fifo_rqd;
	wire		fifo_rqd_wr;
	/* External memory response channel */
	wire		rss_rdy;
	reg [8:0]	rss;
	reg		rss_wr;
	wire		fifo_rss_vld;
	wire [8:0]	fifo_rss;
	wire		fifo_rss_rd;
	wire		rsd_rdy;
	reg [63:0]	rsd;
	reg		rsd_wr;
	wire		fifo_rsd_vld;
	wire [63:0]	fifo_rsd;
	wire		fifo_rsd_rd;
	/* Control interface */
	reg		reinit;
	wire		busy;
	wire		err;
	/* Client interface */
	wire		rrq_rdy;
	reg		rrq_wr;
	reg [2:0]	rrq_th;
	reg [36:0]	rrq_addr;
	reg		rrq_arg;
	wire		wrq_rdy;
	reg		wrq_wr;
	reg [2:0]	wrq_th;
	reg [36:0]	wrq_addr;
	reg [1:0]	wrq_wen;
	reg [63:0]	wrq_data;
	wire		rrs_vld;
	reg		rrs_rd;
	wire [2:0]	rrs_th;
	wire		rrs_arg;
	wire [63:0]	rrs_data;

	/** Testbench specific **/
	reg [0:55]	test_name;	/* Test name, for ex.: Test_01 */
	reg		srst;		/* Responses generator reset */
	reg [7:0]	err_ctr;	/* Count before sending an error response */
	reg [63:0]	data_ptn;	/* Response data pattern */
	reg		tx_active;	/* Enable transmission of responses */
	reg [36:0]	read_addr;	/* Read address pattern */
	reg [36:0]	write_addr;	/* Write address pattern */
	reg [63:0]	write_data;	/* Write data pattern */


	always
		#HCLK clk = !clk;


	/* Wait for "posedge clk" */
	task wait_pos_clk;
	input integer j;	/* Number of cycles*/
	integer i;
	begin
		for(i=0; i<j; i++)
			@(posedge clk);
	end
	endtask


	/* Read patterns generation */
	always @(posedge clk)
	begin
		if(!srst)
		begin
			if(rrq_wr)
			begin
				rrq_addr <= read_addr + 1'b1;
				read_addr <= read_addr + 1'b1;
			end
			else
				rrq_addr <= read_addr;
		end
	end


	/* Write patterns generation */
	always @(posedge clk)
	begin
		if(!srst)
		begin
			if(wrq_wr)
			begin
				wrq_addr <= write_addr + 1'b1;
				wrq_data <= write_data + 1'b1;
				write_addr <= write_addr + 1'b1;
				write_data <= write_data + 1'b1;
			end
			else
			begin
				wrq_addr <= write_addr;
				wrq_data <= write_data;
			end
		end
	end


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_vpu_lsu);

		clk = 1'b1;
		nrst = 1'b0;

		reinit = 1'b0;
		rrq_wr = 1'b0;
		wrq_wr = 1'b0;
		rrs_rd = 1'b0;

		test_name = "Test_XX";
		srst = 1'b0;
		err_ctr = 8'h00;
		data_ptn = 64'h0000;
		tx_active = 1'b1;
		read_addr = 37'h0000;
		write_addr = 37'h0000;
		write_data = 64'h0000;


		#(10*PCLK) nrst = 1'b1;

		wait_pos_clk(1);
		/**************************************************************/


		/*** Test 01 - sending reads while request path is blocked ****/
		@(posedge clk)
		begin
			test_name <= "Test_01";
			read_addr <= 37'h1000;
			data_ptn <= 64'haabbccdd_00000000;
			err_ctr <= 8'h00;
			tx_active <= 1'b0;
			srst <= 1'b1;
		end
		@(posedge clk)
			srst <= 1'b0;
		@(posedge clk)
		begin
			rrq_wr <= 1'b1;
			rrq_th <= 3'b000;
			rrq_arg <= 1'b1;

			rrs_rd <= 1'b1;
		end

		wait_pos_clk(10);

		@(posedge clk)
			tx_active <= 1'b1;

		wait_pos_clk(10);

		@(posedge clk)
			rrq_wr <= 1'b0;

		wait_pos_clk(16);

		@(posedge clk)
			rrs_rd <= 1'b0;

		wait_pos_clk(64);


		/*** Test 02 - sending reads while response path is blocked ***/
		@(posedge clk)
		begin
			test_name <= "Test_02";
			read_addr <= 37'h2000;
			data_ptn <= 64'heeffaacc_00000000;
			err_ctr <= 8'h00;
			tx_active <= 1'b1;
			srst <= 1'b1;
		end
		@(posedge clk)
			srst <= 1'b0;
		@(posedge clk)
		begin
			rrq_wr <= 1'b1;
			rrq_th <= 3'b001;
			rrq_arg <= 1'b0;

			rrs_rd <= 1'b0;
		end

		wait_pos_clk(24);

		@(posedge clk)
			rrs_rd <= 1'b1;

		wait_pos_clk(10);

		@(posedge clk)
			rrq_wr <= 1'b0;

		wait_pos_clk(24);

		@(posedge clk)
			rrs_rd <= 1'b0;

		wait_pos_clk(64);


		/*** Test 03 - sending reads when error is returned ***********/
		@(posedge clk)
		begin
			test_name <= "Test_03";
			read_addr <= 37'h3000;
			data_ptn <= 64'hffaaeecc_00000000;
			err_ctr <= 8'h08;
			tx_active <= 1'b1;
			srst <= 1'b1;
		end
		@(posedge clk)
			srst <= 1'b0;
		@(posedge clk)
		begin
			rrq_wr <= 1'b1;
			rrq_th <= 3'b010;
			rrq_arg <= 1'b1;

			rrs_rd <= 1'b1;
		end

		wait_pos_clk(28);

		@(posedge clk)
			reinit <= 1'b1;
		@(posedge clk)
			reinit <= 1'b0;

		wait_pos_clk(10);

		@(posedge clk)
			rrq_wr <= 1'b0;

		wait_pos_clk(16);

		@(posedge clk)
			rrs_rd <= 1'b0;

		wait_pos_clk(64);


		/*** Test 04 - sending writes while request path is blocked ***/
		@(posedge clk)
		begin
			test_name <= "Test_04";
			write_addr <= 37'h4000;
			write_data <= 64'hfefebebe_00000000;
			err_ctr <= 8'h00;
			tx_active <= 1'b0;
			srst <= 1'b1;
		end
		@(posedge clk)
			srst <= 1'b0;
		@(posedge clk)
		begin
			wrq_wr <= 1'b1;
			wrq_th <= 3'b000;
			wrq_wen <= 2'b10;
		end

		wait_pos_clk(10);

		@(posedge clk)
			tx_active <= 1'b1;

		wait_pos_clk(10);

		@(posedge clk)
			wrq_wr <= 1'b0;

		wait_pos_clk(64);


		/*** Test 05 - sending writes when error is returned **********/
		@(posedge clk)
		begin
			test_name <= "Test_05";
			write_addr <= 37'h5000;
			write_data <= 64'hfafababa_00000000;
			err_ctr <= 8'h08;
			tx_active <= 1'b1;
			srst <= 1'b1;
		end
		@(posedge clk)
			srst <= 1'b0;
		@(posedge clk)
		begin
			wrq_wr <= 1'b1;
			wrq_th <= 3'b001;
			wrq_wen <= 2'b11;
		end

		wait_pos_clk(28);

		@(posedge clk)
			reinit <= 1'b1;
		@(posedge clk)
			reinit <= 1'b0;

		wait_pos_clk(10);

		@(posedge clk)
			wrq_wr <= 1'b0;

		wait_pos_clk(64);


		/*** Done ***/
		#500 $finish;
	end



	/* LSU instance */
	vxe_vpu_lsu #(
		.CLIENT_ID(1),
		.NR_REQ_POW2(4),
		.RD_DEPTH_POW2(2),
		.WR_DEPTH_POW2(2),
		.RS_DEPTH_POW2(2)
	) vpu_lsu (
		.clk(clk),
		.nrst(nrst),
		.i_rqa_rdy(fifo_rqa_rdy),
		.o_rqa(fifo_rqa),
		.o_rqa_wr(fifo_rqa_wr),
		.i_rqd_rdy(fifo_rqd_rdy),
		.o_rqd(fifo_rqd),
		.o_rqd_wr(fifo_rqd_wr),
		.i_rss_vld(fifo_rss_vld),
		.i_rss(fifo_rss),
		.o_rss_rd(fifo_rss_rd),
		.i_rsd_vld(fifo_rsd_vld),
		.i_rsd(fifo_rsd),
		.o_rsd_rd(fifo_rsd_rd),
		.i_reinit(reinit),
		.o_busy(busy),
		.o_err(err),
		.o_rrq_rdy(rrq_rdy),
		.i_rrq_wr(rrq_wr),
		.i_rrq_th(rrq_th),
		.i_rrq_addr(rrq_addr),
		.i_rrq_arg(rrq_arg),
		.o_wrq_rdy(wrq_rdy),
		.i_wrq_wr(wrq_wr),
		.i_wrq_th(wrq_th),
		.i_wrq_addr(wrq_addr),
		.i_wrq_wen(wrq_wen),
		.i_wrq_data(wrq_data),
		.o_rrs_vld(rrs_vld),
		.i_rrs_rd(rrs_rd),
		.o_rrs_th(rrs_th),
		.o_rrs_arg(rrs_arg),
		.o_rrs_data(rrs_data)
	);

	/* FIFO for outgoing request address */
	vxe_fifo #(
		.DATA_WIDTH(44),
		.DEPTH_POW2(2)
	) req_a (
		.clk(clk),
		.nrst(nrst),
		.data_in(fifo_rqa),
		.data_out(rqa),
		.rd(rqa_rd),
		.wr(fifo_rqa_wr),
		.in_rdy(fifo_rqa_rdy),
		.out_vld(rqa_vld)
	);

	/* FIFO for outgoing request data */
	vxe_fifo #(
		.DATA_WIDTH(72),
		.DEPTH_POW2(2)
	) req_d (
		.clk(clk),
		.nrst(nrst),
		.data_in(fifo_rqd),
		.data_out(rqd),
		.rd(rqd_rd),
		.wr(fifo_rqd_wr),
		.in_rdy(fifo_rqd_rdy),
		.out_vld(rqd_vld)
	);

	/* FIFO for incoming response status */
	vxe_fifo #(
		.DATA_WIDTH(9),
		.DEPTH_POW2(2)
	) resp_s (
		.clk(clk),
		.nrst(nrst),
		.data_in(rss),
		.data_out(fifo_rss),
		.rd(fifo_rss_rd),
		.wr(rss_wr),
		.in_rdy(rss_rdy),
		.out_vld(fifo_rss_vld)
	);

	/* FIFO for incoming response data */
	vxe_fifo #(
		.DATA_WIDTH(64),
		.DEPTH_POW2(2)
	) resp_d (
		.clk(clk),
		.nrst(nrst),
		.data_in(rsd),
		.data_out(fifo_rsd),
		.rd(fifo_rsd_rd),
		.wr(rsd_wr),
		.in_rdy(rsd_rdy),
		.out_vld(fifo_rsd_vld)
	);



/****************** Simple response traffic generator *************************/


/* Short FIFO for requests tracking */
reg [9:0]	rqs_rnw_fifo[0:3];	/* RnW requests FIFO */
reg [2:0]	rqs_fifo_rp;		/* Read pointer */
reg [2:0]	rqs_fifo_wp;		/* Write pointer */
/* Previous FIFO read pointer */
wire [2:0]	rqs_fifo_pre_rp = rqs_fifo_rp - 1'b1;
/* FIFO states */
wire rqs_fifo_empty = (rqs_fifo_rp[1:0] == rqs_fifo_wp[1:0]) &&
	(rqs_fifo_rp[2] == rqs_fifo_wp[2]);
wire rqs_fifo_full = (rqs_fifo_rp[1:0] == rqs_fifo_wp[1:0]) &&
	(rqs_fifo_rp[2] != rqs_fifo_wp[2]);
wire rqs_fifo_pre_full = (rqs_fifo_pre_rp[1:0] == rqs_fifo_wp[1:0]) &&
	(rqs_fifo_pre_rp[2] != rqs_fifo_wp[2]);
/* Request FIFO stall */
wire rqs_fifo_stall = rqs_fifo_full || rqs_fifo_pre_full;

/* Request details */
wire [5:0]	rq_txnid;
wire		rq_rnw;
wire [36:0]	rq_addr;
wire [1:0]	rq_cid;
wire [2:0]	rq_tid;
wire		rq_arg;
wire [8:0]	rs_txn;

/* Receive FSM states */
localparam [1:0]	FSM_RX_IDLE = 2'b00;
localparam [1:0]	FSM_RX_RECV = 2'b01;
localparam [1:0]	FSM_RX_STALL = 2'b10;

reg [1:0]	fsm_rx_state;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		rqs_fifo_wp <= 3'b000;
		fsm_rx_state <= FSM_RX_IDLE;
		rqa_rd <= 1'b0;
		rqd_rd <= 1'b0;
	end
	else if(srst)
	begin
		rqs_fifo_wp <= 3'b000;
		fsm_rx_state <= FSM_RX_IDLE;
		rqa_rd <= 1'b0;
		rqd_rd <= 1'b0;
	end
	else if(fsm_rx_state == FSM_RX_IDLE)
	begin
		if(rqa_vld)
		begin
			fsm_rx_state <= FSM_RX_RECV;
			rqa_rd <= 1'b1;
			rqd_rd <= 1'b1;
		end
	end
	else if(fsm_rx_state == FSM_RX_RECV)
	begin
		if(rqa_vld)
		begin
			rqs_rnw_fifo[rqs_fifo_wp[1:0]] <= { rs_txn, rq_rnw };
			rqs_fifo_wp <= rqs_fifo_wp + 1'b1;

			if(err_ctr) err_ctr <= err_ctr - 1'b1;
		end

		/*** Write data ignored ***/

		if(rqs_fifo_stall)
		begin
			fsm_rx_state <= FSM_RX_STALL;
			rqa_rd <= 1'b0;
			rqd_rd <= 1'b0;
		end
	end
	else if(fsm_rx_state == FSM_RX_STALL)
	begin
		if(!rqs_fifo_stall)
		begin
			fsm_rx_state <= FSM_RX_RECV;
			rqa_rd <= 1'b1;
			rqd_rd <= 1'b1;
		end
	end
end

/* Request decoder */
vxe_txnreqa_decoder reqa_dec(
	.i_req_vec_txn(rqa),
	.o_txnid(rq_txnid),
	.o_rnw(rq_rnw),
	.o_addr(rq_addr)
);

/* Txn Id decoder */
vxe_txnid_decoder txnid_dec(
	.i_txnid(rq_txnid),
	.o_client_id(rq_cid),
	.o_thread_id(rq_tid),
	.o_argument(rq_arg)
);

/* Response coder */
vxe_txnress_coder resp_coder(
	.i_txnid(rq_txnid),
	.i_rnw(rq_rnw),
	.i_err(err_ctr == 8'h01 ? 2'b11 : 2'b00),
	.o_res_vec_txn(rs_txn)
);



/* Transmit response FSM */

reg	fsm_tx_send;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		rqs_fifo_rp <= 3'b000;
		fsm_tx_send <= 1'b0;
		rss_wr <= 1'b0;
		rsd_wr <= 1'b0;
	end
	else if(srst)
	begin
		rqs_fifo_rp <= 3'b000;
		fsm_tx_send <= 1'b0;
		rss_wr <= 1'b0;
		rsd_wr <= 1'b0;
	end
	else if(tx_active && fsm_tx_send == 1'b0)
	begin
		if(!rqs_fifo_empty)
		begin
			fsm_tx_send <= 1'b1;
			rss <= rqs_rnw_fifo[rqs_fifo_rp[1:0]][9:1];
			rss_wr <= 1'b1;
			rqs_fifo_rp <= rqs_fifo_rp + 1'b1;

			if(rqs_rnw_fifo[rqs_fifo_rp[1:0]][0])
			begin
				rsd <= data_ptn;
				rsd_wr <= 1'b1;
				data_ptn <= data_ptn + 1'b1;
			end
		end
	end
	else if(tx_active && fsm_tx_send == 1'b1)
	begin
		if(!rqs_fifo_empty && rss_rdy)
		begin
			rss <= rqs_rnw_fifo[rqs_fifo_rp[1:0]][9:1];
			rqs_fifo_rp <= rqs_fifo_rp + 1'b1;

			if(rqs_rnw_fifo[rqs_fifo_rp[1:0]][0])
			begin
				rsd <= data_ptn;
				rsd_wr <= 1'b1;
				data_ptn <= data_ptn + 1'b1;
			end
			else
				rsd_wr <= 1'b0;
		end
		else if(rss_rdy)
		begin
			fsm_tx_send <= 1'b0;
			rss_wr <= 1'b0;
			rsd_wr <= 1'b0;
		end
	end
end


endmodule /* vxe_vpu_lsu */
