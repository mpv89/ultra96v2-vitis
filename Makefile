#!/bin/bash

PETALINUX_PATH=/tools/petalinux/2019.2
VIVADO_PATH=/tools/Xilinx/Vivado/2019.2

## Firmware
firmware/ultra96v2.xsa: source tmp
	cp -r source/firmware tmp/
	cd tmp/firmware && vivado -mode batch -source ultra96v2.tcl
	mkdir firmware
	cp -r tmp/firmware/ultra96v2/* firmware/
	cp source/firmware/build.tcl firmware/
	cd firmware && vivado -mode batch -source build.tcl

firmware: firmware/ultra96v2.xsa

## Petalinux
petalinux: source tmp
	git clone https://github.com/Avnet/petalinux.git -b 2019.1 tmp/avnet-petalinux
	

## Cleanup & misc
source:
	source $(PETALINUX_PATH)/settings.sh
	source $(VIVADO_PATH)/settings64.sh

tmp:
	mkdir -p tmp

clean:
	rm -rf tmp/
	rm -rf firmware/
