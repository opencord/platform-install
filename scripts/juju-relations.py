#!/usr/bin/python

import subprocess
import time
import argparse

sleep_interval = 1

relations = ["keystone mysql",
             "nova-cloud-controller mysql",
             "nova-cloud-controller rabbitmq-server",
             "nova-cloud-controller glance",
             "nova-cloud-controller keystone",
             "glance mysql",
             "glance keystone",
             "neutron-gateway neutron-api",
             "neutron-gateway:amqp rabbitmq-server:amqp",
             "neutron-gateway nova-cloud-controller",
             "neutron-gateway mysql",
             "neutron-api keystone",
             "neutron-api neutron-openvswitch",
             "neutron-api mysql",
             "neutron-api rabbitmq-server",
             "neutron-api nova-cloud-controller",
             "neutron-openvswitch rabbitmq-server",
             "openstack-dashboard keystone",
             "ntp nova-cloud-controller",
             "mysql nagios",
             "rabbitmq-server nagios",
             "keystone nagios",
             "glance nagios",
             "nova-cloud-controller nagios",
             "neutron-gateway nagios",
             "openstack-dashboard nagios",
             "nagios nrpe",
             "mysql nrpe",
             "rabbitmq-server nrpe",
             "keystone nrpe",
             "glance nrpe",
             "nova-cloud-controller nrpe",
             "neutron-gateway nrpe",
             "openstack-dashboard nrpe",
             "ceilometer mongodb",
             "ceilometer rabbitmq-server",
             "ceilometer:identity-service keystone:identity-service",
             "ceilometer:ceilometer-service ceilometer-agent:ceilometer-service",
             "ceilometer nagios",
             "ceilometer nrpe",
             ]

def addrelation(relation):
    subprocess.check_call("juju add-relation %s" % relation, shell=True)

def destroyrelation(relation):
    subprocess.check_call("juju destroy-relation %s" % relation, shell=True)

def addrelations():
    for relation in relations:
        print "Adding relation %s" % relation
        try:
            addrelation(relation)
            time.sleep(sleep_interval)
        except:
            pass

def destroyrelations():
    for relation in relations:
        print "Destroying relation %s" % relation
        try:
            destroyrelation(relation)
            time.sleep(sleep_interval)
        except:
            pass

def main():
    parser = argparse.ArgumentParser(description='Deploy OpenStack controller services')
    parser.add_argument('--destroy', action='store_true',
                       help='Destroy the relations instead of adding them')

    args = parser.parse_args()
    if args.destroy:
        destroyrelations()
    else:
        addrelations()

if  __name__ =='__main__':
    main()
