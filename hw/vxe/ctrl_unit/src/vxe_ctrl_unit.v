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
 * VxE control unit top-level
 */


/* Control unit */
module vxe_ctrl_unit(
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
	o_busy,
	i_pgm_addr,
	/* Interrupts and faults state */
	o_intr_vld,
	o_intr,
	o_last_instr_addr,
	o_last_instr_data,
	o_vpu_fault,
	/* VPU0 interface */
	i_vpu0_busy,
	i_vpu0_err,
	o_vpu0_cmd_sel,
	i_vpu0_cmd_ack,
	o_vpu0_cmd_op,
	o_vpu0_cmd_th,
	o_vpu0_cmd_pl,
	/* VPU1 interface */
	i_vpu1_busy,
	i_vpu1_err,
	o_vpu1_cmd_sel,
	i_vpu1_cmd_ack,
	o_vpu1_cmd_op,
	o_vpu1_cmd_th,
	o_vpu1_cmd_pl
);
`include "vxe_client_params.vh"
/* Global signals */
input wire		clk;
input wire		nrst;
/* Memory request channel */
input wire		i_rqa_rdy;
output wire [43:0]	o_rqa;
output wire		o_rqa_wr;
/* Memory response channel */
input wire		i_rss_vld;
input wire [8:0]	i_rss;
output wire		o_rss_rd;
input wire		i_rsd_vld;
input wire [63:0]	i_rsd;
output wire		o_rsd_rd;
/* Control signals */
input wire		i_start;
output wire		o_busy;
input wire [36:0]	i_pgm_addr;
/* Interrupts and faults state */
output wire		o_intr_vld;
output wire [3:0]	o_intr;
output wire [36:0]	o_last_instr_addr;
output wire [63:0]	o_last_instr_data;
output wire [1:0]	o_vpu_fault;
/* VPU0 interface */
input wire		i_vpu0_busy;
input wire		i_vpu0_err;
output wire		o_vpu0_cmd_sel;
input wire		i_vpu0_cmd_ack;
output wire [4:0]	o_vpu0_cmd_op;
output wire [2:0]	o_vpu0_cmd_th;
output wire [47:0]	o_vpu0_cmd_pl;
/* VPU1 interface */
input wire		i_vpu1_busy;
input wire		i_vpu1_err;
output wire		o_vpu1_cmd_sel;
input wire		i_vpu1_cmd_ack;
output wire [4:0]	o_vpu1_cmd_op;
output wire [2:0]	o_vpu1_cmd_th;
output wire [47:0]	o_vpu1_cmd_pl;



/* Start processing logic */
reg	glb_start;
always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		glb_start <= 1'b0;
	end
	else
	begin
		glb_start <= (i_start && ~glb_busy) ? 1'b1 : 1'b0;
	end
end



/************************** Fetch unit instance *******************************/

wire		fetch_stop_drain;
wire		fetch_busy;
wire [36:0]	fetch_addr;
wire [63:0]	fetch_data;
wire		fetch_vld;
wire		fetch_err;
wire		fetch_rd;


vxe_cu_fetch_unit #(
	.CLIENT_ID(CLNT_CU),
	.FETCH_DEPTH_POW2(4)
) fetch_unit (
	.clk(clk),
	.nrst(nrst),
	/* Memory request channel */
	.i_rqa_rdy(i_rqa_rdy),
	.o_rqa(o_rqa),
	.o_rqa_wr(o_rqa_wr),
	/* Memory response channel */
	.i_rss_vld(i_rss_vld),
	.i_rss(i_rss),
	.o_rss_rd(o_rss_rd),
	.i_rsd_vld(i_rsd_vld),
	.i_rsd(i_rsd),
	.o_rsd_rd(o_rsd_rd),
	/* Control signals */
	.i_start(glb_start),
	.i_start_addr(i_pgm_addr),
	.i_stop_drain(fetch_stop_drain),
	.o_busy(fetch_busy),
	.o_fetch_addr(fetch_addr),
	.o_fetch_data(fetch_data),
	.o_fetch_vld(fetch_vld),
	.o_fetch_err(fetch_err),
	.i_fetch_rd(fetch_rd)
);



/************************** Dispatch unit instance ****************************/

wire		flt_fetch;
wire [36:0]	flt_fetch_addr;
wire		flt_decode;
wire [36:0]	flt_decode_addr;
wire [63:0]	flt_decode_data;
wire		ctl_nop;
wire		ctl_sync;
wire		ctl_sync_stop;
wire		ctl_sync_intr;
wire		ctl_halt;	/* NOT USED. Must be zero. */
wire		ctl_unhalt;
wire		ctl_pipes_active;
wire		fwd_vpu0_rdy;
wire [4:0]	fwd_vpu0_op;
wire [2:0]	fwd_vpu0_th;
wire [47:0]	fwd_vpu0_pl;
wire		fwd_vpu0_wr;
wire		fwd_vpu1_rdy;
wire [4:0]	fwd_vpu1_op;
wire [2:0]	fwd_vpu1_th;
wire [47:0]	fwd_vpu1_pl;
wire		fwd_vpu1_wr;


vxe_cu_dispatch_unit dispatch_unit(
	.clk(clk),
	.nrst(nrst),
	/* Fetch unit interface */
	.i_fetch_addr(fetch_addr),
	.i_fetch_data(fetch_data),
	.i_fetch_vld(fetch_vld),
	.i_fetch_err(fetch_err),
	.o_fetch_rd(fetch_rd),
	/* Faults */
	.o_flt_fetch(flt_fetch),
	.o_flt_fetch_addr(flt_fetch_addr),
	.o_flt_decode(flt_decode),
	.o_flt_decode_addr(flt_decode_addr),
	.o_flt_decode_data(flt_decode_data),
	/* Control interface */
	.o_ctl_nop(ctl_nop),
	.o_ctl_sync(ctl_sync),
	.o_ctl_sync_stop(ctl_sync_stop),
	.o_ctl_sync_intr(ctl_sync_intr),
	.i_ctl_halt(ctl_halt),
	.i_ctl_unhalt(ctl_unhalt),
	.o_ctl_pipes_active(ctl_pipes_active),
	/* VPU0 forwarding interface */
	.i_fwd_vpu0_rdy(fwd_vpu0_rdy),
	.o_fwd_vpu0_op(fwd_vpu0_op),
	.o_fwd_vpu0_th(fwd_vpu0_th),
	.o_fwd_vpu0_pl(fwd_vpu0_pl),
	.o_fwd_vpu0_wr(fwd_vpu0_wr),
	/* VPU1 forwarding interface */
	.i_fwd_vpu1_rdy(fwd_vpu1_rdy),
	.o_fwd_vpu1_op(fwd_vpu1_op),
	.o_fwd_vpu1_th(fwd_vpu1_th),
	.o_fwd_vpu1_pl(fwd_vpu1_pl),
	.o_fwd_vpu1_wr(fwd_vpu1_wr)
);



/****************** Interrupts and faults unit instance ***********************/

wire		send_intr;
wire		complete;


vxe_cu_intr_flt_unit #(
	.VPUS_NR(2)
) intr_flt_unit (
	.clk(clk),
	.nrst(nrst),
	/* External interrupts and faults interface */
	.o_intr_vld(o_intr_vld),
	.o_intr(o_intr),
	.o_last_instr_addr(o_last_instr_addr),
	.o_last_instr_data(o_last_instr_data),
	.o_vpu_fault(o_vpu_fault),
	/* Internal CU interface */
	.i_send_intr(send_intr),
	.i_complete(complete),
	.i_flt_fetch(flt_fetch),
	.i_flt_fetch_addr(flt_fetch_addr),
	.i_flt_decode(flt_decode),
	.i_flt_decode_addr(flt_decode_addr),
	.i_flt_decode_data(flt_decode_data),
	.i_flt_vpu({i_vpu1_err, i_vpu0_err})
);



/********************* VPU0 forwarding unit instance **************************/

wire	vpu0_fwd_busy;


vxe_cu_vpu_fwd_unit #(
	.DEPTH_POW2(4)
) vpu0_fwd_unit (
	.clk(clk),
	.nrst(nrst),
	/* VPU forwarding interface */
	.o_fwd_vpu_rdy(fwd_vpu0_rdy),
	.i_fwd_vpu_op(fwd_vpu0_op),
	.i_fwd_vpu_th(fwd_vpu0_th),
	.i_fwd_vpu_pl(fwd_vpu0_pl),
	.i_fwd_vpu_wr(fwd_vpu0_wr),
	/* VPU command bus interface */
	.o_vpu_cmd_sel(o_vpu0_cmd_sel),
	.i_vpu_cmd_ack(i_vpu0_cmd_ack),
	.o_vpu_cmd_op(o_vpu0_cmd_op),
	.o_vpu_cmd_th(o_vpu0_cmd_th),
	.o_vpu_cmd_pl(o_vpu0_cmd_pl),
	/* Status signals */
	.o_pipes_active(vpu0_fwd_busy)
);



/********************* VPU1 forwarding unit instance **************************/

wire	vpu1_fwd_busy;


vxe_cu_vpu_fwd_unit #(
	.DEPTH_POW2(4)
) vpu1_fwd_unit (
	.clk(clk),
	.nrst(nrst),
	/* VPU forwarding interface */
	.o_fwd_vpu_rdy(fwd_vpu1_rdy),
	.i_fwd_vpu_op(fwd_vpu1_op),
	.i_fwd_vpu_th(fwd_vpu1_th),
	.i_fwd_vpu_pl(fwd_vpu1_pl),
	.i_fwd_vpu_wr(fwd_vpu1_wr),
	/* VPU command bus interface */
	.o_vpu_cmd_sel(o_vpu1_cmd_sel),
	.i_vpu_cmd_ack(i_vpu1_cmd_ack),
	.o_vpu_cmd_op(o_vpu1_cmd_op),
	.o_vpu_cmd_th(o_vpu1_cmd_th),
	.o_vpu_cmd_pl(o_vpu1_cmd_pl),
	/* Status signals */
	.o_pipes_active(vpu1_fwd_busy)
);



/************************** Execute unit instance *****************************/

wire		glb_busy;


vxe_cu_exec_unit exec_unit(
	.clk(clk),
	.nrst(nrst),
	/* External CU interface */
	.i_start(glb_start),
	.o_glb_busy(glb_busy),
	/* Internal control interface */
	.o_halt(ctl_halt),
	.o_unhalt(ctl_unhalt),
	.o_stop_drain(fetch_stop_drain),
	.o_send_intr(send_intr),
	.o_complete(complete),
	/* Command state interface */
	.i_cmd_nop(ctl_nop),
	.i_cmd_sync(ctl_sync),
	.i_cmd_sync_stop(ctl_sync_stop),
	.i_cmd_sync_intr(ctl_sync_intr),
	/* Internal busy signals */
	.i_fetch_busy(fetch_busy),
	.i_dis_pipes_active(ctl_pipes_active),
	.i_fwd_pipes_active(vpu1_fwd_busy | vpu0_fwd_busy),
	.i_vpus_busy(i_vpu1_busy | i_vpu0_busy),
	/* Internal fault signals */
	.i_flt_fetch(flt_fetch),
	.i_flt_decode(flt_decode),
	.i_vpus_err(i_vpu1_err | i_vpu0_err)
);


assign o_busy = glb_busy;


endmodule /* vxe_ctrl_unit */
