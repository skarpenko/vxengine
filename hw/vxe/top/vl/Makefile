# The VxEngine Project
# Makefile for top-level testbench

# Build targets
TARGETS :=


# Top-level testbench build options
TBVXETOP_TARGET := tb_vxe_top.elf
TBVXETOP_CXX_FILES :=		\
	src/main.cxx		\
	src/fake_cpu.cxx	\
	$(VERILATOR_HOME)/share/verilator/include/verilated.cpp	\
	$(VERILATOR_HOME)/share/verilator/include/verilated_vcd_sc.cpp	\
	$(VERILATOR_HOME)/share/verilator/include/verilated_vcd_c.cpp
TBVXETOP_HXX_FILES :=			\
	include/trace.hxx		\
	include/sys_top.hxx		\
	include/vxe_top_wrapper.hxx	\
	include/fake_cpu.hxx		\
	include/memory.hxx		\
	$(VXENGINE_HOME)/hw/vxe/top/vl/hw/obj_dir/Vvxe_top.h
TBVXETOP_CFLAGS := --std=c++17 -O3 -g -Wall -Iinclude		\
	-Ihw	\
	-I$(SYSTEMC_HOME)/include				\
	-I$(VERILATOR_HOME)/share/verilator/include		\
	-I$(VERILATOR_HOME)/share/verilator/include/vltstd
TBVXETOP_LDFLAGS := -Wl,-rpath=$(SYSTEMC_HOME)/lib-linux64		\
	-L$(SYSTEMC_HOME)/lib-linux64 -lsystemc -lpthread -ldl		\
	$(VXENGINE_HOME)/hw/vxe/top/vl/hw/obj_dir/Vvxe_top__ALL.a


# Basic test build options
BASIC_TEST_TARGET := libbasic_test.so
BASIC_TEST_CXX_FILES :=	\
	tests/basic_test/basic_test.cxx
BASIC_TEST_HXX_FILES :=	\
	include/fake_cpu_api.h
BASIC_TEST_CFLAGS := --std=c++17 -O3 -g -Wall -Iinclude	\
	-Itests/include
BASIC_TEST_LDFLAGS := --shared -fPIC


# Store test build options
STORE_TEST_TARGET := libstore_test.so
STORE_TEST_CXX_FILES :=	\
	tests/store_test/store_test.cxx
STORE_TEST_HXX_FILES :=	\
	include/fake_cpu_api.h
STORE_TEST_CFLAGS := --std=c++17 -O3 -g -Wall -Iinclude	\
	-Itests/include
STORE_TEST_LDFLAGS := --shared -fPIC


# ReLU test build options
RELU_TEST_TARGET := librelu_test.so
RELU_TEST_CXX_FILES :=	\
	tests/relu_test/relu_test.cxx
RELU_TEST_HXX_FILES :=	\
	include/fake_cpu_api.h
RELU_TEST_CFLAGS := --std=c++17 -O3 -g -Wall -Iinclude	\
	-Itests/include
RELU_TEST_LDFLAGS := --shared -fPIC


# Broadcast cotrol test build options
BCAST_CTRL_TEST_TARGET := libbcast_ctrl_test.so
BCAST_CTRL_TEST_CXX_FILES :=	\
	tests/bcast_ctrl_test/bcast_ctrl_test.cxx
BCAST_CTRL_TEST_HXX_FILES :=	\
	include/fake_cpu_api.h
BCAST_CTRL_TEST_CFLAGS := --std=c++17 -O3 -g -Wall -Iinclude	\
	-Itests/include
BCAST_CTRL_TEST_LDFLAGS := --shared -fPIC


# Add targets to build
TARGETS += $(TBVXETOP_TARGET)
TARGETS += $(BASIC_TEST_TARGET)
TARGETS += $(STORE_TEST_TARGET)
TARGETS += $(RELU_TEST_TARGET)
TARGETS += $(BCAST_CTRL_TEST_TARGET)


# Main goal
.PHONY: all
all: $(TARGETS)
	@echo "Done."


# Testbench build target
$(TBVXETOP_TARGET): $(TBVXETOP_CXX_FILES) $(TBVXETOP_HXX_FILES)			\
		$(VXENGINE_HOME)/hw/vxe/top/vl/hw/obj_dir/Vvxe_top__ALL.a
	@echo "Building [$(TBVXETOP_TARGET)]"
	@g++ $(TBVXETOP_CFLAGS) -o $(TBVXETOP_TARGET)	\
		$(TBVXETOP_CXX_FILES) $(TBVXETOP_LDFLAGS)


# Verilated top-level model targets
$(VXENGINE_HOME)/hw/vxe/top/vl/hw/obj_dir/Vvxe_top__ALL.a:	\
		$(VXENGINE_HOME)/hw/vxe/top/vl/hw/obj_dir/Vvxe_top.h
	@echo "Building [VxE_Top]"
	@$(MAKE) -j1 -C hw/obj_dir -f Vvxe_top.mk
$(VXENGINE_HOME)/hw/vxe/top/vl/hw/obj_dir/Vvxe_top.h: hw/vl_vxe_top.lst
	@echo "Verilating [VxE_Top]"
	@$(VERILATOR_HOME)/bin/verilator -CFLAGS --std=c++17 -CFLAGS -O3	\
		--Wno-fatal -O3 --trace --Mdir hw/obj_dir -f hw/vl_vxe_top.lst


# Basic test build target
$(BASIC_TEST_TARGET): $(BASIC_TEST_CXX_FILES) $(BASIC_TEST_HXX_FILES)
	@echo "Building [$(BASIC_TEST_TARGET)]"
	@g++ $(BASIC_TEST_CFLAGS) -o $(BASIC_TEST_TARGET)	\
		$(BASIC_TEST_CXX_FILES) $(BASIC_TEST_LDFLAGS)


# Store test build target
$(STORE_TEST_TARGET): $(STORE_TEST_CXX_FILES) $(STORE_TEST_HXX_FILES)
	@echo "Building [$(STORE_TEST_TARGET)]"
	@g++ $(STORE_TEST_CFLAGS) -o $(STORE_TEST_TARGET)	\
		$(STORE_TEST_CXX_FILES) $(STORE_TEST_LDFLAGS)


# ReLU test build target
$(RELU_TEST_TARGET): $(RELU_TEST_CXX_FILES) $(RELU_TEST_HXX_FILES)
	@echo "Building [$(RELU_TEST_TARGET)]"
	@g++ $(RELU_TEST_CFLAGS) -o $(RELU_TEST_TARGET)	\
		$(RELU_TEST_CXX_FILES) $(RELU_TEST_LDFLAGS)


# Broadcast control test build target
$(BCAST_CTRL_TEST_TARGET): $(BCAST_CTRL_TEST_CXX_FILES) $(BCAST_CTRL_TEST_HXX_FILES)
	@echo "Building [$(BCAST_CTRL_TEST_TARGET)]"
	@g++ $(BCAST_CTRL_TEST_CFLAGS) -o $(BCAST_CTRL_TEST_TARGET)	\
		$(BCAST_CTRL_TEST_CXX_FILES) $(BCAST_CTRL_TEST_LDFLAGS)


# Run tests
.PHONY: runtests
runtests: $(TARGETS)
	perl run_tests.pl


# Do clean
.PHONY: clean
clean:
	@echo "Clean"
	-@rm -f $(TARGETS)
	-@rm -Rf hw/obj_dir
	-@rm -f trace.vcd
	-@rm -f vltrace.vcd
	-@rm -f *.tmp
