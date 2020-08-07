#!/bin/sh
# The VxEngine Project.
# Environment configuration.

echo ""
echo "Setting environment for VxEngine."
echo "================================="
echo ""

# Set work directory
export VXENGINE_HOME=${PWD}
echo "Workspace: ${VXENGINE_HOME}"

# Check that SYSTEMC_HOME variable is set.
if [ -z ${SYSTEMC_HOME} ]; then
   echo "SystemC: Warning! SYSTEMC_HOME variable is not set.";
else
   echo "SystemC: SYSTEMC_HOME = ${SYSTEMC_HOME}";
fi

# Check that VERILATOR_HOME variable is set and try to set it automatically if
# it is not.
if [ -z ${VERILATOR_HOME} ]; then
   VERILATOR=$(which verilator)
   export VERILATOR_HOME=${VERILATOR%/*/*}
fi

# Print VERILATOR_HOME if it was set successfully
if [ -z ${VERILATOR_HOME} ]; then
   echo "Verilator: Verilator not found! VERILATOR_HOME variable is not set.";
else
   echo "Verilator: VERILATOR_HOME = ${VERILATOR_HOME}";
fi

echo ""
