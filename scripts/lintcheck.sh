
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


#!/usr/bin/env bash
set +e
fail_ansible=0

# verify that we have ansible-lint installed
command -v ansible-lint  >/dev/null 2>&1 || { echo "ansible-lint not found, please install it" >&2; exit 1; }

# when not running under Jenkins, use current dir as workspace
WORKSPACE=${WORKSPACE:-.}

echo "=> Linting Ansible Code with" `ansible-lint --version`
for f in `find $WORKSPACE -name "*.yml"`; do
    echo "==> CHECKING: $f"
    ansible-lint -p $f
    rc=$?
    if [[ $rc != 0 ]]; then
        echo "==> LINTING FAIL: $f"
        fail_ansible=1
    fi
done

exit 0
