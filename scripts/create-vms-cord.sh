#!/bin/bash

TESTING=false

while [[ $# > 0 ]]
do
key="$1"

case $key in
    --testing)
    TESTING=true
    ;;
    *)
    ;;
esac
shift
done

function create-vm {
	NAME=$1
	CPU=$2
	MEM_MB=$3
	DISK_GB=$4
	uvt-kvm list | grep $1
	if [ "$?" -ne "0" ]
	then
		if $TESTING
		then
			# Don't use mgmtbr for testing
			uvt-kvm create $NAME --cpu=$CPU --memory=$MEM_MB --disk=$DISK_GB
		else
			uvt-kvm create $NAME --cpu=$CPU --memory=$MEM_MB --disk=$DISK_GB --bridge mgmtbr
		fi
		# uvt-kvm wait --insecure $NAME
	fi
}

function wait-for-vm {
  NAME=$1
  until dig $NAME && ssh ubuntu@$NAME "ls"
  do
    sleep 1
  done
}

create-vm juju 1 2048 20
create-vm mysql 2 4096 40
create-vm rabbitmq-server 2 4096 40
create-vm keystone 2 4096 40
create-vm glance 2 4096 160
create-vm nova-cloud-controller 2 4096 40
create-vm neutron-api 2 4096 40
create-vm openstack-dashboard 1 2048 20
create-vm ceilometer 1 2048 20
create-vm nagios 1 2048 20

create-vm xos 2 4096 40
create-vm onos-cord 2 4096 40
create-vm onos-fabric 2 4096 40
if $TESTING
then
	create-vm nova-compute 2 4096 100
fi

# Wait for everything to get set up
wait-for-vm juju
wait-for-vm mysql
wait-for-vm rabbitmq-server
wait-for-vm keystone
wait-for-vm glance
wait-for-vm nova-cloud-controller
wait-for-vm neutron-api
wait-for-vm openstack-dashboard
wait-for-vm ceilometer
wait-for-vm nagios

wait-for-vm xos
wait-for-vm onos-cord
wait-for-vm onos-fabric
if $TESTING
then
	wait-for-vm nova-compute
fi
