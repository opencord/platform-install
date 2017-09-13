
# Copyright 2017-present Open Networking Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


#!/bin/bash

function cleanup_network {
  NETWORK=$1
  SUBNETS=`neutron net-show $NETWORK | grep -i subnets | awk '{print $4}'`
  if [[ $SUBNETS != "" ]]; then
      PORTS=`neutron port-list | grep -i $SUBNETS | awk '{print $2}'`
      for PORT in $PORTS; do
          echo "Deleting port $PORT"
          neutron port-delete $PORT
      done
  fi
  neutron net-delete $NETWORK
}

source /opt/cord_profile/admin-openrc.sh

echo "Deleting VMs"
# Delete all VMs
VMS=$( nova list --all-tenants|grep mysite|awk '{print $2}' )
for VM in $VMS
do
    nova delete $VM
done

echo "Waiting 5 seconds..."
sleep 5

cleanup_network lan_network
cleanup_network wan_network
cleanup_network mysite_vcpe-private
cleanup_network mysite_vsg-access
cleanup_network management
cleanup_network management_hosts

echo "Deleting networks"
# Delete all networks beginning with mysite_
NETS=$( neutron net-list --all-tenants|grep mysite|awk '{print $2}' )
for NET in $NETS
do
    neutron net-delete $NET
done

neutron net-delete lan_network || true
neutron net-delete subscriber_network || true
neutron net-delete public_network || true
neutron net-delete hpc_client_network || true
neutron net-delete ceilometer_network || true
neutron net-delete management || true
neutron net-delete management_hosts || true
neutron net-delete mysite_vsg-access || true
neutron net-delete public || true
neutron net-delete exampleservice_network || true
