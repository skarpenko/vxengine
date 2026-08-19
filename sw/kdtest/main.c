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
 * VxEngine Linux kernel driver tests
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <vxe_ioctl.h>


#define DEVICE_FILE	"/dev/vxengine0"
#define DEVICE_ID	0xFEFEFAFA
#define BUFFER_SIZE	4096

#define FAIL_CODE(adjust)	\
	(-(__LINE__ + (adjust)))


/* Test descriptor */
struct test_descr {
	const char *name;
	int (*func)();
};


/**************************** DRIVER FUNCTIONS ********************************/


int device_open()
{
	return open(DEVICE_FILE, O_RDWR);
}


int device_close(int fd)
{
	return close(fd);
}


int ioctl_device_getinfo(int fd, __u32 *hwid)
{
	struct vxe_device_info di;
	int err;

	err = (int)ioctl(fd, VXE_IOCTL_DEVICE_GETINFO, &di);
	if(!err)
		*hwid = di.hwid;

	return err;
}


int ioctl_buffer_create(int fd, __u32 size, int map, __s32 *out_id, void **out_vaddr)
{
	union vxe_buffer_create bc;
	int err;

	bc.in.size = size;
	if(map)
		bc.in.flags |= VXE_BUFFER_CREATE_FLAG_MAP;

	err = (int)ioctl(fd, VXE_IOCTL_BUFFER_CREATE, &bc);
	if(!err) {
		*out_id = bc.out.buf.id;
		if(map)
			*out_vaddr = bc.out.va.vaddr;
	}

	return err;
}


int ioctl_buffer_destroy(int fd, __s32 id)
{
	struct vxe_buffer_id buf;

	buf.id = id;

	return (int)ioctl(fd, VXE_IOCTL_BUFFER_DESTROY, &buf);
}


int ioctl_buffer_map(int fd, __s32 id, void **out_vaddr)
{
	union vxe_buffer_map bm;
	int err;

	bm.in.id = id;

	err = (int)ioctl(fd, VXE_IOCTL_BUFFER_MAP, &bm);
	if(!err)
		*out_vaddr = bm.out.vaddr;

	return err;
}


int ioctl_buffer_unmap(int fd, __s32 id)
{
	struct vxe_buffer_id buf;

	buf.id = id;

	return (int)ioctl(fd, VXE_IOCTL_BUFFER_UNMAP, &buf);
}


int ioctl_cmd_buffer_create(int fd, __u64 *program, __u32 program_len,
	struct vxe_binding *bindings, __u32 bindings_len, __s32 *out_id)
{
	union vxe_cmd_buffer_create cbc;
	int err;

	cbc.in.program = program;
	cbc.in.program_len = program_len;
	cbc.in.bindings = bindings;
	cbc.in.bindings_len = bindings_len;

	err = (int)ioctl(fd, VXE_IOCTL_CMD_BUFFER_CREATE, &cbc);
	if(!err)
		*out_id = cbc.out.cmd_buf.id;

	return err;
}


int ioctl_cmd_buffer_runpgm(int fd, __s32 id, __u64 *out_fence)
{
	union vxe_cmd_buffer_runpgm rp;
	int err;

	rp.in.id = id;

	err = (int)ioctl(fd, VXE_IOCTL_CMD_BUFFER_RUNPGM, &rp);
	if(!err)
		*out_fence = rp.out.seq;

	return err;
}


int ioctl_cmd_buffer_update(int fd, __s32 id, struct vxe_binding *bindings,
	__u32 bindings_len)
{
	struct vxe_cmd_buffer_update cbu;

	cbu.cmd_buf.id = id;
	cbu.bindings = bindings;
	cbu.bindings_len = bindings_len;

	return (int)ioctl(fd, VXE_IOCTL_CMD_BUFFER_UPDATE, &cbu);
}


int ioctl_fence_wait(int fd, __s32 id, __u64 fence)
{
	struct vxe_fence f;

	f.seq = fence;

	return (int)ioctl(fd, VXE_IOCTL_FENCE_WAIT, &f);
}


/***************************** TEST FUNCTIONS *********************************/


/*
 * Test: device open and close
 */
