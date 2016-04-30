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
