# Copyright (c) 2020-2026 The VxEngine Project. All rights reserved.
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
project(user_mode_driver)

set(CMAKE_CXX_STANDARD 11)


include_directories(include)


# User mode driver library
add_library(vxengine SHARED
	src/instance.cxx
	src/instance.hxx
	src/backend.hxx
	src/backend/swemu/swemu_sema.hxx
	src/backend/swemu/swemu_backend.cxx
	src/backend/swemu/swemu_backend.hxx
	src/backend/swemu/swemu_prog.cxx
	src/backend/swemu/swemu_prog.hxx
	src/backend/swemu/swemu_exec.cxx
	src/backend/swemu/swemu_exec.hxx
	src/backend/hw/hw_backend.cxx
	src/backend/hw/hw_backend.hxx
	include/vxengine/vxe_types.h
	include/vxengine/vxe_enums.h
	include/vxengine/vxengine.h
	include/vxengine/vxe_structs.h
	include/vxengine/vxe_funcs.h
	src/device.hxx
	src/context.cxx
	src/context.hxx
	src/buffer.cxx
	src/buffer.hxx
	src/pipeline.cxx
	src/pipeline.hxx
	src/error.cxx
	src/error.hxx
	src/backend/swemu/swemu_impl.hxx)

target_include_directories(vxengine PUBLIC $ENV{VXENGINE_HOME}/sw/kd)
target_include_directories(vxengine PUBLIC $ENV{VXENGINE_HOME}/sw/vxeasm)
target_compile_options(vxengine PUBLIC --std=c++11 -O3 -g -Wall)
target_link_libraries(vxengine -lpthread) # TODO: revisit



# Simple test application
add_executable(simpletest
	test/simpletest.cxx)

#target_include_directories(simpletest PUBLIC include)
add_dependencies(simpletest vxengine)
target_compile_options(simpletest PUBLIC --std=c++11 -O3 -g -Wall)
target_link_options(simpletest PUBLIC -Wl,-rpath=. -L.)
###target_link_options(simpletest PUBLIC -L.)
##target_link_libraries(simpletest -lpthread -ldl -lvxengine) # TODO: revisit
target_link_libraries(simpletest -lvxengine) # TODO: revisit
