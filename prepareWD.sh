#!/bin/bash

echo -n "Detecting linux-sunxi kernel..."
if [ -z linux-sunxi ] ; then
	echo "Not found, downloading!"
	git clone https://github.com/linux-sunxi/linux-sunxi.git
else 
	echo "Found!"
fi

echo -n "Detecting sunxi-bsp tools..."
if [ -z sunxi-bsp ] ; then
	echo "Not found, downloading!"
	git clone https://github.com/linux-sunxi/sunxi-bsp.git
else
	echo "Found!"
fi

