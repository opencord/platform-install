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
