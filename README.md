# openstack-cluster-setup
This repository contains [Ansible](http://docs.ansible.com) playbooks for installing and configuring an OpenStack Kilo cluster
for use with XOS. This is how we build clusters for [OpenCloud](http://opencloud.us), and is the method of
installing a [CORD](http://cord.onosproject.org) development POD as well.

All of the OpenStack controller services are installed in VMs on a
single "head node" and connected by an isolated private network. [Juju](http://www.ubuntu.com/cloud/tools/juju) is used
to install and configure the OpenStack services.

## Prerequisites (OpenCloud and CORD)

* *Set up control machine:* The install playbooks in this repository can either run on a
  separate control machine (e.g., a laptop) or on the cluster head node.  Either way:
  * Install a recent version of Ansible (Ansible 1.9.x on Mac OS X or Ubuntu should work).
  * Be able to login to all of the cluster servers from the control machine using SSH.
* *Set up servers:* One server in the cluster will be the "head" node, running the OpenStack
  services.  The rest will be "compute" nodes.  
 * Install Ubuntu 14.04 LTS on all servers.
 * The user account used to login from the control machine must have *sudo* access.
 * Each server should have a single active NIC (preferably eth0) with connectivity to the
   Internet.

## How to install a CORD POD

The CORD POD install procedure uses the "head node" of the cluster as the control machine
for the install.  As mentioned above, install Ansible on the head node and check out this repository.

The playbooks assume that a bridge called *mgmtbr* on the head node is connected to the management
network.  Also there must be a DHCP server on the management network to hand out IP addresses
to VMs; if you need to set up `dnsmasq` to do this, take a look at [this example](files/etc/dnsmasq.d/cord).
Then follow these steps:

* Edit *cord-hosts* with the DNS names of your compute nodes, and update the *ansible_ssh_user* variable appropriately.
  Before proceeding any farther, this needs to work: `ansible -i cord-hosts compute -m ping`
* Run: `ansible-playbook -i cord-hosts cord-setup.yml`
* After the playbook finishes, wait for the OpenStack services to come up.  You can check on their progress
  using `juju status --format=tabular`
* Once the services are up, you can use the `admin-openrc.sh` credentials in the home directory to 
  interact with OpenStack.  You can SSH to any VM using `ssh ubuntu@<vm-name>`

This will bring up various OpenStack services, including Neutron with the VTN plugin.  It will also create
two VMs called *xos* and *onos-cord* and prep them. Configuring and running XOS and ONOS in these VMs is beyond
the scope of this README.

## How to install an OpenCloud cluster

Once the prerequisites are satisfied, here are the basic steps for installing a new OpenCloud cluster named 'foo':

* Create *foo-setup.yml* and *foo-compute.yml* files using *cloudlab-setup.yml* and *cloudlab-compute.yml* as templates.  Create a *foo-hosts* file with the DNS names of your nodes based on *cloudlab-hosts*.
* If you are **not** installing on CloudLab, edit *foo-hosts* and add *cloudlab=False*
under *[all:vars]*.  
* If you are installing a cluster for inclusion in the **public OpenCloud**, change *mgmt_net_prefix* in *foo-setup.yml* to be unique across all OpenCloud clusters.
* To set up Juju, use it to install the OpenStack services on the head node, and prep the compute nodes, run on the head node:
```
$ ansible-playbook -i foo-hosts foo-setup.yaml
```
* Log into the head node.  For each compute node, put it under control of Juju, e.g.:
```
$ juju add-machine ssh:ubuntu@compute-node
```
* To install the *nova-compute* service on the compute nodes that were added to Juju, run on the control machine:
```
$ ansible-playbook -i foo-hosts foo-compute.yaml
```

### Things to note

* The installation configures port forwarding so that the OpenStack services can be accessed from outside the private network. Some OpenCloud-specific firewalling is also introduced, which will likely require modification for other setups.  See: [files/etc/libvirt/hooks/qemu](https://github.com/andybavier/opencloud-cluster-setup/blob/master/files/etc/libvirt/hooks/qemu).
* By default the compute nodes are controlled and updated automatically using *ansible-pull* from [this repo](https://github.com/andybavier/opencloud-nova-compute-ansible).  You may want to change this.
* All of the service interfaces are configured to use SSL because that's what OpenCloud uses in production.  To turn this off, look for the relevant Juju commands in *cloudlab-setup.yaml*.
