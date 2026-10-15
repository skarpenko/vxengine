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
 * Software emulation backend implementation specific classes
 */

#include <cstdint>
#include <map>
#include <queue>
#include <vector>
#include "swemu_exec.hxx"
#pragma once


// Unique Id manager
class IdManager {
	std::queue<int> m_avail;	// Recently freed Ids
	int m_next;			// Next available new Id
	const int m_max;		// Max. number of Ids available
public:
	explicit IdManager(int max, int next = 0)
		: m_next(next), m_max(max)
	{}

	int alloc()
	{
		int id = -1;
		if(!m_avail.empty()) {
			id = m_avail.front();
			m_avail.pop();
		} else if(m_next < m_max) {
			id = m_next++;
		}
		return id;
	}

	void free(int id)
	{
		try {
			m_avail.push(id);
		}
		catch(...)
		{ /* Fail silently */ }
	}
};


// Base buffer class
class SwEmuBuffer {
	int m_id;
	void *m_data;
	uint32_t m_size;
	unsigned m_bindCount;
protected:
	bool m_valid;
public:
	SwEmuBuffer(int id, uint32_t size);
	virtual ~SwEmuBuffer();

	SwEmuBuffer(const SwEmuBuffer&) = delete;
	SwEmuBuffer& operator=(const SwEmuBuffer&) = delete;

	int id() const { return m_id; }
	void *data() const { return m_data; }
	uint32_t size() const { return m_size; }
	bool valid() const { return m_valid; }

	bool locked() const { return m_bindCount != 0; }
	unsigned getBindCount() const { return m_bindCount; }
	void incBindCount() { ++m_bindCount; }
	void decBindCount() { ++m_bindCount; }
};


// Data buffer class
class SwEmuDataBuffer: public SwEmuBuffer {
public:
	SwEmuDataBuffer(int id, uint32_t length);
	~SwEmuDataBuffer() = default;

	float *floatData() const { return reinterpret_cast<float*>(data()); }
	uint32_t length() const { return size() / sizeof(float); }
};


// Command buffer class
class SwEmuCmdBuffer: public SwEmuBuffer {
public:
	struct R {
		SwEmuDataBuffer	*data;	// Data buffer
		uint32_t	index;	// Index into data buffer
		int		vlen;	// Vector length used in program (not used if -1)
		uint32_t	cmdpc;	// Command index that uses resource (not used if vlen=-1)
		R() {
			data = nullptr;
			index = 0;
			vlen = -1;
			cmdpc = -1;
		}
	};

	SwEmuCmdBuffer(int id, uint32_t progLen, uint32_t resLen);
	~SwEmuCmdBuffer();

	uint64_t *progData() const { return reinterpret_cast<uint64_t*>(data()); }
	uint32_t progLength() const { return size() / sizeof(uint64_t); }

	R *resData() const { return m_res; }
	uint32_t resLength() const { return m_resLen; }

private:
	uint32_t m_resLen;
	R *m_res;
};


inline SwEmuDataBuffer* toDataBuffer(SwEmuBuffer *buffer)
{
	return dynamic_cast<SwEmuDataBuffer*>(buffer);
}

inline SwEmuCmdBuffer* toCmdBuffer(SwEmuBuffer *buffer)
{
	return dynamic_cast<SwEmuCmdBuffer*>(buffer);
}

inline bool isDataBuffer(SwEmuBuffer *buffer)
{
	return toDataBuffer(buffer) != nullptr;
}

inline bool isCmdBuffer(SwEmuBuffer *buffer)
{
	return toCmdBuffer(buffer) != nullptr;
}


// Context class
class SwEmuContext {
	uint32_t m_devId;
	int m_fd;
	IdManager m_idMan;
	std::map<int, SwEmuBuffer*> m_buffers;
	ProgramExecutor m_executor;
public:
	SwEmuContext(uint32_t devId, int fd, int maxBufs, uint32_t vpumask, bool use_mt);
	~SwEmuContext();

	SwEmuContext(const SwEmuContext&) = delete;
	SwEmuContext& operator=(const SwEmuContext&) = delete;

	bool isMT() const { return m_executor.isMT(); }

	uint32_t devId() const { return m_devId; }
	int fd() const { return m_fd; }

	int allocId() { return m_idMan.alloc(); }
	void deallocId(int id) { m_idMan.free(id); }

	bool insertBuffer(SwEmuBuffer *buffer);
	SwEmuBuffer *getBuffer(int id);
	bool deleteBuffer(int id, bool dealloc = true);

	void execute(SwEmuCmdBuffer *cmdBuf)
	{
		m_executor.execute(cmdBuf);
	}
};


// Implementation class
class SwEmuDriverBackendImpl {
	IdManager m_fdMan;
	std::map<int, SwEmuContext*> m_contexts;
public:
	explicit SwEmuDriverBackendImpl(int maxContexts);
	~SwEmuDriverBackendImpl();

	SwEmuDriverBackendImpl(const SwEmuDriverBackendImpl&) = delete;
	SwEmuDriverBackendImpl& operator=(const SwEmuDriverBackendImpl&) = delete;

	int allocFd() { return m_fdMan.alloc(); }
	void deallocFd(int fd) { m_fdMan.free(fd); }

	bool insertContext(SwEmuContext *context);
	SwEmuContext *getContext(int fd);
	bool deleteContext(int fd, bool dealloc = true);
};
