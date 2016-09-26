#!/bin/bash

#### VARIABLES

TARS="tars"

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
cd sunxi-bsp
./configure cubieboard
make
echoGreen "Done!"
