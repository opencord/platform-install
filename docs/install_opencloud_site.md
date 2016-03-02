## Introduction

The following steps are required in order to bring up a new OpenCloud sites.

1. Allocate servers

2. Install Uubuntu

3. Install OpenStack controller & compute nodes

4. Add site’s OpenStack controller to xos

## Allocate Servers

**It may happen that for different reasons that few servers are offline. **Allocating servers involves finding those nodes that are offline and bringing them back online. In most cases just rebooting the nodes will bring them back online. Sometimes they may be offline for hardware malfunctions or maintenance. In that case someone would need to provide help, locally from the facility.

NOffline nodes can be rebooted either manually (accessing through ssh to the node) or remotely, using an via ipmi script , usually called using the ipmi-cmd.sh script and located on some machines(usually found at /root/ipmi-cmd.sh). Reference at the section "Rebooting machines remotely" for more info.

Note: For example, for the Stanford cluster, the script should be located I’ve installed the ipmi-cmd.sh on node4.stanford.vicci.org. You should be able to reboot nodes from there.

## Install Ubuntu

Opencloud nodes are expected to be Ubuntu 14.x.

Please note that  Ubuntu nodes that are already configured for other OopenCcloud environments (i.e. portal) needs to must be re-installed, even if already running Ubuntu with Ubunutu. At Stanford, every node that is not reserved must be re-installed.

The provisioning of the nodes and their setup (including installing a fresh Ubuntu 14) is done through the Vicci portal. In order to perform such steps, it’s required to have an administrative account on vicci.org. In case you don’t have it, please register on www.vicci.org and wait for the approval.

Below, the main steps needed to install Ubuntu on the cluster machines are reported:

1. After loggin in, on [www.vicci.org](http://www.vicci.org/)

* Change the node’s deployment tag to "ansible_ubuntu_14"

* Set the node’s boot_state to ‘reinstall’

2. Reboot the node

* Manually logging into the remote node (see "accessing the machines", below)

* Through the IPMI script (see "Rebooting machines remotely", below)

After reboot, the machine should go through the Ubuntu installation automatically. At the end of the process, the ones registered as administrators should be notified of the successfully installation. If you’re not an official opencloud.us administrator, just try to log into the machines again after 20-30 mins form the reboot.

3. Update Ubuntu

```
sudo apt-get update
sudo apt-get dist-upgrade
```


**Install Openstack**

Ansible is a software that enables easy centralized configuration and management of a set of machines.

In the context of OpenCloud, it is used to setup the remote clusters machines.

The following steps are needed in order to install Openstack on the clusters machines. 

They The following tasks can be performed from whatever node,  able to access the deployment machines. The deployment Vicci root ssh key is required in order to perform the ansible tasks described in this section. 

1. From a computer able to ssh into the machines:

* Clone the openstack-cluster-setup git repo

*$ git clone **[https://github.com/open-cloud/openstack-cluster-setu*p](https://github.com/open-cloud/openstack-cluster-setup)

The format of the file is the following:

head ansible_ssh_host=headNodeAddress

[compute]

compute01Address

compute02Address

….

* Edit the site-specific hosts file and specify the controller (head) & compute nodes. 

	*$ cd openstack-cluster-setup && vi SITENAME-hosts*

* Setup the controller (head) node by executing the site-specific playbook:

*$ **ansible-playbook -i SITENAME-hosts SITENAME-setup.yml*

*NOTE: The file SITENAME-setup.yml should be created separately or copied over from  *

*another SITENAME-setup.yml file*

**IMPORTANT NOTE:** When the head node is configured by the script, one or more routes are added for each compute node specified in the configuration file. This is needed in order to let the head node and the compute nodes correctly communicate together. Forgetting to insert all the compute nodes, may cause undesired behaviors. If a compute node was forgotten, it’s suggested to repeat the procedure, after correcting the configuration in the config file.

For the same reason, the procedure should be repeated** **whenever we want to add new compute nodes to the cluster. 

2. Log into the head node and for each compute node run

* *$ **juju add-machine ssh:COMPUTE_NODE_ADDRESSnodeXX.stanford.vicci.org*

As stated earlier, before you run 'juju add-machine' for any compute nodes, you need to add them to SITENAME-hosts and re-run SITENAME-setup.yml.  If you don't want to wait through the whole thing you can start at the right step as follows:

    $ ansible-playbook -i SITENAME-hosts SITENAME-setup.yml --start-at-task="Get public key"

5. On your workstation, setup the compute node by executing the site-specific playbook    

    $ ansible-playbook -i SITENAME-hosts SITENAME-compute.yml

**Update XOS**

Now that we have a controller and some compute nodes, we need to add the controller’s information to xos so that it can be access by the synchronizer/observer. 

1. Update the site’s controller record. Stanford’s controller record can be found at:

[http://alpha.opencloud.us/admin/core/controller/18/](http://alpha.opencloud.us/admin/core/controller/18/)

The information that needs to be entered here can be found in /home/ubuntu/admin-openrc.sh on the site’s controller (head) node. 

2. Add the controller to the site:[http://alpha.opencloud.us/admin/core/site/17/#admin-only](http://alpha.opencloud.us/admin/core/site/17/#admin-only)

(tenant_id is showing up in the form even though it is not required here. Just add any string there for now)

3. Add compute nodes to the site:[http://alpha.opencloud.us/admin/core/site/17/#nodes](http://alpha.opencloud.us/admin/core/site/17/#nodes)

4. Add Iptables rules in xos synchronizer host vm so that the synchronizer can access the site’s management network

# Princeton VICCI cluster: head is[ node70.princeton.vicci.org](http://node70.princeton.vicci.org/) (128.112.171.158)

iptables -t nat -A OUTPUT -p tcp -d 192.168.100.0/24 -j DNAT --to-destination 128.112.171.158

# if running synchronizer inside of a container

iptables -t nat -A PREROUTING -p tcp -d 192.168.100.0/24 -j DNAT --to-destination 128.112.171.158

5. Update the firewall rules on the cluster head nodes to accept connections from the xos synchronizer vm

6. Copy the certificates from the cluster head nodes and put them in `/usr/local/share/ca-certificates` on the xos synchronizer vm.  Then re-run `update-ca-certificates` inside the synchronizer container.

Accessing the machines

Accessing new Ubuntu machines is pretty straight forward. The default user is ubuntu. No password is required and the key used to authenticate is the official deployment root key, that one of the administrator should have given to you separately.

So, in order to access to a fresh new Ubuntu node, just type:

ssh -i /path/to/the/root/key ubuntu@ip_of_the_machine

Sometime, it may happen that you need to access to already existing nodes. These nodes may either run an Ubuntu or a Fedora. Knowing what node runs what may be tricky and the only way to discover it would be trying to access to it. While the key to get inside still remains the deployment root key (as described above), the username may vary between Ubuntu and Fedora machines. Contrarily to Ubuntu, the default Fedora username is root.

So, in order to access to a one of the Fedora machines, you would type:

ssh -i /path/to/the/root/key root@ip_of_the_machine

Rebooting machines remotely

Machines can be rebooted remotely through an ipmi script, usually located on specific machines of the clusters under /root. The script is named ipmi-cmd.sh.

In the following example, node44.stanford.vicci.org is rebootd:

$ /root/ipmi-cmd.sh 44 'power cycle'

