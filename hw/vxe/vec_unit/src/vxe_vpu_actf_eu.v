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
 * VxE VPU activation function execution unit
 */


/* Activation function execution unit */
module vxe_vpu_actf_eu(
	clk,
	nrst,
	/* Control unit interface */
	i_start,
	o_busy,
	i_leaky,
	i_expd,
	/* Register file interface */
	o_th,
	o_ridx,
	o_wr_en,
	o_data,
	/* Register values */
	i_th0_acc,
	i_th0_en,
	i_th1_acc,
	i_th1_en,
	i_th2_acc,
	i_th2_en,
	i_th3_acc,
	i_th3_en,
	i_th4_acc,
	i_th4_en,
	i_th5_acc,
	i_th5_en,
	i_th6_acc,
	i_th6_en,
	i_th7_acc,
	i_th7_en
);
`include "vxe_vpu_regidx_params.vh"
/* Global signals */
input wire		clk;
input wire		nrst;
/* Control unit interface */
input wire		i_start;
output wire		o_busy;
input wire		i_leaky;
input wire [6:0]	i_expd;
/* Register file interface */
output reg [2:0]	o_th;
output wire [2:0]	o_ridx;
output reg		o_wr_en;
output wire [37:0]	o_data;
/* Register values */
input wire [31:0]	i_th0_acc;
input wire		i_th0_en;
input wire [31:0]	i_th1_acc;
input wire		i_th1_en;
input wire [31:0]	i_th2_acc;
input wire		i_th2_en;
input wire [31:0]	i_th3_acc;
input wire		i_th3_en;
input wire [31:0]	i_th4_acc;
input wire		i_th4_en;
input wire [31:0]	i_th5_acc;
input wire		i_th5_en;
input wire [31:0]	i_th6_acc;
input wire		i_th6_en;
input wire [31:0]	i_th7_acc;
input wire		i_th7_en;


/* ReLU block connections */
reg [31:0]	relu_v;
wire [31:0]	relu_r;
reg		relu_l;
reg [6:0]	relu_e;


/* Outputs */
assign o_ridx = VPU_REG_IDX_ACC;
assign o_data = { 6'h0, relu_r };


/* Enabled threads vector */
wire [7:0] th_en = { i_th7_en, i_th6_en, i_th5_en, i_th4_en,
		i_th3_en, i_th2_en, i_th1_en, i_th0_en };


/* Stages completion */
wire stg0_done = ~(|th_en[7:0]);
wire stg1_done = ~(|th_en[7:1]);
wire stg2_done = ~(|th_en[7:2]);
wire stg3_done = ~(|th_en[7:3]);
wire stg4_done = ~(|th_en[7:4]);
wire stg5_done = ~(|th_en[7:5]);
wire stg6_done = ~(|th_en[7:6]);
wire stg7_done = ~(|th_en[7:7]);


/* Main logic */
reg [2:0] th;	/* Thread No. */
reg busy;
always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		busy <= 1'b0;
		o_wr_en <= 1'b0;
	end
	else if(!busy)
	begin
		o_wr_en <= 1'b0;

		if(i_start)
		begin
			busy <= ~stg0_done;
			th <= 3'h0;
			relu_l <= i_leaky;
			relu_e <= i_expd;
		end
	end
	else
	begin
		case(th)
		3'h0: begin
			busy <= ~stg1_done;
			th <= 3'h1;
			o_th <= th;
			relu_v <= i_th0_acc;
			o_wr_en <= i_th0_en;
		end
		3'h1: begin
			busy <= ~stg2_done;
			th <= 3'h2;
			o_th <= th;
			relu_v <= i_th1_acc;
			o_wr_en <= i_th1_en;
		end
		3'h2: begin
			busy <= ~stg3_done;
			th <= 3'h3;
			o_th <= th;
			relu_v <= i_th2_acc;
			o_wr_en <= i_th2_en;
		end
		3'h3: begin
			busy <= ~stg4_done;
			th <= 3'h4;
			o_th <= th;
			relu_v <= i_th3_acc;
			o_wr_en <= i_th3_en;
		end
		3'h4: begin
			busy <= ~stg5_done;
			th <= 3'h5;
			o_th <= th;
			relu_v <= i_th4_acc;
			o_wr_en <= i_th4_en;
		end
		3'h5: begin
			busy <= ~stg6_done;
			th <= 3'h6;
			o_th <= th;
			relu_v <= i_th5_acc;
			o_wr_en <= i_th5_en;
		end
		3'h6: begin
			busy <= ~stg7_done;
			th <= 3'h7;
			o_th <= th;
			relu_v <= i_th6_acc;
			o_wr_en <= i_th6_en;
		end
		3'h7: begin
			busy <= 1'b0;
			o_th <= th;
			relu_v <= i_th7_acc;
			o_wr_en <= i_th7_en;
		end
		default: begin
			o_wr_en <= 1'b0;
			busy <= 1'b0;
		end
		endcase
	end
end


/* ReLU function instance */
flp32_relu relu(
	.i_v(relu_v),
	.i_l(relu_l),
	.i_e(relu_e),
	.o_r(relu_r)
);


assign o_busy = busy;


endmodule /* vxe_vpu_actf_eu */
