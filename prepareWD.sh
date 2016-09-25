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

#### DOWNLOADING

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

echoStep "Detecting rtl8192eu module..."
if [ ! -d "rtl8192eu" ] ; then
	echoRed "Not found, downloading!"
	git clone https://github.com/romcyncynatus/rtl8192eu.git
else
	echoGreen "Found!"
fi

echoStep "Detecting tar directory..."
if [ ! -d "$TARS" ] ; then
	echoRed "Not found, creating!"
	mkdir $TARS
else
	echoGreen "Found!"
fi

echoStep "Detecting Linaro SDK..."
if [ ! -f "$TARS/linaro-quantal-alip-20130422-342.tar.gz" ] ; then
	echoRed "Not found, downloading!"
	cd $TARS
	wget "http://creadoresdigitales.com/archivos/linaro-quantal-alip-20130422-342.tar.gz"
	cd ..
else
	echoGreen "Found!"
fi


