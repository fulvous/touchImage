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

#echoStep "Detecting rtl8192eu module..."
#if [ ! -d "rtl8192eu" ] ; then
#	echoRed "Not found, downloading!"
#	git clone https://github.com/romcyncynatus/rtl8192eu.git
#else
#	echoGreen "Found!"
#fi

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

#echoStep "Detecting Cubian desktop image..."
#if [ ! -f "$TARS/Cubian-desktop-x1-a10-hdmi.img" ] ; then
#	echoRed "Not found, Downloading!"
#	tar xvf $TARS/cubiescreen_drv.tar
#else
#	echoGreen "Found!"
#fi



#### PREPARING

echoStep "Installing dependencies..."
sudo apt-get install libusb-1.0 pkg-config -y
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

#echoStep "Copying sun7i_defconfig..."
#cp -vf cubiescreen/sun7i_defconfig linux-sunxi/arch/arm/configs/
#echoGreen "Done!"

#if [ ! -f "$TARS/ubuntu_sdk.tar.gz" ] ; then
#	### Gor for Linaro
#	echoStep "Detecting Linaro SDK..."
#	if [ ! -f "$TARS/linaro-quantal-alip-20130422-342.tar.gz" ] ; then
#		echoRed "Not found, downloading!"
#		cd $TARS
#		wget "http://creadoresdigitales.com/archivos/linaro-quantal-alip-20130422-342.tar.gz"
#		cd ..
#	else
#		echoGreen "Found!"
#	fi
#	
#	
#	echoStep "Detecting uncompressed Linaro SDK..."
#	if [ ! -d "binary" ] ; then
#		echoRed "Not found, extracting!"
#		tar zxvf $TARS/linaro-quantal-alip-20130422-342.tar.gz
#	else
#		echoGreen "Found!"
#	fi
#	
#	
#	
#	echoStep "Updating Linaro configuration..."
#	cp -v cubiescreen/sdk_configure/sources.list binary/etc/apt/
#	cp -v cubiescreen/sdk_configure/lightdm.conf binary/etc/lightdm/
#	RESULT=$( egrep -c 'ft5x_ts' binary/etc/modules )
#	echoStep "Adding ft5x_ts to modules file..."
#	if [ $RESULT -eq 0 ] ; then
#		echo "ft5x_ts" >> binary/etc/modules
#		echoGreen "Added!"
#	else
#		echoRed "Skiping!"
#	fi
#	cp -v cubiescreen/sdk_configure/10-evdev.conf binary/usr/share/X11/xorg.conf.d/
#	cp -v cubiescreen/sdk_configure/exynos.conf binary/usr/share/X11/xorg.conf.d/
#	cp -v cubiescreen/sdk_configure/xinput_calibrator binary/usr/bin/
#	cp -v cubiescreen/sdk_configure/xinput_calibrator.1.gz binary/usr/share/man/man1/
#
#	cp -v shadow binary/etc/shadow
#	
#	####Repacking
#	echoStep "Repacking Linaro..."
#	if [ -d "binary" ] ; then
#		tar cfz $TARS/ubuntu_sdk.tar.gz binary
#		echoGreen "Done!"
#	else
#		echoRed "Failed!"
#	fi
#else
#	echoRed "Linaro already repacked!"
#fi


echoStep "Mounting image..."

echoStep "Detecting Cubian desktop image..."
if [ ! -f "$TARS/Cubian-desktop-x1-a10-hdmi.img" ] ; then
	echoRed "Not found, Downloading!"
else
	echoGreen "Found!"
	LOOP=$( sudo losetup -f )
	echo "Loop device available: $LOOP"
	sudo losetup $LOOP $TARS/Cubian-desktop-x1-a10-hdmi.img
	
	echoStep "creating mount points..."
	mkdir boot -p
	mkdir system -p
	echoGreen "Done!"
	
	echoStep "refreshing partitions..."
	sudo partprobe $LOOP
	echoGreen "Done!"

	echoStep "mounting directories..."
	sudo mount ${LOOP}p1 boot
	sudo mount ${LOOP}p2 system
	echoGreen "Done!"

	echoStep "pushing new fex..."
	sudo sunxi-bsp/sunxi-tools/fex2bin script.fex boot/script.bin
	echoGreen "Done!"

	echo "copying config"
	cp -v cubian.config linux-sunxi/.config
	
	echoStep "compiling..."
	cd linux-sunxi
	make -j4 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- uImage modules
	echoGreen "Done!"

	echoStep "Saving modules in output folder..."
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=output modules_install
	cd ..
	echoGreen "Done!"

	echoStep "Installing kernel..."
	cp -v linux-sunxi/arch/arm/boot/uImage boot 
	echoGreen "Done!"
	
	echoStep "Installing modules..."
	cp -vR linux-sunxi/output/lib/modules system/lib
	echoGreen "Done!"

	####load module
	RESULT=$( egrep -c 'ft5x_ts' system/etc/modules )
	echoStep "Adding ft5x_ts to modules file..."
	if [ $RESULT -eq 0 ] ; then
		echo "ft5x_ts" >> system/etc/modules
		echoGreen "Added!"
	else
		echoRed "Skiping!"
	fi


	
	echoStep "Unmounting directories..."
	sudo umount boot
	sudo umount system
	echoGreen "Done!"

	echoStep "Remooving loop: $LOOP..."
	sudo losetup -d $LOOP
	echoGreen "Done!"
fi



