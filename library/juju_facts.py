#!/usr/bin/env python

# Copyright 2017-present Open Networking Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import json
import subprocess
import sys

def dict_keys_dash_to_underscore(dashed):
    underscored = dict((k.replace('-','_'),v) for k,v in dashed.items())
    return underscored

try:
    juju_status_json = subprocess.check_output("juju status --format=json", shell=True)
    juju_status = json.loads(juju_status_json)
except:
    print json.dumps({
            "failed" : True,
            "msg"    : "'juju status' command failed"
            })
    sys.exit(1)

juju_machines = {}
for index, data in juju_status['machines'].iteritems():
    data_underscore = dict_keys_dash_to_underscore(data)
    juju_machines[data_underscore["dns_name"]] = data_underscore
    juju_machines[data_underscore["dns_name"]]["machine_id"] = index

juju_compute_nodes = {}
if 'nova-compute' in juju_status['services']:
    for name, data in juju_status['services']['nova-compute']['units'].iteritems():
        juju_compute_nodes[data['public-address']] = data

print json.dumps({
    "changed": True,
    "ansible_facts" : {
        "juju_environment": juju_status['environment'],
        "juju_machines": juju_machines,
        "juju_services": juju_status['services'],
        "juju_compute_nodes": juju_compute_nodes,
    },
})

