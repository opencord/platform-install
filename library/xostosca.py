#!/usr/bin/python

import json
import os
import requests
import sys
import traceback

from ansible.module_utils.basic import AnsibleModule

def main():

    # args styled after the uri module
    module = AnsibleModule(
        argument_spec = dict(
            url       = dict(required=True, type='str'),
            recipe    = dict(required=True, type='str'),
            user      = dict(required=True, type='str'),
            password  = dict(required=True, type='str'),
        )
    )

    xos_auth=(module.params['user'], module.params['password'])

    r = requests.post(module.params['url'], data={"recipe": module.params['recipe']}, auth=xos_auth)
    if (r.status_code != 200):
        try:
            error_text=r.json()["error_text"]
        except:
            error_text="error while formatting the error: " + traceback.format_exc()
        module.fail_json(msg=error_text, rc=r.status_code)

    result = r.json()
    if "log_msgs" in result:
        module.exit_json(changed=True, msg="\n".join(result["log_msgs"])+"\n")
    else:
        module.exit_json(changed=True, msg="success")

if __name__ == '__main__':
    main()
