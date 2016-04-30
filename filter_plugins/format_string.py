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

