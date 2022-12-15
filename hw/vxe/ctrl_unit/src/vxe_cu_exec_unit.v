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
 * VxE CU execute unit
 */


/* Execute unit */
module vxe_cu_exec_unit(
	clk,
	nrst,
	/* External CU interface */
	i_start,
	o_glb_busy,
	/* Internal control interface */
	o_halt,
	o_unhalt,
	o_stop_drain,
	o_send_intr,
	o_complete,
	/* Command state interface */
	i_cmd_nop,
	i_cmd_sync,
	i_cmd_sync_stop,
	i_cmd_sync_intr,
	/* Internal busy signals */
	i_fetch_busy,
	i_dis_pipes_active,
	i_fwd_pipes_active,
	i_vpus_busy,
	/* Internal fault signals */
	i_flt_fetch,
	i_flt_decode,
	i_vpus_err
);
parameter VPUS_NR = 2;		/* Number of VPUs */
/* Control FSM states */
localparam [1:0]		FSM_CTL_IDLE = 2'b00;	/* Idle */
localparam [1:0]		FSM_CTL_EXEC = 2'b01;	/* Execute state */
localparam [1:0]		FSM_CTL_SYNC = 2'b10;	/* Sync VPUs state */
localparam [1:0]		FSM_CTL_WAIT = 2'b11;	/* Wait for completion */
/* Global signals */
input wire			clk;
input wire			nrst;
/* External CU interface */
input wire			i_start;
output wire			o_glb_busy;
/* Internal control interface */
output wire			o_halt;
output reg			o_unhalt;
output wire			o_stop_drain;
output reg			o_send_intr;
output reg			o_complete;
/* Command state interface */
input wire			i_cmd_nop;
input wire			i_cmd_sync;
input wire			i_cmd_sync_stop;
input wire			i_cmd_sync_intr;
/* Internal busy signals */
input wire			i_fetch_busy;
input wire			i_dis_pipes_active;
input wire			i_fwd_pipes_active;
input wire [VPUS_NR-1:0]	i_vpus_busy;
/* Internal fault signals */
input wire			i_flt_fetch;
input wire			i_flt_decode;
input wire [VPUS_NR-1:0]	i_vpus_err;


/* Global busy state condition */
assign o_glb_busy = units_busy | (ctl_fsm != FSM_CTL_IDLE);

/* Stop commands fetch */
assign o_stop_drain = fault_cond | stop_cond;

assign o_halt = 1'b0;	/* Not used */

/* Processing units are busy */
wire units_busy = i_fetch_busy | i_dis_pipes_active | i_fwd_pipes_active |
	|i_vpus_busy;

/* Synchronize VPUs */
wire sync_wait = i_fwd_pipes_active | |i_vpus_busy;

/* Stop processing */
wire stop_cond = i_cmd_sync && i_cmd_sync_stop;

/* Fault */
wire fault_cond = i_flt_fetch | i_flt_decode | |i_vpus_err;



/* Control logic */
reg [1:0]	ctl_fsm;	/* FSM state */
reg		sync_intr;	/* Send interrupt */

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		o_unhalt <= 1'b0;
		o_send_intr <= 1'b0;
		o_complete <= 1'b0;
		sync_intr <= 1'b0;
		ctl_fsm <= FSM_CTL_IDLE;
	end
	else if(ctl_fsm == FSM_CTL_EXEC)
	begin
		o_unhalt <= 1'b0;
		o_send_intr <= 1'b0;
		o_complete <= 1'b0;

		if(stop_cond)	/* SYNC command with stop flag set */
		begin
			sync_intr <= i_cmd_sync_intr;
			ctl_fsm <= FSM_CTL_WAIT;
		end
		else if(i_cmd_sync)	/* SYNC command */
		begin
			sync_intr <= i_cmd_sync_intr;
			ctl_fsm <= FSM_CTL_SYNC;
		end
		else if(i_cmd_nop)	/* NOP command */
			o_unhalt <= 1'b1;

		/* Error condition
		 * No commands pending and units are idle.
		 * Send interrupt with "complete" flag set to 0.
		 */
		if(!units_busy)
		begin
			o_send_intr <= 1'b1;
			o_complete <= 1'b0;
			o_unhalt <= 1'b1;
			ctl_fsm <= FSM_CTL_IDLE;
		end
	end
	else if(ctl_fsm == FSM_CTL_SYNC)
	begin
		/* Wait while VPUs are busy */
		if(!sync_wait)
		begin
			o_send_intr <= sync_intr;
			o_unhalt <= 1'b1;
			ctl_fsm <= FSM_CTL_EXEC;
		end
	end
	else if(ctl_fsm == FSM_CTL_WAIT)
	begin
		/* Wait while units are are busy */
		if(!units_busy)
		begin
			o_send_intr <= sync_intr;
			o_complete <= sync_intr;
			o_unhalt <= 1'b1;
			ctl_fsm <= FSM_CTL_IDLE;
		end
	end
	else /* ctl_fsm = FSM_CTL_IDLE */
	begin
		o_send_intr <= 1'b0;
		o_complete <= 1'b0;
		o_unhalt <= 1'b0;

		if(i_start)
			ctl_fsm <= FSM_CTL_EXEC;
	end
end

endmodule /* vxe_cu_exec_unit */