int kd_test_device_open_close()
{
	int fd;

	fd = device_open();
	if(fd < 0)
		return FAIL_CODE(-2);

	if(device_close(fd))
		return FAIL_CODE(-1);

	return 0;
}


/*
 * Test: read and check device Id
 */
int kd_test_device_id_check()
{
	int fd;
	int ret = 0;
	__u32 hwid;

	fd = device_open();
	if(fd < 0)
		return FAIL_CODE(-2);

	if(ioctl_device_getinfo(fd, &hwid)) {
		ret = FAIL_CODE(-1);
		goto err_device_close;
	}

	if(hwid != DEVICE_ID) {
		ret = FAIL_CODE(-1);
		goto err_device_close;
	}

	if(device_close(fd))
		return FAIL_CODE(-1);

	return 0;

err_device_close:
	device_close(fd);

	return ret;
}


/*
 * Test: buffer allocate and deallocate
 */
int kd_test_buffer_alloc_dealloc()
{
	int fd;
	int ret = 0;
	__s32 id;

	fd = device_open();
	if(fd < 0)
		return FAIL_CODE(-2);

	if(ioctl_buffer_create(fd, BUFFER_SIZE, 0, &id, NULL)) {
		ret = FAIL_CODE(-1);
		goto err_device_close;
	}

	if(ioctl_buffer_destroy(fd, id)) {
		ret = FAIL_CODE(-1);
		goto err_device_close;
	}

	if(device_close(fd))
		return FAIL_CODE(-1);

	return 0;

err_device_close:
	device_close(fd);

	return ret;
}


/*
 * Test: mapped buffer allocate and deallocate
 */
int kd_test_mapped_buffer_alloc_dealloc()
{
	int fd;
	__s32 id;
	int ret = 0;
	void *vaddr;

	fd = device_open();
	if(fd < 0)
		return FAIL_CODE(-2);

	if(ioctl_buffer_create(fd, BUFFER_SIZE, 1, &id, &vaddr)) {
		ret = FAIL_CODE(-1);
		goto err_device_close;
	}

	*(volatile __u32*)vaddr = 0xf1f1f1f1;	/* Must not trigger page fault */

	if(ioctl_buffer_destroy(fd, id)) {
		ret = FAIL_CODE(-1);
		goto err_device_close;
	}

	if(device_close(fd))
		return FAIL_CODE(-1);

	return 0;

err_device_close:
	device_close(fd);

	return ret;
}


/*
 * Test: buffer map and unmap
 */
int kd_test_buffer_map_unmap()
{
	int fd;
	int ret = 0;
	__s32 id;
	void *vaddr;

	fd = device_open();
	if(fd < 0)
		return FAIL_CODE(-2);

	if(ioctl_buffer_create(fd, BUFFER_SIZE, 0, &id, NULL)) {
		ret = FAIL_CODE(-1);
		goto err_device_close;
	}

	if(ioctl_buffer_map(fd, id, &vaddr)) {
		ret = FAIL_CODE(-1);
		goto err_destroy_buffer;
	}

	*(volatile __u32*)vaddr = 0xf1f1f1f1;	/* Must not trigger page fault */

	if(ioctl_buffer_unmap(fd, id)) {
		ret = FAIL_CODE(-1);
		goto err_destroy_buffer;
	}

	if(ioctl_buffer_destroy(fd, id)) {
		ret = FAIL_CODE(-1);
		goto err_device_close;
	}

	if(device_close(fd))
		return FAIL_CODE(-1);

	return 0;

err_destroy_buffer:
	ioctl_buffer_destroy(fd, id);

err_device_close:
	device_close(fd);

	return ret;
}


/*
 * Test: command buffer allocate and deallocate
 */
