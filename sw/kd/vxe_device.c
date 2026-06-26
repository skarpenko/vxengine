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

#include <linux/interrupt.h>
#include <linux/dma-mapping.h>
#include <linux/jiffies.h>
#include <linux/slab.h>
#include <linux/pid.h>
#include "vxe.h"
#include "vxe_ioctl.h"


/* ISR */
static irqreturn_t vxe_irq_handler(int irq, void *dev_id)
{
	struct vxe_device *vxdev = (struct vxe_device *)dev_id;
	struct vxe_job *job = vxdev->cur_job;
	u32 active_intr;

	if(job) {
		/* Copy raw interrupts state */
		job->intr_state = vxe_device_rdreg(vxdev, VXE_DEVICE_REG_INTR_RAW);

		/* Mark job as finished */
		atomic_set(&job->done, 1);

		/* Wake up job scheduler */
		wake_up(&vxdev->sched_wq);
	} else
		dev_warn(vxdev->dev, "Spurious interrupt?\n");

	/* Acknowledge active interrupts */
	active_intr = vxe_device_rdreg(vxdev, VXE_DEVICE_REG_INTR_ACT);
	vxe_device_wrreg(vxdev, VXE_DEVICE_REG_INTR_ACT, active_intr);

	return IRQ_HANDLED;
}


/* Scheduler thread func */
static int vxe_sched_task_func(void *data)
{
	struct vxe_device *vxdev = (struct vxe_device*)data;

	while (!kthread_should_stop()) {
		struct vxe_job *job = NULL;
		int res = 0;
		unsigned long flags;
		u64 prog_addr;

		/* Wait for a job or stop request */
		wait_event_interruptible(vxdev->sched_wq,
			!list_empty(&vxdev->job_queue) || kthread_should_stop());

		if(kthread_should_stop())
			break;

		/* Fetch new job */
		spin_lock_irqsave(&vxdev->job_queue_lock, flags);
		job = list_first_entry(&vxdev->job_queue, struct vxe_job, list_node);
		list_del(&job->list_node);
		spin_unlock_irqrestore(&vxdev->job_queue_lock, flags);

		/* Start program on accelerator */
		vxdev->cur_job = job;
		prog_addr = job->cbuf->buf.dma_addr;
		vxe_device_wrreg(vxdev, VXE_DEVICE_REG_PGM_ADDR_LO, prog_addr & 0xffffffff);
		vxe_device_wrreg(vxdev, VXE_DEVICE_REG_PGM_ADDR_HI, prog_addr >> 32);
		vxe_device_wrreg(vxdev, VXE_DEVICE_REG_START, 0);

		/* Wait for completion */
		res = wait_event_timeout(vxdev->sched_wq,
			atomic_read(&job->done) != 0, msecs_to_jiffies(1000 * job_timeout_sec));
		vxdev->cur_job = NULL;
		if(res == 0) {
			u32 stat = vxe_device_rdreg(vxdev, VXE_DEVICE_REG_STATUS);
			dev_err(vxdev->dev, "Device hung or timeout is short!\n");
			dev_err(vxdev->dev, "Device status: %s\n",
				stat & VXE_DEVICE_REG_STATUS_BUSY_BIT ? "Busy" : "Idle");
		}

		/* Check for errors */
		if(res && job->intr_state != VXE_DEVICE_REG_INTR_COMPLETED_BIT) {
			dev_warn(vxdev->dev, "Job %llu Error: fetch_err=%d, cmd_err=%d, data_err=%d\n",
				job->seq,
				!!(job->intr_state & VXE_DEVICE_REG_INTR_ERR_FETCH_BIT),
				!!(job->intr_state & VXE_DEVICE_REG_INTR_ERR_INSTR_BIT),
				!!(job->intr_state & VXE_DEVICE_REG_INTR_ERR_DATA_BIT)
			);
		} else if(!res && !job->intr_state) {
			dev_warn(vxdev->dev, "Job %llu dropped.\n", job->seq);
		}

		atomic_dec(&job->ctx->num_jobs);

		/* Unbind command buffer  */
		vxe_buffer_ctx_lock(job->ctx);
		{
			struct vxe_buffer *buf = &job->cbuf->buf;
			vxe_buffer_unbind_unlocked(&buf, 1);
		}
		vxe_buffer_ctx_unlock(job->ctx);

		kfree(job);

		/* Increment completed job sequence number */
		atomic64_inc(&vxdev->finished_seq);

		/* Wake up user threads if any */
		wake_up_interruptible(&vxdev->user_wq);
	}

	return 0;
}


