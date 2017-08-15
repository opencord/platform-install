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

import sys
import json
import shlex
import subprocess

# Assume nothing has changed
result = {
    "changed" : False,
    "everyone" : "OK"
}

# read the argument string from the arguments file
args_file = sys.argv[1]
args_data = file(args_file).read()

# Variables for the task options
host_list = []
command_on_fail = None

# parse the task options
arguments = shlex.split(args_data)

for arg in arguments:
    # ignore any arguments without an equals in it
    if "=" in arg:
        (key, value) = arg.split("=")

    if key == "hosts":
        # The list of hosts comes as a string that looks sort of like a python list,
        # so some replace magic so we can parse it in to a real list
        try:
            value = value.replace("u'", "").replace("'", "")
            value = json.loads(value)
            host_list = value
        except Exception as e:
            result["everyone"] = "Not OK"
            result["failed"] = True
            result["msg"] = "Unable to parse 'hosts' argument to module : '%s'" % (e)
            print json.dumps(result)
            sys.stdout.flush()
            sys.exit(1)
    if key == "command_on_fail":
        command_on_fail = value

for host in  host_list:
    # Attempt to resolve hostname, if a host can't be resolved then fail the task
    try:
        if subprocess.check_output(["dig", "+short", "+search", host]) == '':
            result["everyone"] = "Not OK"
            result["failed"] = True
            result["msg"] = "Unable to resolve host '%s'" % (host)
    except Exception as e:
        result["everyone"] = "Not OK"
        result["failed"] = True
        result["msg"] = "Error encountered while resolving '%s' : '%s'" % (host, e)
        print json.dumps(result)
        sys.stdout.flush()
        sys.exit(1)

# If not all hosts were resolved and a failure command was specified then call that
# command and capture the results.
if command_on_fail != None:
    result["command_on_fail"] = {}
    result["command_on_fail"]["command"] = command_on_fail
    try:
        cmd_out = subprocess.check_output(shlex.split(command_on_fail), stderr=subprocess.STDOUT)
        result["command_on_fail"]["retcode"] = 0
        result["command_on_fail"]["out"] = cmd_out
    except subprocess.CalledProcessError as e:
        result["command_on_fail"]["retcode"] = e.returncode
        result["command_on_fail"]["out"] = e.output

# Output the results
print json.dumps(result)

if result["failed"]:
    sys.exit(1)
