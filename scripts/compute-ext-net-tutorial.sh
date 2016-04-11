#!/bin/sh

apt-get update
apt-get install bridge-utils
brctl addbr databr
ifconfig databr 10.168.0.1/24 up
ip link add address 02:42:0a:a8:00:01 type veth
ifconfig veth0 up
ifconfig veth1 up
brctl addif databr veth0
ip addr add 10.168.1.1/24 dev databr
iptables -t nat -A POSTROUTING -s 10.168.0.0/16 \! -d 10.168.0.0/16 -j MASQUERADE
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.all.send_redirects=0
sysctl -w net.ipv4.conf.default.send_redirects=0
sysctl -w net.ipv4.conf.eth0.send_redirects=0
sysctl -w net.ipv4.conf.databr.send_redirects=0