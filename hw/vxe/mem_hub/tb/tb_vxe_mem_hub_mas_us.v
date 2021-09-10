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
 * Testbench for VxE master port upstream traffic control
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_mem_hub_mas_us();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;
	/* Incoming request from CU */
	wire		cu_rqa_rdy;
	reg [43:0]	cu_rqa;
	reg		cu_rqa_wr;
	/* Incoming request from VPU0 */
	wire		vpu0_rqa_rdy;
	reg [43:0]	vpu0_rqa;
	reg		vpu0_rqa_wr;
	wire		vpu0_rqd_rdy;
	reg [71:0]	vpu0_rqd;
	reg		vpu0_rqd_wr;
	/* Incoming request from VPU1 */
	wire		vpu1_rqa_rdy;
	reg [43:0]	vpu1_rqa;
	reg		vpu1_rqa_wr;
	wire		vpu1_rqd_rdy;
	reg [71:0]	vpu1_rqd;
	reg		vpu1_rqd_wr;
	/* Outgoing request to master port */
	wire		m_rqa_vld;
	wire [43:0]	m_rqa;
	reg		m_rqa_rd;
	wire		m_rqd_vld;
	wire [71:0]	m_rqd;
	reg		m_rqd_rd;

	/** FIFO connection wires **/

	/* CU -> Upstream */
	wire		cu_us_rqa_vld;
	wire [43:0]	cu_us_rqa;
	wire		cu_us_rqa_rd;
	/* VPU0 -> Upstream */
	wire		vpu0_us_rqa_vld;
	wire [43:0]	vpu0_us_rqa;
	wire		vpu0_us_rqa_rd;
	wire		vpu0_us_rqd_vld;
	wire [71:0]	vpu0_us_rqd;
	wire		vpu0_us_rqd_rd;
	/* VPU1 -> Upstream */
	wire		vpu1_us_rqa_vld;
	wire [43:0]	vpu1_us_rqa;
	wire		vpu1_us_rqa_rd;
	wire		vpu1_us_rqd_vld;
	wire [71:0]	vpu1_us_rqd;
	wire		vpu1_us_rqd_rd;
	/* Upstream -> Master port */
	wire		us_m_rqa_rdy;
	wire [43:0]	us_m_rqa;
	wire		us_m_rqa_wr;
	wire		us_m_rqd_rdy;
	wire [71:0]	us_m_rqd;
	wire		us_m_rqd_wr;

	/** Traffic control **/
	reg		gen_cu_rqa;
	reg		gen_cu_rst;
	reg		gen_vpu0_rqa;
	reg		gen_vpu0_rqd;
	reg		gen_vpu0_rst;
	reg		gen_vpu1_rqa;
	reg		gen_vpu1_rqd;
	reg		gen_vpu1_rst;

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


	task wait_pos_clk64;
	begin
		wait_pos_clk32;
		wait_pos_clk32;
	end
	endtask


	task wait_pos_clk128;
	begin
		wait_pos_clk64;
		wait_pos_clk64;
	end
	endtask


	/* Reset CU traffic generator to initial state */
	task gen_cu_reset;
	begin
		@(posedge clk) gen_cu_rst <= 1'b1;
		@(posedge clk) gen_cu_rst <= 1'b0;
	end
	endtask


	/* Reset VPU0 traffic generator to initial state */
	task gen_vpu0_reset;
	begin
		@(posedge clk) gen_vpu0_rst <= 1'b1;
		@(posedge clk) gen_vpu0_rst <= 1'b0;
	end
	endtask


	/* Reset VPU1 traffic generator to initial state */
	task gen_vpu1_reset;
	begin
		@(posedge clk) gen_vpu1_rst <= 1'b1;
		@(posedge clk) gen_vpu1_rst <= 1'b0;
	end
	endtask


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_mem_hub_mas_us);

		clk = 1;
		nrst = 0;

		gen_cu_rqa = 1'b0;
		gen_cu_rst = 1'b0;
		gen_vpu0_rqa = 1'b0;
		gen_vpu0_rqd = 1'b0;
		gen_vpu0_rst = 1'b0;
		gen_vpu1_rqa = 1'b0;
		gen_vpu1_rqd = 1'b0;
		gen_vpu1_rst = 1'b0;

		m_rqa_rd = 1'b0;
		m_rqd_rd = 1'b0;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		nrst = 1;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		/*********************************/


		/* Test - CU sends read requests */
		@(posedge clk)
		begin
			test_name <= "Test_1";
			m_rqa_rd <= 1'b0;
			m_rqd_rd <= 1'b0;
			gen_cu_rqa <= 1'b1;
		end

		wait_pos_clk32;

		@(posedge clk)
		begin
			m_rqa_rd <= 1'b1;
			m_rqd_rd <= 1'b1;
		end

		wait_pos_clk8;

		@(posedge clk)
		begin
			gen_cu_rqa <= 1'b0;
		end

		gen_cu_reset;


		wait_pos_clk32;


		/* Test - VPU0 sends read requests */
		@(posedge clk)
		begin
			test_name <= "Test_2";
			m_rqa_rd <= 1'b0;
			m_rqd_rd <= 1'b0;
			gen_vpu0_rqa <= 1'b1;
		end

		wait_pos_clk32;

		@(posedge clk)
		begin
			m_rqa_rd <= 1'b1;
			m_rqd_rd <= 1'b1;
		end

		wait_pos_clk8;

		@(posedge clk)
		begin
			gen_vpu0_rqa <= 1'b0;
		end

		gen_vpu0_reset;


		wait_pos_clk32;


		/* Test - VPU1 sends read requests */
		@(posedge clk)
		begin
			test_name <= "Test_3";
			m_rqa_rd <= 1'b0;
			m_rqd_rd <= 1'b0;
			gen_vpu1_rqa <= 1'b1;
		end

		wait_pos_clk32;

		@(posedge clk)
		begin
			m_rqa_rd <= 1'b1;
			m_rqd_rd <= 1'b1;
		end

		wait_pos_clk8;

		@(posedge clk)
		begin
			gen_vpu1_rqa <= 1'b0;
		end

		gen_vpu1_reset;


		wait_pos_clk32;


		/* Test - VPU0 sends write requests */
		@(posedge clk)
		begin
			test_name <= "Test_4";
			m_rqa_rd <= 1'b0;
			m_rqd_rd <= 1'b0;
			gen_vpu0_rqa <= 1'b1;
			gen_vpu0_rqd <= 1'b1;
		end

		wait_pos_clk32;

		@(posedge clk)
		begin
			m_rqa_rd <= 1'b1;
			m_rqd_rd <= 1'b1;
		end

		wait_pos_clk8;

		@(posedge clk)
		begin
			gen_vpu0_rqa <= 1'b0;
			gen_vpu0_rqd <= 1'b0;
		end

		gen_vpu0_reset;


		wait_pos_clk32;


		/* Test - VPU1 sends write requests */
		@(posedge clk)
		begin
			test_name <= "Test_5";
			m_rqa_rd <= 1'b0;
			m_rqd_rd <= 1'b0;
			gen_vpu1_rqa <= 1'b1;
			gen_vpu1_rqd <= 1'b1;
		end

		wait_pos_clk32;

		@(posedge clk)
		begin
			m_rqa_rd <= 1'b1;
			m_rqd_rd <= 1'b1;
		end

		wait_pos_clk8;

		@(posedge clk)
		begin
			gen_vpu1_rqa <= 1'b0;
			gen_vpu1_rqd <= 1'b0;
		end

		gen_vpu1_reset;


		wait_pos_clk32;


		/* Test - CU and VPU0 send read requests */
		@(posedge clk)
		begin
			test_name <= "Test_6";
			m_rqa_rd <= 1'b0;
			m_rqd_rd <= 1'b0;
			gen_cu_rqa <= 1'b1;
			gen_vpu0_rqa <= 1'b1;
		end

		wait_pos_clk32;

		@(posedge clk)
		begin
			m_rqa_rd <= 1'b1;
			m_rqd_rd <= 1'b1;
		end

		wait_pos_clk16;

		@(posedge clk)
		begin
			gen_cu_rqa <= 1'b0;
			gen_vpu0_rqa <= 1'b0;
		end

		gen_cu_reset;
		gen_vpu0_reset;


		wait_pos_clk32;


		/* Test - CU, VPU0 and VPU1 send read requests */
		@(posedge clk)
		begin
			test_name <= "Test_7";
			m_rqa_rd <= 1'b0;
			m_rqd_rd <= 1'b0;
			gen_cu_rqa <= 1'b1;
			gen_vpu0_rqa <= 1'b1;
			gen_vpu1_rqa <= 1'b1;
		end

		wait_pos_clk32;

		@(posedge clk)
		begin
			m_rqa_rd <= 1'b1;
			m_rqd_rd <= 1'b1;
		end

		wait_pos_clk16;

		@(posedge clk)
		begin
			gen_cu_rqa <= 1'b0;
			gen_vpu0_rqa <= 1'b0;
			gen_vpu1_rqa <= 1'b0;
		end

		gen_cu_reset;
		gen_vpu0_reset;
		gen_vpu1_reset;


		wait_pos_clk32;


		/* Test - VPU0 and VPU1 send write requests */
		@(posedge clk)
		begin
			test_name <= "Test_8";
			m_rqa_rd <= 1'b0;
			m_rqd_rd <= 1'b0;
			gen_vpu0_rqa <= 1'b1;
			gen_vpu0_rqd <= 1'b1;
			gen_vpu1_rqa <= 1'b1;
			gen_vpu1_rqd <= 1'b1;
		end

		wait_pos_clk32;

		@(posedge clk)
		begin
			m_rqa_rd <= 1'b1;
			m_rqd_rd <= 1'b1;
		end

		wait_pos_clk32;

		@(posedge clk)
		begin
			gen_vpu0_rqa <= 1'b0;
			gen_vpu0_rqd <= 1'b0;
			gen_vpu1_rqa <= 1'b0;
			gen_vpu1_rqd <= 1'b0;
		end

		gen_vpu0_reset;
		gen_vpu1_reset;


		wait_pos_clk32;


		/* Test - CU sends read and VPU0 and VPU1 send write requests */
		@(posedge clk)
		begin
			test_name <= "Test_9";
			m_rqa_rd <= 1'b0;
			m_rqd_rd <= 1'b0;
			gen_cu_rqa <= 1'b1;
			gen_vpu0_rqa <= 1'b1;
			gen_vpu0_rqd <= 1'b1;
			gen_vpu1_rqa <= 1'b1;
			gen_vpu1_rqd <= 1'b1;
		end

		wait_pos_clk32;

		@(posedge clk)
		begin
			m_rqa_rd <= 1'b1;
			m_rqd_rd <= 1'b1;
		end

		wait_pos_clk32;

		@(posedge clk)
		begin
			gen_cu_rqa <= 1'b0;
			gen_vpu0_rqa <= 1'b0;
			gen_vpu0_rqd <= 1'b0;
			gen_vpu1_rqa <= 1'b0;
			gen_vpu1_rqd <= 1'b0;
		end

		gen_cu_reset;
		gen_vpu0_reset;
		gen_vpu1_reset;


		wait_pos_clk32;


		/* Test - VPU0 sends read then write requests.
		 *        VPU1 sends write requests.
		 */
		@(posedge clk)
		begin
			test_name <= "Test_A";
			m_rqa_rd <= 1'b0;
			m_rqd_rd <= 1'b0;
			gen_vpu0_rqa <= 1'b1;
			gen_vpu1_rqa <= 1'b1;
			gen_vpu1_rqd <= 1'b1;
		end

		wait_pos_clk4;

		@(posedge clk) gen_vpu0_rqd <= 1'b1;	/* Enable data for VPU0 */

		wait_pos_clk32;

		@(posedge clk)
		begin
			m_rqa_rd <= 1'b1;
			m_rqd_rd <= 1'b1;
		end

		wait_pos_clk32;

		@(posedge clk)
		begin
			gen_vpu0_rqa <= 1'b0;
			gen_vpu0_rqd <= 1'b0;
			gen_vpu1_rqa <= 1'b0;
			gen_vpu1_rqd <= 1'b0;
		end

		gen_vpu0_reset;
		gen_vpu1_reset;


		wait_pos_clk32;


		#500 $finish;
	end


	/* Master port upstream instance */
	vxe_mem_hub_mas_us mas_us(
		.clk(clk),
		.nrst(nrst),
		/* Incoming request from CU */
		.i_cu_rqa_vld(cu_us_rqa_vld),
		.i_cu_rqa(cu_us_rqa),
		.o_cu_rqa_rd(cu_us_rqa_rd),
		/* Incoming request from VPU0 */
		.i_vpu0_rqa_vld(vpu0_us_rqa_vld),
		.i_vpu0_rqa(vpu0_us_rqa),
		.o_vpu0_rqa_rd(vpu0_us_rqa_rd),
		.i_vpu0_rqd_vld(vpu0_us_rqd_vld),
		.i_vpu0_rqd(vpu0_us_rqd),
		.o_vpu0_rqd_rd(vpu0_us_rqd_rd),
		/* Incoming request from VPU1 */
		.i_vpu1_rqa_vld(vpu1_us_rqa_vld),
		.i_vpu1_rqa(vpu1_us_rqa),
		.o_vpu1_rqa_rd(vpu1_us_rqa_rd),
		.i_vpu1_rqd_vld(vpu1_us_rqd_vld),
		.i_vpu1_rqd(vpu1_us_rqd),
		.o_vpu1_rqd_rd(vpu1_us_rqd_rd),
		/* Outgoing request to master port */
		.i_m_rqa_rdy(us_m_rqa_rdy),
		.o_m_rqa(us_m_rqa),
		.o_m_rqa_wr(us_m_rqa_wr),
		.i_m_rqd_rdy(us_m_rqd_rdy),
		.o_m_rqd(us_m_rqd),
		.o_m_rqd_wr(us_m_rqd_wr)
	);


	/* Address FIFO for CU requests */
	vxe_fifo #(
		.DATA_WIDTH(44),
		.DEPTH_POW2(2)
	) reqa_cu_fifo (
		.clk(clk),
		.nrst(nrst),
		.data_in(cu_rqa),
		.data_out(cu_us_rqa),
		.rd(cu_us_rqa_rd),
		.wr(cu_rqa_wr),
		.in_rdy(cu_rqa_rdy),
		.out_vld(cu_us_rqa_vld)
	);

	/* Address FIFO for VPU0 requests */
	vxe_fifo #(
		.DATA_WIDTH(44),
		.DEPTH_POW2(2)
	) reqa_vpu0_fifo (
		.clk(clk),
		.nrst(nrst),
		.data_in(vpu0_rqa),
		.data_out(vpu0_us_rqa),
		.rd(vpu0_us_rqa_rd),
		.wr(vpu0_rqa_wr),
		.in_rdy(vpu0_rqa_rdy),
		.out_vld(vpu0_us_rqa_vld)
	);

	/* Data FIFO for VPU0 requests */
	vxe_fifo #(
		.DATA_WIDTH(72),
		.DEPTH_POW2(2)
	) reqd_vpu0_fifo (
		.clk(clk),
		.nrst(nrst),
		.data_in(vpu0_rqd),
		.data_out(vpu0_us_rqd),
		.rd(vpu0_us_rqd_rd),
		.wr(vpu0_rqd_wr),
		.in_rdy(vpu0_rqd_rdy),
		.out_vld(vpu0_us_rqd_vld)
	);

	/* Address FIFO for VPU1 requests */
	vxe_fifo #(
		.DATA_WIDTH(44),
		.DEPTH_POW2(2)
	) reqa_vpu1_fifo (
		.clk(clk),
		.nrst(nrst),
		.data_in(vpu1_rqa),
		.data_out(vpu1_us_rqa),
		.rd(vpu1_us_rqa_rd),
		.wr(vpu1_rqa_wr),
		.in_rdy(vpu1_rqa_rdy),
		.out_vld(vpu1_us_rqa_vld)
	);

	/* Data FIFO for VPU1 requests */
	vxe_fifo #(
		.DATA_WIDTH(72),
		.DEPTH_POW2(2)
	) reqd_vpu1_fifo (
		.clk(clk),
		.nrst(nrst),
		.data_in(vpu1_rqd),
		.data_out(vpu1_us_rqd),
		.rd(vpu1_us_rqd_rd),
		.wr(vpu1_rqd_wr),
		.in_rdy(vpu1_rqd_rdy),
		.out_vld(vpu1_us_rqd_vld)
	);

	/* Address FIFO for outgoing requests to master port */
	vxe_fifo #(
		.DATA_WIDTH(44),
		.DEPTH_POW2(2)
	) reqa_mas_fifo (
		.clk(clk),
		.nrst(nrst),
		.data_in(us_m_rqa),
		.data_out(m_rqa),
		.rd(m_rqa_rd),
		.wr(us_m_rqa_wr),
		.in_rdy(us_m_rqa_rdy),
		.out_vld(m_rqa_vld)
	);

	/* Data FIFO for outgoing requests to master port */
	vxe_fifo #(
		.DATA_WIDTH(72),
		.DEPTH_POW2(2)
	) reqd_mas_fifo (
		.clk(clk),
		.nrst(nrst),
		.data_in(us_m_rqd),
		.data_out(m_rqd),
		.rd(m_rqd_rd),
		.wr(us_m_rqd_wr),
		.in_rdy(us_m_rqd_rdy),
		.out_vld(m_rqd_vld)
	);


	/** Traffic generators **/

	/* CU traffic */
	reg [36:0]	gen_cu_rqa_val;
	reg		gen_cu_rqa_act;
	always @(posedge clk or negedge nrst)
	begin
		if(!nrst)
		begin
			cu_rqa_wr <= 1'b0;
			gen_cu_rqa_val <= 37'b1;
			gen_cu_rqa_act <= 1'b0;
		end
		else
		begin
			if(gen_cu_rst)
			begin
				cu_rqa_wr <= 1'b0;
				gen_cu_rqa_val <= 37'b1;
				gen_cu_rqa_act <= 1'b0;
			end
			else if(gen_cu_rqa)
			begin
				if(!gen_cu_rqa_act)
				begin
					cu_rqa <= { 6'b111100, 1'b1, gen_cu_rqa_val };
					cu_rqa_wr <= 1'b1;
					gen_cu_rqa_val <= gen_cu_rqa_val + 1'b1;
					gen_cu_rqa_act <= 1'b1;
				end
				else if(cu_rqa_rdy)
				begin
					cu_rqa <= { 6'b111100, 1'b1, gen_cu_rqa_val };
					gen_cu_rqa_val <= gen_cu_rqa_val + 1'b1;
				end
			end
			else
			begin
				cu_rqa_wr <= 1'b0;
				gen_cu_rqa_act <= 1'b0;
			end
		end
	end


	/* VPU0 traffic */
	/* Address */
	reg [36:0]	gen_vpu0_rqa_val;
	reg		gen_vpu0_rqa_act;
	always @(posedge clk or negedge nrst)
	begin
		if(!nrst)
		begin
			vpu0_rqa_wr <= 1'b0;
			gen_vpu0_rqa_val <= 37'b1;
			gen_vpu0_rqa_act <= 1'b0;
		end
		else
		begin
			if(gen_vpu0_rst)
			begin
				vpu0_rqa_wr <= 1'b0;
				gen_vpu0_rqa_val <= 37'b1;
				gen_vpu0_rqa_act <= 1'b0;
			end
			else if(gen_vpu0_rqa)
			begin
				if(!gen_vpu0_rqa_act)
				begin
					vpu0_rqa <= { 6'b111101, ~gen_vpu0_rqd, gen_vpu0_rqa_val };
					vpu0_rqa_wr <= 1'b1;
					gen_vpu0_rqa_val <= gen_vpu0_rqa_val + 1'b1;
					gen_vpu0_rqa_act <= 1'b1;
				end
				else if(vpu0_rqa_rdy)
				begin
					vpu0_rqa <= { 6'b111101, ~gen_vpu0_rqd, gen_vpu0_rqa_val };
					gen_vpu0_rqa_val <= gen_vpu0_rqa_val + 1'b1;
				end
			end
			else
			begin
				vpu0_rqa_wr <= 1'b0;
				gen_vpu0_rqa_act <= 1'b0;
			end
		end
	end

	/* Data */
	reg [71:0]	gen_vpu0_rqd_val;
	reg		gen_vpu0_rqd_act;
	always @(posedge clk or negedge nrst)
	begin
		if(!nrst)
		begin
			vpu0_rqd_wr <= 1'b0;
			gen_vpu0_rqd_val <= { 8'b11110100, 64'b1 };
			gen_vpu0_rqd_act <= 1'b0;
		end
		else
		begin
			if(gen_vpu0_rst)
			begin
				vpu0_rqd_wr <= 1'b0;
				gen_vpu0_rqd_val <= { 8'b11110100, 64'b1 };
				gen_vpu0_rqd_act <= 1'b0;
			end
			else if(gen_vpu0_rqd)
			begin
				if(!gen_vpu0_rqd_act)
				begin
					vpu0_rqd <= gen_vpu0_rqd_val;
					vpu0_rqd_wr <= 1'b1;
					gen_vpu0_rqd_val <= gen_vpu0_rqd_val + 1'b1;
					gen_vpu0_rqd_act <= 1'b1;
				end
				else if(vpu0_rqd_rdy)
				begin
					vpu0_rqd <= gen_vpu0_rqd_val;
					gen_vpu0_rqd_val <= gen_vpu0_rqd_val + 1'b1;
				end
			end
			else
			begin
				vpu0_rqd_wr <= 1'b0;
				gen_vpu0_rqd_act <= 1'b0;
			end
		end
	end


	/* VPU1 traffic */
	/* Address */
	reg [36:0]	gen_vpu1_rqa_val;
	reg		gen_vpu1_rqa_act;
	always @(posedge clk or negedge nrst)
	begin
		if(!nrst)
		begin
			vpu1_rqa_wr <= 1'b0;
			gen_vpu1_rqa_val <= 37'b1;
			gen_vpu1_rqa_act <= 1'b0;
		end
		else
		begin
			if(gen_vpu1_rst)
			begin
				vpu1_rqa_wr <= 1'b0;
				gen_vpu1_rqa_val <= 37'b1;
				gen_vpu1_rqa_act <= 1'b0;
			end
			else if(gen_vpu1_rqa)
			begin
				if(!gen_vpu1_rqa_act)
				begin
					vpu1_rqa <= { 6'b111110, ~gen_vpu1_rqd, gen_vpu1_rqa_val };
					vpu1_rqa_wr <= 1'b1;
					gen_vpu1_rqa_val <= gen_vpu1_rqa_val + 1'b1;
					gen_vpu1_rqa_act <= 1'b1;
				end
				else if(vpu1_rqa_rdy)
				begin
					vpu1_rqa <= { 6'b111110, ~gen_vpu1_rqd, gen_vpu1_rqa_val };
					gen_vpu1_rqa_val <= gen_vpu1_rqa_val + 1'b1;
				end
			end
			else
			begin
				vpu1_rqa_wr <= 1'b0;
				gen_vpu1_rqa_act <= 1'b0;
			end
		end
	end

	/* Data */
	reg [71:0]	gen_vpu1_rqd_val;
	reg		gen_vpu1_rqd_act;
	always @(posedge clk or negedge nrst)
	begin
		if(!nrst)
		begin
			vpu1_rqd_wr <= 1'b0;
			gen_vpu1_rqd_val <= { 8'b11111000, 64'b1 };
			gen_vpu1_rqd_act <= 1'b0;
		end
		else
		begin
			if(gen_vpu1_rst)
			begin
				vpu1_rqd_wr <= 1'b0;
				gen_vpu1_rqd_val <= { 8'b11111000, 64'b1 };
				gen_vpu1_rqd_act <= 1'b0;
			end
			else if(gen_vpu1_rqd)
			begin
				if(!gen_vpu1_rqd_act)
				begin
					vpu1_rqd <= gen_vpu1_rqd_val;
					vpu1_rqd_wr <= 1'b1;
					gen_vpu1_rqd_val <= gen_vpu1_rqd_val + 1'b1;
					gen_vpu1_rqd_act <= 1'b1;
				end
				else if(vpu1_rqd_rdy)
				begin
					vpu1_rqd <= gen_vpu1_rqd_val;
					gen_vpu1_rqd_val <= gen_vpu1_rqd_val + 1'b1;
				end
			end
			else
			begin
				vpu1_rqd_wr <= 1'b0;
				gen_vpu1_rqd_act <= 1'b0;
			end
		end
	end


endmodule /* tb_vxe_mem_hub_mas_us */
