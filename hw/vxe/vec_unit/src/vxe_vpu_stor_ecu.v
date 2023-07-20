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
 * VxE VPU store execution control unit
 */


/* Store execution unit */
module vxe_vpu_stor_ecu(
	clk,
	nrst,
	/* Dispatch interface */
	i_disp,
	o_done,
	i_cmd_op,
	i_cmd_th,
	i_cmd_pl,
	/* Execution unit interface */
	o_eu_start,
	i_eu_busy
);
`include "vxe_ctrl_unit_cmds.vh"
/* Global signals */
input wire		clk;
input wire		nrst;
/* Dispatch interface */
input wire		i_disp;
output reg		o_done;
input wire [4:0]	i_cmd_op;
input wire [2:0]	i_cmd_th;
input wire [47:0]	i_cmd_pl;
/* Execution unit interface */
output reg		o_eu_start;
input wire		i_eu_busy;



/* Main logic */
reg [1:0] eu_wait;
always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		o_eu_start <= 1'b0;
		eu_wait <= 2'b00;
		o_done <= 1'b0;
	end
	else if(eu_wait == 2'b00)
	begin
		o_done <= 1'b0;

		if(i_disp)
		begin
			o_eu_start <= 1'b1;
			eu_wait <= 2'b01;

			if(i_cmd_op != CU_CMD_STORE)
				$display("vxe_vpu_stor_ecu: Invalid command");
		end
	end
	else if(eu_wait == 2'b01)
	begin
		eu_wait <= 2'b11;	/* 1 cycle delay */
		o_eu_start <= 1'b0;
	end
	else
	begin
		if(!i_eu_busy)
		begin
			eu_wait <= 2'b00;
			o_done <= 1'b1;
		end
	end
end


endmodule /* vxe_vpu_stor_ecu */
