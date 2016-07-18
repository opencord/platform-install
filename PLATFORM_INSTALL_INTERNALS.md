# Platform-Install Internals

## Prerequisites

When platform-install starts, it is assumed that `gradelew fetch` has already been run on the cord repo, fetching the necessary subrepositories for CORD. This includes fetching the platform-install repository.

## Configuration

Platform-install uses a configuration file, `/cord/components/platform-install/config/default.yml`, that contains several variables that will be passed to Ansible playbooks. Notable variables include the IP address of the target machine and user account information for SSHing into the target machine. There's also an extra-variable, `on-cloudlab` that will trigger additional cloudlab-specific actions to run.

## Cloudlab-specific actions

