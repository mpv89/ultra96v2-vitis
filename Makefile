#!/bin/bash

PETALINUX_PATH=/tools/petalinux/2019.2
VIVADO_PATH=/tools/Xilinx/Vivado/2019.2

#include $(PETALINUX_PATH)/settings.sh
#include $(VIVADO_PATH)/settings64.sh

## Firmware
firmware-create: firmware/

firmware/: tmp
	## Firmware is included in the XSA, so first exact it
	mkdir -p tmp/firmware
	unzip source/firmware/ultra96v2.xsa -d tmp/firmware/

	## Rebuild the firmware
	mkdir firmware
	cd firmware && vivado -mode batch -source ../tmp/firmware/prj/rebuild.tcl -tclargs --origin_dir ../tmp/firmware/prj/
	cp source/firmware/build.tcl firmware/ultra96v2/

firmware-build: firmware-create
	cd firmware/ultra96v2 && vivado -mode batch -source build.tcl

firmware-clean:
	rm -rf firmware/

## Petalinux
petalinux-create: petalinux/ultra96v2

petalinux/ultra96v2: tmp/avnet-petalinux
	echo "Generating Petalinux project..."

	mkdir -p petalinux

	## Create the project
	cd petalinux && petalinux-create -t project -n ultra96v2 --template zynqMP
	cd petalinux/ultra96v2 && petalinux-config --silentconfig --get-hw-description=../../source/firmware/

	## Patch the project as needed
	cp -r tmp/avnet-petalinux/configs/meta-user/ultra96v2_oob/* petalinux/ultra96v2/project-spec/meta-user/
	rm -r petalinux/ultra96v2/project-spec/meta-user/recipes-core/images

	## Device Tree changes
	cp source/petalinux/device-tree/* petalinux/ultra96v2/project-spec/meta-user/recipes-bsp/device-tree/files/

	## Kernel changes
	rm petalinux/ultra96v2/project-spec/meta-user/recipes-kernel/linux/linux-xlnx/*.cfg
	cp source/petalinux/kernel/linux-xlnx_%.bbappend petalinux/ultra96v2/project-spec/meta-user/recipes-kernel/linux/
	cp source/petalinux/kernel/kernel.cfg petalinux/ultra96v2/project-spec/meta-user/recipes-kernel/linux/linux-xlnx/

	## Rootfs changes
	patch petalinux/ultra96v2/project-spec/configs/config source/petalinux/configs/config.patch
	cp source/petalinux/configs/rootfs_config petalinux/ultra96v2/project-spec/configs/rootfs_config
	cp source/petalinux/configs/user-rootfsconfig petalinux/ultra96v2/project-spec/meta-user/conf/user-rootfsconfig

petalinux-build: petalinux-create
	cd petalinux/ultra96v2 && petalinux-build -x mrproper
	cd petalinux/ultra96v2 && petalinux-build -x distclean
	cd petalinux/ultra96v2 && petalinux-build

petalinux-package:
	cd petalinux/ultra96v2 && petalinux-package --boot --fsbl images/linux/zynqmp_fsbl.elf --fpga project-spec/hw-description/ultra96v2.bit --uboot --force

petalinux-platform: pfm/

pfm/:
	mkdir -p pfm/boot
	cd petalinux/ultra96v2 && petalinux-build --sdk
	cd petalinux/ultra96v2/images/linux/ && ./sdk.sh -y -d ../../../../pfm
	cp petalinux/ultra96v2/images/linux/image.ub pfm/boot/
	cp petalinux/ultra96v2/images/linux/zynqmp_fsbl.elf pfm/boot/
	cp petalinux/ultra96v2/images/linux/pmufw.elf pfm/boot/
	cp petalinux/ultra96v2/images/linux/bl31.elf pfm/boot/
	cp petalinux/ultra96v2/images/linux/u-boot.elf pfm/boot/
	cp source/petalinux/linux.bif pfm/boot/
	

tmp/avnet-petalinux: tmp
	git clone https://github.com/Avnet/petalinux.git -b 2019.1 tmp/avnet-petalinux

petalinux-clean:
	rm -rf petalinux/
	rm -rf pfm/

## Cleanup & misc
tmp:
	mkdir -p tmp

clean: petalinux-clean firmware-clean
	rm -rf tmp/

upload:
	scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null petalinux/ultra96v2/linux/image.ub root@171.64.56.12:/run/media/mmcblk0p1/
