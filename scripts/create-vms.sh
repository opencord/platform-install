#!/bin/bash

function create-vm {
	NAME=$1
	CPU=$2
	MEM_MB=$3
	DISK_GB=$4
	uvt-kvm list | grep $1
	if [ "$?" -ne "0" ]
	then
		uvt-kvm create $NAME --cpu=$CPU --memory=$MEM_MB --disk=$DISK_GB
		uvt-kvm wait --insecure $NAME
	fi
}

create-vm juju 1 2048 20
create-vm mysql 2 4096 40
create-vm rabbitmq-server 2 4096 40
create-vm keystone 2 4096 40
create-vm glance 2 4096 160
create-vm nova-cloud-controller 2 4096 40
create-vm quantum-gateway 2 4096 40
create-vm openstack-dashboard 1 2048 20
create-vm ceilometer 1 2048 20
create-vm nagios 1 2048 20
