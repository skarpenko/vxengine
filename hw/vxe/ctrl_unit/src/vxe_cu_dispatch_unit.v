/*
 * Copyright (c) 2020-2025 The VxEngine Project. All rights reserved.
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
 * VxE CU dispatch unit
 */

`include "vxe_config.vh"


/* Dispatch unit */
module vxe_cu_dispatch_unit(
	clk,
	nrst,
	/* Fetch unit interface */
	i_fetch_addr,
	i_fetch_data,
	i_fetch_vld,
	i_fetch_err,
	o_fetch_rd,
	/* Faults */
	o_flt_fetch,
	o_flt_fetch_addr,
	o_flt_decode,
	o_flt_decode_addr,
	o_flt_decode_data,
	/* Control interface */
	o_ctl_nop,
	o_ctl_sync,
	o_ctl_sync_stop,
	o_ctl_sync_intr,
	i_ctl_halt,
	i_ctl_unhalt,
	o_ctl_pipes_active,
	/* VPU0 forwarding interface */
	i_fwd_vpu0_rdy,
	o_fwd_vpu0_op,
	o_fwd_vpu0_th,
	o_fwd_vpu0_pl,
	o_fwd_vpu0_wr,
	/* VPU1 forwarding interface */
	i_fwd_vpu1_rdy,
	o_fwd_vpu1_op,
	o_fwd_vpu1_th,
	o_fwd_vpu1_pl,
	o_fwd_vpu1_wr
);
/* Receive FSM states */
localparam [2:0]	FSM_RX_IDLE = 3'b000;	/* Idle */
localparam [2:0]	FSM_RX_READ = 3'b001;	/* Read commands */
localparam [2:0]	FSM_RX_STLL = 3'b010;	/* Stall */
localparam [2:0]	FSM_RX_HALT = 3'b100;	/* Halt and wait */
/* Dispatch FSM states */
localparam [1:0]	FSM_DP_IDLE = 2'b00;	/* Idle */
localparam [1:0]	FSM_DP_DECD = 2'b01;	/* Decode commands */
localparam [1:0]	FSM_DP_HALT = 2'b10;	/* Halt and wait */
/* Forwarding FSM states */
localparam		FSM_FW_IDLE = 1'b0;	/* Idle */
localparam		FSM_FW_FORW = 1'b1;	/* Forwarding */
/* Global signals */
input wire		clk;
input wire		nrst;
/* Fetch unit interface */
input wire [36:0]	i_fetch_addr;
input wire [63:0]	i_fetch_data;
input wire		i_fetch_vld;
input wire		i_fetch_err;
output reg		o_fetch_rd;
/* Faults */
output reg		o_flt_fetch;
output reg [36:0]	o_flt_fetch_addr;
output reg		o_flt_decode;
output reg [36:0]	o_flt_decode_addr;
output reg [63:0]	o_flt_decode_data;
/* Control interface */
output reg		o_ctl_nop;
output reg		o_ctl_sync;
output reg		o_ctl_sync_stop;
output reg		o_ctl_sync_intr;
input wire		i_ctl_halt;
input wire		i_ctl_unhalt;
output wire		o_ctl_pipes_active;
/* VPU0 forwarding interface */
input wire		i_fwd_vpu0_rdy;
output reg [4:0]	o_fwd_vpu0_op;
output reg [2:0]	o_fwd_vpu0_th;
output reg [47:0]	o_fwd_vpu0_pl;
output reg		o_fwd_vpu0_wr;
/* VPU1 forwarding interface */
input wire		i_fwd_vpu1_rdy;
output reg [4:0]	o_fwd_vpu1_op;
output reg [2:0]	o_fwd_vpu1_th;
output reg [47:0]	o_fwd_vpu1_pl;
output reg		o_fwd_vpu1_wr;


/* Internal pipes still contain valid commands for execution */
assign o_ctl_pipes_active = !cmd_fifo_empty || !cvpu0_fifo_empty
	|| !cvpu1_fifo_empty;


/* Intermediate FIFO for received commands */
reg [36:0]	cmd_addr_fifo[0:3];	/* Incoming command address FIFO */
reg [63:0]	cmd_data_fifo[0:3];	/* Incoming command data FIFO */
reg [2:0]	cmd_fifo_rp;		/* Read pointer */
reg [2:0]	cmd_fifo_wp;		/* Write pointer */
/* Previous FIFO read pointer */
wire [2:0]	cmd_fifo_pre_rp = cmd_fifo_rp - 1'b1;
/* FIFO states */
wire cmd_fifo_empty = (cmd_fifo_rp[1:0] == cmd_fifo_wp[1:0]) &&
	(cmd_fifo_rp[2] == cmd_fifo_wp[2]);
wire cmd_fifo_full = (cmd_fifo_rp[1:0] == cmd_fifo_wp[1:0]) &&
	(cmd_fifo_rp[2] != cmd_fifo_wp[2]);
wire cmd_fifo_pre_full = (cmd_fifo_pre_rp[1:0] == cmd_fifo_wp[1:0]) &&
	(cmd_fifo_pre_rp[2] != cmd_fifo_wp[2]);

/* Commands FIFO stall condition */
wire cmd_fifo_stall = cmd_fifo_full || cmd_fifo_pre_full;



/** Commands stream receive FSM **/

reg [2:0]	cmd_rx_fsm;	/* FSM state */

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		cmd_rx_fsm <= FSM_RX_IDLE;
		o_fetch_rd <= 1'b0;
		o_flt_fetch <= 1'b0;
		cmd_fifo_wp <= 3'b000;
	end
	else if(cmd_rx_fsm == FSM_RX_READ)
	begin
		if(i_fetch_vld && ~i_fetch_err)
		begin
			cmd_addr_fifo[cmd_fifo_wp[1:0]] <= i_fetch_addr;
			cmd_data_fifo[cmd_fifo_wp[1:0]] <= i_fetch_data;
			cmd_fifo_wp <= cmd_fifo_wp + 1'b1;
		end
		else if(i_fetch_vld && i_fetch_err)
		begin
			o_flt_fetch <= 1'b1;
			o_flt_fetch_addr <= i_fetch_addr;
			o_fetch_rd <= 1'b0;
			cmd_rx_fsm <= FSM_RX_HALT;
		end

		/* Check FIFO stall condition */
		if(cmd_fifo_stall && ~i_fetch_err)
		begin
			o_fetch_rd <= 1'b0;
			cmd_rx_fsm <= FSM_RX_STLL;
		end

		/* Switch to halt state on decode error or stop/halt requests */
		if(o_flt_decode || (o_ctl_sync && o_ctl_sync_stop) || i_ctl_halt)
		begin
			o_fetch_rd <= 1'b0;
			cmd_rx_fsm <= FSM_RX_HALT;
			cmd_fifo_wp <= cmd_fifo_wp;	/* Revert fetch */
		end
	end
	else if(cmd_rx_fsm == FSM_RX_STLL)
	begin
		/* Check if stall is resolved */
		if(!cmd_fifo_stall)
		begin
			o_fetch_rd <= 1'b1;
			cmd_rx_fsm <= FSM_RX_READ;
		end

		/* Switch to halt state on decode error or stop/halt requests */
		if(o_flt_decode || (o_ctl_sync && o_ctl_sync_stop) || i_ctl_halt)
		begin
			o_fetch_rd <= 1'b0;
			cmd_rx_fsm <= FSM_RX_HALT;
		end
	end
	else if(cmd_rx_fsm == FSM_RX_HALT)
	begin
		o_flt_fetch <= 1'b0;

		if(i_ctl_unhalt)
		begin
			cmd_rx_fsm <= FSM_RX_IDLE;
		end
	end
	else	/* FSM_RX_IDLE */
	begin
		o_fetch_rd <= 1'b1;
		cmd_rx_fsm <= FSM_RX_READ;
	end
end



/* Command decoder output */
wire			cdec_err;
wire			cdec_cu_cmd;
wire			cdec_cu_nop;
wire			cdec_cu_sync;
wire			cdec_cu_sync_stop;
wire			cdec_cu_sync_intr;
wire			cdec_vpu_cmd;
wire [1:0]		cdec_vpu_mask;
wire [4:0]		cdec_vpu_op;
wire [2:0]		cdec_vpu_th;
wire [47:0]		cdec_vpu_pl;


/* VPU0 command forwarding FIFO */
reg [4:0]	cvpu0_op_fifo[0:3];	/* VPU0 opcode */
reg [2:0]	cvpu0_th_fifo[0:3];	/* VPU0 thread */
reg [47:0]	cvpu0_pl_fifo[0:3];	/* VPU0 payload */
reg [2:0]	cvpu0_fifo_rp;		/* Read pointer */
reg [2:0]	cvpu0_fifo_wp;		/* Write pointer */
/* Previous FIFO read pointer */
wire [2:0]	cvpu0_fifo_pre_rp = cvpu0_fifo_rp - 1'b1;
/* FIFO states */
wire cvpu0_fifo_empty = (cvpu0_fifo_rp[1:0] == cvpu0_fifo_wp[1:0]) &&
	(cvpu0_fifo_rp[2] == cvpu0_fifo_wp[2]);
wire cvpu0_fifo_full = (cvpu0_fifo_rp[1:0] == cvpu0_fifo_wp[1:0]) &&
	(cvpu0_fifo_rp[2] != cvpu0_fifo_wp[2]);
wire cvpu0_fifo_pre_full = (cvpu0_fifo_pre_rp[1:0] == cvpu0_fifo_wp[1:0]) &&
	(cvpu0_fifo_pre_rp[2] != cvpu0_fifo_wp[2]);
/* VPU0 FIFO stall condition */
wire cvpu0_fifo_stall = cvpu0_fifo_full || cvpu0_fifo_pre_full;


/* VPU1 command forwarding FIFO */
reg [4:0]	cvpu1_op_fifo[0:3];	/* VPU1 opcode */
reg [2:0]	cvpu1_th_fifo[0:3];	/* VPU1 thread */
reg [47:0]	cvpu1_pl_fifo[0:3];	/* VPU1 payload */
reg [2:0]	cvpu1_fifo_rp;		/* Read pointer */
reg [2:0]	cvpu1_fifo_wp;		/* Write pointer */
/* Previous FIFO read pointer */
wire [2:0]	cvpu1_fifo_pre_rp = cvpu1_fifo_rp - 1'b1;
/* FIFO states */
wire cvpu1_fifo_empty = (cvpu1_fifo_rp[1:0] == cvpu1_fifo_wp[1:0]) &&
	(cvpu1_fifo_rp[2] == cvpu1_fifo_wp[2]);
wire cvpu1_fifo_full = (cvpu1_fifo_rp[1:0] == cvpu1_fifo_wp[1:0]) &&
	(cvpu1_fifo_rp[2] != cvpu1_fifo_wp[2]);
wire cvpu1_fifo_pre_full = (cvpu1_fifo_pre_rp[1:0] == cvpu1_fifo_wp[1:0]) &&
	(cvpu1_fifo_pre_rp[2] != cvpu1_fifo_wp[2]);
/* VPU1 FIFO stall condition */
wire cvpu1_fifo_stall = cvpu1_fifo_full || cvpu1_fifo_pre_full;


/* Forwarding stall */
wire cvpu_fwd_stall = (cvpu0_fifo_stall && cdec_vpu_mask[0]) ||
		(cvpu1_fifo_stall && cdec_vpu_mask[1]);


/* Halt request active */
reg ctl_halt_act;


/** Commands decode and dispatch FSM **/

reg [1:0]	cmd_dp_fsm;	/* FSM state */

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		cmd_dp_fsm <= FSM_DP_IDLE;
		o_flt_decode <= 1'b0;
		o_ctl_nop <= 1'b0;
		o_ctl_sync <= 1'b0;
		o_ctl_sync_stop <= 1'b0;
		o_ctl_sync_intr <= 1'b0;
		ctl_halt_act <= 1'b0;
		cmd_fifo_rp <= 3'b000;
		cvpu0_fifo_wp <= 3'b000;
		cvpu1_fifo_wp <= 3'b000;
	end
	else if(cmd_dp_fsm == FSM_DP_DECD && !cmd_fifo_empty)
	begin
		if(i_ctl_halt)
		begin
			ctl_halt_act <= 1'b1;
			cmd_dp_fsm <= FSM_DP_HALT;
		end
		else if(cdec_err)	/* Decode error */
		begin
			o_flt_decode <= 1'b1;
			o_flt_decode_addr <= cmd_addr_fifo[cmd_fifo_rp[1:0]];
			o_flt_decode_data <= cmd_data_fifo[cmd_fifo_rp[1:0]];
			cmd_dp_fsm <= FSM_DP_HALT;
		end
		else if(cdec_vpu_cmd && !cvpu_fwd_stall)	/* Fwd to VPUs */
		begin
			if(cdec_vpu_mask[0])
			begin
				cvpu0_op_fifo[cvpu0_fifo_wp[1:0]] <= cdec_vpu_op;
				cvpu0_th_fifo[cvpu0_fifo_wp[1:0]] <= cdec_vpu_th;
				cvpu0_pl_fifo[cvpu0_fifo_wp[1:0]] <= cdec_vpu_pl;
				cvpu0_fifo_wp <= cvpu0_fifo_wp + 1'b1;
			end

			if(cdec_vpu_mask[1])
			begin
				cvpu1_op_fifo[cvpu1_fifo_wp[1:0]] <= cdec_vpu_op;
				cvpu1_th_fifo[cvpu1_fifo_wp[1:0]] <= cdec_vpu_th;
				cvpu1_pl_fifo[cvpu1_fifo_wp[1:0]] <= cdec_vpu_pl;
				cvpu1_fifo_wp <= cvpu1_fifo_wp + 1'b1;
			end

			cmd_fifo_rp <= cmd_fifo_rp + 1'b1;
		end
		else if(cdec_cu_cmd)	/* CU command */
		begin
			o_ctl_nop <= cdec_cu_nop;
			o_ctl_sync <= cdec_cu_sync;
			o_ctl_sync_stop <= cdec_cu_sync_stop;
			o_ctl_sync_intr <= cdec_cu_sync_intr;
			cmd_fifo_rp <= cmd_fifo_rp + 1'b1;
			cmd_dp_fsm <= FSM_DP_HALT;
		end
	end
	else if(cmd_dp_fsm == FSM_DP_HALT)
	begin
		o_ctl_nop <= 1'b0;
		o_ctl_sync <= 1'b0;
		o_flt_decode <= 1'b0;
		ctl_halt_act <= 1'b0;

		/* Clear FIFO on decode error or stop/halt requests */
		cmd_fifo_rp <= o_flt_decode || (o_ctl_sync && o_ctl_sync_stop)
			|| ctl_halt_act ? cmd_fifo_wp : cmd_fifo_rp;

		if(i_ctl_unhalt)
		begin
			cmd_dp_fsm <= FSM_DP_IDLE;
		end
	end
	else	/* FSM_DP_IDLE */
	begin
		cmd_dp_fsm <= FSM_DP_DECD;
	end
end


/** VPU0 forwarding FSM **/
reg	vpu0_fwd_fsm;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		vpu0_fwd_fsm <= FSM_FW_IDLE;
		o_fwd_vpu0_wr <= 1'b0;
		cvpu0_fifo_rp <= 3'b000;
	end
	else if(vpu0_fwd_fsm == FSM_FW_IDLE)
	begin
		if(!cvpu0_fifo_empty)
		begin
			vpu0_fwd_fsm <= FSM_FW_FORW;
			o_fwd_vpu0_op <= cvpu0_op_fifo[cvpu0_fifo_rp[1:0]];
			o_fwd_vpu0_th <= cvpu0_th_fifo[cvpu0_fifo_rp[1:0]];
			o_fwd_vpu0_pl <= cvpu0_pl_fifo[cvpu0_fifo_rp[1:0]];
			cvpu0_fifo_rp <= cvpu0_fifo_rp + 1'b1;
			o_fwd_vpu0_wr <= 1'b1;
		end
	end
	else if(vpu0_fwd_fsm == FSM_FW_FORW)
	begin
		if(i_fwd_vpu0_rdy && !cvpu0_fifo_empty)
		begin
			o_fwd_vpu0_op <= cvpu0_op_fifo[cvpu0_fifo_rp[1:0]];
			o_fwd_vpu0_th <= cvpu0_th_fifo[cvpu0_fifo_rp[1:0]];
			o_fwd_vpu0_pl <= cvpu0_pl_fifo[cvpu0_fifo_rp[1:0]];
			cvpu0_fifo_rp <= cvpu0_fifo_rp + 1'b1;
		end
		else if(i_fwd_vpu0_rdy)
		begin
			vpu0_fwd_fsm <= FSM_FW_IDLE;
			o_fwd_vpu0_wr <= 1'b0;
		end
	end
end


/** VPU1 forwarding FSM **/
reg	vpu1_fwd_fsm;

always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		vpu1_fwd_fsm <= FSM_FW_IDLE;
		o_fwd_vpu1_wr <= 1'b0;
		cvpu1_fifo_rp <= 3'b000;
	end
	else if(vpu1_fwd_fsm == FSM_FW_IDLE)
	begin
		if(!cvpu1_fifo_empty)
		begin
			vpu1_fwd_fsm <= FSM_FW_FORW;
			o_fwd_vpu1_op <= cvpu1_op_fifo[cvpu1_fifo_rp[1:0]];
			o_fwd_vpu1_th <= cvpu1_th_fifo[cvpu1_fifo_rp[1:0]];
			o_fwd_vpu1_pl <= cvpu1_pl_fifo[cvpu1_fifo_rp[1:0]];
			cvpu1_fifo_rp <= cvpu1_fifo_rp + 1'b1;
			o_fwd_vpu1_wr <= 1'b1;
		end
	end
	else if(vpu1_fwd_fsm == FSM_FW_FORW)
	begin
		if(i_fwd_vpu1_rdy && !cvpu1_fifo_empty)
		begin
			o_fwd_vpu1_op <= cvpu1_op_fifo[cvpu1_fifo_rp[1:0]];
			o_fwd_vpu1_th <= cvpu1_th_fifo[cvpu1_fifo_rp[1:0]];
			o_fwd_vpu1_pl <= cvpu1_pl_fifo[cvpu1_fifo_rp[1:0]];
			cvpu1_fifo_rp <= cvpu1_fifo_rp + 1'b1;
		end
		else if(i_fwd_vpu1_rdy)
		begin
			vpu1_fwd_fsm <= FSM_FW_IDLE;
			o_fwd_vpu1_wr <= 1'b0;
		end
	end
end



/* Command decoder instance */
vxe_cu_cmd_decoder #(
	.VPUS_NR(2),
	.VERIFY_FMT(`VXE_CU_STRICT_CMDFMT)
) cmd_decode (
	.i_cmd(cmd_data_fifo[cmd_fifo_rp[1:0]]),
	.o_dec_err(cdec_err),
	.o_cu_cmd(cdec_cu_cmd),
	.o_cu_nop(cdec_cu_nop),
	.o_cu_sync(cdec_cu_sync),
	.o_cu_sync_stop(cdec_cu_sync_stop),
	.o_cu_sync_intr(cdec_cu_sync_intr),
	.o_vpu_cmd(cdec_vpu_cmd),
	.o_vpu_mask(cdec_vpu_mask),
	.o_vpu_op(cdec_vpu_op),
	.o_vpu_th(cdec_vpu_th),
	.o_vpu_pl(cdec_vpu_pl)
);


endmodule /* vxe_cu_dispatch_unit */
