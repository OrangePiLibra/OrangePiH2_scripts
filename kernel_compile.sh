#!/bin/bash

# =====================================================
# After build uImage and lib are in build directory
# =====================================================

if [ "${1}" = "" ]; then
    echo "Source directory not specified."
    echo "USAGE: build_linux_kernel.sh [zero | clean]"
    exit 0
fi

if [ -z $TOP ]; then
	TOP=`cd .. && pwd`
fi
#export PATH="$PWD/brandy/gcc-linaro/bin":"$PATH"
cross_comp="$TOP/toolchain/bin/arm-linux-gnueabi"

# ##############
# Prepare rootfs
# ##############
if [ ! -d $TOP/output ]; then
	mkdir -p $TOP/output
fi
cd $TOP/output
rm -rf $TOP/external/Legacy_patch/rootfs-lobo.img.gz > /dev/null 2>&1
cd $TOP/external/Legacy_patch/rootfs-test1
mkdir run > /dev/null 2>&1
mkdir -p conf/conf.d > /dev/null 2>&1

find . | cpio --quiet -o -H newc > ../rootfs-lobo.img
cd ..
gzip rootfs-lobo.img

cd $TOP/kernel
LINKERNEL_DIR=`pwd`
rm -rf $TOP/output/lib > /dev/null 2>&1
mkdir -p $TOP/output/lib > /dev/null 2>&1
cp $TOP/external/Legacy_patch/rootfs-lobo.img.gz $TOP/output/rootfs.cpio.gz
rm -rf $TOP/kernel/output
if [ ! -d $TOP/kernel/output ]; then
	mkdir -p $TOP/kernel/output
fi
chmod +x $TOP/kernel/output
rm -rf $TOP/kernel/output/*
cp $TOP/output/rootfs.cpio.gz $TOP/kernel/output/


#==================================================================================
# ############
# Build kernel
# ############

# #################################
# change some board dependant files

# ###########################
make_kernel() {
if [ "${1}" = "zero" ]; then
    echo "  Building kernel for OPI-Zero ..."
    echo "  Configuring ..."
    make ARCH=arm CROSS_COMPILE=${cross_comp}- sun8iw7p1smp_linux_defconfig
    if [ $? -ne 0 ]; then
        echo "  Error: KERNEL NOT BUILT."
        exit 1
    fi
    sleep 1

# #############################################################################
# build kernel (use -jN, where N is number of cores you can spare for building)
    echo "  Building kernel & modules ..."
    make -j6 ARCH=arm CROSS_COMPILE=${cross_comp}- uImage modules 
    if [ $? -ne 0 ] || [ ! -f arch/arm/boot/uImage ]; then
        echo "  Error: KERNEL NOT BUILT."
        exit 1
    fi
    sleep 1
# ########################
# export modules to output
    echo "  Exporting modules ..."
    rm -rf output/lib/*
    make ARCH=arm CROSS_COMPILE=${cross_comp}- INSTALL_MOD_PATH=$TOP/output modules_install 
    if [ $? -ne 0 ] || [ ! -f arch/arm/boot/uImage ]; then
        echo "  Error."
    fi
    echo "  Exporting firmware ..."
    make ARCH=arm CROSS_COMPILE=${cross_comp}- INSTALL_MOD_PATH=$TOP/output firmware_install
    if [ $? -ne 0 ] || [ ! -f arch/arm/boot/uImage ]; then
        echo "  Error."
    fi
    sleep 1

    # #####################
    # Copy uImage to output
    cp arch/arm/boot/uImage $TOP/output/uImage
fi
}
#==================================================================================

if [ "${1}" = "clean" ]; then
    echo "Cleaning..."
    make ARCH=arm CROSS_COMPILE=${cross_comp}- mrproper 
    if [ $? -ne 0 ]; then
        echo "  Error."
    fi
    rm -rf ../build/lib/* > /dev/null 2>&1
    rm -f ../build/uImage* > /dev/null 2>&1
    rm -f ../kbuild* > /dev/null 2>&1
    rmdir ../build/lib > /dev/null 2>&1
    rm ../build/rootfs-lobo.img.gz > /dev/null 2>&1
    rm -rf output/* > /dev/null 2>&1
	rm -rf ../../OrangePi-BuildLinux/orange/lib/* 
else
	make_kernel "${1}"
fi

echo "***OK***"
