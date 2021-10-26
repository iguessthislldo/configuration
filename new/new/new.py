#!/usr/bin/env python3

import sys
import os
import re
import stat
from pathlib import Path
from argparse import ArgumentParser
import json
from subprocess import check_call
import itertools


template_re = re.compile(r'(?<!\\)%(\w+)%')

# Paths
config_json_name = 'new.json'
template_dir_name = 'templates'
global_config_dir_path = (Path(os.environ['CONFIG']) / 'new').resolve()
global_template_dir_path = global_config_dir_path / template_dir_name
local_config_dir_subpath = Path('.new')
local_template_dir_subpath = local_config_dir_subpath / template_dir_name

# Builtin Template Variable Names
post_command_var = 'new_post_command'
dest_var = 'dest'
this_base_dir_var = 'new_this_base_dir'

def expect(name, expected, result):
    if result != expected:
        print('For {} expected:\n{}\nBut got:\n{}'.format(
            name, repr(expected), repr(result)), file=sys.stderr)
        sys.exit(1)


def resolve(template_vars, text, recursive=True, restrict=lambda s: True):
    if isinstance(text, list):
        return [resolve(template_vars, t, recursive, restrict) for t in text]
    while True:
        last = text
        var_names = set(filter(restrict, template_re.findall(text)))
        for var_name in var_names:
            text = re.sub(r'(?<!\\)%{}%'.format(var_name), template_vars[var_name], text)
        if not var_names:
            break
        if text == last:
            raise ValueError('Would cause infinite loop')
        if not recursive:
            break
    return text


def test_resolve():
    template_vars = {
        'simple': 'easy',
        'escaped': '\%escaped%',
        'redirect1': '%simple%%escaped%',
        'redirect2': '%redirect1%',
    }
    result = resolve(template_vars, '''
Hello %simple%
%escaped% \%escaped%
%redirect1%
%redirect2%
''')
    expect('recursive resolve test', '''
Hello easy
\%escaped% \%escaped%
easy\%escaped%
easy\%escaped%
''', result)

    # Detect Infinite Loop
    caught = False
    try:
        resolve({'loop': '%loop%'}, '%loop%', recursive=False)
    except ValueError:
        caught = True
    expect('detect infinite loop', True, caught)


def first(it):
    for i in it:
        return i
    return None


def find_paths(base_path, sub_path,
        recursive=False, check=Path.exists, parents_first=True, find_all=False):
    check_paths = [base_path]
    if recursive:
        check_paths.extend([p.resolve() for p in base_path.parents])
        if parents_first:
            check_paths.reverse()
    for check_path in check_paths:
        path = check_path / sub_path
        for p in path.glob('*') if find_all else [path]:
            if check(path):
                yield p


def template_iter(dest_path, kind=None):
    find_all = kind is None
    if find_all:
        kind = ''
    encountered = set()
    it = itertools.chain(
        find_paths(dest_path, local_template_dir_subpath / kind,
            recursive=True, find_all=find_all),
        find_paths(global_template_dir_path, kind, find_all=find_all),
    )
    for i in it:
        if i.name not in encountered:
            encountered |= {i.name,}
            yield i


def find_template(kind, dest_path):
    t = first(template_iter(dest_path, kind))
    if t is not None:
        return t
    raise ValueError('Could not find template named: ' + repr(kind))


def read_new_json(dir_path, template_vars, recursive=False, dir_subpath=None):
    subpath = config_json_name
    if dir_subpath is not None:
        subpath = dir_subpath / subpath
    for path in find_paths(dir_path, subpath, recursive=recursive, check=Path.is_file):
        print('Reading', repr(str(path)))
        with path.open() as f:
            for name, value in json.load(f).items():
                template_vars[name] = resolve({this_base_dir_var: str(path.parent.parent)}, value,
                    restrict=lambda s: s == this_base_dir_var)


def new(kind, dest_path, override_vars={}, dry_run=True):
    dest_path = dest_path.resolve()
    print('Destination is', repr(str(dest_path)))

    template_path = find_template(kind, dest_path)
    print('Template is', repr(str(template_path)))

    # Get variables
    template_vars = {}
    read_new_json(global_config_dir_path, template_vars)
    read_new_json(template_path, template_vars, dir_subpath=local_config_dir_subpath)
    read_new_json(dest_path, template_vars, recursive=True, dir_subpath=local_config_dir_subpath)
    template_vars[dest_var] = str(dest_path)
    template_vars.update(override_vars)
    print('Variable values are:')
    for name, value in template_vars.items():
        print(' - {}: {}'.format(name, repr(value)))

    # Read and resolve template contents
    new_items = []
    if template_path.is_dir():
        # Allow for empty directory template
        new_items.append((template_path, '(template base directory)', dest_path, True, None))
        for path in template_path.rglob('*'):
            if path.name == str(local_config_dir_subpath) and path.is_dir():
                continue
            rel = path.relative_to(template_path)
            new_path = dest_path / rel
            if path.is_file():
                is_dir = False
                contents = resolve(template_vars, path.read_text())
            elif path.is_dir():
                is_dir = True
                contents = None
            else:
                sys.exit('{} is not a file or a directory'.format(repr(str(path))))
            new_items.append((path, rel, new_path, is_dir, contents))
    else:
        new_items.append((template_path, '(template base file)', dest_path,
            False, resolve(template_vars, template_path.read_text())))

    # Create directories and write files
    for path, rel, new_path, is_dir, contents in new_items:
        print('Copying', repr(str(rel)))
        if dry_run:
            print('mode:', path.stat())
            if is_dir:
                print('(Directory)')
            else:
                print('START FILE ====================================================================')
                print(contents)
                print('END FILE ======================================================================')
        else:
            if is_dir:
                new_path.mkdir(parents=True, exist_ok=True)
            else:
                new_path.parent.mkdir(parents=True, exist_ok=True)
                new_path.write_text(contents)
            new_path.chmod(path.stat().st_mode)

    # Post command
    if post_command_var in template_vars:
        post_command = resolve(template_vars, template_vars[post_command_var])
        print('Would run' if dry_run else 'Running',
            ' '.join([repr(i) for i in post_command]))
        if not dry_run:
            check_call(post_command, cwd=dest_path)


def run_tests():
    test_resolve()
    print('Tests Finished')
