#!/bin/bash

PETALINUX_PATH=/tools/petalinux/2019.2
VIVADO_PATH=/tools/Xilinx/Vivado/2019.2

PETALINUX_PROJ=ultra96v2

## Firmware
firmware/ultra96v2.xsa: source tmp
	cp -r source/firmware tmp/
	cd tmp/firmware && vivado -mode batch -source ultra96v2.tcl
	mkdir firmware
	cp -r tmp/firmware/ultra96v2/* firmware/
	cp source/firmware/build.tcl firmware/
	cd firmware && vivado -mode batch -source build.tcl

firmware: firmware/ultra96v2.xsa

clear-firmware:
	rm -rf firmware/

## Petalinux
petalinux/: tmp/avnet-petalinux
	echo "Generating Petalinux project..."

	mkdir -p petalinux

	## Create the project
	cd petalinux && petalinux-create -t project -n $(PETALINUX_PROJ) --template zynqMP
	cd petalinux/$(PETALINUX_PROJ) && petalinux-config --silentconfig --get-hw-description=../../firmware/

	## Patch the project as needed
	cp -r tmp/avnet-petalinux/configs/meta-user/ultra96v2_oob/* petalinux/$(PETALINUX_PROJ)/project-spec/meta-user/
	rm -r petalinux/$(PETALINUX_PROJ)/project-spec/meta-user/recipes-core/images

	## Rootfs changes
	patch petalinux/$(PETALINUX_PROJ)/project-spec/configs/config source/petalinux/configs/config.patch
	cp source/petalinux/configs/rootfs_config petalinux/$(PETALINUX_PROJ)/project-spec/configs/rootfs_config
	cp source/petalinux/configs/user-rootfsconfig petalinux/$(PETALINUX_PROJ)/project-spec/meta-user/conf/user-rootfsconfig

	## Kernel changes
	rm petalinux/$(PETALINUX_PROJ)/project-spec/meta-user/recipes-kernel/linux/linux-xlnx/*.cfg
	cp source/petalinux/kernel/linux-xlnx_%.bbappend petalinux/$(PETALINUX_PROJ)/project-spec/meta-user/recipes-kernel/linux/
	cp source/petalinux/kernel/kernel.cfg petalinux/$(PETALINUX_PROJ)/project-spec/meta-user/recipes-kernel/linux/linux-xlnx/

petalinux-create: petalinux/

petalinux-build: petalinux/
	cd petalinux/$(PETALINUX_PROJ) && petalinux-build -x mrproper
	cd petalinux/$(PETALINUX_PROJ) && petalinux-build -x distclean
	cd petalinux/$(PETALINUX_PROJ) && petalinux-build

petalinux-package:
	cd petalinux/$(PETALINUX_PROJ) && petalinux-package --boot --fsbl images/linux/zynqmp_fsbl.elf --fpga project-spec/hw-description/$(PETALINUX_PROJ).bit --uboot --force

tmp/avnet-petalinux: tmp
	git clone https://github.com/Avnet/petalinux.git -b 2019.1 tmp/avnet-petalinux

petalinux-clean:
	rm -rf petalinux/

## Cleanup & misc
source:
	source $(PETALINUX_PATH)/settings.sh
	source $(VIVADO_PATH)/settings64.sh

tmp:
	mkdir -p tmp

clean:
	rm -rf tmp/
	rm -rf firmware/
