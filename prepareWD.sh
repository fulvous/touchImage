#!/bin/bash

#### VARIABLES

TARS="tars"
GROW_SIZE_M=275
THRESHOLD_M=2000
CUBIAN_IMG="Cubian-desktop-x1-a10-hdmi.img"
NEW_CUBIAN_PART="cubian_new_part_table"

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


#### PREPARING

echoStep "Installing dependencies..."
sudo apt-get install libusb-1.0 pkg-config p7zip-full gcc-arm-linux-gnueabihf -y
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

echoStep "Detecting Cubian Desktop image..."
if [ ! -f "$TARS/${CUBIAN_IMG}.7z" ] ; then
	echoRed "Not found, downloading!"
	cd $TARS
	wget "http://creadoresdigitales.com/archivos/${CUBIAN_IMG}.7z"
	cd ..
else
	echoGreen "Found!"
fi

echoStep "Detecting Cubian extracted image..."
if [ ! -f "$TARS/$CUBIAN_IMG" ] ; then
	echoRed "Not found, Extracting!"
	cd $TARS
	7z x ${CUBIAN_IMG}.7z
	cd ..
fi

echoStep "Mounting image..."

echoStep "Detecting Cubian extracted image..."
if [ ! -f "$TARS/$CUBIAN_IMG" ] ; then
	echoRed "Not found, Extracting!"
	exit -1
else
	echoGreen "Found!"
	LOOP=$( sudo losetup -f )
	echo "Loop device available: $LOOP"

	
	SIZE=$( ls -alF $TARS/$CUBIAN_IMG | egrep -o '\s[0-9]{8,}\s' )
	HUMAN_SIZE_M=$(( SIZE / 1024 / 1024 ))
	FINAL_HUMAN_SIZE_M=$(( HUMAN_SIZE_M + GROW_SIZE_M ))
	
	echoStep "Growing image from $HUMAN_SIZE_M to $FINAL_HUMAN_SIZE_M MB"

	if [ $HUMAN_SIZE_M -lt $THRESHOLD_M ]; then
		dd if=/dev/zero bs=1M count=$GROW_SIZE_M >> $TARS/$CUBIAN_IMG
		sudo losetup $LOOP $TARS/$CUBIAN_IMG
		sudo partprobe $LOOP
		sudo sfdisk --force $LOOP < $NEW_CUBIAN_PART
		sudo partprobe $LOOP
		sudo e2fsck -f ${LOOP}p2 
		sudo resize2fs ${LOOP}p2
		sudo losetup -d $LOOP
		echoGreen "Done!"
	else
		echoRed "Already growned!"
	fi

	LOOP=$( sudo losetup -f )
	sudo losetup $LOOP $TARS/$CUBIAN_IMG
	
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
	sudo cp -v linux-sunxi/arch/arm/boot/uImage boot 
	echoGreen "Done!"
	
	echoStep "Installing modules..."
	sudo cp -vR linux-sunxi/output/lib/modules system/lib
	echoGreen "Done!"

	####load module
	RESULT=$( egrep -c 'ft5x_ts' system/etc/modules )
	echoStep "Adding ft5x_ts to modules file..."
	if [ $RESULT -eq 0 ] ; then
		cp system/etc/modules .
		sudo echo "ft5x_ts" >> modules
		sudo cp -v modules system/etc/modules  
		echoGreen "Added!"
	else
		echoRed "Skiping!"
	fi

	echoStep "Copying configs..."
	cp -v cubiescreen/sdk_configure/10-evdev.conf system/usr/share/X11/xorg.conf.d/
	cp -v cubiescreen/sdk_configure/exynos.conf system/usr/share/X11/xorg.conf.d/
	cp -v cubiescreen/sdk_configure/xinput_calibrator system/usr/bin

	cp -v cubiescreen/sdk_configure/xinput_calibrator.1.gz system/usr/share/man/man1/
	cp -v uEnv.txt boot/

	echoStep "Unmounting directories..."
	sudo umount boot
	sudo umount system
	echoGreen "Done!"

	echoStep "Remooving loop: $LOOP..."
	sudo losetup -d $LOOP
	echoGreen "Done!"

	mv $IMG Cubian-A10-touchImage-lcd.img
fi



