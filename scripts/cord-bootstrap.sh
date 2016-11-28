#!/usr/bin/env bash
# cord-bootstrap.sh
# Bootstraps an environment and downloads CORD repos

set -e

echo "Installing Ansible..."
sudo apt-get update
sudo apt-get install -y software-properties-common
sudo apt-add-repository -y ppa:ansible/ansible
sudo apt-get update
sudo apt-get install -y ansible python-netaddr

echo "Cloning platform-install..."
git clone https://gerrit.opencord.org/p/platform-install.git ~/platform-install

cd ~/platform-install

echo "Downloading CORD/XOS and installing Docker..."
ansible-playbook -i inventory/localhost cord-bootstrap-playbook.yaml

echo "You may want to logout/login so your user account gains the docker group"

