!/usr/bin/env bash

function cleanup_from_previous_test() {
    echo "## Cleanup ##"

    echo "Destroying juju environment"
    juju destroy-environment --force -y manual

    VMS=$( sudo uvt-kvm list )
    for VM in $VMS
    do
      echo "Destroying $VM"
      sudo uvt-kvm destroy $VM
    done

    echo "Cleaning up files"
    rm -rf ~/.juju
    rm -f ~/.ssh/known_hosts
    rm -rf ~/platform-install

    echo "Cleaning up libvirt/dnsmasq"
    sudo rm -f /var/lib/libvirt/dnsmasq/xos-mgmtbr.leases
    sudo killall dnsmasq
    sudo service libvirt-bin restart
}

function bootstrap() {
    cd ~
    sudo apt-get update
    sudo apt-get -y install software-properties-common curl git mosh tmux dnsutils python-netaddr
    sudo add-apt-repository -y ppa:ansible/ansible
    sudo apt-get update
    sudo apt-get install -y ansible

    [ -e ~/.ssh/id_rsa ] || ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

    git clone $SETUP_REPO_URL platform-install
    cd ~/platform-install
    git checkout $SETUP_BRANCH

    sed -i "s/replaceme/`whoami`/" $INVENTORY

    # Log into the local node once to get host key
    ssh -o StrictHostKeyChecking=no localhost "ls > /dev/null"
}

function setup_openstack() {
    cd ~/platform-install

    extra_vars="xos_repo_url=$XOS_REPO_URL xos_repo_branch=$XOS_BRANCH"

    # check if running on cloudlab
    if [[ -x /usr/testbed/bin/mkextrafs ]]
    then
      extra_vars="$extra_vars on_cloudlab=True"
    fi

    ansible-playbook -i $INVENTORY cord-single-playbook.yml --extra-vars="$extra_vars"
}

function setup_xos() {

    if [[ $EXAMPLESERVICE -eq 1 ]]
    then
      ssh ubuntu@xos "cd service-profile/cord-pod; make exampleservice"

      echo "(Temp workaround for bug in Synchronizer) Pause 60 seconds"
      sleep 60
      ssh ubuntu@xos "cd service-profile/cord-pod; make vtn"
    fi

}

function run_e2e_test () {
    ansible-playbook -i $INVENTORY cord-post-deploy-playbook.yml
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

function run_diagnostics() {
    echo "*** COLLECTING DIAGNOSTIC INFO - check ~/diag-* on the head node"
    ansible-playbook -i $INVENTORY cord-diag-playbook.yml
}

# Parse options
RUN_TEST=0
EXAMPLESERVICE=0
SETUP_BRANCH="master"
SETUP_REPO_URL="https://github.com/opencord/platform-install"
INVENTORY="inventory/single-localhost"
XOS_BRANCH="master"
XOS_REPO_URL="https://github.com/opencord/xos"
DIAGNOSTICS=1

while getopts "b:dehi:p:r:ts:" opt; do
  case ${opt} in
    b ) XOS_BRANCH=$OPTARG
      ;;
    d ) DIAGNOSTICS=0
      ;;
    e ) EXAMPLESERVICE=1
      ;;
    h ) echo "Usage:"
      echo "    $0                install OpenStack and prep XOS and ONOS VMs [default]"
      echo "    $0 -b <branch>    checkout <branch> of the xos git repo"
      echo "    $0 -d             don't run diagnostic collector"
      echo "    $0 -e             add exampleservice to XOS"
      echo "    $0 -h             display this help message"
      echo "    $0 -i <inv_file>  specify an inventory file (default is inventory/single-localhost)"
      echo "    $0 -p <git_url>   use <git_url> to obtain the platform-install git repo"
      echo "    $0 -r <git_url>   use <git_url> to obtain the xos git repo"
      echo "    $0 -s <branch>    checkout <branch> of the platform-install git repo"
      echo "    $0 -t             do install, bring up cord-pod configuration, run E2E test"
      exit 0
      ;;
    i ) INVENTORY=$OPTARG
      ;;
    p ) SETUP_REPO_URL=$OPTARG
      ;;
    r ) XOS_REPO_URL=$OPTARG
      ;;
    t ) RUN_TEST=1
      ;;
    s ) SETUP_BRANCH=$OPTARG
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

if [[ $RUN_TEST -eq 1 ]]
then
  run_e2e_test

  if [[ $EXAMPLESERVICE -eq 1 ]]
  then
    setup_xos
    run_exampleservice_test
  fi
fi

if [[ $DIAGNOSTICS -eq 1 ]]
then
  run_diagnostics
fi

exit 0

