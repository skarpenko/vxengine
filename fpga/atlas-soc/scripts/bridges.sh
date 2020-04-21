#!/bin/sh
#
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
#


status() {
	echo "Bridges status"
	FPGA2HPS=$(cat /sys/class/fpga-bridge/fpga2hps/enable)
	HPS2FPGA=$(cat /sys/class/fpga-bridge/hps2fpga/enable)
	LWHPS2FPGA=$(cat /sys/class/fpga-bridge/lwhps2fpga/enable)
	echo "* FPGA-to-HPS: $FPGA2HPS"
	echo "* HPS-to-FPGA: $HPS2FPGA"
	echo "* LWHPS-to-FPGA: $LWHPS2FPGA"
}


disable() {
	echo "Disabling bridges"
	echo 0 > /sys/class/fpga-bridge/fpga2hps/enable
	echo 0 > /sys/class/fpga-bridge/hps2fpga/enable
	echo 0 > /sys/class/fpga-bridge/lwhps2fpga/enable
}


enable() {
	echo "Enabling bridges"
	echo 1 > /sys/class/fpga-bridge/fpga2hps/enable
	echo 1 > /sys/class/fpga-bridge/hps2fpga/enable
	echo 1 > /sys/class/fpga-bridge/lwhps2fpga/enable
}


case "$1" in
	d|dis|disable)
	disable
	exit 0
	;;
	e|en|enable)
	enable
	exit 0
	;;
	s|st|status)
	status
	exit 0
	;;
	*)
	break
	;;
esac


echo
echo "Usage: bridges.sh [status|enable|disable]"
echo
