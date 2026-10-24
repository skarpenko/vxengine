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
 * Hardware backend implementation
 */

#include <new>
#include <string>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <vxe_ioctl.h>
#include "hw_backend.hxx"


namespace {
	const std::string DEVICE_FILE = "/dev/vxengine";
	const uint32_t MAX_DEVICES_COUNT = 100;
	const uint32_t DEFAULT_VPU_MASK = 3;
}


HwDriverBackend::HwDriverBackend()
	: m_devCount(0)
{
	// Scan for available device files
	for(uint32_t i = 0; i < MAX_DEVICES_COUNT; ++i) {
		std::string dev = DEVICE_FILE + std::to_string(i);
		int fd = open(dev.c_str(), O_RDWR);
		if(fd < 0)
			break;
		close(fd);
		++m_devCount;
	}
}


HwDriverBackend::~HwDriverBackend()
{}


uint32_t HwDriverBackend::devicesCount() const
{
	return m_devCount;
}


int HwDriverBackend::deviceOpen(uint32_t no)
{
	if(no < m_devCount) {
		std::string dev = DEVICE_FILE + std::to_string(no);
		return open(dev.c_str(), O_RDWR);
	} else
		return -1;
}


int HwDriverBackend::deviceClose(int fd)
{
	return close(fd);
}


int HwDriverBackend::deviceGetinfo(int fd, uint32_t *hwid, uint32_t *vpus)
{
	struct vxe_device_info di;
	int err;

	err = static_cast<int>(ioctl(fd, VXE_IOCTL_DEVICE_GETINFO, &di));
	if(!err) {
		*hwid = di.hwid;
		*vpus = DEFAULT_VPU_MASK;
	}

	return err;
}


int HwDriverBackend::bufferCreate(int fd, uint32_t size, int map, int32_t *out_id, void **out_vaddr)
{
	union vxe_buffer_create bc;
	int err;

	bc.in.size = size;
	if(map)
		bc.in.flags |= VXE_BUFFER_CREATE_FLAG_MAP;

	err = static_cast<int>(ioctl(fd, VXE_IOCTL_BUFFER_CREATE, &bc));
	if(!err) {
		*out_id = bc.out.buf.id;
		if(map)
			*out_vaddr = bc.out.va.vaddr;
	}

	return err;
}


int HwDriverBackend::bufferDestroy(int fd, int32_t id)
{
	struct vxe_buffer_id buf;

	buf.id = id;

	return static_cast<int>(ioctl(fd, VXE_IOCTL_BUFFER_DESTROY, &buf));
}


int HwDriverBackend::bufferMap(int fd, int32_t id, void **out_vaddr)
{
	union vxe_buffer_map bm;
	int err;

	bm.in.id = id;

	err = static_cast<int>(ioctl(fd, VXE_IOCTL_BUFFER_MAP, &bm));
	if(!err)
		*out_vaddr = bm.out.vaddr;

	return err;
}


int HwDriverBackend::bufferUnmap(int fd, int32_t id)
{
	struct vxe_buffer_id buf;

	buf.id = id;

	return static_cast<int>(ioctl(fd, VXE_IOCTL_BUFFER_UNMAP, &buf));
}


int HwDriverBackend::cmdBufferCreate(int fd, uint64_t *program, uint32_t program_len,
	VxeBinding *bindings, uint32_t bindings_len, int32_t *out_id)
{
	union vxe_cmd_buffer_create cbc;
	int err;

	struct vxe_binding *kd_bindings = new(std::nothrow) struct vxe_binding[bindings_len];
	if(kd_bindings == nullptr)
		return -ENOMEM;

	for(uint32_t i = 0; i < bindings_len; ++i) {
		kd_bindings[i].buf.id = bindings[i].bufferId;
		kd_bindings[i].index = bindings[i].index;
	}

	cbc.in.program = reinterpret_cast<__u64*>(program);
	cbc.in.program_len = program_len;
	cbc.in.bindings = kd_bindings;
	cbc.in.bindings_len = bindings_len;

	err = static_cast<int>(ioctl(fd, VXE_IOCTL_CMD_BUFFER_CREATE, &cbc));
	if(!err)
		*out_id = cbc.out.cmd_buf.id;

	delete[] kd_bindings;

	return err;
}


int HwDriverBackend::cmdBufferRunpgm(int fd, int32_t id, uint64_t *out_fence)
{
	union vxe_cmd_buffer_runpgm rp;
	int err;

	rp.in.id = id;

	err = static_cast<int>(ioctl(fd, VXE_IOCTL_CMD_BUFFER_RUNPGM, &rp));
	if(!err)
		*out_fence = rp.out.seq;

	return err;
}


int HwDriverBackend::cmdBufferUpdate(int fd, int32_t id, VxeBinding *bindings, uint32_t bindings_len)
{
	struct vxe_cmd_buffer_update cbu;
	int err;

	struct vxe_binding *kd_bindings = new(std::nothrow) struct vxe_binding[bindings_len];
	if(kd_bindings == nullptr)
		return -ENOMEM;

	for(uint32_t i = 0; i < bindings_len; ++i) {
		kd_bindings[i].buf.id = bindings[i].bufferId;
		kd_bindings[i].index = bindings[i].index;
	}

	cbu.cmd_buf.id = id;
	cbu.bindings = kd_bindings;
	cbu.bindings_len = bindings_len;

	err = static_cast<int>(ioctl(fd, VXE_IOCTL_CMD_BUFFER_UPDATE, &cbu));

	delete[] kd_bindings;

	return err;
}


int HwDriverBackend::fenceWait(int fd, uint64_t fence)
{
	struct vxe_fence f;

	f.seq = fence;

	return static_cast<int>(ioctl(fd, VXE_IOCTL_FENCE_WAIT, &f));
}
