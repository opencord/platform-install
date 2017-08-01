
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


import hashlib
import netaddr

def genmac(value, prefix='', length=12):
    '''
    deterministically generates a "random" MAC with a configurable prefix
    '''

    # from: http://serverfault.com/questions/40712/what-range-of-mac-addresses-can-i-safely-use-for-my-virtual-machines
    if prefix == '' :
        mac_prefix = "0ac04d" # random "cord"-esque

    # deterministically generate a value
    h = hashlib.new('sha1')
    h.update(value)

    # build/trim MAC
    mac_string = (mac_prefix + h.hexdigest())[0:length]

    return netaddr.EUI(mac_string)

class FilterModule(object):
    ''' MAC generation filter '''
    filter_map = {
        'genmac': genmac,
    }

    def filters(self):
         return self.filter_map
