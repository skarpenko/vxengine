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
 * Testbench for VxE VPU vector address generator unit
 */


`ifndef TRACE_FILE
`define TRACE_FILE "trace.vcd"
`endif


module tb_vxe_vpu_prod_eu_agen();
	localparam HCLK = 5;
	localparam PCLK = 2*HCLK;	/* Clock period */

	reg		clk;
	reg		nrst;
	/* Vector base and length */
	reg [37:0]	vaddr;
	reg [19:0]	vlen;
	/* Control interface */
	reg		latch;
	reg		incr;
	/* Generated address and word enable mask */
	wire		valid;
	wire [36:0]	addr;
	wire [1:0]	we_mask;

	/** Testbench specific **/
	reg [0:55]	test_name;	/* Test name, for ex.: Test_01 */


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


	initial
	begin
		/* Set tracing */
		$dumpfile(`TRACE_FILE);
		$dumpvars(0, tb_vxe_vpu_prod_eu_agen);

		clk = 1'b1;
		nrst = 1'b0;

		latch <= 1'b0;
		incr <= 1'b0;

		#(10*PCLK) nrst = 1'b1;

		wait_pos_clk(1);
		/***********************************************************/

		/*** Test 01 - One element vector ****/
		@(posedge clk) test_name <= "Test_01";

		@(posedge clk)
		begin
			vaddr <= 38'h00100;
			vlen <= 20'h00001;
			latch <= 1'b1;
		end
		@(posedge clk) latch <= 1'b0;

		/* Get value once */
		@(posedge clk) incr <= 1'b1;
		@(posedge clk) incr <= 1'b0;

		wait_pos_clk(5);


		/*** Test 02 - One element vector, unaligned ****/
		@(posedge clk) test_name <= "Test_02";

		@(posedge clk)
		begin
			vaddr <= 38'h00101;
			vlen <= 20'h00001;
			latch <= 1'b1;
		end
		@(posedge clk) latch <= 1'b0;

		/* Get value once */
		@(posedge clk) incr <= 1'b1;
		@(posedge clk) incr <= 1'b0;

		wait_pos_clk(5);


		/*** Test 03 - Suspend and resume ****/
		@(posedge clk) test_name <= "Test_03";

		@(posedge clk)
		begin
			vaddr <= 38'h00100;
			vlen <= 20'h00008;
			latch <= 1'b1;
		end
		@(posedge clk) latch <= 1'b0;

		/* Get value once */
		@(posedge clk) incr <= 1'b1;
		@(posedge clk) incr <= 1'b0;

		/* Sequential read */
		@(posedge clk) incr <= 1'b1;
		@(posedge clk);
		@(posedge clk);
/*		@(posedge clk);*/
		@(posedge clk) incr <= 1'b0;

		wait_pos_clk(5);


		/*** Test 04 - Base address is not aligned ****/
		@(posedge clk) test_name <= "Test_04";

		@(posedge clk)
		begin
			vaddr <= 38'h00101;
			vlen <= 20'h00007;
			latch <= 1'b1;
		end
		@(posedge clk) latch <= 1'b0;

		/* Sequential read */
		@(posedge clk) incr <= 1'b1;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk) incr <= 1'b0;

		wait_pos_clk(5);


		/*** Test 05 - Length is not aligned ****/
		@(posedge clk) test_name <= "Test_05";

		@(posedge clk)
		begin
			vaddr <= 38'h00100;
			vlen <= 20'h00009;
			latch <= 1'b1;
		end
		@(posedge clk) latch <= 1'b0;

		/* Sequential read */
		@(posedge clk) incr <= 1'b1;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk) incr <= 1'b0;

		wait_pos_clk(5);


		/*** Test 06 - Address and length are not aligned ****/
		@(posedge clk) test_name <= "Test_06";

		@(posedge clk)
		begin
			vaddr <= 38'h00101;
			vlen <= 20'h00008;
			latch <= 1'b1;
		end
		@(posedge clk) latch <= 1'b0;

		/* Sequential read */
		@(posedge clk) incr <= 1'b1;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk) incr <= 1'b0;

		wait_pos_clk(5);


		#500 $finish;
	end


	/* Vector address generator */
	vxe_vpu_prod_eu_agen vaddr_gen(
		.clk(clk),
		.nrst(nrst),
		/* Vector base and length */
		.i_vaddr(vaddr),
		.i_vlen(vlen),
		/* Control interface */
		.i_latch(latch),
		.i_incr(incr),
		/* Generated address and word enable mask */
		.o_valid(valid),
		.o_addr(addr),
		.o_we_mask(we_mask)
	);


endmodule /* tb_vxe_vpu_prod_eu_agen */
