# The VxEngine Project
# System model Makefile

# Build targets
TARGETS :=


# System model build options
SYSMODEL_TARGET := vxmodel.elf
SYSMODEL_CXX_FILES :=	\
	src/main.cxx		\
	src/simple_cpu.cxx	\
	src/tlm_payload.cxx	\
	$(VERILATOR_HOME)/share/verilator/include/verilated.cpp
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
	include/vxe_master_port.hxx	\
	include/vxe_tlm_ext.hxx		\
	include/vxe_mem_hub.hxx		\
	include/vxe_ctrl_unit.hxx	\
	include/vxe_vector_unit.hxx	\
	include/vxe_pipe.hxx		\
	include/vxe_fifo64x32.hxx	\
	$(VXENGINE_HOME)/slm/sc/vl/obj_dir/Vflp32_mac_5stg.h	\
	$(VXENGINE_HOME)/slm/sc/vl/obj_dir/Vflp32_relu.h
SYSMODEL_CFLAGS := --std=c++17 -O3 -g -Wall -Iinclude -Ivl	\
	-I$(SYSTEMC_HOME)/include				\
	-I$(VERILATOR_HOME)/share/verilator/include		\
	-I$(VERILATOR_HOME)/share/verilator/include/vltstd
SYSMODEL_LDFLAGS := -Wl,-rpath=$(SYSTEMC_HOME)/lib-linux64		\
	-L$(SYSTEMC_HOME)/lib-linux64 -lsystemc -lpthread -ldl		\
	$(VXENGINE_HOME)/slm/sc/vl/obj_dir/Vflp32_mac_5stg__ALL.a	\
	$(VXENGINE_HOME)/slm/sc/vl/obj_dir/Vflp32_relu__ALL.a


# Simple test build options
SIMPLE_TEST_TARGET := libsimple_test.so
SIMPLE_TEST_CXX_FILES :=	\
	src/so/simple_test/simple_test.cxx
SIMPLE_TEST_HXX_FILES :=	\
	include/simple_cpu_if.h	\
	include/vxe_common.hxx
SIMPLE_TEST_CFLAGS := --std=c++17 -O3 -g -Wall -Iinclude	\
	-I$(VXENGINE_HOME)/alg					\
	-I$(VXENGINE_HOME)/slm/sc/src/so/include
SIMPLE_TEST_LDFLAGS := --shared -fPIC


# ReLU test build options
RELU_TEST_TARGET := librelu_test.so
RELU_TEST_CXX_FILES :=	\
	src/so/relu_test/relu_test.cxx
RELU_TEST_HXX_FILES :=	\
	include/simple_cpu_if.h	\
	include/vxe_common.hxx
RELU_TEST_CFLAGS := --std=c++17 -O3 -g -Wall -Iinclude	\
	-I$(VXENGINE_HOME)/alg				\
	-I$(VXENGINE_HOME)/slm/sc/src/so/include
RELU_TEST_LDFLAGS := --shared -fPIC


# MLP test build options
MLP_TEST_TARGET := libmlp_test.so
MLP_TEST_CXX_FILES :=	\
	src/so/mlp_test/mlp_test.cxx
MLP_TEST_HXX_FILES :=	\
	include/simple_cpu_if.h	\
	include/vxe_common.hxx
MLP_TEST_CFLAGS := --std=c++17 -O3 -g -Wall -Iinclude	\
	-I$(VXENGINE_HOME)/slm/sc/src/so/include
MLP_TEST_LDFLAGS := --shared -fPIC


# Unicast test build options
UNICAST_TEST_TARGET := libunicast_test.so
UNICAST_TEST_CXX_FILES :=	\
	src/so/unicast_test/unicast_test.cxx
UNICAST_TEST_HXX_FILES :=	\
	include/simple_cpu_if.h	\
	include/vxe_common.hxx
UNICAST_TEST_CFLAGS := --std=c++17 -O3 -g -Wall -Iinclude	\
	-I$(VXENGINE_HOME)/alg					\
	-I$(VXENGINE_HOME)/slm/sc/src/so/include
UNICAST_TEST_LDFLAGS := --shared -fPIC


# Add targets to build
TARGETS += $(SYSMODEL_TARGET)
TARGETS += $(SIMPLE_TEST_TARGET)
TARGETS += $(RELU_TEST_TARGET)
TARGETS += $(MLP_TEST_TARGET)
TARGETS += $(UNICAST_TEST_TARGET)


