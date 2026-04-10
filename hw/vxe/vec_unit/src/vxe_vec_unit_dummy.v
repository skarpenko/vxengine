/*
 * Copyright (c) 2020-2026 The VxEngine Project. All rights reserved.
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
 * VxE vector processing unit top-level (dummy)
 */


/* Vector unit dummy */
module vxe_vec_unit_dummy #(
	parameter [1:0] CLIENT_ID = 0	/* Client Id */
)
(
	clk,
	nrst,
	/* Memory request channel */
	i_rqa_rdy,
	o_rqa,
	o_rqa_wr,
	i_rqd_rdy,
	o_rqd,
	o_rqd_wr,
	/* Memory response channel */
	i_rss_vld,
	i_rss,
	o_rss_rd,
	i_rsd_vld,
	i_rsd,
	o_rsd_rd,
	/* Control interface */
	i_start,
	o_busy,
	o_err,
	/* Command interface */
	i_cmd_sel,
	o_cmd_ack,
	i_cmd_op,
	i_cmd_th,
	i_cmd_pl
);
/* Global signals */
input wire		clk;
input wire		nrst;
/* Memory request channel */
input wire		i_rqa_rdy;
output wire [43:0]	o_rqa;
output wire		o_rqa_wr;
input wire		i_rqd_rdy;
output wire [71:0]	o_rqd;
output wire		o_rqd_wr;
/* Memory response channel */
input wire		i_rss_vld;
input wire [8:0]	i_rss;
output wire		o_rss_rd;
input wire		i_rsd_vld;
input wire [63:0]	i_rsd;
output wire		o_rsd_rd;
/* Control interface */
input wire		i_start;
output wire		o_busy;
output wire		o_err;
/* Command interface */
input wire		i_cmd_sel;
output wire		o_cmd_ack;
input wire [4:0]	i_cmd_op;
input wire [2:0]	i_cmd_th;
input wire [47:0]	i_cmd_pl;


assign o_rqa		= 44'h0;
assign o_rqa_wr		= 1'b0;
assign o_rqd		= 72'h0;
assign o_rqd_wr		= 1'b0;
assign o_rss_rd		= 1'b1;
assign o_rsd_rd		= 1'b1;
assign o_busy		= 1'b0;
assign o_err		= 1'b0;
assign o_cmd_ack	= 1'b1;


endmodule /* vxe_vec_unit_dummy */
