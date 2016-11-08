#!/bin/bash

sudo ./bootstrap_ansible.sh

# Generate SSH keys
ssh-keygen

# Add to authorized_keys
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# Add trusty-backports
sudo add-apt-repository -r "deb http://archive.ubuntu.com/ubuntu $(lsb_release -cs)-backports main restricted universe multiverse"

# Add Juju
sudo add-apt-repository "ppa:juju/stable"

sudo apt-get update
sudo apt-get install -y python-netaddr juju-core
sudo apt-get -t trusty-backports install -y lxd

echo "Don't forget to run: sudo dpkg-reconfigure -p medium lxd"
echo "Don't forget to set on_cloudlab: true"