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

#include <linux/slab.h>
#include <linux/dma-mapping.h>
#include <linux/mm.h>
#include <linux/mman.h>
#include "vxe.h"


struct vxe_buffer* vxe_buffer_create(struct vxe_context *ctx, size_t size, bool cmd_buf)
{
	struct vxe_buffer *buf;
	int id;

	/* Alloc buffer structure (regular or command buffer) */
	buf = kzalloc(cmd_buf ? sizeof(struct vxe_cmd_buffer) : sizeof(struct vxe_buffer), GFP_KERNEL);
	if(!buf)
		return ERR_PTR(-ENOMEM);

	buf->ctx = ctx;
	buf->size = size;

	/* Map to kernel space */
	buf->cpu_addr = dma_alloc_coherent(ctx->vxdev->dev, size, &buf->dma_addr, GFP_KERNEL);
	if(!buf->cpu_addr) {
		kfree(buf);
		return ERR_PTR(-ENOMEM);
	}

	/* Store into buffer storage.
	 * Newly created buffers are locked with bind_count = 1.
	 */
	vxe_buffer_ctx_lock(ctx);
	id = idr_alloc(&ctx->buffers_idr, buf, 0, MAX_BUFFERS_PER_CTX, GFP_KERNEL);
	buf->id = id;
	buf->flags |= VXE_BUF_F_LOCKED;
	buf->bind_count = 1;
	if(cmd_buf)
		buf->flags |= VXE_BUF_F_CMDBUF;
	vxe_buffer_ctx_unlock(ctx);

	if(id < 0) {
		dma_free_coherent(ctx->vxdev->dev, size, buf->cpu_addr, buf->dma_addr);
		kfree(buf);
		return ERR_PTR(id);
	}

	return buf;
}


void vxe_buffer_destroy_raw_unlocked(struct vxe_buffer *buf)
{
	int err;

	/* Unmap if the buffer is mapped to user space */
	if(vxe_buf_mapped(buf)) {
		err = vm_munmap(buf->user_addr, buf->size);
		if(err) {
			dev_err(buf->ctx->vxdev->dev, "Failed to unmap buffer on destroy.\n");
		}
	}

	/* If the buffer is command buffer - unbind all resource buffers */
	if(vxe_buf_cmdbuf(buf)) {
		struct vxe_cmd_buffer *cbuf = vxe_buf2cbuf(buf);

		vxe_buffer_unbind_unlocked(cbuf->res->bufs, cbuf->res->nres);

		vxe_prog_res_destroy(cbuf->res);
	}

	dma_free_coherent(buf->ctx->vxdev->dev, buf->size, buf->cpu_addr, buf->dma_addr);

	kfree(buf);
}


int vxe_buffer_destroy(struct vxe_context *ctx, int id)
{
	struct vxe_buffer *buf;
	int err = 0;

	vxe_buffer_ctx_lock(ctx);
	buf = (struct vxe_buffer *)idr_find(&ctx->buffers_idr, id);
	if(buf) {
		/* Locked buffers cannot be destroyed */
		if(vxe_buf_locked(buf))
			err = -EPERM;
		else
			idr_remove(&ctx->buffers_idr, id);
	} else
		err = -ENOENT;
	vxe_buffer_ctx_unlock(ctx);

	if(err)
		return err;

	vxe_buffer_ctx_lock(ctx);
	vxe_buffer_destroy_raw_unlocked(buf);
	vxe_buffer_ctx_unlock(ctx);

	return 0;
}


