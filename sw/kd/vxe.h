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

#ifndef __VXE_H
#define __VXE_H

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/platform_device.h>
#include <linux/io.h>
#include <linux/of.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/atomic.h>
#include <linux/kthread.h>
#include <linux/workqueue.h>
#include <linux/mutex.h>
#include <linux/list.h>
#include <linux/idr.h>
#include <linux/fs.h>


#define CLASS_NAME		"vxe_dev"
#define DEVICE_NAME		"vxengine"
#define MAX_MINOR_NUM		32
#define MAX_MAX_JOBS_LIMIT	128
#define MAX_BUFFERS_PER_CTX	8192


extern int max_jobs_per_ctx;
extern int job_timeout_sec;


/* Device struct */
struct vxe_device {
	int			id;		/* Device Id number (minor) */
	int			major;		/* Major number */
	dev_t			devn;		/* Device number (major:minor) */

	struct device		*dev;		/* Device object */
	struct platform_device	*pdev;		/* Platform device object */
	struct class		*class;		/* Device class */

	int			irq;		/* IRQ number */
	void __iomem		*ioregs;	/* MMIO region */

	struct cdev		cdev;		/* CharDev */

	struct task_struct	*sched_task;	/* Jobs scheduler thread */

	struct vxe_job		*cur_job;	/* Currently dispatched job */

	spinlock_t		job_queue_lock;	/* Job queue lock */
	struct list_head	job_queue;	/* Job queue */

	atomic64_t		finished_seq;	/* Last finished job seq number */
	atomic64_t		active_seq;	/* Newest active job seq number */

	wait_queue_head_t	sched_wq;	/* Scheduler wait queue */
	wait_queue_head_t	user_wq;	/* User wait queue */
};


/* Register numbers */
#define VXE_DEVICE_REG_ID			0	/* HW ID (ro) */
#define VXE_DEVICE_REG_CTRL			1	/* Control (rw) */
#define VXE_DEVICE_REG_STATUS			2	/* Status (ro) */
#define VXE_DEVICE_REG_INTR_ACT			3	/* Active interrupts (rw) */
#define VXE_DEVICE_REG_INTR_MSK			4	/* Interrupts mask (rw) */
#define VXE_DEVICE_REG_INTR_RAW			5	/* Raw interrupts (ro) */
#define VXE_DEVICE_REG_PGM_ADDR_LO		6	/* Program address /low/ (rw) */
#define VXE_DEVICE_REG_PGM_ADDR_HI		7	/* Program address /high/ (rw) */
#define VXE_DEVICE_REG_START			8	/* Start program execution (wo) */
#define VXE_DEVICE_REG_FAULT_INSTR_ADDR_LO	9	/* Faulted instr. address /low/ (ro) */
#define VXE_DEVICE_REG_FAULT_INSTR_ADDR_HI	10	/* Faulted instr. address /high/ (ro) */
#define VXE_DEVICE_REG_FAULT_INSTR_LO		11	/* Faulted instruction /low/ (ro) */
#define VXE_DEVICE_REG_FAULT_INSTR_HI		12	/* Faulted instruction /high/ (ro) */
#define VXE_DEVICE_REG_FAULT_VPU_MASK0		13	/* Faulted VPUs mask (ro) */

/* Register bits */
#define VXE_DEVICE_REG_CTRL_CU_MAS_SEL_BIT	0x00000001	/* Control unit master select */
#define VXE_DEVICE_REG_STATUS_BUSY_BIT		0x00000001	/* Busy state */
#define VXE_DEVICE_REG_INTR_COMPLETED_BIT	0x00000001	/* Program complete */
#define VXE_DEVICE_REG_INTR_ERR_FETCH_BIT	0x00000002	/* Command fetch error */
#define VXE_DEVICE_REG_INTR_ERR_INSTR_BIT	0x00000004	/* Command decode error */
#define VXE_DEVICE_REG_INTR_ERR_DATA_BIT	0x00000008	/* Data load/store error */


