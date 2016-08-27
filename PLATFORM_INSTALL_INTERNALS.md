# Platform-Install Internals

This repository consists of some Ansible playbooks that deploy and configure OpenStack,
ONOS, and XOS in a CORD POD, as well as some Gradle "glue" to invoke these playbooks
during the process of building a [single-node POD](https://wiki.opencord.org/display/CORD/Build+CORD-in-a-Box)
and a [multi-node POD](https://wiki.opencord.org/display/CORD/Build+a+CORD+POD).

## Prerequisites

When platform-install starts, it is assumed that `gradlew fetch` has already been run on the cord repo, fetching the necessary sub-repositories for CORD. This includes fetching the platform-install repository.

For the purposes of this document, paths are relative to the root of the platform-install repo unless specified otherwise. When starting from the uber-cord repo, platform-install is usually located at `/cord/components/platform-install`.

## Configuration

Platform-install uses a configuration file, `config/default.yml`, that contains several variables that will be passed to Ansible playbooks. Notable variables include the IP address of the target machine and user account information for SSHing into the target machine. There's also an extra-variable, `on-cloudlab` that will trigger additional cloudlab-specific actions to run.

Cloudlab nodes boot with small disk partitions setup, and most of the disk space unallocated. Setting the variable `on-cloudlab` in `config/default.yml` to true will cause actions to be run that will allocate this unallocated space.

## Gradle Scripts

The main gradle script is located in `build.gradle`.

`build.gradle` includes two notable tasks, `deployPlatform` and `deploySingle`. These are for multi-node and single-node pod installs and end up executing the Ansible playbooks `cord-head-playbook.yml` and `cord-single-playbook.yml` respectively.

## Ansible Playbooks

Platform-install makes extensive use of Ansible Roles, and the roles are selected via two playbooks: `cord-head-playbook.yml` and `cord-single-playbook.yml`.

They key differences are that:
* The single-node playbook sets up a simulated fabric, whereas the multi-node install uses a real fabric.
* The single-node playbook sets up a single compute node running in a VM, whereas the multi-node playbook uses maas to provision compute nodes.
* The single-node playbook installs a DNS server. The multi-node playbook only installs a DNS Server when maas is not used.

## Ansible Roles and Variables

Ansible roles are located in the `roles` directory.

Ansible variables are located in the `vars` directory.

### DNS-server and Apt Cache

The first step in bringing up the platform is to setup a DNS server. This is done for the single-node install, and for the multi-node install if maas is not used. An apt cache is setup to facilitate package installation in the many VMs that will be setup as part of the platform. Roles executed include:

* dns-nsd
* dns-unbound
* apt-cacher-ng

### Pointing to the DNS server

Assuming a DNS server was setup in the previous step, then the next step is to point the head node to use that DNS server. Roles executed include:

* dns-configure

### Prep system

The next step is to prepare the system. This includes such tasks as installing default packages (tmux, vim, etc), configuring editors, etc. Roles executed include:

* common-prep

### Configuring the head node and setting up VMs

Next the head node is configured and VMs are created to host the OpenStack and XOS services. Roles executed include:

* head-prep
* config-virt
* create-vms

### Set up VMs, juju, simulate fabric

Finally, we install the appropriate software in the VMs. This is a large, time consuming step since it includes launching the OpenStack services (using juju), launching ONOS, and launching XOS (using service-platform). Roles executed include:

* xos-vm-install
* onos-vm-install
* test-client-install
* juju-setup
* docker-compose
* simulate-fabric
* onos-load-apps
* xos-start

Juju is leveraged to perform the OpenStack portion of the install. Cord specific juju charm changes are documented in [Internals of the CORD Build Process](https://wiki.opencord.org/display/CORD/Internals+of+the+CORD+Build+Process).

## Starting XOS

The final ansible role executed by platform-install is to start XOS. This uses the XOS `service-profile` repository to bring up a stack of CORD services.

For a discussion of how the XOS service-profile system works, please see [Dynamic On-boarding System and Service Profiles](https://wiki.opencord.org/display/CORD/Dynamic+On-boarding+System+and+Service+Profiles).

## Helpful log files and diagnostic information

The xos-build and xos-onboard steps run ansible playbooks to setup the xos virtual machine. The output of these playbooks is stored (inside the `xos-1` VM) in the files `service-profile/cord-pod/xos-build.out` and `service-profile/cord-pod/xos-onboard.out` respectively.
