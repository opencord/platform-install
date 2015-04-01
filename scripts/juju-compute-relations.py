#!/usr/bin/python

import subprocess
import time
import argparse

sleep_interval = 1

relations = [
    "nova-compute:shared-db mysql:shared-db",
    "nova-compute:amqp rabbitmq-server:amqp",
    "nova-compute glance",
    "nova-compute nova-cloud-controller",
    "ntp nova-compute",
    "nova-compute nagios",
    "nova-compute nrpe",
    "nova-compute:nova-ceilometer ceilometer-agent:nova-ceilometer",
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
