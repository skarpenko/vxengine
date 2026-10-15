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
 * Instance API functions
 */

#include <cstddef>
#include <new>
#include "instance.hxx"
#include "backend/swemu/swemu_backend.hxx"
#include "backend/hw/hw_backend.hxx"


VxResult Instance::init(const VxInstanceCreateInfo &createInfo)
{
	switch(createInfo.type) {
		case VX_INSTANCE_TYPE_HW:
			m_drv = new(std::nothrow) HwDriverBackend();
			break;
		case VX_INSTANCE_TYPE_SW:
			m_drv = new(std::nothrow) SwEmuDriverBackend(false);
			break;
		case VX_INSTANCE_TYPE_SW_MT:
			m_drv = new(std::nothrow) SwEmuDriverBackend(true);
			break;
		default:
			return VX_ERROR_INVALID;
	}

	for(uint32_t i = 0; i < m_drv->devicesCount(); ++i) {
		uint32_t hwid;
		int fd = m_drv->deviceOpen(i);
		if(fd < 0)
			continue;
		if(m_drv->deviceGetinfo(fd, &hwid)) {
			m_drv->deviceClose(fd);
			continue;
		}
		m_drv->deviceClose(fd);
		try {
			m_devices.push_back(Device(m_drv, i, hwid));
		}
		catch(...)
		{
			break;
		}
	}

	if(m_devices.empty()) {
		delete m_drv;
		return VX_ERROR_NO_DEVICE;
	}

	return VX_SUCCESS;
}


VxResult Instance::deinit()
{
	delete m_drv;
	return VX_SUCCESS;
}


void Instance::populateDevices(VxDevice *devices)
{
	for(size_t i = 0; i < m_devices.size(); ++i)
		devices[i] = reinterpret_cast<VxDevice>(&m_devices[i]);
}


VxResult vxCreateInstance(VxInstanceCreateInfo* pCreateInfo, VxInstance* pInstance)
{
	Instance *inst = new(std::nothrow) Instance();
	VxResult result;

	if(inst == nullptr)
		return VX_ERROR_NO_MEMORY;

	result = inst->init(*pCreateInfo);
	if(result != VX_SUCCESS) {
		delete inst;
		return result;
	}

	*pInstance = reinterpret_cast<VxInstance>(inst);

	return VX_SUCCESS;
}


VxResult vxDestroyInstance(VxInstance instance)
{
	Instance *inst = reinterpret_cast<Instance*>(instance);
	VxResult result;

	result = inst->deinit();
	if(result != VX_SUCCESS)
		return result;

	delete inst;

	return VX_SUCCESS;
}


VxResult vxEnumerateDevices(VxInstance instance, VxCount* pDeviceCount, VxDevice* pDevices)
{
	Instance *inst = reinterpret_cast<Instance*>(instance);

	*pDeviceCount = inst->getDeviceCount();

	if(pDevices)
		inst->populateDevices(pDevices);

	return VX_SUCCESS;
}
