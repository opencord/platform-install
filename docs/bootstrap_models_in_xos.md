# TOSCA Development

TOSCA is typically used to provision the services loaded into CORD as part of
some profile. This is a two-step process: (1) during the build stage, TOSCA
templates are rendered using variables set in the `podconfig`, `scenario`, and
`default` roles into fully qualified TOSCA recipes, and (2) as the last step of
the deploy stage, these TOSCA recipes are onboarded into XOS (which provisions
the service profile accordingly). These two steps are implemented by a pair of
Ansible roles:

* `cord-profile` responsible for generating the TOSCA recipes from templates
* `xos-config` responsible for onboarding the TOSCA recipes into XOS

The following describes how to create a new TOSCA template and make it
available to provision CORD. This is done in the context of the profile you
want to provision, where profiles are defined in
`orchestration/profiles/<profilename>`.

## Create a New Template

You can create as many templates as needed for your profile in directory
`orchestration/profiles/<profilename>/templates`.  There are also some
platform-wide TOSCA templates defined in
`/platform-install/roles/cord-profile/templates` but these are typically not
modified on a profile-by-profile basis.

These templates use the [jinja2
syntax](http://jinja.pocoo.org/docs/latest/templates/), so for example, a basic
template might be `site.yml.j2`:

```yaml
tosca_definitions_version: tosca_simple_yaml_1_0

description: created by platform-install, need to add M-CORD services later

imports:
   - custom_types/xos.yaml

topology_template:
  node_templates:
    {{ site_name }}:
      type: tosca.nodes.Site
```

Your templates can use all the variables defined in the [build
glossary](../build_glossary.md).

## Add the Template to your Profile Manifest

Locate and open the profile manifest you want to affect:
`orchestration/profiles/<profilename>/<profilename>.yml`.

Locate a section called `xos_tosca_config_templates` (if it's missing create
it), and add there the list of templates you want to be generated and
onboarded; for example:

```yaml
xos_tosca_config_templates:
  - site.yml
```

> NOTE: the template name is whatever you specify in this list plus `.j2`
