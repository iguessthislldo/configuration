#!/usr/bin/env python3


import sys
import os
from subprocess import check_call, CalledProcessError
from argparse import ArgumentParser
from pathlib import Path


orig_cfg = Path(__file__).parent.resolve()


class Env:
    def __init__(self, user: str, home: Path, cwd: Path = None, **vars):
        self.user = user
        self.home = home
        self.vars = {
            'USER': user,
            'HOME': str(home),
            'TERM': 'xterm-256color',
        }
        self.vars.update(vars)
        self.cwd = cwd or home

    def run(self, *cmd, cwd=None, **vars):
        ev = self.vars.copy()
        ev.update(vars)
        check_call(cmd, cwd=(cwd or self.cwd), env=ev)


if __name__ == '__main__':
    arg_parser = ArgumentParser()
    arg_parser.add_argument('--create', action='store_true')
    arg_parser.add_argument('--clone', action='store_true')
    arg_parser.add_argument('root', type=Path)
    arg_parser.add_argument('command', nargs='+')
    args = arg_parser.parse_args()

    root = args.root.resolve()

    env = Env(os.environ['USER'], root / 'home')

    if args.create:
        if root.exists():
            sys.exit(f'{root} already exists!')

        root.mkdir()
        env.home.mkdir()
        install_data = root / 'data'
        install_data.mkdir()
        if args.clone:
            install_config = install_data / 'configuration'
            check_call(['git', 'clone', '--recursive', str(orig_cfg), str(install_config)])
        else:
            install_config = orig_cfg

        env.run('bash', 'install_data.sh',
            cwd=install_config,
            install_data=str(install_data),
            skip_set_ssh_origin='true',
        )

    elif not root.exists():
        sys.exit(f'{root} does not exist!')

    env.run(*args.command)
