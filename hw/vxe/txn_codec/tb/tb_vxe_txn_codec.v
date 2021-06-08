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
 * Transaction coders and decoders testbench
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_txn_codec();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	/***/
	reg [5:0]	i_txnid_rq;
	reg		i_rnw_rq;
	reg [36:0]	i_addr_rq;
	reg [63:0]	i_data_rq;
	reg [7:0]	i_ben_rq;
	wire [43:0]	req_vec_txn;
	wire [71:0]	req_vec_dat;
	wire [5:0]	o_txnid_rq;
	wire		o_rnw_rq;
	wire [36:0]	o_addr_rq;
	wire [63:0]	o_data_rq;
	wire [7:0]	o_ben_rq;
	/***/
	reg [5:0]	i_txnid_rs;
	reg		i_rnw_rs;
	reg [1:0]	i_err_rs;
	reg [63:0]	i_data_rs;
	wire [8:0]	res_vec_txn;
	wire [63:0]	res_vec_dat;
	wire [5:0]	o_txnid_rs;
	wire		o_rnw_rs;
	wire [1:0]	o_err_rs;
	wire [63:0]	o_data_rs;
	/***/
	reg [5:0]	i_txnid_rqa;
	reg		i_rnw_rqa;
	reg [36:0]	i_addr_rqa;
	wire [43:0]	reqa_vec_txn;
	wire [5:0]	o_txnid_rqa;
	wire		o_rnw_rqa;
	wire [36:0]	o_addr_rqa;
	/***/
	reg [63:0]	i_data_rqd;
	reg [7:0]	i_ben_rqd;
	wire [71:0]	reqd_vec_dat;
	wire [63:0]	o_data_rqd;
	wire [7:0]	o_ben_rqd;
	/***/
	reg [5:0]	i_txnid_rss;
	reg		i_rnw_rss;
	reg [1:0]	i_err_rss;
	wire [8:0]	ress_vec_txn;
	wire [5:0]	o_txnid_rss;
	wire		o_rnw_rss;
	wire [1:0]	o_err_rss;

	always
		#HCLK clk = !clk;

	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_txn_codec);

		clk = 1;
		/***/
		i_txnid_rq = 6'b0;
		i_rnw_rq = 1'b0;
		i_addr_rq = 37'b0;
		i_data_rq = 64'b0;
		i_ben_rq = 8'b0;
		/***/
		i_txnid_rs = 6'b0;
		i_rnw_rs = 1'b0;
		i_err_rs = 2'b0;
		i_data_rs = 64'b0;
		/***/
		i_txnid_rqa = 6'b0;
		i_rnw_rqa = 1'b0;
		i_addr_rqa = 37'b0;
		/***/
		i_data_rqd = 64'b0;
		i_ben_rqd = 8'b0;
		/***/
		i_txnid_rss = 6'b0;
		i_rnw_rss = 1'b0;
		i_err_rss = 2'b0;


		@(posedge clk);
		@(posedge clk);


		@(posedge clk)
		begin
			i_txnid_rq <= 6'h3f;
			i_rnw_rq <= 1'b0;
			i_addr_rq <= 37'h03_0303_0303;
			i_data_rq <= 64'hfefe_fafa_dada_dede;
			i_ben_rq <= 8'h33;
			/***/
			i_txnid_rqa <= 6'h3f;
			i_rnw_rqa <= 1'b0;
			i_addr_rqa <= 37'h03_0303_0303;
			/***/
			i_data_rqd <= 64'hfefe_fafa_dada_dede;
			i_ben_rqd <= 8'h33;
		end

		@(posedge clk);
		@(posedge clk);

		@(posedge clk)
		begin
			i_txnid_rq <= 6'h2a;
			i_rnw_rq <= 1'b1;
			i_addr_rq <= 37'h1f_1313_1313;
			i_data_rq <= 64'hdede_dada_fafa_fefe;
			i_ben_rq <= 8'h11;
			/***/
			i_txnid_rqa <= 6'h2a;
			i_rnw_rqa <= 1'b1;
			i_addr_rqa <= 37'h1f_1313_1313;
			/***/
			i_data_rqd <= 64'hdede_dada_fafa_fefe;
			i_ben_rqd <= 8'h11;
		end

		@(posedge clk);
		@(posedge clk);


		@(posedge clk)
		begin
			i_txnid_rs <= 6'h3f;
			i_rnw_rs <= 1'b0;
			i_err_rs <= 2'b11;
			i_data_rs <= 64'hfefe_fafa_dada_dede;
			/***/
			i_txnid_rss <= 6'h3f;
			i_rnw_rss <= 1'b0;
			i_err_rss <= 2'b11;
		end

		@(posedge clk);
		@(posedge clk);


		@(posedge clk)
		begin
			i_txnid_rs <= 6'h2a;
			i_rnw_rs <= 1'b1;
			i_err_rs <= 2'b10;
			i_data_rs <= 64'hdede_dada_fafa_fefe;
			/***/
			i_txnid_rss <= 6'h2a;
			i_rnw_rss <= 1'b1;
			i_err_rss <= 2'b10;
		end


		#500 $finish;
	end


	/* Request coder/decoder instances */
	vxe_txnreq_coder txnreq_coder(
		.i_txnid(i_txnid_rq),
		.i_rnw(i_rnw_rq),
		.i_addr(i_addr_rq),
		.i_data(i_data_rq),
		.i_ben(i_ben_rq),
		.o_req_vec_txn(req_vec_txn),
		.o_req_vec_dat(req_vec_dat)
	);
	vxe_txnreq_decoder txnreq_decoder(
		.i_req_vec_txn(req_vec_txn),
		.i_req_vec_dat(req_vec_dat),
		.o_txnid(o_txnid_rq),
		.o_rnw(o_rnw_rq),
		.o_addr(o_addr_rq),
		.o_data(o_data_rq),
		.o_ben(o_ben_rq)
	);


	/* Response coder/decoder instances */
	vxe_txnres_coder txnres_coder(
		.i_txnid(i_txnid_rs),
		.i_rnw(i_rnw_rs),
		.i_err(i_err_rs),
		.i_data(i_data_rs),
		.o_res_vec_txn(res_vec_txn),
		.o_res_vec_dat(res_vec_dat)
	);
	vxe_txnres_decoder txnres_decoder(
		.i_res_vec_txn(res_vec_txn),
		.i_res_vec_dat(res_vec_dat),
		.o_txnid(o_txnid_rs),
		.o_rnw(o_rnw_rs),
		.o_err(o_err_rs),
		.o_data(o_data_rs)
	);


	/* Request coder/decoder instances (address only) */
	vxe_txnreqa_coder txnreqa_coder(
		.i_txnid(i_txnid_rqa),
		.i_rnw(i_rnw_rqa),
		.i_addr(i_addr_rqa),
		.o_req_vec_txn(reqa_vec_txn)
	);
	vxe_txnreqa_decoder txnreqa_decoder(
		.i_req_vec_txn(reqa_vec_txn),
		.o_txnid(o_txnid_rqa),
		.o_rnw(o_rnw_rqa),
		.o_addr(o_addr_rqa)
	);


	/* Request coder/decoder instances (data only) */
	vxe_txnreqd_coder txnreqd_coder(
		.i_data(i_data_rqd),
		.i_ben(i_ben_rqd),
		.o_req_vec_dat(reqd_vec_dat)
	);
	vxe_txnreqd_decoder txnreqd_decoder(
		.i_req_vec_dat(reqd_vec_dat),
		.o_data(o_data_rqd),
		.o_ben(o_ben_rqd)
	);


	/* Response coder/decoder instances (status only) */
	vxe_txnress_coder txnress_coder(
		.i_txnid(i_txnid_rss),
		.i_rnw(i_rnw_rss),
		.i_err(i_err_rss),
		.o_res_vec_txn(ress_vec_txn)
	);
	vxe_txnress_decoder txnress_decoder(
		.i_res_vec_txn(ress_vec_txn),
		.o_txnid(o_txnid_rss),
		.o_rnw(o_rnw_rss),
		.o_err(o_err_rss)
	);


endmodule /* tb_vxe_txn_codec */