# Main goal
.PHONY: all
all: $(TARGETS)
	@echo "Done."


# System model build target
$(SYSMODEL_TARGET): $(SYSMODEL_CXX_FILES) $(SYSMODEL_HXX_FILES)			\
		$(VXENGINE_HOME)/slm/sc/vl/obj_dir/Vflp32_mac_5stg__ALL.a	\
		$(VXENGINE_HOME)/slm/sc/vl/obj_dir/Vflp32_relu__ALL.a
	@echo "Building [$(SYSMODEL_TARGET)]"
	@g++ $(SYSMODEL_CFLAGS) -o $(SYSMODEL_TARGET)	\
		$(SYSMODEL_CXX_FILES) $(SYSMODEL_LDFLAGS)


# Verilated FMAC32 model targets
$(VXENGINE_HOME)/slm/sc/vl/obj_dir/Vflp32_mac_5stg__ALL.a:	\
		$(VXENGINE_HOME)/slm/sc/vl/obj_dir/Vflp32_mac_5stg.h
	@echo "Building [FMAC32]"
	@$(MAKE) -j1 -C vl/obj_dir -f Vflp32_mac_5stg.mk
$(VXENGINE_HOME)/slm/sc/vl/obj_dir/Vflp32_mac_5stg.h: vl/vl_flp32_mac_5stg.lst
	@echo "Verilating [FMAC32]"
	@$(VERILATOR_HOME)/bin/verilator -CFLAGS --std=c++17 -CFLAGS -O3	\
		--Wno-fatal -O3 --Mdir vl/obj_dir -f vl/vl_flp32_mac_5stg.lst


# Verilated FReLU32 model targets
$(VXENGINE_HOME)/slm/sc/vl/obj_dir/Vflp32_relu__ALL.a:	\
		$(VXENGINE_HOME)/slm/sc/vl/obj_dir/Vflp32_relu.h
	@echo "Building [FReLU32]"
	@$(MAKE) -j1 -C vl/obj_dir -f Vflp32_relu.mk
$(VXENGINE_HOME)/slm/sc/vl/obj_dir/Vflp32_relu.h: vl/vl_flp32_relu.lst
	@echo "Verilating [FReLU32]"
	@$(VERILATOR_HOME)/bin/verilator -CFLAGS --std=c++17 -CFLAGS -O3	\
		--Wno-fatal -O3 --Mdir vl/obj_dir -f vl/vl_flp32_relu.lst


# Simple test build target
$(SIMPLE_TEST_TARGET): $(SIMPLE_TEST_CXX_FILES) $(SIMPLE_TEST_HXX_FILES)
	@echo "Building [$(SIMPLE_TEST_TARGET)]"
	@g++ $(SIMPLE_TEST_CFLAGS) -o $(SIMPLE_TEST_TARGET)	\
		$(SIMPLE_TEST_CXX_FILES) $(SIMPLE_TEST_LDFLAGS)


# ReLU test build target
$(RELU_TEST_TARGET): $(RELU_TEST_CXX_FILES) $(RELU_TEST_HXX_FILES)
	@echo "Building [$(RELU_TEST_TARGET)]"
	@g++ $(RELU_TEST_CFLAGS) -o $(RELU_TEST_TARGET)	\
		$(RELU_TEST_CXX_FILES) $(RELU_TEST_LDFLAGS)


# MLP test build target
$(MLP_TEST_TARGET): $(MLP_TEST_CXX_FILES) $(MLP_TEST_HXX_FILES)
	@echo "Building [$(MLP_TEST_TARGET)]"
	@g++ $(MLP_TEST_CFLAGS) -o $(MLP_TEST_TARGET)	\
		$(MLP_TEST_CXX_FILES) $(MLP_TEST_LDFLAGS)


# Unicast test build target
$(UNICAST_TEST_TARGET): $(UNICAST_TEST_CXX_FILES) $(UNICAST_TEST_HXX_FILES)
	@echo "Building [$(UNICAST_TEST_TARGET)]"
	@g++ $(UNICAST_TEST_CFLAGS) -o $(UNICAST_TEST_TARGET)	\
		$(UNICAST_TEST_CXX_FILES) $(UNICAST_TEST_LDFLAGS)


# Do clean
.PHONY: clean
clean:
	@echo "Clean"
	-@rm -f $(TARGETS)
	-@rm -Rf vl/obj_dir
	-@rm -f trace.vcd
