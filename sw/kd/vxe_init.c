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

#include <linux/init.h>
#include "vxe.h"


static int minor_count = 1;
module_param(minor_count, int, 0444);
MODULE_PARM_DESC(minor_count, "Number of minor numbers to allocate (>0)");

int max_jobs_per_ctx = 32;
module_param(max_jobs_per_ctx, int, 0444);
MODULE_PARM_DESC(max_jobs_per_ctx, "Maximum jobs per context (>0)");

int job_timeout_sec = 10;
module_param(job_timeout_sec, int, 0444);
MODULE_PARM_DESC(job_timeout_sec, "Job timeout in seconds (>0)");


static struct class *vxe_dev_class = NULL;
static atomic_t next_id = ATOMIC_INIT(0);
dev_t device_num;


static int vxe_driver_probe(struct platform_device *pdev)
{
	int id = atomic_fetch_inc(&next_id);
	int major = MAJOR(device_num);
	struct vxe_device *vxdev;

	if(id >= MAX_MINOR_NUM) {
		dev_err(&pdev->dev, "Ran out of minor numbers!\n");
		return -ENOSPC;
	}

	vxdev = vxe_device_register(pdev, vxe_dev_class, MKDEV(major, id));
	if(IS_ERR(vxdev)) {
		dev_err(&pdev->dev, "Failed to register " DEVICE_NAME "!\n");
		return PTR_ERR(vxdev);
	}

	dev_set_drvdata(&pdev->dev, vxdev);

	dev_info(&pdev->dev, "Registered " DEVICE_NAME "(%d:%d)!\n", major, id);

	return 0;
}


static int vxe_driver_remove(struct platform_device *pdev)
{
	struct vxe_device *vxdev = dev_get_drvdata(&pdev->dev);

	vxe_device_unregister(vxdev);

	return 0;
}


static const struct of_device_id vxe_driver_id[] = {
	{ .compatible = "svk,vxengine" },
	{}
};


static struct platform_driver vxe_driver = {
	.driver = {
		.name = DEVICE_NAME,
		.owner = THIS_MODULE,
		.of_match_table = of_match_ptr(vxe_driver_id),
	},
	.probe = vxe_driver_probe,
	.remove = vxe_driver_remove
};



static int vxe_device_uevent(struct device *dev, struct kobj_uevent_env *env)
{
	add_uevent_var(env, "DEVMODE=%#o", 0666);
	return 0;
}


static int __init init(void)
{
	int err = 0;

	if(minor_count <= 0)
		minor_count = 1;
	if(minor_count > MAX_MINOR_NUM)
		minor_count = MAX_MINOR_NUM;

	if(max_jobs_per_ctx <= 0)
		max_jobs_per_ctx = 1;
	if(max_jobs_per_ctx > MAX_MAX_JOBS_LIMIT)
		max_jobs_per_ctx = MAX_MAX_JOBS_LIMIT;

	if(job_timeout_sec <= 0)
		job_timeout_sec = 10;


	/* Create device class */
	vxe_dev_class = class_create(THIS_MODULE, CLASS_NAME);
	if(IS_ERR(vxe_dev_class)) {
		pr_err("Failed to create '" CLASS_NAME "' class!\n");
		return PTR_ERR(vxe_dev_class);
	}
	vxe_dev_class->dev_uevent = vxe_device_uevent;

	/* Allocate device numbers */
	err = alloc_chrdev_region(&device_num, 0, minor_count, DEVICE_NAME);
	if(err < 0) {
		class_unregister(vxe_dev_class);
		pr_err("Cannot allocate device number!\n");
		return err;
	}

	/* Register device driver */
	err = platform_driver_register(&vxe_driver);
	if(err < 0) {
		unregister_chrdev_region(device_num, minor_count);
		class_unregister(vxe_dev_class);
		pr_err("Failed to register " DEVICE_NAME " device driver!\n");
		return err;
	}

	return 0;
}


static void __exit fini(void)
{
	platform_driver_unregister(&vxe_driver);

	unregister_chrdev_region(device_num, minor_count);

	class_unregister(vxe_dev_class);
	class_destroy(vxe_dev_class);
}

module_init(init);
module_exit(fini);

MODULE_AUTHOR("Stepan Karpenko <stepan.karpenko@gmail.com>");
MODULE_DESCRIPTION("VxEngine accelerator driver");
MODULE_LICENSE("GPL");
