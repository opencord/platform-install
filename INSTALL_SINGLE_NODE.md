# Installing a CORD POD on a Single Physical Host
[*This description is for bringing up a CORD POD on virtual machines on a single physical host. The purpose
of this solution is to enable those interested in understanding how CORD works to examine and interact with a running CORD environment.*]

This tutorial walks you through the steps to bring up a CORD "POD" on a single server using multiple virtual machines.

## What you need (Prerequisites)
You will need a build machine (can be your developer laptop) and a target server.

Build host:
* Mac OS X, Linux, or Windows with a 64-bit OS
* [`git`](https://git-scm.com/) (2.5.4 or later)
* [`Vagrant`](https://www.vagrantup.com/) (1.8.1 or later)
* Access to the Internet
* SSH access to the target server

Target server:
* Fresh install of Ubuntu 14.04 LTS with latest updates
* Minimum 12 CPU cores, 48GB RAM, 1TB disk
* Access to the Internet
* Account used to SSH from build host has password-less *sudo* capability

### Running on CloudLab (optional)
If you do not have a target server available, you can borrow one on
[CloudLab](https://www.cloudlab.us).  Sign up for an account using your organization's
email address and choose "Join Existing Project"; for "Project Name" enter `cord-testdrive`.

[*Note: CloudLab is supporting CORD as a courtesy.  It is expected that you will
not use CloudLab resources for purposes other than evaluating CORD.  If, after a
week or two, you wish to continue using CloudLab to experiment with or develop CORD,
then you must apply for your own separate CloudLab project.*]

Once your account is approved, start an experiment using the `OnePC-Ubuntu14.04.4` profile
on either the Wisconsin or Clemson cluster.  This will provide you with a temporary target server
meeting the above requirements.

Refer to the [CloudLab documentation](https://docs.cloudlab.us) for more information.

## Bring up the developer environment
On the build host, clone the
[`platform-install`](https://gerrit.opencord.org/platform-install) repository
anonymously and switch into its top directory:

```
git clone https://gerrit.opencord.org/platform-install
cd platform-install
```

Bring up the development Vagrant box.  This will take a few minutes, depending on your
connection speed:

```
vagrant up
```

Login to the Vagrant box:

```
vagrant ssh
```

Switch to the `platform-install` directory.

```
cd /platform-install
```

## Prepare the configuration file

Edit the configuration file `config/default.yml`.  Add the IP address of your target
server as well as the username / password for accessing the server.  

If your target server is a CloudLab machine, uncomment the following two lines in the
configuration file:

```
#extraVars:
#  - 'on_cloudlab=True'
```

## Deploy the single-node CORD POD on the target server

Deploy the CORD software to the the target server and configure it to form a running POD.

```
./gradlew deploySingle
```
> *What this does:*
>
> This command uses an Ansible playbook (cord-single-playbook.yml) to install
> OpenStack services, ONOS, and XOS in VMs on the target server.  It also brings up
> a compute node as a VM.
>
> (You *could* also run the above Ansible playbook directly, but Gradle is the
> top-level build tool of CORD and so we use it here for consistency.)

Note that this step usually takes *at least an hour* to complete.  Be patient!

Once the above step completes, you can log into XOS as follows:

* URL: `http://<target-server>/`
* Username: `padmin@vicci.org`
* Password: `letmein`

[*STILL TO DO*]:
* Port forwarding for XOS login as described above
* Add pointer to where to go next.  At this point the services are all in place, but the vSG has not been created yet.
