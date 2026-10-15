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
 * Semaphore implementation
 */

#include <mutex>
#include <condition_variable>


class Sema {
	std::mutex m_mutex;
	int m_count;
	const int m_maxCount;
	std::condition_variable m_condVar;
public:
	Sema()
		: m_count(0), m_maxCount(1)
	{}
	Sema(int count, int maxCount)
		: m_count(count), m_maxCount(maxCount)
	{}
	~Sema() = default;

	void down()
	{
		std::unique_lock<std::mutex> lock(m_mutex);
		m_condVar.wait(lock, [=]{ return m_count > 0; });
		--m_count;
	}

	bool try_down()
	{
		std::lock_guard<std::mutex> lock(m_mutex);
		if (m_count > 0) {
			--m_count;
			return true;
		} else
			return false;
	}

	void up()
	{
		std::lock_guard<std::mutex> lock(m_mutex);
		if (m_count < m_maxCount) {
			++m_count;
			m_condVar.notify_one();
		}
	}

	void lock() { down(); }
	bool try_lock() { return try_down(); }
	void unlock() { up(); }

	void wait() { down(); }
	bool try_wait() { return try_down(); }
	void signal() { up(); }
};
