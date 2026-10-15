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
 * Program verification and assembly
 */

#include <cstdint>
#pragma once


class SwEmuCmdBuffer;


class ProgramAssembler {
	static constexpr unsigned VXE_NR_VPU = 2;	// Number of VPUs
	static constexpr unsigned VXE_NR_THR = 8;	// Number of threads per VPU

	// VPU thread state
	struct ThreadState {
		// Thread enable:
		// -1 - undefined;
		//  0 - explicitly disabled;
		//  1 - explicitly enabled.
		int	en_st;
		// Accumulator: 0 - not set; 1 - set
		int	a_set;
		// Rs buffer index. -1 - not set
		int	rs_idx;
		// Rs length
		int	rs_len;
		// Rt buffer index. -1 - not set
		int	rt_idx;
		// Rt length
		int	rt_len;
		// Rd buffer index. -1 - not set
		int	rd_idx;
		// Rd length
		int	rd_len;
		// Vectors length. -1 - not set
		int	vlen;

		ThreadState()
		{
			reset();
		}

		void reset()
		{
			en_st = -1;
			a_set = 0;
			rs_idx = -1;
			rs_len = 0;
			rt_idx = -1;
			rt_len = 0;
			rd_idx = -1;
			rd_len = 0;
			vlen = -1;
		}
	};

	// Threads state
	ThreadState m_threads[VXE_NR_VPU][VXE_NR_THR];

	// Current resource index
	uint32_t m_currentRes;

	// Command buffer
	SwEmuCmdBuffer *m_cmdBuf;

	// Parse destination field of the command
	void parseDst(unsigned dst, unsigned *vpu, unsigned *th);

	// Index of the next resource
	uint32_t nextRes();

	// Check if resource index is valid
	bool isValidRes(uint32_t ri);

	// Verify state for PROD command
	int verifPROD(unsigned vpu);

	// Verify state for STORE command
	int verifSTORE(unsigned vpu);

	// SETACC command
	int prepSETACC(uint32_t pc);

	// SETVL command
	int prepSETVL(uint32_t pc);

	// SETRS command
	int prepSETRS(uint32_t pc);

	// SETRT command
	int prepSETRT(uint32_t pc);

	// SETRD command
	int prepSETRD(uint32_t pc);

	// SETEN command
	int prepSETEN(uint32_t pc);

	// PROD command
	int prepPROD(uint32_t pc);

	// STORE command
	int prepSTORE(uint32_t pc);

	// SYNC command
	int prepSYNC(uint32_t pc);

public:
	// Number of required additional command slots in the command buffer
	static constexpr unsigned NRSVD = 1;

	ProgramAssembler(SwEmuCmdBuffer *cmdBuf);
	~ProgramAssembler() = default;

	ProgramAssembler(const ProgramAssembler&) = delete;
	ProgramAssembler& operator=(const ProgramAssembler&) = delete;

	int prepareProg();

	void reset(SwEmuCmdBuffer *cmdBuf);
};
