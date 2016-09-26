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

echoStep "Detecting uncompressed cubiescreen module..."
if [ ! -d "cubiescreen" ] ; then
	echoRed "Not found, extracting!"
	tar xvf $TARS/cubiescreen_drv.tar
else
	echoGreen "Found!"
fi




#### PREPARING

echoStep "Installing dependencies..."
sudo apt-get install libusb-1.0 libusb-1.0-dev
echoGreen "Done!"


#### INSTALLING

echoStep "Installing cubiescreen on kernel sources..."
#### Copying all sources
cp -v cubiescreen/driver/touchscreen/* linux-sunxi/drivers/input/touchscreen/
cp -v cubiescreen/driver/video/disp/* linux-sunxi/drivers/video/sunxi/disp/
cp -v cubiescreen/driver/video/lcd/* linux-sunxi/drivers/video/sunxi/lcd/
cp -v cubiescreen/driver/ctp.h linux-sunxi/include/linux/
echoGreen "Done!"

#### CONFIGURING

echoStep "Configuring sunxi-bsp ..."
#### Running configure script
cd sunxi-bsp
./configure
cd ..
echoGreen "Done!"

echoStep "Copying default cubieboard.fex..."
cp -vf cubiescreen/cubieboard.fex sunxi-bsp/sunxi-boards/sys_config/a10/
echoGreen "Done!"

if [ ! -f "$TARS/ubuntu_sdk.tar.gz" ] ; then
	### Gor for Linaro
	echoStep "Detecting Linaro SDK..."
	if [ ! -f "$TARS/linaro-quantal-alip-20130422-342.tar.gz" ] ; then
		echoRed "Not found, downloading!"
		cd $TARS
		wget "http://creadoresdigitales.com/archivos/linaro-quantal-alip-20130422-342.tar.gz"
		cd ..
	else
		echoGreen "Found!"
	fi
	
	
	echoStep "Detecting uncompressed Linaro SDK..."
	if [ ! -d "binary" ] ; then
		echoRed "Not found, extracting!"
		tar zxvf $TARS/linaro-quantal-alip-20130422-342.tar.gz
	else
		echoGreen "Found!"
	fi
	
	
	
	echoStep "Updating Linaro configuration..."
	cp -v cubiescreen/sdk_configure/sources.list binary/etc/apt/
	cp -v cubiescreen/sdk_configure/lightdm.conf binary/etc/lightdm/
	RESULT=$( egrep -c 'ft5x_ts' binary/etc/modules )
	echoStep "Adding ft5x_ts to modules file..."
	if [ $RESULT -eq 0 ] ; then
		echo "ft5x_ts" >> binary/etc/modules
		echoGreen "Added!"
	else
		echoRed "Skiping!"
	fi
	cp -v cubiescreen/sdk_configure/10-evdev.conf binary/usr/share/X11/xorg.conf.d/
	cp -v cubiescreen/sdk_configure/exynos.conf binary/usr/share/X11/xorg.conf.d/
	cp -v cubiescreen/sdk_configure/xinput_calibrator binary/usr/bin/
	cp -v cubiescreen/sdk_configure/xinput_calibrator.1.gz binary/usr/share/man/man1/
	
	####Repacking
	echoStep "Repacking Linaro..."
	if [ -d "binary" ] ; then
		tar cfz $TARS/ubuntu_sdk.tar.gz binary
		echoGreen "Done!"
	else
		echoRed "Failed!"
	fi
else
	echoRed "Linaro already repacked!"
fi



