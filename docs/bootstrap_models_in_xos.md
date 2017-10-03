# How to add a TOSCA recipe to platform-install

All the data model bootstrapping in XOS is done via TOSCA in platform install. 
There two ansible roles involved in that:
- `cord-profile` responsible to generate the recipes
- `xos-config-new-tosca` responsible for onboarding the recipes

Here is a list of changes you'll need to make in order to add a new recipe to your profiles:

## Create a new template in `cord-profile`

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

## Add the template to your profile manifest

In `platform-install/profile_manifests` locate the profile that your using and open it.

Locate a section called `xos_new_tosca_config_templates` (if it's missing create it), 
and add there the list of templates you want to be generated and onboarded, eg:
```
xos_new_tosca_config_templates:
  - site.yml
```

> NOTE: the template name is whatever you specify in this list plus `.j2`