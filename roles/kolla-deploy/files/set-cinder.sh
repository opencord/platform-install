#!/bin/sh

free_device=$(losetup -f)

fallocate -l 50G /var/lib/cinder_data.img

losetup $free_device /var/lib/cinder_data.img

pvcreate $free_device

vgcreate cinder-volumes $free_device
