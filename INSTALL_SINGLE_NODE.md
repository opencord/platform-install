# Installing a CORD POD on a Single Physical Host

*A full description of how to bring up a CORD POD on a single physical host, using the CORD developer
environment, is [described here](https://github.com/opencord/cord/blob/master/docs/quickstart.md).
That's probably what you want.*

This page describes a simple alternative method for setting up a single-node POD that does not
require a separate build host running Vagrant.  It's mainly for developers looking to
set up a custom POD and run tests on it.

## What you need (Prerequisites)
You need a target server meeting the requirements below:
* Fresh install of Ubuntu 14.04 LTS with latest updates
* Minimum 12 CPU cores, 48GB RAM, 1TB disk
* Access to the Internet
* A user account with password-less *sudo* capability (e.g., the *ubuntu* user)

## Run scripts/single-node-pod.sh

The [single-node-pod.sh](scripts/single-node-pod.sh) script in the `scripts` directory
of this repository can be used to build and test a single-node CORD POD.
It should be run on the target server in a user account with password-less
*sudo* capability.  The most basic way to run the script is as follows:

```
$ wget https://raw.githubusercontent.com/opencord/platform-install/cord-1.0/scripts/single-node-pod.sh
$ bash single-node-pod.sh
```

The script will load the necessary software onto the target server, download the `master` branch of
this repository, and run an Ansible playbook to set up OpenStack, ONOS, and XOS.

Note that this process
will take at least an hour!  Also some individual steps in the playbook can take 30 minutes or more.
*Be patient!*

### Script options

Run `bash single-node-pod.sh -h` for a list of options:

```
~$ bash single-node-pod.sh -h
Usage:
    single-node-pod.sh                install OpenStack and prep XOS and ONOS VMs [default]
    single-node-pod.sh -b <branch>    checkout <branch> of the xos git repo
    single-node-pod.sh -c             cleanup from previous test
    single-node-pod.sh -d             don't run diagnostic collector
    single-node-pod.sh -h             display this help message
    single-node-pod.sh -i <inv_file>  specify an inventory file (default is inventory/single-localhost)
    single-node-pod.sh -p <git_url>   use <git_url> to obtain the platform-install git repo
    single-node-pod.sh -r <git_url>   use <git_url> to obtain the xos git repo
    single-node-pod.sh -s <branch>    checkout <branch> of the platform-install git repo
    single-node-pod.sh -t             do install, bring up cord-pod configuration, run E2E test
```

A few useful options are:

The `-s` option can be used to install different versions of the CORD POD.  For example, to install
the latest CORD v1.0 release candidate:

```
~$ bash single-node-pod.sh -s cord-1.0
```

The `-t` option runs a couple of tests on the POD after it has been built:
  - `test-vsg:` Adds a CORD subscriber to XOS, brings up a vSG for the subscriber, creates a simulated
     device in the subscriber's home (using an LXC container), and runs a `ping` from the device
     through the vSG to the Internet.  This test demonstrates that the vSG is working.
  - `test-exampleservice:` Assumes that `test-vsg` has already been run to set up a vSG.  Onboards
     the `exampleservice` described in the
     [Tutorial on Assembling and On-Boarding Services](https://wiki.opencord.org/display/CORD/Assembling+and+On-Boarding+Services%3A+A+Tutorial)
     and creates an `exampleservice` tenant in XOS.  This causes the `exampleservice` synchronizer
     to spin up a VM, install Apache in the VM, and configure Apache with a "hello world" welcome message.
     This test demonstrates a customer-facing service being added to the POD.

The `-c` option deletes all state left over from a previous install.  For example, the
[nightly Jenkins E2E test](https://jenkins.opencord.org/job/cord-single-node-pod-e2e/) runs
the script as follows:
```
~$ bash single-node-pod.sh -c -t
```
This invocation cleans up the previous build, brings up the POD, and runs the tests described above.
