#!/bin/bash

QDLOADID="05c6:9008"
DLOADID="05c6:9008"
SDMODE="05c6:9025"
MODEL="GT-I8730"
DEVICEID=/dev/disk/by-id/usb-Qualcomm_MMC_Storage-0\:0

DEVICE=`ls -lah /dev/disk/by-id/ | grep usb\-Qualcomm_MMC | head -n 1 | awk '{ print $11 }' | sed 's/\..\/..//'`
USBNAME=`lsusb | grep Qualcomm  ` 
USBID=`lsusb | grep Qualcomm  | awk '{ print $6 }'` 

echo 
echo -e "\033[38;5;148mUnbrick v1.0\033[39m"
echo ""
echo "Originally by Darkspr1te, forked by aureljared."
echo "See README for credits."
echo "---------------------------------------------"
echo ""
echo -n "Checking for Qualcomm devices in QDLOAD mode... "

if [ $USBID == $DLOADID ]; then 
	echo -e "found!"
	choice="n"
	
	echo -e -n "Do you wish to upload HEX & msimage.mbn now? [y/n]: "
	read -n 1 choice
		
	if [ $choice == "y" ]; then
		echo ""
		echo "Executing qdload.pl"
		perl qdload.pl -pfile MPRG8960.hex -lfile 8960_msimage.mbn -lreset
		echo ""
		echo "If HEX/MBN uploaded correctly, please wait a while and re-run unbrick.sh"
		echo "to continue the unbricking session. A screen showing device options may appear;"
		echo "close this new screen."
		exit 
	else
		echo ""
		echo "Operation cancelled at user request. Exiting."
		exit 1
	fi
else
	echo -e "not found.\n"
fi

echo -e -n "\e[00m"
echo -n "Checking for Qualcomm devices in SDBOOT mode... "
if [ $USBID == $SDMODE ]; then
	echo -e "found!"
	echo ""
	echo -e "Location: device node /dev$DEVICE"
	echo -e "with USB PID/VID ID of \e[00;44m$USBID\e[00;31m"
	echo -e "Detailed output is"
	echo -e "\e[00;33m$USBNAME\e[00m"
 
	# Write back the MBR to sector 0 and EBF to sector 208801
	echo ""
	echo -e "Do you wish to write the MBR? \e[00;31mWarning, dangerous!\e[00m"
	read -n 1 choice
	echo ""
	if [ $choice == "y" ]; then
		echo "Writing to /dev$DEVICE"
		dd if=$MODEL/partition0.bin of=/dev$DEVICE seek=0 count=1 bs=512 
		dd if=$MODEL/partition0.bin of=/dev$DEVICE skip=1 seek=208801 count=22 bs=512
		
		choice="n"
		echo ""
	fi

	# SMD_HDR seems to be the modem partition, uncomment at your own risk
	# dd if=smd_hdr.mbn of=/dev/sdb seek=1 count=102400 bs=512 

	# These next few lines are bootloader repair, all files required to get basic ODIN mode only.
	# If you know what is corrupt then only flash that file.
	echo -e "Do you wish to write bootloaders? \e[00;31mWarning, dangerous!\e[00m"
	read -n 1 choice
	echo ""
	if [ $choice == "y" ]; then
		echo "Writing bootloaders to /dev$DEVICE"
		echo " - secondary bootloader"
		dd if=$MODEL/sbl1.mbn of=/dev$DEVICE  seek=131072 count=500 bs=512
		dd if=$MODEL/sbl2.mbn of=/dev$DEVICE  seek=131328 count=1500 bs=512
		dd if=$MODEL/sbl3.mbn of=/dev$DEVICE  seek=131840 count=2048 bs=512
		echo "- AP bootloader"
		dd if=$MODEL/aboot.mbn of=/dev$DEVICE  seek=132864 count=2500 bs=512
		echo "- resource power manager"
		dd if=$MODEL/rpm.mbn of=/dev$DEVICE  seek=136960 count=500 bs=512
		
		choice="n"
		echo
	fi
	
	# boot.img only needed if it's damaged on the device.
	# dd if=$MODEL/boot.img of=/dev/sdb  seek=237568 count=10240 bs=512 

	echo -e "Do you wish to write TrustZone? \e[00;31mWarning, dangerous!\e[00m"
	read -n 1 choice
	echo
	if [ $choice == "y" ]; then
		echo "Writing TrustZone to /dev/$DEVICE"
		dd  if=$MODEL/tz.mbn of=/dev$DEVICE  seek=158464 count=500 bs=512 
	
		choice="n"
	fi

	echo ""
	echo "If no errors occurred then disconnect and remove/replace battery."
	echo "If ANY error occurred, do not disconnect device, fix error and rerun or seek advice."
else
	echo "not found."
	echo ""
	echo -e "\e[00;31mError:\e[00m No Qualcomm device found. Check cables, run lsusb and verify the device is connected."
	echo ""
	exit 1
fi
	
exit 0