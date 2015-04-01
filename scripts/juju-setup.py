#!/usr/bin/python

import subprocess
import json
import socket

jujuconfig="openstack.cfg"

# Assumption: VMs have same hostname as service that runs inside
machines = ["mysql", "rabbitmq-server", "keystone", "glance", "nova-cloud-controller",
            "quantum-gateway", "openstack-dashboard", "ceilometer", "nagios"]

services = {
    "mysql" : "mysql",
    "rabbitmq-server" : "rabbitmq-server",
    "keystone" : "--config=%s keystone" % jujuconfig,
    "glance" : "--config=%s glance" % jujuconfig,
    "nova-cloud-controller" : "--config=%s cs:~andybavier/trusty/nova-cloud-controller" % jujuconfig,
    "quantum-gateway" : "--config=%s cs:~andybavier/trusty/quantum-gateway" % jujuconfig,
    "openstack-dashboard" : "--config=%s openstack-dashboard" % jujuconfig,
    "nagios" : "nagios",
    "mongodb" : "mongodb",   # deploy to ceilometer machine
    "ceilometer" : "ceilometer",
    "nrpe" : "nrpe",
    "ntp" : "ntp",
    "ceilometer-agent" : "ceilometer-agent"
}

# Figure out Juju ID of machine we should install on
def get_machine(status, service):
    if service == "mongodb":
        service = "ceilometer"
    for key, value in status['machines'].iteritems():
        (hostname, aliaslist, ipaddrlist) = socket.gethostbyaddr(value['dns-name'])
        if hostname == service:
            return key
    return None

def deploy(status, service, cmd):
    if service in status['services']:
        return

    print "Installing %s" % service
    machine = get_machine(status, service)
    if machine:
        subprocess.check_call("juju deploy --to=%s %s" % (machine, cmd), shell=True)
    else:
        subprocess.check_call("juju deploy %s" % cmd, shell=True)

def get_juju_status():
    output = subprocess.check_output("juju status --format=json", shell=True)
    status = json.loads(output)
    return status

def addservices():
    status = get_juju_status()

    for service, cmd in services.iteritems():
        try:
            deploy(status, service, cmd)
        except:
            pass

def addmachines():
    status = get_juju_status()

    for machine in machines:
        if get_machine(status, machine) == None:
            ipaddr = socket.gethostbyname(machine)
            subprocess.check_call("juju add-machine ssh:%s" % ipaddr, shell=True)

def main():
    addmachines()
    addservices()

if  __name__ =='__main__':
    main()
