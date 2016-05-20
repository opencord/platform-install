#!/bin/bash

function cleanup_from_previous_test() {
    VMS=$( sudo virsh list|grep running|awk '{print $2}' )
    for VM in $VMS
    do
      sudo uvt-kvm destroy $VM
    done

    rm -rf ~/.juju
    rm -f ~/.ssh/known_hosts
    rm -rf ~/openstack-cluster-setup

    sudo rm -f /var/lib/libvirt/dnsmasq/default.leases
    sudo killall -HUP dnsmasq
}

function bootstrap() {
    cd ~
    sudo apt-get update
    sudo apt-get -y install git
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

function pull_onos_docker_image() {
    echo ""
    echo "Pull down the ONOS Docker image"
    ssh ubuntu@onos-cord "cd cord; sudo docker-compose up -d"
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
    if [[ $EXAMPLESERVICE -eq 1 ]]
    then
      SCRIPT=compute-ext-net-tutorial.sh
    else
      SCRIPT=compute-ext-net.sh
    fi
    ssh ubuntu@nova-compute "wget https://raw.githubusercontent.com/open-cloud/openstack-cluster-setup/master/scripts/$SCRIPT; sudo bash $SCRIPT"
}

function build_xos_docker_images() {
    echo ""
    echo "Checking out XOS branch $BUILD_BRANCH"
    ssh ubuntu@xos "cd xos; git config --global user.email 'ubuntu@localhost'; git config --global user.name 'XOS ExampleService'"
    ssh ubuntu@xos "cd xos; git checkout $BUILD_BRANCH"
    if [[ $EXAMPLESERVICE -eq 1 ]]
    then
      echo ""
      echo "Adding exampleservice to XOS"
      ssh ubuntu@xos "cd xos; git cherry-pick 775e00549e535803522fbcd70152e5e1b0629c83"
    fi
    echo ""
    echo "Rebuilding XOS containers"
    ssh ubuntu@xos "cd xos/xos/configurations/cord-pod; make local_containers"

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

    if [[ $EXAMPLESERVICE -eq 1 ]]
    then
      ssh ubuntu@xos "cd xos/xos/configurations/cord-pod; make exampleservice"
    fi
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
    until nova list --all-tenants|grep 'vsg.*ACTIVE' > /dev/null
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
    else
      echo "*** [FAILED] End-to-end connectivity test"
      exit 1
    fi
}

function run_exampleservice_test () {
    source ~/admin-openrc.sh

    echo "*** Wait for exampleservice VM to come up."
    echo "!!! NOTE that currently the VM will only be created after you login"
    echo "!!! to XOS and manually create an ExampleService tenant."
    i=0
    until nova list --all-tenants|grep exampleservice.*ACTIVE > /dev/null
    do
      sleep 60
	    (( i += 1 ))
	    echo "Waited $i minutes"
    done

    # get mgmt IP address
    ID=$( nova list --all-tenants|grep mysite_exampleservice|awk '{print $2}' )
    MGMTIP=$( nova interface-list $ID|grep 172.27|awk '{print $8}' )
    PUBLICIP=$( nova interface-list $ID|grep 10.168|awk '{print $8}' )

    echo ""
    echo "*** ssh into exampleservice VM, wait for Apache come up"
    i=0
    until ssh -o ProxyCommand="ssh -W %h:%p ubuntu@nova-compute" ubuntu@$MGMTIP "ls /var/run/apache2/apache2.pid"
    do
      sleep 60
      (( i += 1 ))
      echo "Waited $i minutes"
    done


    echo ""
    echo "*** Install curl in test client"
    ssh ubuntu@nova-compute "sudo lxc-attach -n testclient -- apt-get -y install curl"

    echo ""
    echo "*** Test connectivity to ExampleService from test client"
    ssh ubuntu@nova-compute "sudo lxc-attach -n testclient -- curl -s http://$PUBLICIP"
}

# Parse options
RUN_TEST=0
EXAMPLESERVICE=0
BUILD_BRANCH=""
while getopts "b:eht" opt; do
  case ${opt} in
    b ) BUILD_BRANCH=$OPTARG
      ;;
    h ) echo "Usage:"
      echo "    $0             install OpenStack and prep XOS and ONOS VMs [default]"
      echo "    $0 -b <branch> build XOS containers based on GitHub <branch> instead of pulling them from Docker Hub"
      echo "    $0 -e          add exampleservice to XOS"
      echo "    $0 -h          display this help message"
      echo "    $0 -t          do install, bring up cord-pod configuration, run E2E test"
      exit 0
      ;;
    t ) RUN_TEST=1
      ;;
    e ) EXAMPLESERVICE=1
      ;;
    \? ) echo "Invalid option: -$OPTARG"
      exit 1
      ;;
  esac
done

# What to do
if [[ $RUN_TEST -eq 1 ]]
then
  cleanup_from_previous_test
fi

set -e

bootstrap
setup_openstack
pull_onos_docker_image
wait_for_openstack
simulate_fabric

if [[ $RUN_TEST -eq 1 ]]
then
  if [[ -n $BUILD_BRANCH || $EXAMPLESERVICE -eq 1 ]]
  then
    build_xos_docker_images
  fi
  setup_xos
  setup_test_client
  run_e2e_test
  if [[ $EXAMPLESERVICE -eq 1 ]]
  then
    run_exampleservice_test
  fi
fi

exit 0
