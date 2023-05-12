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
 * VxE VPU register file
 */


/* Register file */
module vxe_vpu_rf(
	clk,
	nrst,
	/* RF write interface */
	i_regu_cmd,
	i_regu_th,
	i_regu_ridx,
	i_regu_wr_en,
	i_regu_data,
	i_prod_cmd,
	i_prod_th,
	i_prod_ridx,
	i_prod_wr_en,
	i_prod_data,
	i_actf_cmd,
	i_actf_th,
	i_actf_ridx,
	i_actf_wr_en,
	i_actf_data,
	/* Register values */
	out_th0_acc,
	out_th0_vl,
	out_th0_en,
	out_th0_rs,
	out_th0_rt,
	out_th0_rd,
	out_th1_acc,
	out_th1_vl,
	out_th1_en,
	out_th1_rs,
	out_th1_rt,
	out_th1_rd,
	out_th2_acc,
	out_th2_vl,
	out_th2_en,
	out_th2_rs,
	out_th2_rt,
	out_th2_rd,
	out_th3_acc,
	out_th3_vl,
	out_th3_en,
	out_th3_rs,
	out_th3_rt,
	out_th3_rd,
	out_th4_acc,
	out_th4_vl,
	out_th4_en,
	out_th4_rs,
	out_th4_rt,
	out_th4_rd,
	out_th5_acc,
	out_th5_vl,
	out_th5_en,
	out_th5_rs,
	out_th5_rt,
	out_th5_rd,
	out_th6_acc,
	out_th6_vl,
	out_th6_en,
	out_th6_rs,
	out_th6_rt,
	out_th6_rd,
	out_th7_acc,
	out_th7_vl,
	out_th7_en,
	out_th7_rs,
	out_th7_rt,
	out_th7_rd
);
/* Global signals */
input wire		clk;
input wire		nrst;
/* RF write interface */
input wire		i_regu_cmd;
input wire [2:0]	i_regu_th;
input wire [2:0]	i_regu_ridx;
input wire		i_regu_wr_en;
input wire [37:0]	i_regu_data;
input wire		i_prod_cmd;
input wire [2:0]	i_prod_th;
input wire [2:0]	i_prod_ridx;
input wire		i_prod_wr_en;
input wire [37:0]	i_prod_data;
input wire		i_actf_cmd;
input wire [2:0]	i_actf_th;
input wire [2:0]	i_actf_ridx;
input wire		i_actf_wr_en;
input wire [37:0]	i_actf_data;
/* Register values */
output wire [31:0]	out_th0_acc;
output wire [19:0]	out_th0_vl;
output wire		out_th0_en;
output wire [37:0]	out_th0_rs;
output wire [37:0]	out_th0_rt;
output wire [37:0]	out_th0_rd;
output wire [31:0]	out_th1_acc;
output wire [19:0]	out_th1_vl;
output wire		out_th1_en;
output wire [37:0]	out_th1_rs;
output wire [37:0]	out_th1_rt;
output wire [37:0]	out_th1_rd;
output wire [31:0]	out_th2_acc;
output wire [19:0]	out_th2_vl;
output wire		out_th2_en;
output wire [37:0]	out_th2_rs;
output wire [37:0]	out_th2_rt;
output wire [37:0]	out_th2_rd;
output wire [31:0]	out_th3_acc;
output wire [19:0]	out_th3_vl;
output wire		out_th3_en;
output wire [37:0]	out_th3_rs;
output wire [37:0]	out_th3_rt;
output wire [37:0]	out_th3_rd;
output wire [31:0]	out_th4_acc;
output wire [19:0]	out_th4_vl;
output wire		out_th4_en;
output wire [37:0]	out_th4_rs;
output wire [37:0]	out_th4_rt;
output wire [37:0]	out_th4_rd;
output wire [31:0]	out_th5_acc;
output wire [19:0]	out_th5_vl;
output wire		out_th5_en;
output wire [37:0]	out_th5_rs;
output wire [37:0]	out_th5_rt;
output wire [37:0]	out_th5_rd;
output wire [31:0]	out_th6_acc;
output wire [19:0]	out_th6_vl;
output wire		out_th6_en;
output wire [37:0]	out_th6_rs;
output wire [37:0]	out_th6_rt;
output wire [37:0]	out_th6_rd;
output wire [31:0]	out_th7_acc;
output wire [19:0]	out_th7_vl;
output wire		out_th7_en;
output wire [37:0]	out_th7_rs;
output wire [37:0]	out_th7_rt;
output wire [37:0]	out_th7_rd;



