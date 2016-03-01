#!/bin/sh

apt-get update
apt-get install bridge-utils
brctl addbr databr
ifconfig databr 192.168.0.254/24 up
ip link add type veth
ifconfig veth0 up
ifconfig veth1 up
brctl addif databr veth0
iptables -t nat -A POSTROUTING -s 192.168.0.0/24 \! -d 192.168.0.0/24 -j MASQUERADE
