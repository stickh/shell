#!/bin/bash

version=`uname -r`
echo -n "Please input what version you want(such as 3.13.0-24-genric):"
read new_version
echo "Now your server kernel version is ($version),and you are going to installing ($new_version)  "
read -s -n1 -p "Please press any key to continue....."
aptitude install linux-image-$new_version linux-image-extra-$new_version linux-headers-$new_version -y
#apt-get remove linux-image-$version linux-headers-$version -y
update-grub
echo "You are going to reboot now"
reboot
