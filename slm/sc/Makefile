# The VxEngine Project
# System model Makefile

# Build targets
TARGETS :=


# System model build options
SYSMODEL_TARGET := vxmodel.elf
SYSMODEL_CXX_FILES :=	\
	src/main.cxx		\
	src/simple_cpu.cxx	\
	src/tlm_payload.cxx
SYSMODEL_HXX_FILES :=	\
	include/sys_top.hxx		\
	include/trace.hxx		\
	include/simple_cpu_if.h		\
	include/util.hxx		\
	include/memory.hxx		\
	include/vxe_top.hxx		\
	include/register_set.hxx	\
	include/memory_port.hxx		\
	include/vxe_common.hxx		\
	include/vxe_internal.hxx	\
	include/tlm_payload.hxx		\
	include/vxe_port_util.hxx	\
	include/vxe_slave_port.hxx	\
	include/vxe_master_port.hxx
SYSMODEL_CFLAGS := --std=c++17 -O3 -g -Wall -Iinclude -I$(SYSTEMC_HOME)/include
SYSMODEL_LDFLAGS := -Wl,-rpath=$(SYSTEMC_HOME)/lib-linux64	\
	-L$(SYSTEMC_HOME)/lib-linux64 -lsystemc -lpthread -ldl


# Simple test build options
SIMPLE_TEST_TARGET := libsimple_test.so
SIMPLE_TEST_CXX_FILES := src/so/simple_test/simple_test.cxx
SIMPLE_TEST_HXX_FILES := include/simple_cpu_if.h
SIMPLE_TEST_CFLAGS := --std=c++17 -O3 -g -Wall -Iinclude
SIMPLE_TEST_LDFLAGS := --shared -fPIC


# Add targets to build
TARGETS += $(SYSMODEL_TARGET)
TARGETS += $(SIMPLE_TEST_TARGET)


# Main goal
.PHONY: all
all: $(TARGETS)
	@echo "Done."


# System model build target
$(SYSMODEL_TARGET): $(SYSMODEL_CXX_FILES) $(SYSMODEL_HXX_FILES)
	@echo "Building [$(SYSMODEL_TARGET)]"
	@g++ $(SYSMODEL_CFLAGS) -o $(SYSMODEL_TARGET)	\
		$(SYSMODEL_CXX_FILES) $(SYSMODEL_LDFLAGS)


# Simple test build target
$(SIMPLE_TEST_TARGET): $(SIMPLE_TEST_CXX_FILES) $(SIMPLE_TEST_HXX_FILES)
	@echo "Building [$(SIMPLE_TEST_TARGET)]"
	@g++ $(SIMPLE_TEST_CFLAGS) -o $(SIMPLE_TEST_TARGET)	\
		$(SIMPLE_TEST_CXX_FILES) $(SIMPLE_TEST_LDFLAGS)


# Do clean
.PHONY: clean
clean:
	@echo "Clean"
	-@rm -f $(TARGETS)
	-@rm -f trace.vcd
