#!/usr/bin/env bash
# cord-bootstrap.sh
# Bootstraps environment and downloads CORD repos

set -e
set -x

CORDDIR=~/cord

function bootstrap() {

  if [ ! -x "/usr/bin/ansible" ]
  then
    echo "Installing Ansible..."
#     sudo apt-get update
#     sudo apt-get install -y software-properties-common
#     sudo apt-add-repository -y ppa:ansible/ansible
    sudo apt-get -y install python-dev libffi-dev python-pip libssl-dev sshpass
    pip install ansible==2.2.2.0
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

    if [ ! -e "~/.gitconfig" ]
    then
      echo "No ~/.gitconfig, setting testing defaults"
      git config --global user.name 'Test User'
      git config --global user.email 'test@null.com'
      git config --global color.ui false
    fi

    mkdir $CORDDIR && cd $CORDDIR
    repo init -u https://gerrit.opencord.org/manifest -b master -g build,onos,orchestration,voltha
    repo sync

    # check out gerrit branches using repo
    for gerrit_branch in ${GERRIT_BRANCHES[@]}; do
      echo "checking out opencord gerrit branch: $gerrit_branch"
      repo download ${gerrit_branch/:/ }
    done
  fi

  if [ ! -x "/usr/bin/docker" ]
  then
    echo "Installing Devel Tools..."
    cd ${CORDDIR}/build/platform-install
    ansible-playbook -i inventory/localhost devel-tools-playbook.yml
  fi

  set +x
  echo "*******************************************************************************"
  echo "*  IMPORTANT: Logout and login so your account is added to the docker group!  *"
  echo "*   Then 'cd ${CORDDIR}/build/platform-install' and start your CORD profile.  *"
  echo "*        Need help?  Check out the wiki at: https://wiki.opencord.org/        *"
  echo "*******************************************************************************"

}

function cleanup() {
  if [ ! -x "/usr/bin/ansible" ]
  then
    echo "Ansible not installed, can't cleanup. Is this the initial run?"
  else
    echo "Cleaning up - destroying docker containers..."
    cd ${CORDDIR}/build/platform-install
    ansible-playbook -i inventory/localhost teardown-playbook.yaml
  fi
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

# "main" function
if [[ $CLEANUP -eq 1 ]]
then
  cleanup
fi

bootstrap

if [[ $CORD_PROFILE -ne "" ]]
then
  set -x
  cord_profile
fi

exit 0
