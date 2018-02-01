# TOSCA Development

TOSCA is typically used to provision the services loaded into
CORD. This is a two-step process: (1) during the build stage,
TOSCA templates are translated into fully qualified TOSCA recipes,
and (2) as the last step of the deploy stage, these TOSCA recipes
are onboarded into XOS (which provisions the services accordingly).
These two steps are implemented by a pair of Ansible roles:

- `cord-profile` responsible for generating the TOSCA recipes from templates
- `xos-config` responsible for onboarding the TOSCA recipes into XOS

The following describes how to create a new TOSCA template and make it
available to provision CORD.

## Create a New Template

You can create as many templates as needed under `/platform-install/roles/cord-profile/templates`. 
These are ansible templates, and they use the `jinja2` syntax. 

For example a basic template can be `site.yml.j2`:

```
tosca_definitions_version: tosca_simple_yaml_1_0

description: created by platform-install, need to add M-CORD services later

imports:
   - custom_types/xos.yaml

topology_template:
  node_templates:
    {{ site_name }}:
      type: tosca.nodes.Site
```

You can use here all the variables defined in the [build glossary](../build_glossary.md).

## Add the Template to your Profile Manifest

In `platform-install/profile_manifests` locate the profile that you
are using and open it.

Locate a section called `xos_tosca_config_templates` (if it's missing create it), 
and add there the list of templates you want to be generated and onboarded, eg:
```
xos_tosca_config_templates:
  - site.yml
```

> NOTE: the template name is whatever you specify in this list plus `.j2`
