#!/usr/bin/env bash
# cord-bootstrap.sh
# Bootstraps an environment and downloads CORD repos

set -e

echo "Installing Ansible..."
apt-get install -y software-properties-common
apt-add-repository ppa:ansible/ansible
apt-get update
apt-get install -y ansible

echo "Cloning platform-install..."
git clone https://gerrit.opencord.org/p/platform-install.git ~/platform-install

cd ~/platform-install

echo "Downloading CORD/XOS and installing Docker..."
ansible -i inventory/localhost cord-bootstrap-playbook.yaml

echo "You may want to logout/login so your user account gains the docker group"

