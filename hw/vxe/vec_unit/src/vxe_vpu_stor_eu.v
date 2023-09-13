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
 * VxE VPU store execution unit
 */


/* Store execution unit */
module vxe_vpu_stor_eu(
	clk,
	nrst,
	/* Control unit interface */
	i_start,
	o_busy,
	/* LSU interface */
	i_lsu_wrq_rdy,
	o_lsu_wrq_wr,
	o_lsu_wrq_th,
	o_lsu_wrq_addr,
	o_lsu_wrq_wen,
	o_lsu_wrq_data,
	/* Register values */
	i_th0_acc,
	i_th0_en,
	i_th0_rd,
	i_th1_acc,
	i_th1_en,
	i_th1_rd,
	i_th2_acc,
	i_th2_en,
	i_th2_rd,
	i_th3_acc,
	i_th3_en,
	i_th3_rd,
	i_th4_acc,
	i_th4_en,
	i_th4_rd,
	i_th5_acc,
	i_th5_en,
	i_th5_rd,
	i_th6_acc,
	i_th6_en,
	i_th6_rd,
	i_th7_acc,
	i_th7_en,
	i_th7_rd
);
/* Requests prepare FSM states */
localparam [3:0]	FSM_RQP_IDLE = 4'h0;	/* Idle */
localparam [3:0]	FSM_RQP_STOR0 = 4'h1;	/* Store for thread 0 */
localparam [3:0]	FSM_RQP_STOR1 = 4'h2;	/* Store for thread 1 */
localparam [3:0]	FSM_RQP_STOR2 = 4'h3;	/* Store for thread 2 */
localparam [3:0]	FSM_RQP_STOR3 = 4'h4;	/* Store for thread 3 */
localparam [3:0]	FSM_RQP_STOR4 = 4'h5;	/* Store for thread 4 */
localparam [3:0]	FSM_RQP_STOR5 = 4'h6;	/* Store for thread 5 */
localparam [3:0]	FSM_RQP_STOR6 = 4'h7;	/* Store for thread 6 */
localparam [3:0]	FSM_RQP_STOR7 = 4'h8;	/* Store for thread 7 */
/* Global signals */
input wire		clk;
input wire		nrst;
/* Control unit interface */
input wire		i_start;
output wire		o_busy;
/* LSU interface */
input wire		i_lsu_wrq_rdy;
output reg		o_lsu_wrq_wr;
output reg [2:0]	o_lsu_wrq_th;
output reg [36:0]	o_lsu_wrq_addr;
output reg [1:0]	o_lsu_wrq_wen;
output reg [63:0]	o_lsu_wrq_data;
/* Register values */
input wire [31:0]	i_th0_acc;
input wire		i_th0_en;
input wire [37:0]	i_th0_rd;
input wire [31:0]	i_th1_acc;
input wire		i_th1_en;
input wire [37:0]	i_th1_rd;
input wire [31:0]	i_th2_acc;
input wire		i_th2_en;
input wire [37:0]	i_th2_rd;
input wire [31:0]	i_th3_acc;
input wire		i_th3_en;
input wire [37:0]	i_th3_rd;
input wire [31:0]	i_th4_acc;
input wire		i_th4_en;
input wire [37:0]	i_th4_rd;
input wire [31:0]	i_th5_acc;
input wire		i_th5_en;
input wire [37:0]	i_th5_rd;
input wire [31:0]	i_th6_acc;
input wire		i_th6_en;
input wire [37:0]	i_th6_rd;
input wire [31:0]	i_th7_acc;
input wire		i_th7_en;
input wire [37:0]	i_th7_rd;



/* Write combine conditions */
wire wc0_cond = i_th0_en && i_th1_en && (i_th0_rd[37:1] == i_th1_rd[37:1]);
wire wc2_cond = i_th2_en && i_th3_en && (i_th2_rd[37:1] == i_th3_rd[37:1]);
wire wc4_cond = i_th4_en && i_th5_en && (i_th4_rd[37:1] == i_th5_rd[37:1]);
wire wc6_cond = i_th6_en && i_th7_en && (i_th6_rd[37:1] == i_th7_rd[37:1]);



