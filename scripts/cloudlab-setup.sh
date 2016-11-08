#!/bin/bash

sudo apt-get update
sudo ./bootstrap_ansible.sh

# Generate SSH keys
ssh-keygen

# Add to authorized_keys
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# Add Juju
sudo add-apt-repository "ppa:juju/stable"

sudo apt-get update
sudo apt-get install -y python-netaddr juju-core

# Set up extra space
sudo mkdir /var/extra
sudo /usr/testbed/bin/mkextrafs /var/extra

# Duplicates some stuff in the playbook
sudo mkdir /var/extra/lxd
sudo ln -s /var/extra/lxd /var/lib/lxd
