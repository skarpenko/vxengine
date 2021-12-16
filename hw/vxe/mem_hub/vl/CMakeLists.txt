# Copyright (c) 2020-2021 The VxEngine Project. All rights reserved.
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
project(tb_mem_hub)

set(CMAKE_CXX_STANDARD 17)


include_directories(include)


# Testbench for memory hub
add_executable(tb_mem_hub.elf
	src/main.cxx
	include/trace.hxx
	include/tb_top.hxx
	include/axi4_2port_mem.hxx
	include/axi4_mem_port.hxx
	include/axi4_internal.hxx
	include/stimulus.hxx
	include/stimulus_common.hxx
	include/stimulus_cu.hxx
	include/stimulus_vpu.hxx
	# Verilator dependencies
	$ENV{VXENGINE_HOME}/hw/vxe/mem_hub/vl/hw/obj_dir/Vvl_axi4_mem_hub.h
	$ENV{VERILATOR_HOME}/share/verilator/include/verilated.cpp)

target_include_directories(tb_mem_hub.elf PUBLIC $ENV{VXENGINE_HOME}/hw/vxe/mem_hub/vl/hw)
target_include_directories(tb_mem_hub.elf PUBLIC $ENV{SYSTEMC_HOME}/include)
target_include_directories(tb_mem_hub.elf PUBLIC $ENV{VERILATOR_HOME}/share/verilator/include)
target_include_directories(tb_mem_hub.elf PUBLIC $ENV{VERILATOR_HOME}/share/verilator/include/vltstd)
target_compile_options(tb_mem_hub.elf PUBLIC --std=c++17 -O3 -g -Wall)
target_link_options(tb_mem_hub.elf PUBLIC -Wl,-rpath=$ENV{SYSTEMC_HOME}/lib-linux64
	-L$ENV{SYSTEMC_HOME}/lib-linux64)
target_link_libraries(tb_mem_hub.elf -lsystemc -lpthread -ldl
	$ENV{VXENGINE_HOME}/hw/vxe/mem_hub/vl/hw/obj_dir/Vvl_axi4_mem_hub__ALL.a)


# Verilated memory hub model
add_custom_command(
	OUTPUT $ENV{VXENGINE_HOME}/hw/vxe/mem_hub/vl/hw/obj_dir/Vvl_axi4_mem_hub__ALL.a
	OUTPUT $ENV{VXENGINE_HOME}/hw/vxe/mem_hub/vl/hw/obj_dir/Vvl_axi4_mem_hub.h
	WORKING_DIRECTORY $ENV{VXENGINE_HOME}/hw/vxe/mem_hub/vl/hw
	COMMAND verilator -CFLAGS --std=c++17 -CFLAGS -O3 --Wno-fatal -O3
		-f vl_axi4_mem_hub.lst
	COMMAND make -j1 -C obj_dir -f Vvl_axi4_mem_hub.mk
)
