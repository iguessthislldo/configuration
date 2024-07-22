import importlib.util
import sys


class IpyCmd(gdb.Command):

    def __init__(self):
        super(IpyCmd, self).__init__("ipy", gdb.COMMAND_USER)

    def invoke(self, arg, from_tty):
        if not from_tty:
            print('Must be run from TTY', file=sys.stderr)
            return

        if importlib.util.find_spec("IPython") is None:
            print('Missing ipython', file=sys.stderr)
            return

        sys.stdout=sys.__stdout__
        sys.stderr=sys.__stderr__

        import IPython
        IPython.embed(colors="neutral")


IpyCmd()
