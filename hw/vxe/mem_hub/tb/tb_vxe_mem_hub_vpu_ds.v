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
 * Testbench for VxE VPU downstream traffic control
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_mem_hub_vpu_ds();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;
	/* Incoming response on Master 0 */
	wire		m0_rss_rdy;
	reg [8:0]	m0_rss;
	reg		m0_rss_wr;
	wire		m0_rsd_rdy;
	reg [63:0]	m0_rsd;
	reg		m0_rsd_wr;
	/* Incoming response on Master 1 */
	wire		m1_rss_rdy;
	reg [8:0]	m1_rss;
	reg		m1_rss_wr;
	wire		m1_rsd_rdy;
	reg [63:0]	m1_rsd;
	reg		m1_rsd_wr;
	/* Outgoing response */
	wire		vpu_rss_vld;
	wire [8:0]	vpu_rss;
	reg		vpu_rss_rd;
	wire		vpu_rsd_vld;
	wire [63:0]	vpu_rsd;
	reg		vpu_rsd_rd;


	/** FIFO connection wires **/

	/* Master port 0 -> Downstream */
	wire		m0_ds_rss_vld;
	wire [8:0]	m0_ds_rss;
	wire		m0_ds_rss_rd;
	wire		m0_ds_rsd_vld;
	wire [63:0]	m0_ds_rsd;
	wire		m0_ds_rsd_rd;
	/* Master port 1 -> Downstream */
	wire		m1_ds_rss_vld;
	wire [8:0]	m1_ds_rss;
	wire		m1_ds_rss_rd;
	wire		m1_ds_rsd_vld;
	wire [63:0]	m1_ds_rsd;
	wire		m1_ds_rsd_rd;
	/* Downstream -> VPU */
	wire		ds_vpu_rss_rdy;
	wire [8:0]	ds_vpu_rss;
	wire		ds_vpu_rss_wr;
	wire		ds_vpu_rsd_rdy;
	wire [63:0]	ds_vpu_rsd;
	wire		ds_vpu_rsd_wr;

	/** Traffic control **/
	reg		gen_m0_rss;
	reg		gen_m0_rsd;
	reg		gen_m0_rst;
	reg		gen_m1_rss;
	reg		gen_m1_rsd;
	reg		gen_m1_rst;

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


	/* Reset master port 0 traffic generator to initial state */
	task gen_m0_reset;
	begin
		@(posedge clk) gen_m0_rst <= 1'b1;
		@(posedge clk) gen_m0_rst <= 1'b0;
	end
	endtask


	/* Reset master port 1 traffic generator to initial state */
	task gen_m1_reset;
	begin
		@(posedge clk) gen_m1_rst <= 1'b1;
		@(posedge clk) gen_m1_rst <= 1'b0;
	end
	endtask


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_mem_hub_vpu_ds);

		clk = 1;
		nrst = 0;

		gen_m0_rss = 1'b0;
		gen_m0_rsd = 1'b0;
		gen_m0_rst = 1'b0;
		gen_m1_rss = 1'b0;
		gen_m1_rsd = 1'b0;
		gen_m1_rst = 1'b0;

		vpu_rss_rd = 1'b0;
		vpu_rsd_rd = 1'b0;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		nrst = 1;

		wait_pos_clk();
		wait_pos_clk();
		wait_pos_clk();

		/*********************************/


		/* Test - M0 and M1 send read responses */
		@(posedge clk)
		begin
			test_name <= "Test_1";
			vpu_rss_rd <= 1'b0;
			vpu_rsd_rd <= 1'b0;
			gen_m0_rss <= 1'b1;
			gen_m0_rsd <= 1'b1;
			gen_m1_rss <= 1'b1;
			gen_m1_rsd <= 1'b1;
		end

		wait_pos_clk16;

		@(posedge clk)
		begin
			vpu_rss_rd <= 1'b1;
			vpu_rsd_rd <= 1'b1;
		end

		wait_pos_clk8;

		@(posedge clk)
		begin
			gen_m0_rss <= 1'b0;
			gen_m0_rsd <= 1'b0;
			gen_m1_rss <= 1'b0;
			gen_m1_rsd <= 1'b0;
		end

		gen_m0_reset;
		gen_m1_reset;


		wait_pos_clk32;


		/* Test - M0 and M1 send write responses */
		@(posedge clk)
		begin
			test_name <= "Test_2";
			vpu_rss_rd <= 1'b0;
			vpu_rsd_rd <= 1'b0;
			gen_m0_rss <= 1'b1;
			gen_m0_rsd <= 1'b0;
			gen_m1_rss <= 1'b1;
			gen_m1_rsd <= 1'b0;
		end

		wait_pos_clk16;

		@(posedge clk)
		begin
			vpu_rss_rd <= 1'b1;
			vpu_rsd_rd <= 1'b1;
		end

		wait_pos_clk8;

		@(posedge clk)
		begin
			gen_m0_rss <= 1'b0;
			gen_m0_rsd <= 1'b0;
			gen_m1_rss <= 1'b0;
			gen_m1_rsd <= 1'b0;
		end

		gen_m0_reset;
		gen_m1_reset;


		wait_pos_clk32;


		/* Test - M0 sends read and M1 sends write responses */
		/* Note: returned data won't match with response since the
		 * testbench doesn't force order.
		 */
		@(posedge clk)
		begin
			test_name <= "Test_3";
			vpu_rss_rd <= 1'b0;
			vpu_rsd_rd <= 1'b0;
			gen_m0_rss <= 1'b1;
			gen_m0_rsd <= 1'b1;
			gen_m1_rss <= 1'b1;
			gen_m1_rsd <= 1'b0;
		end

		wait_pos_clk16;

		@(posedge clk)
		begin
			vpu_rss_rd <= 1'b1;
			vpu_rsd_rd <= 1'b1;
		end

		wait_pos_clk8;

		@(posedge clk)
		begin
			gen_m0_rss <= 1'b0;
			gen_m0_rsd <= 1'b0;
			gen_m1_rss <= 1'b0;
			gen_m1_rsd <= 1'b0;
		end

		gen_m0_reset;
		gen_m1_reset;


		wait_pos_clk32;


		/* Test - M0 sends write and M1 sends read responses */
		/* Note: returned data won't match with response since the
		 * testbench doesn't force order.
		 */
		@(posedge clk)
		begin
			test_name <= "Test_4";
			vpu_rss_rd <= 1'b0;
			vpu_rsd_rd <= 1'b0;
			gen_m0_rss <= 1'b1;
			gen_m0_rsd <= 1'b0;
			gen_m1_rss <= 1'b1;
			gen_m1_rsd <= 1'b1;
		end

		wait_pos_clk16;

		@(posedge clk)
		begin
			vpu_rss_rd <= 1'b1;
			vpu_rsd_rd <= 1'b1;
		end

		wait_pos_clk8;

		@(posedge clk)
		begin
			gen_m0_rss <= 1'b0;
			gen_m0_rsd <= 1'b0;
			gen_m1_rss <= 1'b0;
			gen_m1_rsd <= 1'b0;
		end

		gen_m0_reset;
		gen_m1_reset;


		wait_pos_clk32;


		/* Test - M0 sends read responses */
		@(posedge clk)
		begin
			test_name <= "Test_5";
			vpu_rss_rd <= 1'b0;
			vpu_rsd_rd <= 1'b0;
			gen_m0_rss <= 1'b1;
			gen_m0_rsd <= 1'b1;
			gen_m1_rss <= 1'b0;
			gen_m1_rsd <= 1'b0;
		end

		wait_pos_clk16;

		@(posedge clk)
		begin
			vpu_rss_rd <= 1'b1;
			vpu_rsd_rd <= 1'b1;
		end

		wait_pos_clk8;

		@(posedge clk)
		begin
			gen_m0_rss <= 1'b0;
			gen_m0_rsd <= 1'b0;
			gen_m1_rss <= 1'b0;
			gen_m1_rsd <= 1'b0;
		end

		gen_m0_reset;
		gen_m1_reset;


		wait_pos_clk32;


		/* Test - M1 sends read responses */
		@(posedge clk)
		begin
			test_name <= "Test_6";
			vpu_rss_rd <= 1'b0;
			vpu_rsd_rd <= 1'b0;
			gen_m0_rss <= 1'b0;
			gen_m0_rsd <= 1'b0;
			gen_m1_rss <= 1'b1;
			gen_m1_rsd <= 1'b1;
		end

		wait_pos_clk16;

		@(posedge clk)
		begin
			vpu_rss_rd <= 1'b1;
			vpu_rsd_rd <= 1'b1;
		end

		wait_pos_clk8;

		@(posedge clk)
		begin
			gen_m0_rss <= 1'b0;
			gen_m0_rsd <= 1'b0;
			gen_m1_rss <= 1'b0;
			gen_m1_rsd <= 1'b0;
		end

		gen_m0_reset;
		gen_m1_reset;


		#500 $finish;
	end


	/* VPU downstream instance */
	vxe_mem_hub_vpu_ds vpu_ds(
		.clk(clk),
		.nrst(nrst),
		/* Incoming response on Master 0 */
		.i_m0_rss_vld(m0_ds_rss_vld),
		.i_m0_rss(m0_ds_rss),
		.o_m0_rss_rd(m0_ds_rss_rd),
		.i_m0_rsd_vld(m0_ds_rsd_vld),
		.i_m0_rsd(m0_ds_rsd),
		.o_m0_rsd_rd(m0_ds_rsd_rd),
		/* Incoming response on Master 1 */
		.i_m1_rss_vld(m1_ds_rss_vld),
		.i_m1_rss(m1_ds_rss),
		.o_m1_rss_rd(m1_ds_rss_rd),
		.i_m1_rsd_vld(m1_ds_rsd_vld),
		.i_m1_rsd(m1_ds_rsd),
		.o_m1_rsd_rd(m1_ds_rsd_rd),
		/* Outgoing response */
		.i_rss_rdy(ds_vpu_rss_rdy),
		.o_rss(ds_vpu_rss),
		.o_rss_wr(ds_vpu_rss_wr),
		.i_rsd_rdy(ds_vpu_rsd_rdy),
		.o_rsd(ds_vpu_rsd),
		.o_rsd_wr(ds_vpu_rsd_wr)
	);

	/* Status FIFO for master port 0 responses */
	vxe_fifo #(
		.DATA_WIDTH(9),
		.DEPTH_POW2(2)
	) ress_m0_fifo (
		.clk(clk),
		.nrst(nrst),
		.data_in(m0_rss),
		.data_out(m0_ds_rss),
		.rd(m0_ds_rss_rd),
		.wr(m0_rss_wr),
		.in_rdy(m0_rss_rdy),
		.out_vld(m0_ds_rss_vld)
	);

	/* Data FIFO for master port 0 responses */
	vxe_fifo #(
		.DATA_WIDTH(64),
		.DEPTH_POW2(2)
	) resd_m0_fifo (
		.clk(clk),
		.nrst(nrst),
		.data_in(m0_rsd),
		.data_out(m0_ds_rsd),
		.rd(m0_ds_rsd_rd),
		.wr(m0_rsd_wr),
		.in_rdy(m0_rsd_rdy),
		.out_vld(m0_ds_rsd_vld)
	);

	/* Status FIFO for master port 1 responses */
	vxe_fifo #(
		.DATA_WIDTH(9),
		.DEPTH_POW2(2)
	) ress_m1_fifo (
		.clk(clk),
		.nrst(nrst),
		.data_in(m1_rss),
		.data_out(m1_ds_rss),
		.rd(m1_ds_rss_rd),
		.wr(m1_rss_wr),
		.in_rdy(m1_rss_rdy),
		.out_vld(m1_ds_rss_vld)
	);

	/* Data FIFO for master port 1 responses */
	vxe_fifo #(
		.DATA_WIDTH(64),
		.DEPTH_POW2(2)
	) resd_m1_fifo (
		.clk(clk),
		.nrst(nrst),
		.data_in(m1_rsd),
		.data_out(m1_ds_rsd),
		.rd(m1_ds_rsd_rd),
		.wr(m1_rsd_wr),
		.in_rdy(m1_rsd_rdy),
		.out_vld(m1_ds_rsd_vld)
	);

	/* Status FIFO for outgoing responses to VPU */
	vxe_fifo #(
		.DATA_WIDTH(9),
		.DEPTH_POW2(2)
	) ress_vpu_fifo (
		.clk(clk),
		.nrst(nrst),
		.data_in(ds_vpu_rss),
		.data_out(vpu_rss),
		.rd(vpu_rss_rd),
		.wr(ds_vpu_rss_wr),
		.in_rdy(ds_vpu_rss_rdy),
		.out_vld(vpu_rss_vld)
	);

	/* Data FIFO for outgoing responses to VPU */
	vxe_fifo #(
		.DATA_WIDTH(64),
		.DEPTH_POW2(2)
	) resd_vpu_fifo (
		.clk(clk),
		.nrst(nrst),
		.data_in(ds_vpu_rsd),
		.data_out(vpu_rsd),
		.rd(vpu_rsd_rd),
		.wr(ds_vpu_rsd_wr),
		.in_rdy(ds_vpu_rsd_rdy),
		.out_vld(vpu_rsd_vld)
	);


	/** Traffic generators **/

	/* Master port 0 traffic */
	/* Status */
	reg [5:0]	gen_m0_rss_val;
	reg		gen_m0_rss_act;
	always @(posedge clk or negedge nrst)
	begin
		if(!nrst)
		begin
			m0_rss_wr <= 1'b0;
			gen_m0_rss_val <= 6'b1;
			gen_m0_rss_act <= 1'b0;
		end
		else
		begin
			if(gen_m0_rst)
			begin
				m0_rss_wr <= 1'b0;
				gen_m0_rss_val <= 6'b1;
				gen_m0_rss_act <= 1'b0;
			end
			else if(gen_m0_rss)
			begin
				if(!gen_m0_rss_act)
				begin
					m0_rss <= { gen_m0_rss_val, gen_m0_rsd, 2'b00 };
					m0_rss_wr <= 1'b1;
					gen_m0_rss_val <= gen_m0_rss_val + 1'b1;
					gen_m0_rss_act <= 1'b1;
				end
				else if(m0_rss_rdy)
				begin
					m0_rss <= { gen_m0_rss_val, gen_m0_rsd, 2'b00 };
					gen_m0_rss_val <= gen_m0_rss_val + 1'b1;
				end
			end
			else
			begin
				m0_rss_wr <= 1'b0;
				gen_m0_rss_act <= 1'b0;
			end
		end
	end

	/* Data */
	reg [61:0]	gen_m0_rsd_val;
	reg		gen_m0_rsd_act;
	always @(posedge clk or negedge nrst)
	begin
		if(!nrst)
		begin
			m0_rsd_wr <= 1'b0;
			gen_m0_rsd_val <= 61'b1;
			gen_m0_rsd_act <= 1'b0;
		end
		else
		begin
			if(gen_m0_rst)
			begin
				m0_rsd_wr <= 1'b0;
				gen_m0_rsd_val <= 61'b1;
				gen_m0_rsd_act <= 1'b0;
			end
			else if(gen_m0_rsd)
			begin
				if(!gen_m0_rsd_act)
				begin
					m0_rsd <= { gen_m0_rsd_val, 3'b000 };
					m0_rsd_wr <= 1'b1;
					gen_m0_rsd_val <= gen_m0_rsd_val + 1'b1;
					gen_m0_rsd_act <= 1'b1;
				end
				else if(m0_rsd_rdy)
				begin
					m0_rsd <= { gen_m0_rsd_val, 3'b000 };
					gen_m0_rsd_val <= gen_m0_rsd_val + 1'b1;
				end
			end
			else
			begin
				m0_rsd_wr <= 1'b0;
				gen_m0_rsd_act <= 1'b0;
			end
		end
	end


	/* Master port 1 traffic */
	/* Status */
	reg [5:0]	gen_m1_rss_val;
	reg		gen_m1_rss_act;
	always @(posedge clk or negedge nrst)
	begin
		if(!nrst)
		begin
			m1_rss_wr <= 1'b0;
			gen_m1_rss_val <= 6'b1;
			gen_m1_rss_act <= 1'b0;
		end
		else
		begin
			if(gen_m1_rst)
			begin
				m1_rss_wr <= 1'b0;
				gen_m1_rss_val <= 6'b1;
				gen_m1_rss_act <= 1'b0;
			end
			else if(gen_m1_rss)
			begin
				if(!gen_m1_rss_act)
				begin
					m1_rss <= { gen_m1_rss_val, gen_m1_rsd, 2'b01 };
					m1_rss_wr <= 1'b1;
					gen_m1_rss_val <= gen_m1_rss_val + 1'b1;
					gen_m1_rss_act <= 1'b1;
				end
				else if(m1_rss_rdy)
				begin
					m1_rss <= { gen_m1_rss_val, gen_m1_rsd, 2'b01 };
					gen_m1_rss_val <= gen_m1_rss_val + 1'b1;
				end
			end
			else
			begin
				m1_rss_wr <= 1'b0;
				gen_m1_rss_act <= 1'b0;
			end
		end
	end

	/* Data */
	reg [61:0]	gen_m1_rsd_val;
	reg		gen_m1_rsd_act;
	always @(posedge clk or negedge nrst)
	begin
		if(!nrst)
		begin
			m1_rsd_wr <= 1'b0;
			gen_m1_rsd_val <= 61'b1;
			gen_m1_rsd_act <= 1'b0;
		end
		else
		begin
			if(gen_m1_rst)
			begin
				m1_rsd_wr <= 1'b0;
				gen_m1_rsd_val <= 61'b1;
				gen_m1_rsd_act <= 1'b0;
			end
			else if(gen_m1_rsd)
			begin
				if(!gen_m1_rsd_act)
				begin
					m1_rsd <= { gen_m1_rsd_val, 3'b001 };
					m1_rsd_wr <= 1'b1;
					gen_m1_rsd_val <= gen_m1_rsd_val + 1'b1;
					gen_m1_rsd_act <= 1'b1;
				end
				else if(m1_rsd_rdy)
				begin
					m1_rsd <= { gen_m1_rsd_val, 3'b001 };
					gen_m1_rsd_val <= gen_m1_rsd_val + 1'b1;
				end
			end
			else
			begin
				m1_rsd_wr <= 1'b0;
				gen_m1_rsd_act <= 1'b0;
			end
		end
	end


endmodule /* tb_vxe_mem_hub_vpu_ds */
