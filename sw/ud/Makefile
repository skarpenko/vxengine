# The VxEngine Project
# User mode driver Makefile

# Path to driver ioctls header
KDHDR ?= $(VXENGINE_HOME)/sw/kd

# Path to vxeasm commands header
ASHDR ?= $(VXENGINE_HOME)/sw/vxeasm

# Cross-compiler toolchain name
CROSS_COMPILE ?=


# Build targets
TARGETS :=


# User mode driver build options
LIBVXENGINE_TARGET := libvxengine.so
LIBVXENGINE_CXX_FILES :=			\
	src/instance.cxx			\
	src/context.cxx				\
	src/buffer.cxx				\
	src/pipeline.cxx			\
	src/error.cxx				\
	src/codegen.cxx				\
	src/debug.cxx				\
	src/backend/swemu/swemu_backend.cxx	\
	src/backend/swemu/swemu_prog.cxx	\
	src/backend/swemu/swemu_exec.cxx	\
	src/backend/hw/hw_backend.cxx

LIBVXENGINE_HXX_FILES :=			\
	src/instance.hxx			\
	src/backend.hxx				\
	src/device.hxx				\
	src/context.hxx				\
	src/buffer.hxx				\
	src/pipeline.hxx			\
	src/error.hxx				\
	src/codegen.hxx				\
	src/debug.hxx				\
	src/backend/swemu/swemu_sema.hxx	\
	src/backend/swemu/swemu_backend.hxx	\
	src/backend/swemu/swemu_prog.hxx	\
	src/backend/swemu/swemu_exec.hxx	\
	src/backend/swemu/swemu_impl.hxx	\
	src/backend/hw/hw_backend.hxx

LIBVXENGINE_H_FILES :=				\
	include/vxengine/vxe_types.h		\
	include/vxengine/vxe_enums.h		\
	include/vxengine/vxengine.h		\
	include/vxengine/vxe_structs.h		\
	include/vxengine/vxe_funcs.h

LIBVXENGINE_CFLAGS := --std=c++11 -O3 -g -Wall -Iinclude -I$(KDHDR) -I$(ASHDR)
LIBVXENGINE_LDFLAGS := --shared -fPIC -lpthread


# Simple test application build options
SIMPLETEST_TARGET := simpletest
SIMPLETEST_CXX_FILES :=	\
	test/simpletest.cxx
SIMPLETEST_HXX_FILES := $(LIBVXENGINE_H_FILES)
SIMPLETEST_CFLAGS := --std=c++11 -O3 -g -Wall -Iinclude
SIMPLETEST_LDFLAGS := -Wl,-rpath=. -L. -lvxengine


# Add targets to build
TARGETS += $(LIBVXENGINE_TARGET)
TARGETS += $(SIMPLETEST_TARGET)


# Main goal
.PHONY: all
all: $(TARGETS)
	@echo "Done."


# User mode driver build target
$(LIBVXENGINE_TARGET): $(LIBVXENGINE_CXX_FILES) $(LIBVXENGINE_HXX_FILES) $(LIBVXENGINE_H_FILES)
	@echo "Building [$(LIBVXENGINE_TARGET)]"
	@$(CROSS_COMPILE)g++ $(LIBVXENGINE_CFLAGS) -o $(LIBVXENGINE_TARGET)	\
		$(LIBVXENGINE_CXX_FILES) $(LIBVXENGINE_LDFLAGS)

# Simple test application build target
$(SIMPLETEST_TARGET): $(SIMPLETEST_CXX_FILES) $(SIMPLETEST_HXX_FILES) $(LIBVXENGINE_TARGET)
	@echo "Building [$(SIMPLETEST_TARGET)]"
	@$(CROSS_COMPILE)g++ $(SIMPLETEST_CFLAGS) -o $(SIMPLETEST_TARGET)	\
		$(SIMPLETEST_CXX_FILES) $(SIMPLETEST_LDFLAGS)


# Do clean
.PHONY: clean
clean:
	@echo "Clean"
	-@rm -f $(TARGETS)
