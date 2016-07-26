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

    extra_vars="single_node_pod_script=true"

    if [[ "$XOS_REPO_URL" != "" ]]; then
        extra_vars="$extra_vars xos_repo_url=$XOS_REPO_URL"
    fi
    if [[ "$XOS_BRANCH" != "" ]]; then 
        extra_vars="$extra_vars xos_repo_branch=$XOS_BRANCH"
    fi

    # check if running on cloudlab
    if [[ -x /usr/testbed/bin/mkextrafs ]]
    then
      extra_vars="$extra_vars on_cloudlab=True"
    fi

    ansible-playbook -i $INVENTORY cord-single-playbook.yml --extra-vars="$extra_vars"
}

function run_e2e_test () {
    ansible-playbook -i $INVENTORY cord-post-deploy-playbook.yml
}

function run_diagnostics() {
    echo "*** COLLECTING DIAGNOSTIC INFO - check ~/diag-* on the head node"
    ansible-playbook -i $INVENTORY cord-diag-playbook.yml
}

# Parse options
RUN_TEST=0
SETUP_BRANCH="master"
SETUP_REPO_URL="https://github.com/opencord/platform-install"
INVENTORY="inventory/single-localhost"
DIAGNOSTICS=1
CLEANUP=0

while getopts "b:dehi:p:r:ts:" opt; do
  case ${opt} in
    b ) XOS_BRANCH=$OPTARG
      ;;
    c ) CLEANUP=1
      ;;
    d ) DIAGNOSTICS=0
      ;;
    h ) echo "Usage:"
      echo "    $0                install OpenStack and prep XOS and ONOS VMs [default]"
      echo "    $0 -b <branch>    checkout <branch> of the xos git repo"
      echo "    $0 -c             cleanup from previous test"
      echo "    $0 -d             don't run diagnostic collector"
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
if [[ $CLEANUP -eq 1 ]]
then
  cleanup_from_previous_test
fi

set -e

bootstrap
setup_openstack

if [[ $RUN_TEST -eq 1 ]]
then
  run_e2e_test
fi

if [[ $DIAGNOSTICS -eq 1 ]]
then
  run_diagnostics
fi

exit 0