int kd_test_cmd_buffer_alloc_dealloc()
{
	int fd;
	int ret = 0;
	__s32 id, cmdid;
	__u64 program = 0;
	struct vxe_binding bindings;

	fd = device_open();
	if(fd < 0)
		return FAIL_CODE(-2);

	/* Allocate data buffer to bind to command buffer */
	if(ioctl_buffer_create(fd, BUFFER_SIZE, 0, &id, NULL)) {
		ret = FAIL_CODE(-1);
		goto err_device_close;
	}

	bindings.buf.id = id;
	bindings.index = 0;

	if(ioctl_cmd_buffer_create(fd, &program, 1, &bindings, 1, &cmdid)) {
		ret = FAIL_CODE(-1);
		goto err_destroy_buffer;
	}

	/* Must fail since the buffer is binded to command buffer */
	if(!ioctl_buffer_destroy(fd, id)) {
		ret = FAIL_CODE(-1);
		goto err_destroy_cmd_buffer;
	}

	if(ioctl_buffer_destroy(fd, cmdid)) {
		ret = FAIL_CODE(-1);
		goto err_destroy_buffer;
	}

	if(ioctl_buffer_destroy(fd, id)) {
		ret = FAIL_CODE(-1);
		goto err_device_close;
	}

	if(device_close(fd))
		return FAIL_CODE(-1);

	return 0;

err_destroy_cmd_buffer:
	ioctl_buffer_destroy(fd, cmdid);

err_destroy_buffer:
	ioctl_buffer_destroy(fd, id);

err_device_close:
	device_close(fd);

	return ret;
}


/*
 * Test: create command buffer for "bad" program
 *
 * Restrictions:
 *  - Enabled but not fully configured threads are not allowed.
 *  - "sync" command with "stop" and/or "int" flags set is not allowed.
 */
int kd_test_cmd_buffer_bad_program()
{
#include "prog/bad.h"
	int fd;
	int ret = 0;
	__s32 cmdid;
	__u64 *program = (__u64*)prog_bad_bin;
	__u32 program_len = prog_bad_bin_len / sizeof(__u64);

	fd = device_open();
	if(fd < 0)
		return FAIL_CODE(-2);

	/* Must fail */
	if(!ioctl_cmd_buffer_create(fd, program, program_len, NULL, 0, &cmdid)) {
		ret = FAIL_CODE(-1);
		goto err_destroy_cmd_buffer;
	}

	if(device_close(fd))
		return FAIL_CODE(-1);

	return 0;

err_destroy_cmd_buffer:
	ioctl_buffer_destroy(fd, cmdid);
	device_close(fd);

	return ret;
}


/*
 * Test: run program two times on two different data sets
 */
