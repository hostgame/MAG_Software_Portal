#!/bin/bash
# Original image in ./image/vmlinux.bin
# Result:
#	  uImage 	   -  signed kernel prepared for bootloader  
#	  uImzlib_null.img -  image for partition mtd4
#	  uImzlib.img 	   -  signed image for mtd4 include in updateimage  
#
# Allowed options: --custom -> signes as custom image

. ../includes/initialize.sh
. ../includes/message.sh

if [ "$1" == "--custom" ]
then
	export MAKE_CUSTOM_IMAGE=1
fi

rm -f ./uImage_mag250 ./uImzlib_null_mag250.img ./uImzlib_mag250.img
if [ -e ./images/vmlinux.mag250 ]; then
searchstr="start address"
entrypoint=`sh4-linux-objdump -f ./images/vmlinux.mag250 | grep "$searchstr" | tail --bytes=11`
else
entrypoint=0x80801000
fi
gzip -c9 ./images/vmlinux.bin.mag250 > ./vmlinux.bin.gz

if [ "$MAKE_CUSTOM_IMAGE" != "" ] ; then
    OLD_KEY=$MAG200_OP_KEY
    export MAG200_OP_KEY=STB_PUBLIC
    ./mksign.sh vmlinux.bin.gz vmlinux.sign 
    export MAG200_OP_KEY=$OLD_KEY
else
    ./mksign.sh vmlinux.bin.gz vmlinux.sign 
fi
./mkimage -A sh -O linux -T kernel -C gzip -a 0x80800000 -e $entrypoint -n 'MAG250 SH4 Kernel Linux 2.6.17' -d ./vmlinux.sign ./uImage_mag250
rm -f vmlinux.bin.gz vmlinux.sign
rm -f ./uImzlib_mag250.img
rm -f -R ./kernel
mkdir ./kernel
cp ./uImage_mag250 ./kernel/uImage
./or_mkfs.jffs2 -d ./kernel -o uImzlib_null_mag250.img -x zlib -x rtime -s 2048 -e 128KiB  -n
rm -f ./kernel/*
rmdir ./kernel
./mksign.sh uImzlib_null_mag250.img uImzlib_mag250.img

