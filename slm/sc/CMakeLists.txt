# Copyright (c) 2020 The VxEngine Project. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

cmake_minimum_required(VERSION 3.15)
project(vxmodel)

set(CMAKE_CXX_STANDARD 17)


include_directories(include)


# System model
add_executable(vxmodel.elf
	src/main.cxx
	src/simple_cpu.cxx
	src/tlm_payload.cxx
	include/sys_top.hxx
	include/trace.hxx
	include/simple_cpu_if.h
	include/util.hxx
	include/memory.hxx
	include/vxe_top.hxx
	include/register_set.hxx
	include/memory_port.hxx
	include/vxe_common.hxx
	include/vxe_internal.hxx
	include/tlm_payload.hxx
	include/vxe_port_util.hxx
	include/vxe_slave_port.hxx
	include/vxe_master_port.hxx
	include/vxe_tlm_ext.hxx
	include/vxe_mem_hub.hxx
	include/vxe_ctrl_unit.hxx
	include/vxe_vector_unit.hxx
	include/vxe_pipe.hxx
	include/vxe_fifo64x32.hxx
	# Verilator dependencies
	$ENV{VXENGINE_HOME}/slm/sc/vl/obj_dir/Vflp32_mac_5stg.h
	$ENV{VXENGINE_HOME}/slm/sc/vl/obj_dir/Vflp32_relu.h
	$ENV{VERILATOR_HOME}/share/verilator/include/verilated.cpp)

target_include_directories(vxmodel.elf PUBLIC $ENV{VXENGINE_HOME}/slm/sc/vl)
target_include_directories(vxmodel.elf PUBLIC $ENV{SYSTEMC_HOME}/include)
target_include_directories(vxmodel.elf PUBLIC $ENV{VERILATOR_HOME}/share/verilator/include)
target_include_directories(vxmodel.elf PUBLIC $ENV{VERILATOR_HOME}/share/verilator/include/vltstd)
target_compile_options(vxmodel.elf PUBLIC --std=c++17 -O3 -g -Wall)
target_link_options(vxmodel.elf PUBLIC -Wl,-rpath=$ENV{SYSTEMC_HOME}/lib-linux64
	-L$ENV{SYSTEMC_HOME}/lib-linux64)
target_link_libraries(vxmodel.elf -lsystemc -lpthread -ldl
	$ENV{VXENGINE_HOME}/slm/sc/vl/obj_dir/Vflp32_mac_5stg__ALL.a
	$ENV{VXENGINE_HOME}/slm/sc/vl/obj_dir/Vflp32_relu__ALL.a)


# Verilated FMAC32 model
add_custom_command(
	OUTPUT $ENV{VXENGINE_HOME}/slm/sc/vl/obj_dir/Vflp32_mac_5stg__ALL.a
	OUTPUT $ENV{VXENGINE_HOME}/slm/sc/vl/obj_dir/Vflp32_mac_5stg.h
	WORKING_DIRECTORY $ENV{VXENGINE_HOME}/slm/sc/vl
	COMMAND verilator -CFLAGS --std=c++17 -CFLAGS -O3 --Wno-fatal -O3
		-f vl_flp32_mac_5stg.lst
	COMMAND make -j1 -C obj_dir -f Vflp32_mac_5stg.mk
)


# Verilated FReLU32 model
add_custom_command(
	OUTPUT $ENV{VXENGINE_HOME}/slm/sc/vl/obj_dir/Vflp32_relu__ALL.a
	OUTPUT $ENV{VXENGINE_HOME}/slm/sc/vl/obj_dir/Vflp32_relu.h
	WORKING_DIRECTORY $ENV{VXENGINE_HOME}/slm/sc/vl
	COMMAND verilator -CFLAGS --std=c++17 -CFLAGS -O3 --Wno-fatal -O3
		-f vl_flp32_relu.lst
	COMMAND make -j1 -C obj_dir -f Vflp32_relu.mk
)


# Simple test
add_library(simple_test SHARED
	src/so/simple_test/simple_test.cxx
	include/simple_cpu_if.h
	include/vxe_common.hxx)

target_include_directories(simple_test PUBLIC $ENV{VXENGINE_HOME}/alg)
target_include_directories(simple_test PUBLIC $ENV{VXENGINE_HOME}/slm/sc/src/so/include)
target_compile_options(simple_test PUBLIC --std=c++17 -O3 -g -Wall)


# ReLU test
add_library(relu_test SHARED
	src/so/relu_test/relu_test.cxx
	include/simple_cpu_if.h
	include/vxe_common.hxx)

target_include_directories(relu_test PUBLIC $ENV{VXENGINE_HOME}/alg)
target_include_directories(relu_test PUBLIC $ENV{VXENGINE_HOME}/slm/sc/src/so/include)
target_compile_options(relu_test PUBLIC --std=c++17 -O3 -g -Wall)


# MLP test
add_library(mlp_test SHARED
	src/so/mlp_test/mlp_test.cxx
	include/simple_cpu_if.h
	include/vxe_common.hxx)

target_include_directories(mlp_test PUBLIC $ENV{VXENGINE_HOME}/slm/sc/src/so/include)
target_compile_options(mlp_test PUBLIC --std=c++17 -O3 -g -Wall)
