#!/bin/bash

cd ~
git clone https://github.com/open-cloud/openstack-cluster-setup.git
cd ~/openstack-cluster-setup
./bootstrap.sh
ansible-playbook -i cord-test-hosts cord-setup.yml

ssh ubuntu@onos-cord "cd cord; sudo docker-compose up -d"
ssh ubuntu@xos "cd xos/xos/configurations/cord-pod; sudo docker-compose pull"

# Need to wait for OpenStack services to come up before running any XOS "make" commands
echo "Waiting for the OpenStack services to fully come up."
echo "This can take 30 minutes or more, be patient!"
i=0
until juju status --format=summary|grep "started:  23" > /dev/null
do
    sleep 60
    (( i += 1 ))
    echo "Waited $i minutes"
done

echo "All OpenStack services are up."