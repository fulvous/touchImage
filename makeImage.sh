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
dd if=/dev/zero of=$IMG count=$SECTORS bs=$CHUNK
echoGreen "Done!"

