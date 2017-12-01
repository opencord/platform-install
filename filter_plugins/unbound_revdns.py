#!/usr/bin/env python

# Copyright 2017-present Open Networking Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# unbound_revdns - ansible filter - ipv4 address or cidr and generates a
# reverse DNS string suitable for use with unbound, which requires them in a
# slightly unusual format when a RFC1918 address is used with a local-zone
# definition:
# https://www.unbound.net/documentation/unbound.conf.html
# https://www.claudiokuenzler.com/blog/699/unbound-dns-not-serving-reverse-lookup-for-internal-addresses-rfc1918

import netaddr


class FilterModule(object):

    def filters(self):
        return {
            'unbound_revdns': self.unbound_revdns,
            }

    def unbound_revdns(self, var):
        (o1, o2, o3, o4) = netaddr.IPNetwork(var).network.words

        revdns = "%d.%d.%d.%d.in-addr.arpa." % (o4, o3, o2, o1)

        if (o2 == 0 or o1 == 10):
            revdns = "%d.in-addr.arpa." % (o1)
        elif (o3 == 0
                or (o1 == 172 and o2 >= 16 and o2 <= 31)
                or (o1 == 192 and o2 == 168)):
            revdns = "%d.%d.in-addr.arpa." % (o2, o1)
        elif(o4 == 0):
            revdns = "%d.%d.%d.in-addr.arpa." % (o3, o2, o1)

        return revdns