static int vxe_device_open(struct inode *inode, struct file *file)
{
	struct vxe_device *vxdev =
		container_of(inode->i_cdev, struct vxe_device, cdev);

	struct vxe_context *ctx = vxe_context_create(vxdev, task_tgid_vnr(current),
		max_jobs_per_ctx);
	if(IS_ERR(ctx))
		return PTR_ERR(ctx);

	file->private_data = ctx;

	nonseekable_open(inode, file);

	dev_info(vxdev->dev, "Device opened!\n");

	return 0;
}


static int vxe_device_release(struct inode *inode, struct file *file)
{
	struct vxe_context *ctx = vxe_fil2ctx(file);

	vxe_context_destroy(ctx);

	return 0;
}


static long vxe_device_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
{
	struct vxe_context *ctx = vxe_fil2ctx(file);
	struct vxe_device *vxdev = ctx->vxdev;
	void __user *uarg = (void __user *)arg;
	long ret = 0;

	/* Child forks cannot use parent context */
	if(!vxe_context_owner_valid(ctx)) {
		dev_info(vxdev->dev, "Context cannot be used!\n");
		return -EACCES;
	}

	switch(cmd) {
		case VXE_IOCTL_DEVICE_GETINFO:
			ret = vxe_ioctl_device_getinfo(ctx, uarg);
			break;
		case VXE_IOCTL_BUFFER_CREATE:
			ret = vxe_ioctl_buffer_create(ctx, uarg);
			break;
		case VXE_IOCTL_BUFFER_DESTROY:
			ret = vxe_ioctl_buffer_destroy(ctx, uarg);
			break;
		case VXE_IOCTL_BUFFER_MAP:
			ret = vxe_ioctl_buffer_map(ctx, uarg);
			break;
		case VXE_IOCTL_BUFFER_UNMAP:
			ret = vxe_ioctl_buffer_unmap(ctx, uarg);
			break;
		case VXE_IOCTL_CMD_BUFFER_CREATE:
			ret = vxe_ioctl_cmd_buffer_create(ctx, uarg);
			break;
		case VXE_IOCTL_CMD_BUFFER_RUNPGM:
			ret = vxe_ioctl_cmd_buffer_runpgm(ctx, uarg);
			break;
		case VXE_IOCTL_CMD_BUFFER_UPDATE:
			ret = vxe_ioctl_cmd_buffer_update(ctx, uarg);
			break;
		case VXE_IOCTL_FENCE_WAIT:
			ret = vxe_ioctl_fence_wait(ctx, uarg);
			break;
		default:
			ret = -ENOTTY;
			break;
	}

	return ret;
}


const struct file_operations vxe_device_fops = {
	.owner = THIS_MODULE,
	.open = vxe_device_open,
	.release = vxe_device_release,
	.unlocked_ioctl = vxe_device_ioctl
};


struct vxe_device* vxe_device_register(struct platform_device *pdev, struct class *class, dev_t devn)
{
	struct vxe_device *vxdev;
	struct resource *iomem;
	struct device *dev;
	char *dev_name;
	int irq;
	int err;

	/* Try to set DMA mask */
	err = dma_set_mask_and_coherent(&pdev->dev, DMA_BIT_MASK(40));
	if(err) {
		dev_err(&pdev->dev, "Failed to set 40-bit DMA mask, fallback to 32-bit mask!\n");
		err = dma_set_mask_and_coherent(&pdev->dev, DMA_BIT_MASK(32));
		if(err) {
			dev_err(&pdev->dev, "Failed to set DMA mask!\n");
			return ERR_PTR(err);
		}
	}

