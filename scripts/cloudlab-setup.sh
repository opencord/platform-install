#!/bin/bash

sudo apt-get update
sudo ./bootstrap_ansible.sh

# Generate SSH keys
ssh-keygen

# Add to authorized_keys
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# Add trusty-backports
sudo sed -i 's!# deb http://us.archive.ubuntu.com/ubuntu/ trusty-backports!deb http://us.archive.ubuntu.com/ubuntu/ trusty-backports!' /etc/apt/sources.list
sudo sed -i 's!# deb-src http://us.archive.ubuntu.com/ubuntu/ trusty-backports!deb-src http://us.archive.ubuntu.com/ubuntu/ trusty-backports!' /etc/apt/sources.list

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