/* FIFO for outgoing write requests */
reg [2:0]	wrq_th_fifo[0:3];	/* Thread Id */
reg [36:0]	wrq_addr_fifo[0:3];	/* Address */
reg [1:0]	wrq_wen_fifo[0:3];	/* Write enable */
reg [31:0]	wrq_data_lo_fifo[0:3];	/* Data low half */
reg [31:0]	wrq_data_hi_fifo[0:3];	/* Data high half */
reg [2:0]	wrq_fifo_rp;		/* Read pointer */
reg [2:0]	wrq_fifo_wp;		/* Write pointer */
/* FIFO states */
wire wrq_fifo_empty = (wrq_fifo_rp[1:0] == wrq_fifo_wp[1:0]) &&
	(wrq_fifo_rp[2] == wrq_fifo_wp[2]);
wire wrq_fifo_full = (wrq_fifo_rp[1:0] == wrq_fifo_wp[1:0]) &&
	(wrq_fifo_rp[2] != wrq_fifo_wp[2]);


/* Valid stores mask */
reg [7:0] stor_mask;
wire stor_done = ~(|stor_mask);


/* Requests prepare FSM */
reg [3:0] fsm_rqp_state;
always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		fsm_rqp_state <= FSM_RQP_IDLE;
		wrq_fifo_wp <= 3'b000;
	end
	else
	begin
		case(fsm_rqp_state)
		/** IDLE **/
		FSM_RQP_IDLE: begin
			if(i_start)
			begin
				fsm_rqp_state <= FSM_RQP_STOR0;
				stor_mask <= { i_th7_en, i_th6_en, i_th5_en,
					i_th4_en, i_th3_en, i_th2_en, i_th1_en,
					i_th0_en };
			end
		end
		/** STOR0 **/
		FSM_RQP_STOR0: begin
			if(!stor_done && i_th0_en && !wrq_fifo_full)
			begin
				wrq_th_fifo[wrq_fifo_wp[1:0]] <= 3'h0;
				wrq_addr_fifo[wrq_fifo_wp[1:0]] <= i_th0_rd[37:1];

				stor_mask[0] <= 1'b0;

				/* Write combine? */
				if(wc0_cond)
				begin
					stor_mask[1] <= 1'b0;

					wrq_wen_fifo[wrq_fifo_wp[1:0]] <= 2'b11;
					wrq_data_lo_fifo[wrq_fifo_wp[1:0]] <=
							~i_th0_rd[0] ? i_th0_acc : i_th1_acc;
					wrq_data_hi_fifo[wrq_fifo_wp[1:0]] <=
							i_th1_rd[0] ? i_th1_acc : i_th0_acc;
				end
				else if(~i_th0_rd[0])	/* Low word */
				begin
					wrq_wen_fifo[wrq_fifo_wp[1:0]] <= 2'b01;
					wrq_data_lo_fifo[wrq_fifo_wp[1:0]] <= i_th0_acc;
				end
				else			/* High word */
				begin
					wrq_wen_fifo[wrq_fifo_wp[1:0]] <= 2'b10;
					wrq_data_hi_fifo[wrq_fifo_wp[1:0]] <= i_th0_acc;
				end

				wrq_fifo_wp <= wrq_fifo_wp + 1'b1;

				fsm_rqp_state <= wc0_cond ? FSM_RQP_STOR2 : FSM_RQP_STOR1;
			end
			else if(!stor_done && !i_th0_en)
				fsm_rqp_state <= FSM_RQP_STOR1;
			else if(stor_done)
				fsm_rqp_state <= FSM_RQP_IDLE;
		end
		/** STOR1 **/
		FSM_RQP_STOR1: begin
			if(!stor_done && i_th1_en && !wrq_fifo_full)
			begin
				wrq_th_fifo[wrq_fifo_wp[1:0]] <= 3'h1;
				wrq_addr_fifo[wrq_fifo_wp[1:0]] <= i_th1_rd[37:1];

				stor_mask[1] <= 1'b0;

				if(~i_th1_rd[0])	/* Low word */
				begin
					wrq_wen_fifo[wrq_fifo_wp[1:0]] <= 2'b01;
					wrq_data_lo_fifo[wrq_fifo_wp[1:0]] <= i_th1_acc;
				end
				else			/* High word */
				begin
					wrq_wen_fifo[wrq_fifo_wp[1:0]] <= 2'b10;
					wrq_data_hi_fifo[wrq_fifo_wp[1:0]] <= i_th1_acc;
				end

				wrq_fifo_wp <= wrq_fifo_wp + 1'b1;

				fsm_rqp_state <= FSM_RQP_STOR2;
			end
			else if(!stor_done && !i_th1_en)
				fsm_rqp_state <= FSM_RQP_STOR2;
			else if(stor_done)
				fsm_rqp_state <= FSM_RQP_IDLE;
		end
		/** STOR2 **/
		FSM_RQP_STOR2: begin
			if(!stor_done && i_th2_en && !wrq_fifo_full)
			begin
				wrq_th_fifo[wrq_fifo_wp[1:0]] <= 3'h2;
				wrq_addr_fifo[wrq_fifo_wp[1:0]] <= i_th2_rd[37:1];

				stor_mask[2] <= 1'b0;

				/* Write combine? */
				if(wc2_cond)
				begin
					stor_mask[3] <= 1'b0;

					wrq_wen_fifo[wrq_fifo_wp[1:0]] <= 2'b11;
					wrq_data_lo_fifo[wrq_fifo_wp[1:0]] <=
							~i_th2_rd[0] ? i_th2_acc : i_th3_acc;
					wrq_data_hi_fifo[wrq_fifo_wp[1:0]] <=
							i_th3_rd[0] ? i_th3_acc : i_th2_acc;
				end
				else if(~i_th2_rd[0])	/* Low word */
				begin
					wrq_wen_fifo[wrq_fifo_wp[1:0]] <= 2'b01;
					wrq_data_lo_fifo[wrq_fifo_wp[1:0]] <= i_th2_acc;
				end
				else			/* High word */
				begin
					wrq_wen_fifo[wrq_fifo_wp[1:0]] <= 2'b10;
					wrq_data_hi_fifo[wrq_fifo_wp[1:0]] <= i_th2_acc;
				end

				wrq_fifo_wp <= wrq_fifo_wp + 1'b1;

				fsm_rqp_state <= wc2_cond ? FSM_RQP_STOR4 : FSM_RQP_STOR3;
			end
			else if(!stor_done && !i_th2_en)
				fsm_rqp_state <= FSM_RQP_STOR3;
			else if(stor_done)
				fsm_rqp_state <= FSM_RQP_IDLE;
		end
		/** STOR3 **/
		FSM_RQP_STOR3: begin
			if(!stor_done && i_th3_en && !wrq_fifo_full)
			begin
				wrq_th_fifo[wrq_fifo_wp[1:0]] <= 3'h3;
				wrq_addr_fifo[wrq_fifo_wp[1:0]] <= i_th3_rd[37:1];

				stor_mask[3] <= 1'b0;

				if(~i_th3_rd[0])	/* Low word */
				begin
					wrq_wen_fifo[wrq_fifo_wp[1:0]] <= 2'b01;
					wrq_data_lo_fifo[wrq_fifo_wp[1:0]] <= i_th3_acc;
				end
				else			/* High word */
				begin
					wrq_wen_fifo[wrq_fifo_wp[1:0]] <= 2'b10;
					wrq_data_hi_fifo[wrq_fifo_wp[1:0]] <= i_th3_acc;
				end

				wrq_fifo_wp <= wrq_fifo_wp + 1'b1;

				fsm_rqp_state <= FSM_RQP_STOR4;
			end
			else if(!stor_done && !i_th3_en)
				fsm_rqp_state <= FSM_RQP_STOR4;
			else if(stor_done)
				fsm_rqp_state <= FSM_RQP_IDLE;
		end
		/** STOR4 **/
		FSM_RQP_STOR4: begin
			if(!stor_done && i_th4_en && !wrq_fifo_full)
			begin
				wrq_th_fifo[wrq_fifo_wp[1:0]] <= 3'h4;
				wrq_addr_fifo[wrq_fifo_wp[1:0]] <= i_th4_rd[37:1];

				stor_mask[4] <= 1'b0;

				/* Write combine? */
				if(wc4_cond)
				begin
					stor_mask[5] <= 1'b0;

					wrq_wen_fifo[wrq_fifo_wp[1:0]] <= 2'b11;
					wrq_data_lo_fifo[wrq_fifo_wp[1:0]] <=
							~i_th4_rd[0] ? i_th4_acc : i_th5_acc;
					wrq_data_hi_fifo[wrq_fifo_wp[1:0]] <=
							i_th5_rd[0] ? i_th5_acc : i_th4_acc;
				end
				else if(~i_th4_rd[0])	/* Low word */
				begin
					wrq_wen_fifo[wrq_fifo_wp[1:0]] <= 2'b01;
					wrq_data_lo_fifo[wrq_fifo_wp[1:0]] <= i_th4_acc;
				end
				else			/* High word */
				begin
					wrq_wen_fifo[wrq_fifo_wp[1:0]] <= 2'b10;
					wrq_data_hi_fifo[wrq_fifo_wp[1:0]] <= i_th4_acc;
				end

				wrq_fifo_wp <= wrq_fifo_wp + 1'b1;

				fsm_rqp_state <= wc4_cond ? FSM_RQP_STOR6 : FSM_RQP_STOR5;
			end
			else if(!stor_done && !i_th4_en)
				fsm_rqp_state <= FSM_RQP_STOR5;
			else if(stor_done)
				fsm_rqp_state <= FSM_RQP_IDLE;
		end
		/** STOR5 **/
		FSM_RQP_STOR5: begin
			if(!stor_done && i_th5_en && !wrq_fifo_full)
			begin
				wrq_th_fifo[wrq_fifo_wp[1:0]] <= 3'h5;
				wrq_addr_fifo[wrq_fifo_wp[1:0]] <= i_th5_rd[37:1];

				stor_mask[5] <= 1'b0;

				if(~i_th5_rd[0])	/* Low word */
				begin
					wrq_wen_fifo[wrq_fifo_wp[1:0]] <= 2'b01;
					wrq_data_lo_fifo[wrq_fifo_wp[1:0]] <= i_th5_acc;
				end
				else			/* High word */
				begin
					wrq_wen_fifo[wrq_fifo_wp[1:0]] <= 2'b10;
					wrq_data_hi_fifo[wrq_fifo_wp[1:0]] <= i_th5_acc;
				end

				wrq_fifo_wp <= wrq_fifo_wp + 1'b1;

				fsm_rqp_state <= FSM_RQP_STOR6;
			end
			else if(!stor_done && !i_th5_en)
				fsm_rqp_state <= FSM_RQP_STOR6;
			else if(stor_done)
				fsm_rqp_state <= FSM_RQP_IDLE;
		end
		/** STOR6 **/
		FSM_RQP_STOR6: begin
			if(!stor_done && i_th6_en && !wrq_fifo_full)
			begin
				wrq_th_fifo[wrq_fifo_wp[1:0]] <= 3'h6;
				wrq_addr_fifo[wrq_fifo_wp[1:0]] <= i_th6_rd[37:1];

				stor_mask[6] <= 1'b0;

				/* Write combine? */
				if(wc6_cond)
				begin
					stor_mask[7] <= 1'b0;

					wrq_wen_fifo[wrq_fifo_wp[1:0]] <= 2'b11;
					wrq_data_lo_fifo[wrq_fifo_wp[1:0]] <=
							~i_th6_rd[0] ? i_th6_acc : i_th7_acc;
					wrq_data_hi_fifo[wrq_fifo_wp[1:0]] <=
							i_th7_rd[0] ? i_th7_acc : i_th6_acc;
				end
				else if(~i_th6_rd[0])	/* Low word */
				begin
					wrq_wen_fifo[wrq_fifo_wp[1:0]] <= 2'b01;
					wrq_data_lo_fifo[wrq_fifo_wp[1:0]] <= i_th6_acc;
				end
				else			/* High word */
				begin
					wrq_wen_fifo[wrq_fifo_wp[1:0]] <= 2'b10;
					wrq_data_hi_fifo[wrq_fifo_wp[1:0]] <= i_th6_acc;
				end

				wrq_fifo_wp <= wrq_fifo_wp + 1'b1;

				fsm_rqp_state <= wc6_cond ? FSM_RQP_IDLE : FSM_RQP_STOR7;
			end
			else if(!stor_done && !i_th6_en)
				fsm_rqp_state <= FSM_RQP_STOR7;
			else if(stor_done)
				fsm_rqp_state <= FSM_RQP_IDLE;
		end
		/** STOR7 **/
		FSM_RQP_STOR7: begin
			if(!stor_done && i_th7_en && !wrq_fifo_full)
			begin
				wrq_th_fifo[wrq_fifo_wp[1:0]] <= 3'h7;
				wrq_addr_fifo[wrq_fifo_wp[1:0]] <= i_th7_rd[37:1];

				stor_mask[7] <= 1'b0;

				if(~i_th7_rd[0])	/* Low word */
				begin
					wrq_wen_fifo[wrq_fifo_wp[1:0]] <= 2'b01;
					wrq_data_lo_fifo[wrq_fifo_wp[1:0]] <= i_th7_acc;
				end
				else			/* High word */
				begin
					wrq_wen_fifo[wrq_fifo_wp[1:0]] <= 2'b10;
					wrq_data_hi_fifo[wrq_fifo_wp[1:0]] <= i_th7_acc;
				end

				wrq_fifo_wp <= wrq_fifo_wp + 1'b1;

				fsm_rqp_state <= FSM_RQP_IDLE;
			end
			else if(!stor_done && !i_th7_en) /* SHOULD NEVER HAPPEN */
				$display("Invalid state: !stor_done && !i_th7_en");
			else if(stor_done)
				fsm_rqp_state <= FSM_RQP_IDLE;
		end
		default: $display("Wrong value of fsm_rqp_state");
		endcase
	end

