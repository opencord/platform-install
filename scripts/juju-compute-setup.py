#!/usr/bin/python

import subprocess
import json
import time

jujuconfig="/usr/local/src/openstack.cfg"

services = {
#    "nova-compute" : "--config=%s cs:~andybavier/trusty/nova-compute" % jujuconfig,
    "nova-compute" : "--config=%s nova-compute" % jujuconfig,
}

def get_free_machines(status):
    for (service, svcinfo) in status['services'].iteritems():
        if 'units' in svcinfo:
            for (unit, unitinfo) in svcinfo['units'].iteritems():
                if 'machine' in unitinfo:
                    machine = unitinfo['machine']
                    status['machines'][machine]['unit'] = unit

    free = {}
    for (machine, mchinfo) in status['machines'].iteritems():
        if machine == "0":
            continue

        if 'unit' not in mchinfo:
            # print "%s: %s" % (machine, mchinfo['dns-name'])
            free[machine] = mchinfo

    return free


def deploy(status, service, cmd):
    # Deploy nova-compute to all free machines
    machines = get_free_machines(status)

    for (machine, mchinfo) in machines.iteritems():
        if service in status['services']:
            print "Adding unit %s on %s" % (service, mchinfo['dns-name'])
            subprocess.check_call("juju add-unit --to=%s %s" % (machine, service), shell=True)
        else:
            print "Deploying service %s on %s" % (service, mchinfo['dns-name'])
            subprocess.check_call("juju deploy --to=%s %s" % (machine, cmd), shell=True)
            status['services'][service] = "installed"
            time.sleep(10)

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

def main():
    addservices()

if  __name__ =='__main__':
    main()
