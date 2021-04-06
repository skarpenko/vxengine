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
 * Request transaction decoder
 */


/* Req decoder */
module vxe_txnreq_decoder(
	i_req_vec_txn,
	i_req_vec_dat,
	o_txnid,
	o_rnw,
	o_addr,
	o_data,
	o_ben
);
input wire [43:0]	i_req_vec_txn;	/* Transaction info */
input wire [71:0]	i_req_vec_dat;	/* Transaction data */
output wire [5:0]	o_txnid;	/* Transaction Id */
output wire		o_rnw;		/* Read or Write transaction */
output wire [36:0]	o_addr;		/* Upper 37-bits of 40-bit address */
output wire [63:0]	o_data;		/* Data to write (if i_rnw == 0) */
output wire [7:0]	o_ben;		/* Byte enables */


assign o_txnid = i_req_vec_txn[43:38];
assign o_rnw = i_req_vec_txn[37];
assign o_addr = i_req_vec_txn[36:0];

assign o_ben = i_req_vec_dat[71:64];
assign o_data = i_req_vec_dat[63:0];


endmodule /* vxe_txnreq_decoder */