end



/* Requests transmission FSM */
reg fsm_tx_en;
always @(posedge clk or negedge nrst)
begin
	if(!nrst)
	begin
		fsm_tx_en <= 1'b0;
		o_lsu_wrq_wr <= 1'b0;
		wrq_fifo_rp <= 3'b000;
	end
	else if(fsm_tx_en == 1'b0)
	begin
		if(!wrq_fifo_empty)
		begin
			fsm_tx_en <= 1'b1;
			o_lsu_wrq_wr <= 1'b1;
			o_lsu_wrq_th <= wrq_th_fifo[wrq_fifo_rp[1:0]];
			o_lsu_wrq_addr <= wrq_addr_fifo[wrq_fifo_rp[1:0]];
			o_lsu_wrq_wen <= wrq_wen_fifo[wrq_fifo_rp[1:0]];
			o_lsu_wrq_data <= { wrq_data_hi_fifo[wrq_fifo_rp[1:0]],
					wrq_data_lo_fifo[wrq_fifo_rp[1:0]] };
			wrq_fifo_rp <= wrq_fifo_rp + 1'b1;
		end
	end
	else if(i_lsu_wrq_rdy)
	begin
		if(!wrq_fifo_empty)
		begin
			o_lsu_wrq_th <= wrq_th_fifo[wrq_fifo_rp[1:0]];
			o_lsu_wrq_addr <= wrq_addr_fifo[wrq_fifo_rp[1:0]];
			o_lsu_wrq_wen <= wrq_wen_fifo[wrq_fifo_rp[1:0]];
			o_lsu_wrq_data <= { wrq_data_hi_fifo[wrq_fifo_rp[1:0]],
					wrq_data_lo_fifo[wrq_fifo_rp[1:0]] };
			wrq_fifo_rp <= wrq_fifo_rp + 1'b1;
		end
		else
		begin
			fsm_tx_en <= 1'b0;
			o_lsu_wrq_wr <= 1'b0;
		end
	end
end


/* Busy condition */
assign o_busy = fsm_tx_en || !wrq_fifo_empty || (fsm_rqp_state != FSM_RQP_IDLE);


endmodule /* vxe_vpu_stor_eu */
