import getopt
import time
import errno
import os
import sys

# The following exits cleanly on Ctrl-C or EPIPE
# while treating other exceptions as before.
def std_exceptions(etype, value, tb):
    sys.excepthook = sys.__excepthook__
    if issubclass(etype, KeyboardInterrupt):
        pass
    elif issubclass(etype, IOError) and value.errno == errno.EPIPE:
        pass
    else:
        sys.__excepthook__(etype, value, tb)
sys.excepthook = std_exceptions

#
#   Define some global variables
#

PAGESIZE = os.sysconf("SC_PAGE_SIZE") / 1024 #KiB
our_pid = os.getpid()

have_pss = 0
have_swap_pss = 0

class Proc:
    def __init__(self):
        uname = os.uname()
        if uname[0] == "FreeBSD":
            self.proc = '/compat/linux/proc'
        else:
            self.proc = '/proc'

    def path(self, *args):
        return os.path.join(self.proc, *(str(a) for a in args))

    def open(self, *args):
        try:
            if sys.version_info < (3,):
                return open(self.path(*args))
            else:
                return open(self.path(*args), errors='ignore')
        except (IOError, OSError):
            val = sys.exc_info()[1]
            if (val.errno == errno.ENOENT or # kernel thread or process gone
                val.errno == errno.EPERM):
                raise LookupError
            raise

proc = Proc()


#
#   Functions
#

def parse_options():
    try:
        long_options = [
            'split-args',
            'help',
            'total',
            'discriminate-by-pid',
            'swap'
        ]
        opts, args = getopt.getopt(sys.argv[1:], "shtdSp:w:", long_options)
    except getopt.GetoptError:
        sys.stderr.write(help())
        sys.exit(3)

    if len(args):
        sys.stderr.write("Extraneous arguments: %s\n" % args)
        sys.exit(3)

    # ps_mem.py options
    split_args = False
    pids_to_show = None
    discriminate_by_pid = False
    show_swap = False
    watch = None
    only_total = False

    for o, a in opts:
        if o in ('-s', '--split-args'):
            split_args = True
        if o in ('-t', '--total'):
            only_total = True
        if o in ('-d', '--discriminate-by-pid'):
            discriminate_by_pid = True
        if o in ('-S', '--swap'):
            show_swap = True
        if o in ('-h', '--help'):
