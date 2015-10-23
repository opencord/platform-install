#!/bin/sh

FILE=/etc/libvirt/qemu/networks/default.xml

cp $FILE $FILE.tmp
virsh net-destroy default
virsh net-undefine default

cp $FILE.tmp $FILE
virsh net-create $FILE
