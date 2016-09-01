# platform-install

This repository contains [Ansible](http://docs.ansible.com) playbooks for
installing and configuring software components on a CORD POD: OpenStack, ONOS,
and XOS.  It is a sub-module of the [main CORD
repository](https://github.com/opencord/cord).

To install a single-node CORD POD, read
[INSTALL_SINGLE_NODE.md](./INSTALL_SINGLE_NODE.md).

Otherwise you should start with the [CORD
repository](https://github.com/opencord/cord).

# Lint checking your code

Before commit, please run `scripts/lintcheck.sh`, which will perform the same
lint check that Jenkins performs when in review in Gerrit.

