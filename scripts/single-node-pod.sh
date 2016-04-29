#!/bin/bash

function bootstrap() {
    cd ~
    git clone https://github.com/open-cloud/openstack-cluster-setup.git
    cd ~/openstack-cluster-setup
    ./bootstrap.sh

    # Log into the local node once to get host key
    ssh -o StrictHostKeyChecking=no localhost "ls > /dev/null"
}

function setup_openstack() {
    # Run the playbook
    ansible-playbook -i cord-test-hosts cord-setup.yml
}

function pull_docker_images() {
    # Pull down the Docker images
    echo ""
    echo "Pull down the Docker images for ONOS and XOS"
    echo "This can take 20 minutes or more, be patient!"
    ssh ubuntu@onos-cord "cd cord; sudo docker-compose up -d"
    ssh ubuntu@xos "cd xos/xos/configurations/cord-pod; sudo docker-compose pull"
}

function wait_for_openstack() {
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
}

function simulate_fabric() {
    echo ""
    echo "Setting up simulated fabric on nova-compute node"
    ssh ubuntu@nova-compute "wget https://raw.githubusercontent.com/open-cloud/openstack-cluster-setup/master/scripts/compute-ext-net.sh; sudo bash compute-ext-net.sh"
}

function setup_xos() {
    echo ""
    echo "Setting up XOS, will take a few minutes"
    ssh ubuntu@xos "cd xos/xos/configurations/cord-pod; make"
    echo ""
    echo "Pause 2 minutes"
    sleep 120

    ssh ubuntu@xos "cd xos/xos/configurations/cord-pod; make vtn"
    echo ""
    echo "Pause 30 seconds"
    sleep 30

    ssh ubuntu@xos "cd xos/xos/configurations/cord-pod; make cord"
}

function setup_test_client() {
    ssh ubuntu@nova-compute "sudo apt-get -y install lxc"

    # Change default bridge
    ssh ubuntu@nova-compute "sudo sed -i 's/lxcbr0/databr/' /etc/lxc/default.conf"

    # Create test client
    ssh ubuntu@nova-compute "sudo lxc-create -t ubuntu -n testclient"
    ssh ubuntu@nova-compute "sudo lxc-start -n testclient"

    # Configure network interface inside of test client with s-tag and c-tag
    ssh ubuntu@nova-compute "sudo lxc-attach -n testclient -- ip link add link eth0 name eth0.222 type vlan id 222"
    ssh ubuntu@nova-compute "sudo lxc-attach -n testclient -- ip link add link eth0.222 name eth0.222.111 type vlan id 111"
    ssh ubuntu@nova-compute "sudo lxc-attach -n testclient -- ifconfig eth0.222 up"
    ssh ubuntu@nova-compute "sudo lxc-attach -n testclient -- ifconfig eth0.222.111 up"
}

function run_e2e_test() {
    source ~/admin-openrc.sh

    echo "*** Wait for vSG VM to come up"
    i=0
    until nova list --all-tenants|grep ACTIVE > /dev/null
    do
	sleep 60
	(( i += 1 ))
	echo "Waited $i minutes"
    done

    # get mgmt IP address
    ID=$( nova list --all-tenants|grep mysite_vsg|awk '{print $2}' )
    MGMTIP=$( nova interface-list $ID|grep 172.27|awk '{print $8}' )

    echo ""
    echo "*** ssh into vsg VM, wait for Docker container to come up"
    i=0
    until ssh -o ProxyCommand="ssh -W %h:%p ubuntu@nova-compute" ubuntu@$MGMTIP "sudo docker ps|grep vcpe" > /dev/null
    do
	sleep 60
	(( i += 1 ))
	echo "Waited $i minutes"
    done

    echo ""
    echo "*** Run dhclient in test client"
    ssh ubuntu@nova-compute "sudo lxc-attach -n testclient -- dhclient eth0.222.111" > /dev/null

    echo ""
    echo "*** Routes in test client"
    ssh ubuntu@nova-compute "sudo lxc-attach -n testclient -- route -n"


    echo ""
    echo "*** Test external connectivity in test client"
    ssh ubuntu@nova-compute "sudo lxc-attach -n testclient -- ping -c 3 8.8.8.8"

    echo ""
    if [ $? -eq 0 ]
    then
	echo "*** [PASSED] End-to-end connectivity test"
	exit 0
    else
	echo "*** [FAILED] End-to-end connectivity test"
	exit 1
    fi
}

# Parse options
RUN_TEST=0
while getopts ":ht" opt; do
  case ${opt} in
    h ) "echo Usage:"
      echo "    $0            install OpenStack and prep XOS and ONOS VMs [default]"
      echo "    $0 -h         display this help message"
      echo "    $0 -t         do install, bring up cord-pod configuration, run E2E test"
      exit 0
      ;;
    t ) RUN_TEST=1
      ;;
    \? ) echo "Invalid option"
      exit 1
      ;;
  esac
done

# What to do
bootstrap
setup_openstack
pull_docker_images
wait_for_openstack
simulate_fabric

if [[ $RUN_TEST -eq 1 ]]
then
  setup_xos
  setup_test_client
  run_e2e_test
fi
