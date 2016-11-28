#!/usr/bin/env bash
# cord-bootstrap.sh
# Bootstraps environment and downloads CORD repos

set -e
set -x

CORDDIR=~/opencord

function bootstrap() {

  if [ ! -x "/usr/bin/ansible" ]
  then
    echo "Installing Ansible..."
    sudo apt-get update
    sudo apt-get install -y software-properties-common
    sudo apt-add-repository -y ppa:ansible/ansible
    sudo apt-get update
    sudo apt-get install -y ansible python-netaddr
  fi

  if [ ! -x "/usr/local/bin/repo" ]
  then
    echo "Installing repo..."
    REPO_SHA256SUM="e147f0392686c40cfd7d5e6f332c6ee74c4eab4d24e2694b3b0a0c037bf51dc5"
    curl -o /tmp/repo https://storage.googleapis.com/git-repo-downloads/repo
    echo "$REPO_SHA256SUM  /tmp/repo" | sha256sum -c -
    sudo mv /tmp/repo /usr/local/bin/repo
    sudo chmod a+x /usr/local/bin/repo
  fi

  if [ ! -d "$CORDDIR" ]
  then
    echo "Downloading CORD/XOS..."
    mkdir $CORDDIR && cd $CORDDIR
    git config --global user.name 'Test User'
    git config --global user.email 'test@null.com'
    git config --global color.ui false

    repo init -u https://gerrit.opencord.org/manifest -b master -g build,onos,orchestration
    repo sync

    # check out gerrit branches using repo
    for gerrit_branch in ${GERRIT_BRANCHES[@]}; do
      echo "checking out opencord gerrit branch: $gerrit_branch"
      repo download ${gerrit_branch/:/ }
    done
  fi

  if [ ! -x "/usr/bin/docker" ]
  then
    echo "Installing Docker..."
    cd ${CORDDIR}/build/platform-install
    ansible-playbook -i inventory/localhost cord-bootstrap-playbook.yaml
  fi

  echo "IMPORTANT: Logout and login again so your user account gains the docker group!"
  echo "Then 'cd ${CORDDIR}/build/platform-install' and start your CORD profile."
}

function cleanup() {
  echo "Cleanup: remains to be implemented..."
}

function cord_profile() {
  echo "Running a profile is broken due to docker group membership issue"
}

# options that may be set by getopt
GERRIT_BRANCHES=
CLEANUP=0
CORD_PROFILE=""

while getopts "b:hcp:" opt; do
  case ${opt} in
    b ) GERRIT_BRANCHES+=("$OPTARG")
      ;;
    c ) CLEANUP=1
      ;;
    h ) echo "Usage:"
      echo "    $0                prep system to run a CORD profile"
      echo "    $0 -b <project:changeset/revision>  checkout a changesets from gerrit. Can"
      echo "                      be used multiple times."
      echo "    $0 -c             cleanup from previous test"
      echo "    $0 -p <profile>   prep then start running the specified profile"
      echo "    $0 -h             display this help message"
      exit 0
      ;;
    p ) CORD_PROFILE=$OPTARG
      ;;
    \? ) echo "Invalid option: -$OPTARG"
      exit 1
      ;;
  esac
done

# What to do
if [[ $CLEANUP -eq 1 ]]
then
  cleanup_from_previous_test
fi

bootstrap

if [[ $CORD_PROFILE -ne "" ]]
then
  cord_profile
fi

exit 0
