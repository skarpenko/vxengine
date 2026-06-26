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
#include <linux/pid.h>
#include <linux/wait.h>
#include "vxe.h"


struct vxe_context* vxe_context_create(struct vxe_device *vxdev, pid_t owner, int max_jobs)
{
	struct vxe_context *ctx = kzalloc(sizeof(struct vxe_context), GFP_KERNEL);
	if(!ctx)
		return ERR_PTR(-ENOMEM);

	ctx->vxdev = vxdev;
	ctx->max_jobs = max_jobs;
	ctx->owner = owner;

	mutex_init(&ctx->buffers_idr_lock);
	idr_init(&ctx->buffers_idr);

	return ctx;
}


void vxe_context_destroy(struct vxe_context *ctx)
{
	struct vxe_buffer *buf;
	int id;

	/* Wait for completion of any jobs issued by this context */
	wait_event(ctx->vxdev->user_wq, atomic_read(&ctx->num_jobs) == 0);

	vxe_buffer_ctx_lock(ctx);
	idr_for_each_entry(&ctx->buffers_idr, buf, id) {
		vxe_buffer_destroy_raw_unlocked(buf);
	}
	vxe_buffer_ctx_unlock(ctx);

	idr_destroy(&ctx->buffers_idr);
	kfree(ctx);
}


bool vxe_context_owner_valid(struct vxe_context *ctx)
{
	return task_tgid_vnr(current) == ctx->owner;
}
