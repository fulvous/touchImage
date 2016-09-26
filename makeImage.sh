#!/bin/bash

#### VARIABLES

if [ -z "$1" ] ; then
	IMG="touchImage.img"
else
	IMG="$1"
fi

SIZE_GB="7"
TARS="tars"

BYTES=$(( SIZE_GB * 1024 * 1024 * 1024 ))
CHUNK=512
SECTORS=$(( BYTES / CHUNK ))
echo "Building image of $SIZE_GB GB"
echo "Sectors: $SECTORS, Chunk: $CHUNK"

#### FUNCTIONS

function echoGreen {
	echo -e "\e[32m$1\e[0m"
}

function echoRed {
	echo -e "\e[91m$1\e[0m"
}

function echoStep {
	echo -ne "\e[1m$1\e[0m"
}

#### PROCESS

echoStep "Building image..."
#dd if=/dev/zero of=$IMG count=$SECTORS bs=$CHUNK
echo "img file created with zeros"
LOOP=$( sudo losetup -f )
echo "Loop device available: $LOOP"
sudo losetup $LOOP $IMG

if [ -f "sunxi-bsp/output/cubieboard_hwpack.tar.xz" ] && [ -f "$TARS/ubuntu_sdk.tar.gz" ] ; then
	sudo sunxi-bsp/scripts/sunxi-media-create.sh $LOOP sunxi-bsp/output/cubieboard_hwpack.tar.xz $TARS/ubuntu_sdk.tar.gz 
else
	echoRed "Files not found!"
	echo "sunxi-bsp/output/cubieboard_hwpack.tar.xz and $TARS/ubuntu_sdk.tar.gz"
fi

echo "Erasing loop"
sudo losetup -d $LOOP


echoGreen "Done!"