/* Read device register */
static inline
u32 vxe_device_rdreg(struct vxe_device *vxdev, int regno)
{
	return readl(vxdev->ioregs + (regno*4));
}


/* Write device register */
static inline
void vxe_device_wrreg(struct vxe_device *vxdev, int regno, u32 val)
{
	writel(val, vxdev->ioregs + (regno*4));
}


/* Context struct */
struct vxe_context {
	struct vxe_device	*vxdev;			/* Device the context refers to */

	pid_t			owner;			/* Owning process (PID) */

	int			max_jobs;		/* Max. jobs allowed */
	atomic_t		num_jobs;		/* Current number of jobs on the fly */

	struct mutex		buffers_idr_lock;	/* Buffers storage lock */
	struct idr		buffers_idr;		/* Buffers storage */
};


/* Buffer struct */
struct vxe_buffer {
	int			id;		/* Buffer Id */
	dma_addr_t		dma_addr;	/* DMA address */
	void			*cpu_addr;	/* CPU address (Kernel address) */
	size_t			size;		/* Buffer size */

	struct vxe_context	*ctx;		/* Owner context */

	u32			flags;		/* Flags (see below) */

	unsigned		bind_count;	/* Number of bindings (users) */

	unsigned long		user_addr;	/* User address, valid if MAPPED flag set */
};
#define VXE_BUF_F_MAPPED	(1<<0)	/* Buffer is mapped to userspace */
#define VXE_BUF_F_LOCKED	(1<<1)	/* Locked buffer. Cannot be destroyed */
#define VXE_BUF_F_CMDBUF	(1<<31)	/* Command buffer. Cannot be mapped to userspace */
/*
 * Locked buffers are either regular buffers binded to a command buffer or command buffers on the fly
*/


/* Check if buffer is mapped */
static inline
bool vxe_buf_mapped(struct vxe_buffer *buf)
{
	return (buf->flags & VXE_BUF_F_MAPPED) != 0;
}


/* Check if buffer is locked */
static inline
bool vxe_buf_locked(struct vxe_buffer *buf)
{
	return (buf->flags & VXE_BUF_F_LOCKED) != 0;
}


/* Check if command buffer */
static inline
bool vxe_buf_cmdbuf(struct vxe_buffer *buf)
{
	return (buf->flags & VXE_BUF_F_CMDBUF) != 0;
}


/* Command buffer struct */
struct vxe_cmd_buffer {
	struct vxe_buffer	buf;	/* Storage buffer (do not move this field) */
	struct vxe_prog_res	*res;	/* Program resources */
};

/* Cast buffer to command buffer */
static inline
struct vxe_cmd_buffer* vxe_buf2cbuf(struct vxe_buffer *buffer)
{
	return container_of(buffer, struct vxe_cmd_buffer, buf);
}


/* Job struct */
struct vxe_job {
	struct list_head	list_node;	/* List node */

	struct vxe_context	*ctx;		/* Owning context */

	struct vxe_cmd_buffer	*cbuf;		/* Command buffer */
	u64			seq;		/* Job sequence number */

	u32			intr_state;	/* Interrupt state (set by ISR) */
	atomic_t		done;		/* Job done (set by ISR) */
};


/* VPU thread state struct */
struct vxe_thread_state {
	int	en_st;	/* Thread enable:
			 * -1 - undefined;
			 *  0 - explicitly disabled;
			 *  1 - explicitly enabled.
			 */

	int	a_set;	/* Accumulator: 0 - not set; 1 - set */

	int	rs_idx;	/* Rs buffer index. -1 - not set */
	int	rs_len;	/* Rs length */
	int	rt_idx;	/* Rt buffer index. -1 - not set */
	int	rt_len;	/* Rt length */

	int	rd_idx;	/* Rd buffer index. -1 - not set */
	int	rd_len;	/* Rd length */

	int	vlen;	/* Vectors length. -1 - not set */
};


/* Program resource */
struct vxe_prog_res {
	size_t			nres;		/* Number of resources */
	struct vxe_buffer	**bufs;		/* Binded buffers */
	int			*vlens;		/* Vector lengths (-1 for unused) */
	size_t			*cmdixs;	/* Cmd indexes that refer buffers (-1 for no ref) */
};


