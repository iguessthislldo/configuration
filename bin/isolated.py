#!/usr/bin/env python3


import sys
import os
from subprocess import check_call, CalledProcessError
from argparse import ArgumentParser
from pathlib import Path
from textwrap import dedent


orig_cfg = Path(__file__).parent.parent.resolve()


class Env:
    def __init__(self, user: str, home: Path, cwd: Path = None, **vars):
        self.user = user
        self.home = home
        self.vars = {
            'USER': user,
            'HOME': str(home),
            'TERM': 'xterm-256color',
            'IGTD_ENV_NAME': 'isoenv',
        }
        inherit = {
            'LANG': 'en_US.UTF-8',
        }
        self.vars.update({name: os.environ.get(name, default) for name, default in inherit.items()})
        self.vars.update(vars)
        self.cwd = cwd or home

    def run(self, *cmd, cwd=None, **vars):
        ev = self.vars.copy()
        ev.update(vars)
        check_call(cmd, cwd=(cwd or self.cwd), env=ev)


def isolated_env(args, root):
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
            set_ssh_origin='false',
            install_user_dirs='true',
        )

    elif not root.exists():
        sys.exit(f'{root} does not exist!')

    env.run(*args.command)


def graph_node_i(file, ref, is_dir, name, extra=''):
    kind = 'folder' if is_dir else 'note'
    if extra:
        extra = f', {extra}'
    print(f'    {ref} [shape={kind}, label="{name}"{extra}]', file=file)


def graph_edge(file, a, b, extra=''):
    if extra:
        extra = f' [{extra}]'
    print(f'    {a} -> {b}{extra}', file=file)


def point(depth, i):
    return f'"p{depth}-{i}"'


def graph_node(file, p, ref, is_dir, is_link, is_exec, name, points, extra_label=''):
    this_p = p / name
    depth = len(this_p.parts) - 1
    prev_parent, count = points.get(depth, (p, 0))
    prev_point = point(depth, count)
    count += 1
    this_point = point(depth, count)
    if count > 1 and prev_parent == p:
        # Connect point to prev point
        graph_edge(file, prev_point, this_point)
    else:
        # Connect point to parent node
        graph_edge(file, ref, this_point)
    this_ref = f'"{this_p}"'
    graph_edge(file, this_point, this_ref)
    points[depth] = (p, count)
    extra = ''
    if is_link:
        if is_dir:
            extra = 'color=black, style=filled, fillcolor=royalblue3'
        else:
            extra = 'color=black, style=filled, fillcolor=turquoise'
    elif is_dir:
        extra = 'color=black, style=filled, fillcolor=orange1'
    elif is_exec:
        extra = 'color=black, style=filled, fillcolor=lightgreen'
    graph_node_i(file, this_ref, is_dir, name + extra_label, extra)


def read_graph_file(dir_path, ignore, always_graph):
    graph_path = dir_path / '.graph'
    if graph_path.exists():
        with graph_path.open() as f:
            for line in f:
                line = line.strip()
                if len(line) > 2:
                    what = None
                    values = line.split(':', 1)
                    if len(values) > 1:
                        what = values[0]
                        path = (dir_path / values[1]).absolute()
                    if what == 'ignore':
                        ignore.add(path)
                    elif what == 'graph':
                        always_graph.add(path.resolve())
                    else:
                        print(f'Invalid .graph line in {graph_path}:', line)


def all_ancestors(root, paths, all_paths):
    for path in paths:
        for ancestor in path.parents:
            if ancestor == root.parent:
                break
            all_paths.add(ancestor)
        all_paths.add(path)


def interested_walk(root):
    links = {}
    ignore = set()
    always_graph = set()

    for current_dir, dirs, files in root.walk():
        read_graph_file(current_dir, ignore, always_graph)
        for name in dirs + files:
            child = current_dir / name
            if child in ignore or (child / '.git').is_file() or name == '.git':
                if child.is_dir():
                    dirs.remove(name)
                continue
            if child.is_symlink():
                try:
                    links[child.absolute()] = child.resolve(strict=True)
                except FileNotFoundError:
                    print(f'{child} is broken!')

    all_paths = set()
    all_ancestors(root, links.keys(), all_paths)
    all_ancestors(root, links.values(), all_paths)
    all_ancestors(root, always_graph, all_paths)

    result = []
    for current, dirs, files in root.walk():
        if current not in all_paths:
            continue
        kept_dirs = [d for d in dirs if (current / d) in all_paths]
        kept_files = [f for f in files if (current / f) in all_paths]
        if kept_dirs or kept_files or current in all_paths:
            result.append((current, kept_dirs, kept_files))

    return result


def resolve(root, p):
    rel = p.relative_to(root)
    if rel.parts and rel.parts[0] == '..':
        return None
    return Path('/') / rel


def graph(root, file):
    print(dedent('''\
        strict digraph tree {
            graph[overlap=false, splines=ortho, ranksep=0.05, rankdir=LR]
            edge[arrowhead=none, color=black]
        '''), file=file)

    points = {}

    p = Path("/")
    ref = f'"{p}"'
    graph_node_i(file, ref, True, str(p))
    for dirpath, dirnames, filenames in interested_walk(root):
        p = resolve(root, dirpath)
        ref = f'"{p}"'

        for name in filenames:
            path = dirpath / name
            realpath = path.resolve()
            is_link = path != realpath
            is_dir = realpath.is_dir()
            is_exec = not is_dir and os.access(realpath, os.X_OK)
            extra_label = ''
            if is_link:
                real_p = resolve(root, realpath)
                if real_p:
                    extra_label = f' ({real_p})'
                    # this_p = p / name
                    # graph_edge(file, f'"{this_p}"', f'"{real_p}"', 'constraint=false,arrowhead=normal,color=red')
            graph_node(file, p, ref, is_dir, is_link, is_exec, name, points, extra_label)

        for name in dirnames:
            extra_label = ''
            graph_node(file, p, ref, True, False, False, name, points, extra_label)

    for depth, (_, count) in points.items():
        print('    {', file=file)
        print('        rank=same', file=file)
        for def_point in [point(depth, i + 1) for i in range(0, count)]:
            print(f'        {def_point} [shape="point", width=0, height=0]', file=file)
        print('    }', file=file)

    print('}', file=file)


if __name__ == '__main__':
    arg_parser = ArgumentParser()
    arg_parser.add_argument('--create', action='store_true')
    arg_parser.add_argument('--clone', action='store_true')
    arg_parser.add_argument('--graph', action='store_true')
    arg_parser.add_argument('root', type=Path)
    arg_parser.add_argument('command', nargs='*')
    args = arg_parser.parse_args()

    root = args.root.resolve()

    if args.graph:
        dot = 'tree.dot'
        with open(dot, 'w') as file:
            graph(root, file)
        check_call(['dot', '-Tpng', dot, '-o', str(orig_cfg / 'tree.png')])
    else:
        isolated_env(args, root)
