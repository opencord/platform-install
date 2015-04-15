#!/bin/bash

source ~/admin-openrc.sh

# Create nat-net network
neutron net-show nat-net 2>&1 > /dev/null
if [ "$?" -ne 0 ]
then
    neutron net-create --provider:physical_network=nat --provider:network_type=flat --shared nat-net
fi

# Create nat-net subnet
neutron subnet-show nat-net 2>&1 > /dev/null
if [ "$?" -ne 0 ]
then
    neutron subnet-create nat-net --name nat-net 172.16.0.0/16 --gateway=172.16.0.1 --enable-dhcp=false
fi

# Create nat-net network
neutron net-show ext-net 2>&1 > /dev/null
if [ "$?" -ne 0 ]
then
    neutron net-create --provider:physical_network=ext --provider:network_type=flat --shared ext-net
fi


