# The VxEngine Project
# Makefile for memory hub testbench

# Build targets
TARGETS :=


# Memory hub testbench build options
TBMEMHUB_TARGET := tb_mem_hub.elf
TBMEMHUB_CXX_FILES :=	\
	src/main.cxx	\
	$(VERILATOR_HOME)/share/verilator/include/verilated.cpp	\
	$(VERILATOR_HOME)/share/verilator/include/verilated_vcd_sc.cpp	\
	$(VERILATOR_HOME)/share/verilator/include/verilated_vcd_c.cpp

TBMEMHUB_HXX_FILES :=		\
	include/trace.hxx	\
	include/tb_top.hxx	\
	include/axi4_2port_mem.hxx	\
	include/axi4_mem_port.hxx	\
	include/axi4_internal.hxx	\
	include/stimulus.hxx	\
	include/stimulus_common.hxx	\
	include/stimulus_cu.hxx	\
	include/stimulus_vpu.hxx	\
	$(VXENGINE_HOME)/hw/vxe/mem_hub/vl/hw/obj_dir/Vvl_axi4_mem_hub.h
TBMEMHUB_CFLAGS := --std=c++17 -O3 -g -Wall -Iinclude -Ivl	\
	-I$(VXENGINE_HOME)/hw/vxe/mem_hub/vl/hw			\
	-I$(SYSTEMC_HOME)/include				\
	-I$(VERILATOR_HOME)/share/verilator/include		\
	-I$(VERILATOR_HOME)/share/verilator/include/vltstd
TBMEMHUB_LDFLAGS := -Wl,-rpath=$(SYSTEMC_HOME)/lib-linux64		\
	-L$(SYSTEMC_HOME)/lib-linux64 -lsystemc -lpthread -ldl		\
	$(VXENGINE_HOME)/hw/vxe/mem_hub/vl/hw/obj_dir/Vvl_axi4_mem_hub__ALL.a


# Add targets to build
TARGETS += $(TBMEMHUB_TARGET)


# Main goal
.PHONY: all
all: $(TARGETS)
	@echo "Done."


# Testbench build target
$(TBMEMHUB_TARGET): $(TBMEMHUB_CXX_FILES) $(TBMEMHUB_HXX_FILES)			\
		$(VXENGINE_HOME)/hw/vxe/mem_hub/vl/hw/obj_dir/Vvl_axi4_mem_hub__ALL.a
	@echo "Building [$(TBMEMHUB_TARGET)]"
	@g++ $(TBMEMHUB_CFLAGS) -o $(TBMEMHUB_TARGET)	\
		$(TBMEMHUB_CXX_FILES) $(TBMEMHUB_LDFLAGS)


# Verilated memory hub model targets
$(VXENGINE_HOME)/hw/vxe/mem_hub/vl/hw/obj_dir/Vvl_axi4_mem_hub__ALL.a:	\
		$(VXENGINE_HOME)/hw/vxe/mem_hub/vl/hw/obj_dir/Vvl_axi4_mem_hub.h
	@echo "Building [Mem_Hub]"
	@$(MAKE) -j1 -C hw/obj_dir -f Vvl_axi4_mem_hub.mk
$(VXENGINE_HOME)/hw/vxe/mem_hub/vl/hw/obj_dir/Vvl_axi4_mem_hub.h: hw/vl_axi4_mem_hub.lst
	@echo "Verilating [Mem_Hub]"
	@$(VERILATOR_HOME)/bin/verilator -CFLAGS --std=c++17 -CFLAGS -O3	\
		--Wno-fatal -O3 --trace --Mdir hw/obj_dir -f hw/vl_axi4_mem_hub.lst


# Do clean
.PHONY: clean
clean:
	@echo "Clean"
	-@rm -f $(TARGETS)
	-@rm -Rf hw/obj_dir
	-@rm -f trace.vcd
	-@rm -f vltrace.vcd
