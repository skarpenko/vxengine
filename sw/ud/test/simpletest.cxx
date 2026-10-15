#include <iostream>
#include <unistd.h> //for sleep()
#include <vxengine/vxengine.h>

int main()
{
	VxInstance inst = VX_NULL_HANDLE;
	VxResult res;
	std::cout << "Hello!" << std::endl;

	VxInstanceCreateInfo info;
//	info.type = VX_INSTANCE_TYPE_SW;
	info.type = VX_INSTANCE_TYPE_SW_MT;

	res = vxCreateInstance(&info, &inst);
	if(res) {
		std::cout << "Failed to create instance\n";
		return 0;
	}

	VxCount dev_count = 0;
	VxDevice devices[10];//TEST ONLY
	vxEnumerateDevices(inst, &dev_count, devices);
	std::cout << "No.Devices " << dev_count << std::endl;

	VxContextCreateInfo ctxInfo;
	ctxInfo.vpuMask = 3;
	ctxInfo.device = devices[0];

	VxContext context;

	vxCreateContext(&ctxInfo, &context);
	sleep(10);
	vxDestroyContext(context);


	vxDestroyInstance(inst);

	return 0;
}
