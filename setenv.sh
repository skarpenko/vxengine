#!/bin/sh
# The VxEngine Project.
# Environment configuration.

echo ""
echo "Setting environment for VxEngine."
echo "================================="
echo ""

# Set work directory
export VXENGINE_HOME=`pwd`
echo "Workspace: $VXENGINE_HOME"

# Check that SYSTEMC_HOME variable is set.
if [ -z ${SYSTEMC_HOME+x} ]; then
   echo "SystemC: Warning! SYSTEMC_HOME variable is not unset.";
else
   echo "SystemC: SYSTEMC_HOME = $SYSTEMC_HOME";
fi

echo ""
