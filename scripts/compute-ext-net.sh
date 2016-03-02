#!/bin/sh

apt-get update
apt-get install bridge-utils
brctl addbr databr
ifconfig databr 10.168.0.1/24 up
ip link add address 02:42:0a:a8:00:01 type veth
ifconfig veth0 up
ifconfig veth1 up
brctl addif databr veth0
iptables -t nat -A POSTROUTING -s 10.168.0.0/24 \! -d 10.168.0.0/24 -j MASQUERADE
