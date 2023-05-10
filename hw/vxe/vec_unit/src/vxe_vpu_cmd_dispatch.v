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
 * VxE VPU command dispatch unit
 */


/* Command dispatch unit */
module vxe_vpu_cmd_dispatch(
	clk,
	nrst,
	/* Command queue interface */
	i_vld,
	o_rd,
	i_op,
	i_th,
	i_pl,
	/* Status */
	o_busy,
	/* Functional units interface */
	regu_disp,
	regu_done,
	prod_disp,
	prod_done,
	stor_disp,
	stor_done,
	actf_disp,
	actf_done,
	fu_cmd_op,
	fu_cmd_th,
	fu_cmd_pl,
	/* Datapath MUX control */
	regu_cmd,
	prod_cmd,
	stor_cmd,
	actf_cmd
);
`include "vxe_ctrl_unit_cmds.vh"
/* FSM states */
localparam [1:0]	FSM_IDLE	= 2'b00;	/* Idle state */
localparam [1:0]	FSM_DISP	= 2'b01;	/* Dispatch active */
localparam [1:0]	FSM_WAIT	= 2'b10;	/* Idle state */
/* Global signals */
input wire		clk;
input wire		nrst;
/* Command queue interface */
input wire		i_vld;
output reg		o_rd;
input wire [4:0]	i_op;
input wire [2:0]	i_th;
input wire [47:0]	i_pl;
/* Status */
output wire		o_busy;
/* Functional units interface */
output reg		regu_disp;
input wire		regu_done;
output reg		prod_disp;
input wire		prod_done;
output reg		stor_disp;
input wire		stor_done;
output reg		actf_disp;
input wire		actf_done;
output reg [4:0]	fu_cmd_op;
output reg [2:0]	fu_cmd_th;
output reg [47:0]	fu_cmd_pl;
/* Datapath MUX control */
output wire		regu_cmd;
output wire		prod_cmd;
output wire		stor_cmd;
output wire		actf_cmd;


/* Active dispatches */
reg [3:0]	disp;
wire [3:0]	done = disp & ~{ regu_done, prod_done, stor_done, actf_done };
wire		rdy = ~|done;


reg [1:0] fsm_disp_state;	/* Dispatch FSM state */

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		fsm_disp_state <= FSM_IDLE;
		o_rd <= 1'b0;
		regu_disp <= 1'b0;
		prod_disp <= 1'b0;
		stor_disp <= 1'b0;
		actf_disp <= 1'b0;
		disp <= 4'h0;
	end
	else
	begin
		disp <= done;
		regu_disp <= 1'b0;
		prod_disp <= 1'b0;
		stor_disp <= 1'b0;
		actf_disp <= 1'b0;

		if (fsm_disp_state == FSM_IDLE)
		begin
			if(i_vld)
			begin
				fsm_disp_state <= FSM_DISP;
				o_rd <= 1'b1;
			end
		end
		else if(fsm_disp_state == FSM_DISP)
		begin
			if(i_vld && rdy)
			begin
				fsm_disp_state <= FSM_WAIT;

				o_rd <= 1'b0;
				fu_cmd_op <= i_op;
				fu_cmd_th <= i_th;
				fu_cmd_pl <= i_pl;

				/* Set dispatch destination */
				case(i_op)
				CU_CMD_SETACC,
				CU_CMD_SETVL,
				CU_CMD_SETEN,
				CU_CMD_SETRS,
				CU_CMD_SETRT,
				CU_CMD_SETRD: begin
					regu_disp <= 1'b1;
					disp[3] <= 1'b1;
				end
				CU_CMD_PROD: begin
					prod_disp <= 1'b1;
					disp[2] <= 1'b1;
				end
				CU_CMD_STORE: begin
					stor_disp <= 1'b1;
					disp[1] <= 1'b1;
				end
				CU_CMD_ACTF: begin
					actf_disp <= 1'b1;
					disp[0] <= 1'b1;
				end
				default: $display("Wrong VPU opcode!\n");
				endcase
			end
		end
		else if(fsm_disp_state == FSM_WAIT)
		begin
			if(i_vld && rdy)
			begin
				/* Acknowledge received, dispatch next */
				fsm_disp_state <= FSM_DISP;
				o_rd <= 1'b1;
			end
			else if(!i_vld && rdy)
			begin
				/* Nothing to do */
				fsm_disp_state <= FSM_IDLE;
				o_rd <= 1'b0;
			end
		end
	end
end


assign o_busy = (fsm_disp_state != FSM_IDLE);	/* Busy state */

/* External MUX control */
assign regu_cmd = disp[3];
assign prod_cmd = disp[2];
assign stor_cmd = disp[1];
assign actf_cmd = disp[0];


endmodule /* vxe_vpu_cmd_dispatch */
