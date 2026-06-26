/*
 * Copyright (c) 2020-2026 The VxEngine Project. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef __VXE_IOCTL_H
#define __VXE_IOCTL_H

#include <linux/types.h>
#include <linux/ioctl.h>

#ifndef __user
#  define __user
#endif


#define VXE_IOCTL	'v'	/* IOCTL magic */


/* Maximum number of commands in a program */
#define VXE_IOCTL_MAX_COMMANDS	8192
/* Maximum number of bindings per program/command buffer */
#define VXE_IOCTL_MAX_BINDINGS	(VXE_IOCTL_MAX_COMMANDS>>1)


struct vxe_device_info {
	__u32 hwid;
};


struct vxe_buffer_id {
	__s32 id;
};


struct vxe_buffer_va {
	void *vaddr;
};


struct vxe_fence {
	__u64 seq;
};


union vxe_buffer_create {
	struct {
		__u32 size;
		__u32 flags;
	} in;
	struct {
		struct vxe_buffer_id buf;
		struct vxe_buffer_va va;	/* Valid if MAP flag set */
	} out;
};
#define VXE_BUFFER_CREATE_FLAG_MAP	(1<<0)	/* Map newly created buffer */


union vxe_buffer_map {
	struct vxe_buffer_id in;
	struct vxe_buffer_va out;
};


struct vxe_binding {
	struct vxe_buffer_id buf;	/* Buffer Id */
	__u32 index;			/* Index of fp32 value within the buffer */
};


union vxe_cmd_buffer_create {
	struct {
		/* Commands that need to be verified and converted into a valid program */
		__u64 __user *program;
		__u32 program_len;
		/* Each setrs, setrt, setrd command must have a corresponding buffer binding */
		struct vxe_binding __user *bindings;
		__u32 bindings_len;
	} in;
	struct {
		struct vxe_buffer_id cmd_buf;
	} out;
};


union vxe_cmd_buffer_runpgm {
	struct vxe_buffer_id in;
	struct vxe_fence out;
};


/*
 * Update existing bindings of a command buffer
 * "bindings_len" must be the same as when the buffer was created,
 * source and destination storages cannot be less in size than originally binded.
 */
struct vxe_cmd_buffer_update {
	struct vxe_buffer_id cmd_buf;
	struct vxe_binding __user *bindings;
	__u32 bindings_len;
};


#define VXE_IOCTL_DEVICE_GETINFO	_IOR (VXE_IOCTL, 0x00, struct vxe_device_info)

#define VXE_IOCTL_BUFFER_CREATE		_IOWR(VXE_IOCTL, 0x01, union vxe_buffer_create)
#define VXE_IOCTL_BUFFER_DESTROY	_IOW (VXE_IOCTL, 0x02, struct vxe_buffer_id)
#define VXE_IOCTL_BUFFER_MAP		_IOWR(VXE_IOCTL, 0x03, union vxe_buffer_map)
#define VXE_IOCTL_BUFFER_UNMAP		_IOW (VXE_IOCTL, 0x04, struct vxe_buffer_id)

#define VXE_IOCTL_CMD_BUFFER_CREATE	_IOWR(VXE_IOCTL, 0x05, union vxe_cmd_buffer_create)
#define VXE_IOCTL_CMD_BUFFER_RUNPGM	_IOWR(VXE_IOCTL, 0x06, union vxe_cmd_buffer_runpgm)
#define VXE_IOCTL_CMD_BUFFER_UPDATE	_IOW (VXE_IOCTL, 0x07, struct vxe_cmd_buffer_update)

#define VXE_IOCTL_FENCE_WAIT		_IOW (VXE_IOCTL, 0x08, struct vxe_fence)


#endif /* __VXE_IOCTL_H */
