#!/usr/bin/python

import subprocess
import json
import socket

# Assumption: VMs have same hostname as service that runs inside
machines = ["mysql", "rabbitmq-server", "keystone", "glance", "nova-cloud-controller",
            "neutron-gateway", "openstack-dashboard", "ceilometer", "nagios", "neutron-api"]


# Figure out Juju ID of machine we should install on
def get_machine(status, service):
    if service == "mongodb":
        service = "ceilometer"
    for key, value in status['machines'].iteritems():
        (hostname, aliaslist, ipaddrlist) = socket.gethostbyaddr(value['dns-name'])
        if hostname == service:
            return key
    return None

def get_juju_status():
    output = subprocess.check_output("juju status --format=json", shell=True)
    status = json.loads(output)
    return status

def addmachines():
    status = get_juju_status()

    for machine in machines:
        if get_machine(status, machine) == None:
            ipaddr = socket.gethostbyname(machine)
            subprocess.check_call("juju add-machine ssh:%s" % ipaddr, shell=True)

def main():
    addmachines()

if  __name__ =='__main__':
    main()
