import argparse
import inspect
import dataclasses

from .utils import doublewrap


class FuncAction(argparse.Action):
    def __init__(self, option_strings, dest, nargs=None, metavar=None, **kw):
        if self.fixed_args is None:
            nargs = len(self.params)
            metavar = tuple([a.upper() for a in self.params])
        else:
            nargs = 0
            metavar = tuple()
        super().__init__(option_strings, dest, nargs=nargs, metavar=metavar, **kw)

    def __call__(self, parser, namespace, values, option_string=None):
        if self.fixed_args is not None:
            values = self.fixed_args
        try:
            result = self.func(*values)
            if self.dest is not argparse.SUPPRESS:
                setattr(namespace, self.dest, result)
        except RuntimeError as e:
            raise argparse.ArgumentError(self, e)

    @classmethod
    def add_func_arg(cls, arg_parser, func, *args, dest=None, fixed_args=None, **kw):
        sig = inspect.signature(func)
        params = func.__code__.co_varnames
        if inspect.ismethod(func):
            params = params[1:]
        if sig.return_annotation is sig.empty and dest is None:
            dest = argparse.SUPPRESS
        arg_parser.add_argument(*args, dest=dest,
            action=type(f'{func.__name__}Action', (cls,), {
                'func': func,
                'params': params,
                'fixed_args': fixed_args,
            }),
            **kw)


@doublewrap
def cli_call(func, *args, pos=None, opt=True, **kw):
    func._cli_call = (pos, opt, args, kw)
    return func


def _get_doc(kw, name, obj):
    return kw.get(name, getattr(obj, '__doc__', None))


def _arg_name(name, pos, opt, args):
    rv = None
    if args:
        rv = args
    elif pos:
        rv = [name]
    elif opt:
        rv = ['--' + name.lower().replace('_', '-')]
    if rv is not None:
        return rv
    raise RuntimeError(f'args and pos and opt are all false for {name}')


class Cli:
    def __init_subclass__(cls):
        """Automatically add __post_init__ to subclasses that don't have one"""
        super().__init_subclass__()
        if '__post_init__' not in cls.__dict__:
            # Create a __post_init__ that calls Cli.__init__
            def __post_init__(self):
                Cli.__init__(self)
            cls.__post_init__ = __post_init__

    def __init__(self, *args, **kw):
        self._arg_parser = argparse.ArgumentParser(description=_get_doc(kw, 'description', self))

        for name, member in inspect.getmembers(self, lambda m: getattr(m, '_cli_call', None)):
            pos, opt, _args, _kw = member._cli_call
            self._add_cli_call(name, member, pos, opt, *_args, **_kw)

        if dataclasses.is_dataclass(self):
            for field in dataclasses.fields(self):
                cli = field.metadata.get('cli')
                if cli:
                    pos, opt, _args, _kw = cli
                    self._add_cli_field(field, pos, opt, *_args, **_kw)

    def _add_cli_call(self, name, member, pos, opt, *args, **kw):
        FuncAction.add_func_arg(self._arg_parser, member, *_arg_name(name, pos, opt, args),
            help=_get_doc(kw, 'help', member), **kw)

    def _add_cli_field(self, field, pos, opt, *args, **kw):
        if opt:
            kw['dest'] = field.name
        if field.type is bool and 'action' not in kw:
            if 'default' not in kw:
                kw['default'] = False
            kw['action'] = 'store_false' if kw['default'] else 'store_true'
        else:
            kw['type'] = field.type
        self._arg_parser.add_argument(*_arg_name(field.name, pos, opt, args), **kw)

    def parse_args(self, args=None):
        return self._arg_parser.parse_args(args=args, namespace=self)


def cli_field(*args, field=None, pos=None, opt=None, **kw):
    if field is None:
        field = {}
    if 'default' in kw:
        value = kw.get('default')
        field['default'] = value
        kw['default'] = value
    else:
        field['default'] = None
    return dataclasses.field(**field, metadata={'cli': (pos, opt, args, kw)})


def cli_field_opt_pos(*args, default=None, field=None, **kw):
    return cli_field(*args, nargs='?', default=default, field=field, pos=True, opt=False, **kw)