int vxe_buffer_mmap(struct vxe_context *ctx, int id, void **user_addr)
{
	struct mm_struct *mm = current->mm;
	struct vm_area_struct *vma;
	struct vxe_buffer *buf;
	int err = 0;

	vxe_buffer_ctx_lock(ctx);
	buf = (struct vxe_buffer *)idr_find(&ctx->buffers_idr, id);
	if(buf) {
		/* Command buffers cannot be mapped */
		if(vxe_buf_cmdbuf(buf))
			err = -EPERM;
	} else
		err = -ENOENT;

	if(err)
		goto err_unlock_buffers;

	/* If the buffer is already mapped */
	if(vxe_buf_mapped(buf)) {
		if(user_addr)
			*user_addr = (void*)buf->user_addr;
		return 0;
	}

	/* Create user space mapping */
	buf->user_addr = vm_mmap(NULL, 0, buf->size, PROT_READ | PROT_WRITE,
		MAP_ANONYMOUS | MAP_SHARED, 0);
	if(buf->user_addr >= TASK_SIZE) {
		dev_err(ctx->vxdev->dev, "Failed to create mapping.");
		err = PTR_ERR((void*)buf->user_addr);
		goto err_unlock_buffers;
	}

	if(user_addr)
		*user_addr = (void*)buf->user_addr;

	/* Populate mapping */
	down_write(&mm->mmap_sem);
	vma = find_vma(mm, buf->user_addr);
	if(vma && vma->vm_start == buf->user_addr && (buf->user_addr + buf->size) <= vma->vm_end) {
		unsigned long bak;

		/* Temporarily backup vm_pgoff */
		bak = vma->vm_pgoff;
		vma->vm_pgoff = 0;

		err = dma_mmap_coherent(ctx->vxdev->dev, vma, buf->cpu_addr, buf->dma_addr, buf->size);

		vma->vm_pgoff = bak;
	} else {
		dev_err(ctx->vxdev->dev, "Mapping not found.");
		err = -ENOENT;
	}
	up_write(&mm->mmap_sem);


	if(!err) {
		vma->vm_flags |= VM_DONTCOPY;
		buf->flags |= VXE_BUF_F_MAPPED;
	} else
		goto err_unlock_buffers;


	vxe_buffer_ctx_unlock(ctx);


	return 0;

err_unlock_buffers:
	vxe_buffer_ctx_unlock(ctx);
	return err;
}


int vxe_buffer_munmap(struct vxe_context *ctx, int id)
{
	struct vxe_buffer *buf;
	int err = 0;

	vxe_buffer_ctx_lock(ctx);
	buf = (struct vxe_buffer *)idr_find(&ctx->buffers_idr, id);
	if(buf) {
		/* Command buffers cannot be used in map/unmap calls */
		if(vxe_buf_cmdbuf(buf))
			err = -EPERM;
		else if(!vxe_buf_mapped(buf))
			err = -EINVAL;
	} else
		err = -ENOENT;

	if(err)
		goto err_unlock_buffers;

	err = vm_munmap(buf->user_addr, buf->size);
	if(err) {
		dev_err(ctx->vxdev->dev, "Failed to unmap buffer.");
		err = -ENOENT;
		goto err_unlock_buffers;
	}

	buf->flags &= ~VXE_BUF_F_MAPPED;

	vxe_buffer_ctx_unlock(ctx);

	return err;

err_unlock_buffers:
	vxe_buffer_ctx_unlock(ctx);
	return err;

}


void vxe_buffer_bind_unlocked(struct vxe_buffer **buf, size_t count)
{
	size_t i;
	for(i = 0; i < count; ++i) {
		if(!buf[i])
			continue;
		if(++buf[i]->bind_count == 1)
			buf[i]->flags |= VXE_BUF_F_LOCKED;
	}
}


void vxe_buffer_unbind_unlocked(struct vxe_buffer **buf, size_t count)
{
	size_t i;
	for(i = 0; i < count; ++i) {
		if(!buf[i] || !buf[i]->bind_count)
			continue;
		if(--buf[i]->bind_count == 0)
			buf[i]->flags &= ~VXE_BUF_F_LOCKED;
	}
}


struct vxe_buffer* vxe_buffer_find_unlocked(struct vxe_context *ctx, int id)
{
	return (struct vxe_buffer *)idr_find(&ctx->buffers_idr, id);
}


void vxe_buffer_ctx_lock(struct vxe_context *ctx)
{
	mutex_lock(&ctx->buffers_idr_lock);
}


void vxe_buffer_ctx_unlock(struct vxe_context *ctx)
{
	mutex_unlock(&ctx->buffers_idr_lock);
}
