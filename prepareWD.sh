#!/bin/bash

function echoGreen {
	echo -e "\e[32m$1\e[0m"
}

function echoRed {
	echo -e "\e[91m$1\e[0m"
}

function echoStep {
	echo -ne "\e[1m$1\e[0m"
}

echoStep "Detecting linux-sunxi kernel..."
if [ ! -d "linux-sunxi" ] ; then
	echoRed "Not found, downloading!"
	git clone https://github.com/linux-sunxi/linux-sunxi.git
else 
	echoGreen "Found!"
fi

echoStep "Detecting sunxi-bsp tools..."
if [ ! -d "sunxi-bsp" ] ; then
	echoRed "Not found, downloading!"
	git clone https://github.com/linux-sunxi/sunxi-bsp.git
else
	echoGreen "Found!"
fi

