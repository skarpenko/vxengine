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
 * Testbench for VxE master port downstream traffic control
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_mem_hub_mas_ds();
`include "vxe_client_params.vh"
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;
	/* Incoming response on master port */
	wire		m_rss_rdy;
	reg [8:0]	m_rss;
	reg		m_rss_wr;
	wire		m_rsd_rdy;
	reg [63:0]	m_rsd;
	reg		m_rsd_wr;
	/* Outgoing response for CU */
	wire		cu_rss_vld;
	wire [8:0]	cu_rss;
	reg		cu_rss_rd;
	wire		cu_rsd_vld;
	wire [63:0]	cu_rsd;
	reg		cu_rsd_rd;
	/* Outgoing response for VPU0 */
	wire		vpu0_rss_vld;
	wire [8:0]	vpu0_rss;
	reg		vpu0_rss_rd;
	wire		vpu0_rsd_vld;
	wire [63:0]	vpu0_rsd;
	reg		vpu0_rsd_rd;
	/* Outgoing response for VPU1 */
	wire		vpu1_rss_vld;
	wire [8:0]	vpu1_rss;
	reg		vpu1_rss_rd;
	wire		vpu1_rsd_vld;
	wire [63:0]	vpu1_rsd;
	reg		vpu1_rsd_rd;

	/** FIFO connection wires **/

	/* Master port -> Downstream */
	wire		m_ds_rss_vld;
	wire [8:0]	m_ds_rss;
	wire		m_ds_rss_rd;
	wire		m_ds_rsd_vld;
	wire [63:0]	m_ds_rsd;
	wire		m_ds_rsd_rd;
	/* Downstream -> CU */
	wire		ds_cu_rss_rdy;
	wire [8:0]	ds_cu_rss;
	wire		ds_cu_rss_wr;
	wire		ds_cu_rsd_rdy;
	wire [63:0]	ds_cu_rsd;
	wire		ds_cu_rsd_wr;
	/* Downstream -> VPU0 */
	wire		ds_vpu0_rss_rdy;
	wire [8:0]	ds_vpu0_rss;
	wire		ds_vpu0_rss_wr;
	wire		ds_vpu0_rsd_rdy;
	wire [63:0]	ds_vpu0_rsd;
	wire		ds_vpu0_rsd_wr;
	/* Downstream -> VPU1 */
	wire		ds_vpu1_rss_rdy;
	wire [8:0]	ds_vpu1_rss;
	wire		ds_vpu1_rss_wr;
	wire		ds_vpu1_rsd_rdy;
	wire [63:0]	ds_vpu1_rsd;
	wire		ds_vpu1_rsd_wr;

	/** Current test name **/
	reg [0:47]	test_name;


	always
		#HCLK clk = !clk;


	task wait_pos_clk;
		@(posedge clk);
	endtask


	task wait_pos_clk4;
	begin
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
	end
	endtask


	task wait_pos_clk8;
	begin
		wait_pos_clk4;
		wait_pos_clk4;
	end
	endtask


	task wait_pos_clk16;
	begin
		wait_pos_clk8;
		wait_pos_clk8;
	end
	endtask


	task wait_pos_clk32;
	begin
		wait_pos_clk16;
		wait_pos_clk16;
	end
	endtask


	/* Send response to a client */
	task start_send_resp;
	input [1:0] client;
	input data_vld;
	input [63:0] data;
	input [3:0] misc;
	begin
		@(posedge clk)
		begin
			m_rss <= { client, misc, data_vld, client };
			m_rss_wr <= 1'b1;
			if(data_vld)
			begin
				m_rsd <= data;
				m_rsd_wr <= 1'b1;
			end
			else
				m_rsd_wr <= 1'b0;
		end
	end
	endtask


	/* Stop sending responses */
	task stop_send_resp;
	begin
		@(posedge clk)
		begin
			m_rss_wr <= 1'b0;
			m_rsd_wr <= 1'b0;
		end
	end
	endtask


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_mem_hub_mas_ds);

		clk = 1;
		nrst = 0;

		m_rss_wr = 0;
		m_rsd_wr = 0;
		cu_rss_rd = 0;
		cu_rsd_rd = 0;
		vpu0_rss_rd = 0;
		vpu0_rsd_rd = 0;
		vpu1_rss_rd = 0;
		vpu1_rsd_rd = 0;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		nrst = 1;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		/*********************************/

		/** Test - responses with data **/
		test_name = "Test_1";

		start_send_resp(CLNT_CU, 1'b1, 64'hA1A2A3A4A5A6A7A8, 4'h0);
		start_send_resp(CLNT_VPU0, 1'b1, 64'hB1B2B3B4B5B6B7B8, 4'h0);
		start_send_resp(CLNT_VPU1, 1'b1, 64'hC1C2C3C4C5C6C7C8, 4'h0);

		stop_send_resp();

		@(posedge clk)
		begin
			cu_rss_rd <= 1'b1;
			cu_rsd_rd <= 1'b1;
			vpu0_rss_rd <= 1'b1;
			vpu0_rsd_rd <= 1'b1;
			vpu1_rss_rd <= 1'b1;
			vpu1_rsd_rd <= 1'b1;
		end

		wait_pos_clk8();

		@(posedge clk)
		begin
			cu_rss_rd <= 1'b0;
			cu_rsd_rd <= 1'b0;
			vpu0_rss_rd <= 1'b0;
			vpu0_rsd_rd <= 1'b0;
			vpu1_rss_rd <= 1'b0;
			vpu1_rsd_rd <= 1'b0;
		end


		/** Test - only first response with data **/
		test_name = "Test_2";

		start_send_resp(CLNT_CU, 1'b1, 64'hA1A2A3A4A5A6A7A8, 4'h0);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h0);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h0);

		stop_send_resp();

		@(posedge clk)
		begin
			cu_rss_rd <= 1'b1;
			cu_rsd_rd <= 1'b1;
			vpu0_rss_rd <= 1'b1;
			vpu0_rsd_rd <= 1'b1;
			vpu1_rss_rd <= 1'b1;
			vpu1_rsd_rd <= 1'b1;
		end

		wait_pos_clk8();

		@(posedge clk)
		begin
			cu_rss_rd <= 1'b0;
			cu_rsd_rd <= 1'b0;
			vpu0_rss_rd <= 1'b0;
			vpu0_rsd_rd <= 1'b0;
			vpu1_rss_rd <= 1'b0;
			vpu1_rsd_rd <= 1'b0;
		end


		/** Test - only last response with data **/
		test_name = "Test_3";

		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h0);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h0);
		start_send_resp(CLNT_VPU1, 1'b1, 64'hC1C2C3C4C5C6C7C8, 4'h0);

		stop_send_resp();

		@(posedge clk)
		begin
			cu_rss_rd <= 1'b1;
			cu_rsd_rd <= 1'b1;
			vpu0_rss_rd <= 1'b1;
			vpu0_rsd_rd <= 1'b1;
			vpu1_rss_rd <= 1'b1;
			vpu1_rsd_rd <= 1'b1;
		end

		wait_pos_clk8();

		@(posedge clk)
		begin
			cu_rss_rd <= 1'b0;
			cu_rsd_rd <= 1'b0;
			vpu0_rss_rd <= 1'b0;
			vpu0_rsd_rd <= 1'b0;
			vpu1_rss_rd <= 1'b0;
			vpu1_rsd_rd <= 1'b0;
		end


		/* Note: for Tests 4 - 6 data has to be properly routed to a
		 * client. It may not match returned status value since the
		 * testbench doesn't correct ordering of client FIFO reads.
		 */

		/** Test - only last CU response has data (clogged test case) **/
		test_name = "Test_4";

		/* Fill all FIFOs to cause internal stall */
		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h0);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h0);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h0);

		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h1);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h1);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h1);

		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h2);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h2);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h2);

		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h3);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h3);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h3);

		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h4);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h4);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h4);

		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h5);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h5);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h5);

		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h6);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h6);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h6);

		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h7);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h7);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h7);

		/* These three go to master input FIFO */
		start_send_resp(CLNT_CU, 1'b1, 64'hA1A2A3A4A5A6A7A4, 4'h8); // <<
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B4, 4'h8);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C4, 4'h8);

		stop_send_resp();

		wait_pos_clk8();

		@(posedge clk)
		begin
			cu_rss_rd <= 1'b1;
			cu_rsd_rd <= 1'b1;
			vpu0_rss_rd <= 1'b1;
			vpu0_rsd_rd <= 1'b1;
			vpu1_rss_rd <= 1'b1;
			vpu1_rsd_rd <= 1'b1;
		end

		wait_pos_clk16();

		@(posedge clk)
		begin
			cu_rss_rd <= 1'b0;
			cu_rsd_rd <= 1'b0;
			vpu0_rss_rd <= 1'b0;
			vpu0_rsd_rd <= 1'b0;
			vpu1_rss_rd <= 1'b0;
			vpu1_rsd_rd <= 1'b0;
		end


		/** Test - only last VPU0 response has data (clogged test case) **/
		test_name = "Test_5";

		/* Fill all FIFOs to cause internal stall */
		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h0);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h0);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h0);

		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h1);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h1);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h1);

		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h2);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h2);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h2);

		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h3);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h3);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h3);

		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h4);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h4);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h4);

		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h5);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h5);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h5);

		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h6);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h6);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h6);

		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h7);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h7);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h7);

		/* These three go to master input FIFO */
		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A5, 4'h8);
		start_send_resp(CLNT_VPU0, 1'b1, 64'hB1B2B3B4B5B6B7B5, 4'h8); // <<
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C5, 4'h8);

		stop_send_resp();

		wait_pos_clk8();

		@(posedge clk)
		begin
			cu_rss_rd <= 1'b1;
			cu_rsd_rd <= 1'b1;
			vpu0_rss_rd <= 1'b1;
			vpu0_rsd_rd <= 1'b1;
			vpu1_rss_rd <= 1'b1;
			vpu1_rsd_rd <= 1'b1;
		end

		wait_pos_clk16();

		@(posedge clk)
		begin
			cu_rss_rd <= 1'b0;
			cu_rsd_rd <= 1'b0;
			vpu0_rss_rd <= 1'b0;
			vpu0_rsd_rd <= 1'b0;
			vpu1_rss_rd <= 1'b0;
			vpu1_rsd_rd <= 1'b0;
		end


		/** Test - only last VPU1 response has data (clogged test case) **/
		test_name = "Test_6";

		/* Fill all FIFOs to cause internal stall */
		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h0);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h0);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h0);

		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h1);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h1);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h1);

		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h2);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h2);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h2);

		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h3);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h3);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h3);

		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h4);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h4);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h4);

		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h5);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h5);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h5);

		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h6);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h6);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h6);

		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A8, 4'h7);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B8, 4'h7);
		start_send_resp(CLNT_VPU1, 1'b0, 64'hC1C2C3C4C5C6C7C8, 4'h7);

		/* These three go to master input FIFO */
		start_send_resp(CLNT_CU, 1'b0, 64'hA1A2A3A4A5A6A7A6, 4'h8);
		start_send_resp(CLNT_VPU0, 1'b0, 64'hB1B2B3B4B5B6B7B6, 4'h8);
		start_send_resp(CLNT_VPU1, 1'b1, 64'hC1C2C3C4C5C6C7C6, 4'h8); // <<

		stop_send_resp();

		wait_pos_clk8();

		@(posedge clk)
		begin
			cu_rss_rd <= 1'b1;
			cu_rsd_rd <= 1'b1;
			vpu0_rss_rd <= 1'b1;
			vpu0_rsd_rd <= 1'b1;
			vpu1_rss_rd <= 1'b1;
			vpu1_rsd_rd <= 1'b1;
		end

		wait_pos_clk16();

		@(posedge clk)
		begin
			cu_rss_rd <= 1'b0;
			cu_rsd_rd <= 1'b0;
			vpu0_rss_rd <= 1'b0;
			vpu0_rsd_rd <= 1'b0;
			vpu1_rss_rd <= 1'b0;
			vpu1_rsd_rd <= 1'b0;
		end


		#500 $finish;
	end



	/* Master port downstream instance */
	vxe_mem_hub_mas_ds mas_ds(
		.clk(clk),
		.nrst(nrst),
		.i_m_rss_vld(m_ds_rss_vld),
		.i_m_rss(m_ds_rss),
		.o_m_rss_rd(m_ds_rss_rd),
		.i_m_rsd_vld(m_ds_rsd_vld),
		.i_m_rsd(m_ds_rsd),
		.o_m_rsd_rd(m_ds_rsd_rd),
		.i_cu_rss_rdy(ds_cu_rss_rdy),
		.o_cu_rss(ds_cu_rss),
		.o_cu_rss_wr(ds_cu_rss_wr),
		.i_cu_rsd_rdy(ds_cu_rsd_rdy),
		.o_cu_rsd(ds_cu_rsd),
		.o_cu_rsd_wr(ds_cu_rsd_wr),
		.i_vpu0_rss_rdy(ds_vpu0_rss_rdy),
		.o_vpu0_rss(ds_vpu0_rss),
		.o_vpu0_rss_wr(ds_vpu0_rss_wr),
		.i_vpu0_rsd_rdy(ds_vpu0_rsd_rdy),
		.o_vpu0_rsd(ds_vpu0_rsd),
		.o_vpu0_rsd_wr(ds_vpu0_rsd_wr),
		.i_vpu1_rss_rdy(ds_vpu1_rss_rdy),
		.o_vpu1_rss(ds_vpu1_rss),
		.o_vpu1_rss_wr(ds_vpu1_rss_wr),
		.i_vpu1_rsd_rdy(ds_vpu1_rsd_rdy),
		.o_vpu1_rsd(ds_vpu1_rsd),
		.o_vpu1_rsd_wr(ds_vpu1_rsd_wr)
	);

	/* Status FIFO for master port responses */
	vxe_fifo #(
		.DATA_WIDTH(9),
		.DEPTH_POW2(2)
	) ress_m_fifo (
		.clk(clk),
		.nrst(nrst),
		.data_in(m_rss),
		.data_out(m_ds_rss),
		.rd(m_ds_rss_rd),
		.wr(m_rss_wr),
		.in_rdy(m_rss_rdy),
		.out_vld(m_ds_rss_vld)
	);

	/* Data FIFO for master port responses */
	vxe_fifo #(
		.DATA_WIDTH(64),
		.DEPTH_POW2(2)
	) resd_m_fifo (
		.clk(clk),
		.nrst(nrst),
		.data_in(m_rsd),
		.data_out(m_ds_rsd),
		.rd(m_ds_rsd_rd),
		.wr(m_rsd_wr),
		.in_rdy(m_rsd_rdy),
		.out_vld(m_ds_rsd_vld)
	);

	/* Status FIFO for outgoing responses to CU */
	vxe_fifo #(
		.DATA_WIDTH(9),
		.DEPTH_POW2(2)
	) ress_cu_fifo (
		.clk(clk),
		.nrst(nrst),
		.data_in(ds_cu_rss),
		.data_out(cu_rss),
		.rd(cu_rss_rd),
		.wr(ds_cu_rss_wr),
		.in_rdy(ds_cu_rss_rdy),
		.out_vld(cu_rss_vld)
	);

	/* Data FIFO for outgoing responses to CU */
	vxe_fifo #(
		.DATA_WIDTH(64),
		.DEPTH_POW2(2)
	) resd_cu_fifo (
		.clk(clk),
		.nrst(nrst),
		.data_in(ds_cu_rsd),
		.data_out(cu_rsd),
		.rd(cu_rsd_rd),
		.wr(ds_cu_rsd_wr),
		.in_rdy(ds_cu_rsd_rdy),
		.out_vld(cu_rsd_vld)
	);

	/* Status FIFO for outgoing responses to VPU0 */
	vxe_fifo #(
		.DATA_WIDTH(9),
		.DEPTH_POW2(2)
	) ress_vpu0_fifo (
		.clk(clk),
		.nrst(nrst),
		.data_in(ds_vpu0_rss),
		.data_out(vpu0_rss),
		.rd(vpu0_rss_rd),
		.wr(ds_vpu0_rss_wr),
		.in_rdy(ds_vpu0_rss_rdy),
		.out_vld(vpu0_rss_vld)
	);

	/* Data FIFO for outgoing responses to VPU0 */
	vxe_fifo #(
		.DATA_WIDTH(64),
		.DEPTH_POW2(2)
	) resd_vpu0_fifo (
		.clk(clk),
		.nrst(nrst),
		.data_in(ds_vpu0_rsd),
		.data_out(vpu0_rsd),
		.rd(vpu0_rsd_rd),
		.wr(ds_vpu0_rsd_wr),
		.in_rdy(ds_vpu0_rsd_rdy),
		.out_vld(vpu0_rsd_vld)
	);

	/* Status FIFO for outgoing responses to VPU1 */
	vxe_fifo #(
		.DATA_WIDTH(9),
		.DEPTH_POW2(2)
	) ress_vpu1_fifo (
		.clk(clk),
		.nrst(nrst),
		.data_in(ds_vpu1_rss),
		.data_out(vpu1_rss),
		.rd(vpu1_rss_rd),
		.wr(ds_vpu1_rss_wr),
		.in_rdy(ds_vpu1_rss_rdy),
		.out_vld(vpu1_rss_vld)
	);

	/* Data FIFO for outgoing responses to VPU1 */
	vxe_fifo #(
		.DATA_WIDTH(64),
		.DEPTH_POW2(2)
	) resd_vpu1_fifo (
		.clk(clk),
		.nrst(nrst),
		.data_in(ds_vpu1_rsd),
		.data_out(vpu1_rsd),
		.rd(vpu1_rsd_rd),
		.wr(ds_vpu1_rsd_wr),
		.in_rdy(ds_vpu1_rsd_rdy),
		.out_vld(vpu1_rsd_vld)
	);


endmodule /* tb_vxe_mem_hub_mas_ds */
