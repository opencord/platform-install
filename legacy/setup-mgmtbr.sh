#!/bin/bash

IFACE=$1

# Assumes that mgmtbr is set up on 10.10.1.1 interface
apt-get install bridge-utils dnsmasq
brctl addbr mgmtbr
ifconfig $IFACE 0.0.0.0
brctl addif mgmtbr $IFACE
ifconfig mgmtbr 10.10.1.1/24 up

cat <<EOF > /etc/dnsmasq.d/cord
dhcp-range=10.10.1.3,10.10.1.253
interface=mgmtbr
dhcp-option=option:router,10.10.1.1
EOF

service dnsmasq restart

# Assumes eth0 is the public interface
iptables -t nat -I POSTROUTING -s 10.10.1.0/24 \! -d 10.10.1.0/24 -j MASQUERADE