int kd_test_cmd_buffer_run_program()
{
#include "prog/prod.h"
	const int veclen = 100;
	int fd;
	int ret = 0;
	__s32 cmdid;
	int i;
	__u64 *program = (__u64*)prog_prod_bin;
	__u32 program_len = prog_prod_bin_len / sizeof(__u64);
	struct vxe_binding bindings1[3];
	struct vxe_binding bindings2[3];
	float *vaddr1[3];
	float *vaddr2[3];
	float ref1 = 0.0;
	float ref2 = 0.0;
	__u64 fence;

	/* Init binding structures */
	for(i = 0; i < 3; ++i) {
		bindings1[i].buf.id = bindings2[i].buf.id = -1;
	}

	fd = device_open();
	if(fd < 0)
		return FAIL_CODE(-2);

	/* Allocate data buffers */
	for(i = 0; i < 3; ++i) {
		__s32 id;
		void *vaddr;

		if(ioctl_buffer_create(fd, BUFFER_SIZE, 1, &id, &vaddr)) {
			ret = FAIL_CODE(-1);
			goto err_destroy_buffers;
		}

		bindings1[i].buf.id = id;
		bindings1[i].index = 0;
		vaddr1[i] = (float*)vaddr;

		/* Third buffer (destination) is common for two runs of the program */
		if(i == 2) {
			bindings2[i].buf.id = id;
			bindings2[i].index = 1;
			vaddr2[i] = (float*)vaddr;
			break;
		}

		if(ioctl_buffer_create(fd, BUFFER_SIZE, 1, &id, &vaddr)) {
			ret = FAIL_CODE(-1);
			goto err_destroy_buffers;
		}

		bindings2[i].buf.id = id;
		bindings2[i].index = 0;
		vaddr2[i] = (float*)vaddr;
	}

	/* Generate input vectors */
	for(i = 0; i < veclen; ++i) {
		vaddr1[0][i] = (float)(i + 1);
		vaddr1[1][i] = 1.0 / (float)(i + 1);
		ref1 += vaddr1[0][i] * vaddr1[1][i];	/* Reference value 1 */
	}
	for(i = 0; i < veclen; ++i) {
		vaddr2[0][i] = 2.0 * (float)(i + 1);
		vaddr2[1][i] = 2.0 / (float)(i + 1);
		ref2 += vaddr2[0][i] * vaddr2[1][i];	/* Reference value 2 */
	}

	/* Create command buffer */
	if(ioctl_cmd_buffer_create(fd, program, program_len, bindings1, 3, &cmdid)) {
		ret = FAIL_CODE(-1);
		goto err_destroy_buffers;
	}

	/* Run the program on the first data set */
	if(ioctl_cmd_buffer_runpgm(fd, cmdid, &fence)) {
		ret = FAIL_CODE(-1);
		goto err_destroy_cmd_buffer;
	}

	/* Wait for completion */
	if(ioctl_fence_wait(fd, cmdid, fence)) {
		ret = FAIL_CODE(-1);
		goto err_destroy_cmd_buffer;
	}

	/* Check result from the hardware */
	if(ref1 != vaddr1[2][0]) {
		ret = FAIL_CODE(-1);
		goto err_destroy_cmd_buffer;
	}

	/* Bind a new data set to the command buffer */
	if(ioctl_cmd_buffer_update(fd, cmdid, bindings2, 3)) {
		ret = FAIL_CODE(-1);
		goto err_destroy_cmd_buffer;
	}

	/* Run the program on the second data set */
	if(ioctl_cmd_buffer_runpgm(fd, cmdid, &fence)) {
		ret = FAIL_CODE(-1);
		goto err_destroy_cmd_buffer;
	}

	/* Wait for completion */
	if(ioctl_fence_wait(fd, cmdid, fence)) {
		ret = FAIL_CODE(-1);
		goto err_destroy_cmd_buffer;
	}

	/* Check result from the hardware */
	if(ref2 != vaddr2[2][1]) {
		ret = FAIL_CODE(-1);
		goto err_destroy_cmd_buffer;
	}

	if(device_close(fd))
		return FAIL_CODE(-1);

	return 0;


err_destroy_cmd_buffer:
	ioctl_buffer_destroy(fd, cmdid);

err_destroy_buffers:
	for(i = 0; i < 3; ++i) {
		if(bindings1[i].buf.id != -1)
			ioctl_buffer_destroy(fd, bindings1[i].buf.id);

		if(i == 2)
			break;

		if(bindings2[i].buf.id != -1)
			ioctl_buffer_destroy(fd, bindings2[i].buf.id);
	}

	device_close(fd);

	return ret;
}


struct test_descr kd_tests_list[] = {
	{
		.name = "Device open and close",
		.func = kd_test_device_open_close
	},
	{
		.name = "Device Id check",
		.func = kd_test_device_id_check
	},
	{
		.name = "Buffer alloc and dealloc",
		.func = kd_test_buffer_alloc_dealloc
	},
	{
		.name = "Mapped buffer alloc and dealloc",
		.func = kd_test_mapped_buffer_alloc_dealloc
	},
	{
		.name = "Buffer map and unmap",
		.func = kd_test_buffer_map_unmap
	},
	{
		.name = "Cmd buffer alloc and dealloc",
		.func = kd_test_cmd_buffer_alloc_dealloc
	},
	{
		.name = "Cmd buffer for bad program",
		.func = kd_test_cmd_buffer_bad_program
	},
	{
		.name = "Run program from cmd buffer",
		.func = kd_test_cmd_buffer_run_program
	},
	/***/
	{ NULL, NULL }
};


/******************************** MAIN ****************************************/


int main()
{
	struct test_descr *itr;
	int fail = 0;
	int pass = 0;

	printf(
		"VxE Linux kernel driver test suite\n"
		"==================================\n\n"
	);

	itr = &kd_tests_list[0];
	while(itr->name) {
		int res;
		printf("%-33s ... ", itr->name);
		res = itr->func();
		if(res) {
			++fail;
			printf("FAIL (Code: %d)\n", res);
		} else {
			++pass;
			printf("PASS\n");
		}
		++itr;
	}

	printf(
		"\n==================================\n"
		"PASSED = %d, FAILED = %d\n", pass, fail
	);

	return fail ? -1 : 0;
}