/* Internal wiring */
reg [2:0]	th_ridx[0:7];
reg		th_wr_en[0:7];
reg [37:0]	th_data[0:7];
wire [31:0]	th_out_acc[0:7];
wire [19:0]	th_out_vl[0:7];
wire		th_out_en[0:7];
wire [37:0]	th_out_rs[0:7];
wire [37:0]	th_out_rt[0:7];
wire [37:0]	th_out_rd[0:7];



/* Main MUX */
integer i;
always @(*)
begin : main_mux
	for(i = 0; i < 8; i = i + 1)
	begin
		th_ridx[i] = 3'h0;
		th_wr_en[i] = 1'h0;
		th_data[i] = 38'h0;
	end

	if(i_regu_cmd)
	begin
		th_ridx[i_regu_th] = i_regu_ridx;
		th_wr_en[i_regu_th] = i_regu_wr_en;
		th_data[i_regu_th] = i_regu_data;
	end
	else if(i_prod_cmd)
	begin
		th_ridx[i_prod_th] = i_prod_ridx;
		th_wr_en[i_prod_th] = i_prod_wr_en;
		th_data[i_prod_th] = i_prod_data;
	end
	else if(i_actf_cmd)
	begin
		th_ridx[i_actf_th] = i_actf_ridx;
		th_wr_en[i_actf_th] = i_actf_wr_en;
		th_data[i_actf_th] = i_actf_data;
	end
end



/* Generate thread RFs */
genvar g;
generate
for(g = 0; g < 8; g = g + 1)
begin : stor
	vxe_vpu_thread_rf th_rf(
		.clk(clk),
		.nrst(nrst),
		.ridx(th_ridx[g]),
		.wr_en(th_wr_en[g]),
		.data(th_data[g]),
		.out_acc(th_out_acc[g]),
		.out_vl(th_out_vl[g]),
		.out_en(th_out_en[g]),
		.out_rs(th_out_rs[g]),
		.out_rt(th_out_rt[g]),
		.out_rd(th_out_rd[g])
);

end
endgenerate



/* Outputs */
assign out_th0_acc	= th_out_acc[0];
assign out_th0_vl	= th_out_vl[0];
assign out_th0_en	= th_out_en[0];
assign out_th0_rs	= th_out_rs[0];
assign out_th0_rt	= th_out_rt[0];
assign out_th0_rd	= th_out_rd[0];

assign out_th1_acc	= th_out_acc[1];
assign out_th1_vl	= th_out_vl[1];
assign out_th1_en	= th_out_en[1];
assign out_th1_rs	= th_out_rs[1];
assign out_th1_rt	= th_out_rt[1];
assign out_th1_rd	= th_out_rd[1];

assign out_th2_acc	= th_out_acc[2];
assign out_th2_vl	= th_out_vl[2];
assign out_th2_en	= th_out_en[2];
assign out_th2_rs	= th_out_rs[2];
assign out_th2_rt	= th_out_rt[2];
assign out_th2_rd	= th_out_rd[2];

assign out_th3_acc	= th_out_acc[3];
assign out_th3_vl	= th_out_vl[3];
assign out_th3_en	= th_out_en[3];
assign out_th3_rs	= th_out_rs[3];
assign out_th3_rt	= th_out_rt[3];
assign out_th3_rd	= th_out_rd[3];

assign out_th4_acc	= th_out_acc[4];
assign out_th4_vl	= th_out_vl[4];
assign out_th4_en	= th_out_en[4];
assign out_th4_rs	= th_out_rs[4];
assign out_th4_rt	= th_out_rt[4];
assign out_th4_rd	= th_out_rd[4];

assign out_th5_acc	= th_out_acc[5];
assign out_th5_vl	= th_out_vl[5];
assign out_th5_en	= th_out_en[5];
assign out_th5_rs	= th_out_rs[5];
assign out_th5_rt	= th_out_rt[5];
assign out_th5_rd	= th_out_rd[5];

assign out_th6_acc	= th_out_acc[6];
assign out_th6_vl	= th_out_vl[6];
assign out_th6_en	= th_out_en[6];
assign out_th6_rs	= th_out_rs[6];
assign out_th6_rt	= th_out_rt[6];
assign out_th6_rd	= th_out_rd[6];

assign out_th7_acc	= th_out_acc[7];
assign out_th7_vl	= th_out_vl[7];
assign out_th7_en	= th_out_en[7];
assign out_th7_rs	= th_out_rs[7];
assign out_th7_rt	= th_out_rt[7];
assign out_th7_rd	= th_out_rd[7];


endmodule /* vxe_vpu_rf */
