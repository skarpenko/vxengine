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
 * Transaction response coder
 */


/* Resp coder */
module vxe_txnres_coder(
	i_txnid,
	i_rnw,
	i_err,
	i_data,
	o_res_vec_txn,
	o_res_vec_dat
);
input wire [5:0]	i_txnid;	/* Transaction Id */
input wire		i_rnw;		/* Read or Write transaction */
input wire [1:0]	i_err;		/* Error status */
input wire [63:0]	i_data;		/* Read data (if i_rnw == 1) */
output wire [8:0]	o_res_vec_txn;	/* Transaction info */
output wire [63:0]	o_res_vec_dat;	/* Transaction data */


assign o_res_vec_txn = { i_txnid, i_rnw, i_err };
assign o_res_vec_dat = i_data;


endmodule /* vxe_txnres_coder */
