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
 * Code generator
 */

#include <cstddef>
#include <vector>
#include "backend.hxx"
#pragma once


class CodeGenerator {
	struct Thread {
		uint16_t vpu;
		uint16_t thr;
		int en;
		Thread(uint16_t v, uint16_t t, int e = -1)
			: vpu(v), thr(t), en(e)
		{}
	};

	std::vector<Thread> m_inactive;		// Disabled threads (masked using VPU mask)
	std::vector<Thread> m_threads;		// Available threads
	size_t m_curThread;			// Current thread for use

	unsigned makeDst(uint16_t vpu, uint16_t th);

public:
	std::vector<uint64_t> program;		// Generated program code
	std::vector<VxeBinding> bindings;	// Bindings / resources

	CodeGenerator(uint32_t vpus, uint32_t vpuMask);
	~CodeGenerator() = default;

	size_t totalThreads() const { return m_threads.size(); }
	size_t availThreads() const { return totalThreads() - m_curThread; }

	void reset();

	void prepare();	// Must be called first after reset() to init disabled threads
	bool allocThread(float accum, VxeBinding rs, VxeBinding rt, VxeBinding rd, size_t length);
	void finalize();

	void execProd();
	void execStore();
	void execRELU();
	void execLRELU(int ed);
	void execSync();
};