#define VXE_NR_VPU	2	/* Number of VPUs */
#define VXE_NR_THR	8	/* Number of threads per VPU */

/* Program state struct */
struct vxe_prog_state {
	struct vxe_context	*ctx;					/* Context */

	struct vxe_prog_res	*res;					/* Program resources */
	u32			*indexes;				/* Indexes passed by user */
	size_t			curres;					/* Current resource index */

	struct vxe_thread_state	ts[VXE_NR_VPU][VXE_NR_THR];		/* Threads state */

	u64			*prog;					/* Program array */
	size_t			prog_len;				/* Program length */

	int			npost;					/* Postamble len */
	u64			postamble[1];				/* Postamble */
};


/* Device */
struct vxe_device* vxe_device_register(struct platform_device *pdev, struct class *class, dev_t devn);
void vxe_device_unregister(struct vxe_device *vxdev);


/* Context */
struct vxe_context* vxe_context_create(struct vxe_device *vxdev, pid_t owner, int max_jobs);
void vxe_context_destroy(struct vxe_context *ctx);
bool vxe_context_owner_valid(struct vxe_context *ctx);
static inline struct vxe_context* vxe_fil2ctx(struct file *file)
{
	return (struct vxe_context*)file->private_data;
}


/* Buffers */
struct vxe_buffer* vxe_buffer_create(struct vxe_context *ctx, size_t size, bool cmd_buf);
void vxe_buffer_destroy_raw_unlocked(struct vxe_buffer *buf);
int vxe_buffer_destroy(struct vxe_context *ctx, int id);
int vxe_buffer_mmap(struct vxe_context *ctx, int id, void **user_addr);
int vxe_buffer_munmap(struct vxe_context *ctx, int id);
void vxe_buffer_bind_unlocked(struct vxe_buffer **buf, size_t count);
void vxe_buffer_unbind_unlocked(struct vxe_buffer **buf, size_t count);
struct vxe_buffer* vxe_buffer_find_unlocked(struct vxe_context *ctx, int id);
void vxe_buffer_ctx_lock(struct vxe_context *ctx);
void vxe_buffer_ctx_unlock(struct vxe_context *ctx);


/* Program */
struct vxe_prog_state* vxe_prog_state_create(struct vxe_context *ctx, size_t proglen, size_t nres);
void vxe_prog_state_destroy(struct vxe_prog_state *state);
struct vxe_prog_res* vxe_prog_res_create(size_t nres);
void vxe_prog_res_destroy(struct vxe_prog_res *res);
static inline size_t vxe_prog_len(struct vxe_prog_state *state)
{
	return state->prog_len + state->npost;
}
int vxe_prog_assemble(struct vxe_prog_state *state);
void vxe_prog_move_to_cbuf(struct vxe_prog_state *state, struct vxe_cmd_buffer *cbuf);
struct vxe_buffer** vxe_prog_swap_res(struct vxe_cmd_buffer *cbuf, struct vxe_buffer **buffers,
	u32 *indexes);


/* ioctl handlers */
long vxe_ioctl_device_getinfo(struct vxe_context *ctx, void __user *arg);
long vxe_ioctl_buffer_create(struct vxe_context *ctx, void __user *arg);
long vxe_ioctl_buffer_destroy(struct vxe_context *ctx, void __user *arg);
long vxe_ioctl_buffer_map(struct vxe_context *ctx, void __user *arg);
long vxe_ioctl_buffer_unmap(struct vxe_context *ctx, void __user *arg);
long vxe_ioctl_cmd_buffer_create(struct vxe_context *ctx, void __user *arg);
long vxe_ioctl_cmd_buffer_runpgm(struct vxe_context *ctx, void __user *arg);
long vxe_ioctl_cmd_buffer_update(struct vxe_context *ctx, void __user *arg);
long vxe_ioctl_fence_wait(struct vxe_context *ctx, void __user *arg);


#endif /* __VXE_H */
