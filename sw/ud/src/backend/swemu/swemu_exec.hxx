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
 * Program executor
 */

#include <cstdint>
#include <thread>
#include <atomic>
#include "swemu_sema.hxx"
#pragma once


class SwEmuCmdBuffer;


class ProgramExecutor {
	static constexpr unsigned VXE_NR_VPU = 2;	// Number of VPUs
	static constexpr unsigned VXE_NR_THR = 8;	// Number of threads per VPU

	// VPU thread state
	struct ThreadState {
		bool		en;
		float		acc;
		float		*rs;
		float		*rt;
		float		*rd;
		uint32_t	vlen;

		ThreadState()
		{
			reset();
		}

		void reset()
		{
			en = false;
			acc = 0.0;
			rs = nullptr;
			rt = nullptr;
			rd = nullptr;
			vlen = 0;
		}
	};

	struct MTSupport {
		std::thread		thrd;	// Thread object
		Sema			ready;	// Work is ready
		Sema			done;	// Work complete
		std::atomic<bool>	stop;	// Stop thread
		MTSupport()
			: ready(0, 1), done(0, 1), stop(false)
		{}
		~MTSupport()
		{
			if(thrd.joinable()) {
				stop.store(true);
				ready.signal();
				thrd.join();
			}
		}
	};

	// Threads state
	ThreadState m_threads[VXE_NR_VPU][VXE_NR_THR];

	// Optional multithreading support
	MTSupport *m_MT;

	// VPUs mask
	uint32_t m_vpuMask;

	// Command buffer
	SwEmuCmdBuffer *m_cmdBuf;

	// Check if VPU is enabled by mask
	bool isEnabledVPU(unsigned vpu);

	// Parse destination field of the command
	void parseDst(unsigned dst, unsigned *vpu, unsigned *th);

	// SETACC command
	void execSETACC(uint32_t pc);

	// SETVL command
	void execSETVL(uint32_t pc);

	// SETRS command
	void execSETRS(uint32_t pc);

	// SETRT command
	void execSETRT(uint32_t pc);

	// SETRD command
	void execSETRD(uint32_t pc);

	// SETEN command
	void execSETEN(uint32_t pc);

	// PROD command
	void execPROD_ST(uint32_t pc);
	void execPROD_MT(uint32_t pc);

	// STORE command
	void execSTORE(uint32_t pc);

	// ACTF command
	void execACTF(uint32_t pc);

	// Vector product
	void compVecProd(unsigned vpu, unsigned th);

public:
	ProgramExecutor(uint32_t vpuMask, bool mt);
	~ProgramExecutor();

	ProgramExecutor(const ProgramExecutor&) = delete;
	ProgramExecutor& operator=(const ProgramExecutor&) = delete;

	void execute(SwEmuCmdBuffer *cmdBuf);

	// Check if in multithreaded mode
	bool isMT() const { return m_MT != nullptr; }
};