	/* Get IRQ resource */
	irq = platform_get_irq(pdev, 0);
	if(irq < 0) {
		dev_err(&pdev->dev, "No IRQ provided!\n");
		return ERR_PTR(-ENOENT);
	}

	/* Get MMIO region resource */
	iomem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	if(!iomem) {
		dev_err(&pdev->dev, "No MMIO region provided!\n");
		return ERR_PTR(-ENOENT);
	}

	/* Allocate device struct */
	vxdev = kzalloc(sizeof(struct vxe_device), GFP_KERNEL);
	if(!vxdev)
		return ERR_PTR(-ENOMEM);

	vxdev->id = MINOR(devn);
	vxdev->major = MAJOR(devn);
	vxdev->devn = devn;
	vxdev->dev = &pdev->dev;
	vxdev->pdev = pdev;
	vxdev->class = class;
	vxdev->irq = irq;

	INIT_LIST_HEAD(&vxdev->job_queue);
	spin_lock_init(&vxdev->job_queue_lock);

	init_waitqueue_head(&vxdev->sched_wq);
	init_waitqueue_head(&vxdev->user_wq);


	dev_name = devm_kasprintf(vxdev->dev, GFP_KERNEL, DEVICE_NAME "%d", vxdev->id); 
	if(!dev_name)
		dev_name = DEVICE_NAME;

	/* Setup IRQ hadnler */
	err = devm_request_irq(vxdev->dev, vxdev->irq, vxe_irq_handler, 0, dev_name, vxdev);
	if(err) {
		dev_err(vxdev->dev, "Cannot set IRQ handler!\n");
		goto err_free_dev_data;
	}

	/* Map I/O regrion */
	vxdev->ioregs = devm_ioremap_resource(vxdev->dev, iomem);
	if(IS_ERR(vxdev->ioregs)) {
		dev_err(vxdev->dev, "Cannot map MMIO space!\n");
		err = PTR_ERR(vxdev->ioregs);
		goto err_free_irq;
	}

	/* Start scheduler thread */
	vxdev->sched_task = kthread_run(vxe_sched_task_func, vxdev, dev_name);
	if(IS_ERR(vxdev->sched_task)) {
		dev_err(vxdev->dev, "Cannot start kernel thread!\n");
		err = PTR_ERR(vxdev->sched_task);
		goto err_free_irq;
	}

	/* Init characrer device */
	cdev_init(&vxdev->cdev, &vxe_device_fops);
	vxdev->cdev.owner = THIS_MODULE;

	/* Now make the device available */
	err = cdev_add(&vxdev->cdev, vxdev->devn, 1);
	if(err < 0) {
		dev_err(vxdev->dev, "Cannot add character device!\n");
		goto err_stop_sched_task;
	}

	/* Expose device to userspace  */
	dev = device_create(vxdev->class, vxdev->dev, vxdev->devn, vxdev, DEVICE_NAME "%d", vxdev->id);
	if(IS_ERR(dev)) {
		dev_err(vxdev->dev, "Cannot create device!\n");
		err = PTR_ERR(dev);
		goto err_stop_sched_task;
	}


	return vxdev;

err_stop_sched_task:
	kthread_stop(vxdev->sched_task);

err_free_irq:
	devm_free_irq(vxdev->dev, vxdev->irq, vxdev);

err_free_dev_data:
	kfree(vxdev);

	return ERR_PTR(err);
}


void vxe_device_unregister(struct vxe_device *vxdev)
{
	device_destroy(vxdev->class, vxdev->devn);

	cdev_del(&vxdev->cdev);

	kthread_stop(vxdev->sched_task);

	devm_free_irq(vxdev->dev, vxdev->irq, vxdev);

	kfree(vxdev);
}
