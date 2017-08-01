
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


from jinja2.utils import soft_unicode

def format_string(string, pattern):
    """
    formats the string with the value passed to it
    basicaly the reverse order of standard "format()"
    """
    return soft_unicode(pattern) % (string)

class FilterModule(object):

    def filters(self):
        return {
            'format_string': format_string,
        }

