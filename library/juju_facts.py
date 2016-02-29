#!/usr/bin/python

import json
import subprocess

def dict_keys_dash_to_underscore(dashed):
    underscored = dict((k.replace('-','_'),v) for k,v in dashed.items())
    return underscored

juju_status_json = subprocess.check_output("juju status --format=json", shell=True)
juju_status = json.loads(juju_status_json)

juju_machines = {}
for index, data in juju_status['machines'].iteritems():
    data_underscore = dict_keys_dash_to_underscore(data)
    juju_machines[data_underscore["dns_name"]] = data_underscore

juju_services = {}
for index, data in juju_status['services'].iteritems():
    data_underscore = dict_keys_dash_to_underscore(data)
    juju_services[data_underscore["dns-name"]] = data_underscore

print json.dumps({
    "changed": True,
    "ansible_facts" : {
        "juju_enviromnment": juju_status['environment'],
        "juju_machines": juju_machines,
        "juju_services": juju_services,
    },
})

