#!/usr/bin/env python3

import sys
import json
import tarfile
import subprocess
from pathlib import Path
from argparse import ArgumentParser
from configparser import RawConfigParser

import gi
try:
    gi.require_version('Flatpak', '1.0')
except ValueError:
    print('Might need gir1.2-flatpak-1.0', file=sys.stderr)
    raise
from gi.repository import Flatpak
from gi.repository import GLib


config_dir = Path(__file__).parent.parent


def user_select(prompt, options, default=None):
    """Prompt the user to select from a list of options.

    options: list of (key, label) tuples. If only one option, auto-selects it.
    default: key to use when input is empty.
    Returns the key of the selected option.
    """
    if len(options) == 1:
        key, label = options[0]
        print(f'{prompt} {label}')
        return key
    hint = ' / '.join(f'[{key}] {label}' for key, label in options)
    valid_keys = {key for key, _ in options}
    while True:
        choice = input(f'{prompt} {hint} ').strip()
        if not choice and default is not None:
            return default
        if choice in valid_keys:
            return choice
        print('  Invalid choice, try again.')


KNOWN_REMOTES = {
    'https://dl.flathub.org/repo/': ('flathub', 'https://flathub.org/repo/flathub.flatpakrepo'),
}


def ensure_remote(installation, url):
    for remote in installation.list_remotes():
        if remote.get_url() == url:
            return
    known = KNOWN_REMOTES.get(url)
    if known is None:
        raise RuntimeError(f'Unknown remote URL: {url}')
    subprocess.check_call(['flatpak', 'remote-add', '--user', '--if-not-exists', *known])


def setup_transaction(installation):
    transaction = Flatpak.Transaction.new_for_installation(installation)
    transaction.add_default_dependency_sources()
    for sys_inst in Flatpak.get_system_installations():
        transaction.add_dependency_source(sys_inst)

    def format_size(size):
        for unit in ('B', 'KB', 'MB', 'GB'):
            if size < 1024:
                return f'{size:.1f} {unit}'
            size /= 1024
        return f'{size:.1f} TB'

    def on_ready(tx):
        total_download = 0
        total_installed = 0
        print('Transaction ready, operations:')
        for op in tx.get_operations():
            dl = op.get_download_size()
            inst = op.get_installed_size()
            total_download += dl
            total_installed += inst
            print(f'  {op.get_operation_type().value_nick} {op.get_ref()} from {op.get_remote()}'
                  f' (dl: {format_size(dl)}, inst: {format_size(inst)})')
        print(f'Total download: {format_size(total_download)}, installed: {format_size(total_installed)}')
        return user_select('Proceed with transaction?', [('Y', 'yes'), ('n', 'no')], default='Y') == 'Y'

    def on_new_operation(tx, operation, progress):
        print(f'  Starting: {operation.get_operation_type().value_nick} {operation.get_ref()}')
        def on_progress_changed(prog):
            status = prog.get_status()
            if status:
                print(f'\r    {status}', end='', flush=True)
            else:
                print(f'\r    {prog.get_progress()}%', end='', flush=True)
        progress.set_update_frequency(200)
        progress.connect('changed', on_progress_changed)

    def on_operation_done(tx, operation, commit, details):
        print(f'\r  Done: {operation.get_ref()}')

    def on_operation_error(tx, operation, error, detail):
        print(f'  Error: {operation.get_ref()}: {error.message}')
        return False

    def on_choose_remote(tx, for_ref, runtime_ref, remotes):
        options = [(str(i), remote) for i, remote in enumerate(remotes)]
        return int(user_select(f'  Remote for {runtime_ref}:', options))

    transaction.connect('ready', on_ready)
    transaction.connect('new-operation', on_new_operation)
    transaction.connect('operation-done', on_operation_done)
    transaction.connect('operation-error', on_operation_error)
    transaction.connect('choose-remote-for-ref', on_choose_remote)
    return transaction


class App:
    section = 'Flatpak Ref'

    def get_cfg(self):
        # Avoid it tying to normalize keys
        cfg = RawConfigParser()
        cfg.optionxform = lambda x: x
        return cfg

    extra_section = 'sync-flatpak.py'

    def __init__(self, synced_flatpakrefs, installation=None, *, ref=None, path=None):
        self.installation = installation
        self.ref = ref
        self.groups = set()
        if self.ref is not None:
            # This is an installed application
            self.raw = {'Flatpak Ref': {}}
            self.app_id = ref.get_name()
            self.name = ref.get_appdata_name()
            self.branch = ref.get_branch()
            self.remote_url = installation.get_remote_by_name(ref.get_origin()).get_url()
        elif path is not None:
            # This is a flatpakref file
            cfg = self.get_cfg()
            cfg.read(path)
            self.raw = {sec: dict(cfg[sec]) for sec in cfg.sections()}
            refsec = self.raw[self.section]
            self.app_id = refsec['Name']
            self.name = refsec['Title']
            self.branch = refsec['Branch']
            self.remote_url = refsec['Url']
            extra = self.raw.get(self.extra_section, {})
            if 'Groups' in extra:
                self.groups = {g.strip() for g in extra['Groups'].split(',')}
            # TODO: what if path is different from self.path?
        self.path = synced_flatpakrefs / f'{self.app_id}.flatpakref'

    def write(self):
        refsec = self.raw[self.section]
        refsec['Name'] = self.app_id
        refsec['Title'] = self.name
        refsec['Branch'] = self.branch
        refsec['Url'] = self.remote_url
        if self.groups:
            extra = self.raw.setdefault(self.extra_section, {})
            extra['Groups'] = ','.join(sorted(self.groups))
        elif self.extra_section in self.raw:
            self.raw[self.extra_section].pop('Groups', None)
        cfg = self.get_cfg()
        for sec_name, sec_values in self.raw.items():
            cfg.add_section(sec_name)
            sec = cfg[sec_name]
            for k, v in sec_values.items():
                sec[k] = v

        self.path.parent.mkdir(exist_ok=True, parents=True)
        with self.path.open('w') as f:
            cfg.write(f)

    def __repr__(self):
        groups = ''
        if self.groups:
            groups = f' [{', '.join(self.groups)}]'
        # If downloaded from flatpak the title is "<app_id> from flathub" for
        # some reason, so avoid saying the app id twice.
        if self.app_id in self.name:
            name = self.name
        else:
            name = f'{self.name} ({self.app_id})'
        return name + groups

    def __str__(self):
        return repr(self)


def get_installed_apps(synced_flatpakrefs, installation):
    return [App(synced_flatpakrefs, installation, ref=ref) for ref in installation.list_installed_refs_by_kind(Flatpak.RefKind.APP)]


def get_all_installed_apps(synced_flatpakrefs, user_installation):
    apps = get_installed_apps(synced_flatpakrefs, user_installation)
    for installation in Flatpak.get_system_installations():
        apps.extend(get_installed_apps(synced_flatpakrefs, installation))
    return apps


class LocalConfig:
    def __init__(self, synced_flatpakrefs, args):
        self.path = synced_flatpakrefs / 'local.json'
        self.ignore_apps = {}
        self.groups = set()
        self._raw_ignore = list(args.ignore or [])
        self._raw_unignore = list(args.unignore or [])
        self.new_ignore_apps = {}
        self.unignore_apps = {}
        if self.path.exists():
            with self.path.open() as f:
                local_config = json.load(f)
            self.ignore_apps = local_config.get('ignore_apps', {})
            self.groups = set(local_config.get('groups', []))
        self._orig_groups = self.groups.copy()
        self._ignore_apps = dict(self.ignore_apps)

    def resolve_apps(self, known_apps):
        self.new_ignore_apps = {resolve_app_id(q, known_apps): True for q in self._raw_ignore}
        self.unignore_apps = {resolve_app_id(q, known_apps): False for q in self._raw_unignore}
        self._ignore_apps = self.ignore_apps | self.new_ignore_apps | self.unignore_apps

    def ignore(self, app_id, value=True):
        d = {app_id: value}
        if value:
            self.new_ignore_apps |= d
        else:
            self.unignore_apps |= d
        self._ignore_apps |= d

    def should_ignore(self, app):
        if self._ignore_apps.get(app.app_id):
            return True
        if app.groups and not (app.groups & self.groups):
            return True
        return False

    def write(self):
        if self.new_ignore_apps or self.unignore_apps or self.groups != self._orig_groups:
            with self.path.open('w') as f:
                json.dump(dict(
                    ignore_apps={k: v for k, v in self._ignore_apps.items() if v},
                    groups=sorted(self.groups),
                ), f, indent=2)


def resolve_app_id(query, known_apps):
    """Resolve a partial, case-insensitive query to a full app_id.

    Matches against app_id and name. Exact app_id match (case-insensitive) is
    preferred, then partial matches. Raises if ambiguous or no match.
    """
    query_lower = query.lower()
    # Exact app_id match (case-insensitive)
    for app in known_apps:
        if app.app_id.lower() == query_lower:
            return app.app_id
    # Partial matches against app_id and name
    matches = []
    for app in known_apps:
        if query_lower in app.app_id.lower() or query_lower in app.name.lower():
            if app.app_id not in [m.app_id for m in matches]:
                matches.append(app)
    if len(matches) == 1:
        return matches[0].app_id
    if not matches:
        raise SystemExit(f'No app matching "{query}"')
    names = ', '.join(str(app) for app in matches)
    raise SystemExit(f'Ambiguous app "{query}", matches: {names}')


def parse_group_args(arg_list, known_apps=None):
    result = {}
    for entry in (arg_list or []):
        if ':' in entry:
            app_id, _, groups = entry.partition(':')
            if known_apps is not None:
                app_id = resolve_app_id(app_id, known_apps)
        else:
            app_id = None
            groups = entry
        result.setdefault(app_id, set()).update(g.strip() for g in groups.split(',') if g.strip())
    return result


def apply_group_changes(app_id, groups, add_groups, rm_groups):
    if app_id in add_groups or app_id in rm_groups:
        groups |= add_groups.get(app_id, set())
        groups -= rm_groups.get(app_id, set())
        return True
    return False


FLATPAK_APP_DATA = Path.home() / '.var/app'


def _user_overrides_dir():
    return Path(Flatpak.Installation.new_user().get_path().get_path()) / 'overrides'


DATA_KINDS = {
    'config': lambda app_id: FLATPAK_APP_DATA / app_id / 'config',
    'data': lambda app_id: FLATPAK_APP_DATA / app_id / 'data',
    'cache': lambda app_id: FLATPAK_APP_DATA / app_id / 'cache',
    'state': lambda app_id: FLATPAK_APP_DATA / app_id / '.local/state',
    'perms': lambda app_id: _user_overrides_dir() / app_id,
}
DEFAULT_KINDS = {'config', 'data', 'state', 'perms'}
ALL_KINDS = set(DATA_KINDS)
EXPORT_ARCHIVE = Path('export-flatpak-data.txz')


def parse_export_args(app_specs, known_apps):
    result = []
    for spec in app_specs:
        if ':' in spec:
            query, _, kinds_str = spec.partition(':')
            kinds = {k.strip() for k in kinds_str.split(',') if k.strip()}
            if 'all' in kinds:
                kinds = ALL_KINDS
            invalid = kinds - ALL_KINDS
            if invalid:
                raise SystemExit(f'Invalid kinds: {", ".join(sorted(invalid))}. '
                    f'Valid: {", ".join(sorted(ALL_KINDS))}, all')
        else:
            query = spec
            kinds = DEFAULT_KINDS
        app_id = resolve_app_id(query, known_apps)
        result.append((app_id, kinds))
    return result


def export_data(args, synced_flatpakrefs):
    _, _, known_apps, _ = load_known_apps(synced_flatpakrefs)
    app_specs = parse_export_args(args.apps, known_apps)

    if EXPORT_ARCHIVE.exists():
        raise SystemExit(f'{EXPORT_ARCHIVE} already exists')

    with tarfile.open(EXPORT_ARCHIVE, 'w:xz') as tar:
        for app_id, kinds in app_specs:
            for kind in sorted(kinds):
                src = DATA_KINDS[kind](app_id)
                if not src.exists():
                    print(f'  Skipping {app_id}/{kind} (not found: {src})')
                    continue
                print(f'  Adding {app_id}/{kind}')
                tar.add(src, arcname=f'{app_id}/{kind}')
    print(f'Created {EXPORT_ARCHIVE}')


import os
import shutil


def import_data(args, synced_flatpakrefs):
    if not EXPORT_ARCHIVE.exists():
        raise SystemExit(f'{EXPORT_ARCHIVE} not found')

    _, installed_apps, known_apps, _ = load_known_apps(synced_flatpakrefs)
    installed_ids = {app.app_id for app in installed_apps}

    with tarfile.open(EXPORT_ARCHIVE, 'r:xz') as tar:
        # Discover app_ids and their kinds from the archive
        archive_apps = {}
        for member in tar.getmembers():
            parts = Path(member.name).parts
            if len(parts) >= 2:
                archive_apps.setdefault(parts[0], set()).add(parts[1])

        if args.apps:
            selected = set()
            for query in args.apps:
                app_id = resolve_app_id(query, known_apps)
                if app_id not in archive_apps:
                    raise SystemExit(f'{app_id} not found in archive')
                selected.add(app_id)
        else:
            selected = set(archive_apps)

        for app_id in sorted(selected):
            if app_id not in installed_ids:
                raise SystemExit(f'{app_id} is not installed, install it first')

        for app_id in sorted(selected):
            kinds = archive_apps[app_id]
            existing = []
            for kind in sorted(kinds):
                dest = DATA_KINDS[kind](app_id)
                if dest.exists():
                    existing.append(kind)
            if existing:
                if user_select(
                        f'{app_id} has existing data ({", ".join(existing)}), overwrite?',
                        [('Y', 'yes'), ('n', 'no')], default='n') == 'n':
                    print(f'  Skipping {app_id}')
                    continue

            print(f'  Importing {app_id} ({", ".join(sorted(kinds))})')
            for kind in sorted(kinds):
                dest = DATA_KINDS[kind](app_id)
                if dest.exists():
                    if dest.is_dir():
                        shutil.rmtree(dest)
                    else:
                        dest.unlink()

                prefix = f'{app_id}/{kind}'
                members = [m for m in tar.getmembers()
                    if m.name == prefix or m.name.startswith(prefix + '/')]
                dest.parent.mkdir(parents=True, exist_ok=True)
                for member in members:
                    rel = member.name[len(prefix):].lstrip('/')
                    target = dest / rel if rel else dest
                    if member.isdir():
                        target.mkdir(parents=True, exist_ok=True)
                    elif member.issym():
                        target.parent.mkdir(parents=True, exist_ok=True)
                        target.symlink_to(member.linkname)
                    else:
                        target.parent.mkdir(parents=True, exist_ok=True)
                        with tar.extractfile(member) as src, open(target, 'wb') as dst:
                            shutil.copyfileobj(src, dst)
                        os.chmod(target, member.mode)

    print('Import complete')


def load_known_apps(synced_flatpakrefs):
    user_installation = Flatpak.Installation.new_user()
    synced_apps = []
    for ref_path in synced_flatpakrefs.iterdir():
        if ref_path.suffix == '.flatpakref':
            synced_apps.append(App(synced_flatpakrefs, user_installation, path=ref_path))
    installed_apps = get_all_installed_apps(synced_flatpakrefs, user_installation)
    known_apps = list(synced_apps)
    for app in installed_apps:
        if app.app_id not in {a.app_id for a in known_apps}:
            known_apps.append(app)
    return synced_apps, installed_apps, known_apps, user_installation


def main(args, synced_flatpakrefs, local_config):
    synced_apps, installed_apps, known_apps, user_installation = load_known_apps(synced_flatpakrefs)

    local_config.resolve_apps(known_apps)
    add_groups = parse_group_args(args.add_groups, known_apps)
    rm_groups = parse_group_args(args.rm_groups, known_apps)
    apply_group_changes(None, local_config.groups, add_groups, rm_groups)
    install = {}
    groups_changed = []
    all_groups = {}

    def ask_activate_groups(groups):
        for group in groups - local_config.groups:
            if user_select(f'Activate group "{group}" locally?',
                    [('Y', 'yes'), ('n', 'no')], default='Y') == 'Y':
                local_config.groups.add(group)

    for app in synced_apps:
        if apply_group_changes(app.app_id, app.groups, add_groups, rm_groups):
            ask_activate_groups(add_groups.get(app.app_id, set()))
            app.write()
        for group in app.groups:
            all_groups[group] = all_groups.get(group, 0) + 1
        if local_config.should_ignore(app):
            if args.list:
                print(f'Skipping {app}')
            continue
        install[app.app_id] = app
    for group in local_config.groups:
        all_groups.setdefault(group, 0)
    if all_groups:
        print('Groups:')
        for group in sorted(all_groups):
            count = all_groups[group]
            active = ' (active)' if group in local_config.groups else ''
            print(f'  {group} ({count} apps){active}')
    else:
        print('No groups')

    decide = []
    rm_synced_apps = []
    apps = installed_apps
    if apps:
        print('Installed:')
    for app in apps:
        app_id = app.ref.get_name()
        synced = app_id in install
        check_app = install[app_id] if synced else app
        print(' ', check_app)
        if local_config.should_ignore(check_app):
            print('    Ignored')
            if synced:
                del install[app_id]
                rm_synced_apps.append(app)
                print('    To be removed from sync list')
        elif synced:
            print('    Synced')
            del install[app_id]
        else:
            print('    Not synced!')
            decide.append(app)

    if args.list:
        if install:
            print('Not Installed:')
            for app in install:
                print(' ', app)
        return

    new_synced_apps = []
    uninstall = []
    def add_group(app):
        group = input('    Group name: ').strip()
        if group:
            app.groups.add(group)
            ask_activate_groups({group})
            if app not in groups_changed:
                groups_changed.append(app)

    if decide:
        print('Decide what to do with unsynced apps:')
        decide_options = [
            ('s', 'sync'), ('u', 'uninstall'), ('i', 'ignore'), ('g', 'group'), ('S', 'skip')]
        decide_actions = {
            's': lambda app: new_synced_apps.append(app),
            'u': lambda app: uninstall.append(app),
            'i': lambda app: local_config.ignore(app.app_id),
            'g': add_group,
            'S': lambda app: None,
        }
        for app in decide:
            choice = user_select(f'  {app} -', decide_options)
            decide_actions[choice](app)
            while choice == 'g':
                choice = user_select(f'  {app} -', decide_options)
                decide_actions[choice](app)

    actions = [
        ('The following apps will be IGNORED:', [
            v for app_id, v in local_config.new_ignore_apps.items() if v]),
        ('The following apps will be UNIGNORED:', [
            v for app_id, v in local_config.unignore_apps.items() if not v]),
        ('The following apps will be INSTALLED:', install.values()),
        ('The following apps will be UNINSTALLED:', uninstall),
        ('The following apps will be ADDED to the sync list:', new_synced_apps),
        ('The following apps will be REMOVED from the sync list:', rm_synced_apps),
    ]
    has_actions = False
    for header, items in actions:
        if items:
            has_actions = True
            print(header)
            for item in items:
                print(f'  {item}')
    if not has_actions:
        print('Nothing to do.')
        return
    if user_select('Do you want to continue?', [('Y', 'yes'), ('n', 'no')], default='Y') == 'n':
        print('Aborted.')
        return

    if install or uninstall:
        transaction = setup_transaction(user_installation)
        for app in install.values():
            print(f'  Installing {app}')
            ensure_remote(user_installation, app.remote_url)
            transaction.add_install_flatpakref(GLib.Bytes.new(app.path.read_bytes()))
        for app in uninstall:
            print(f'  Uninstalling {app}')
            transaction.add_uninstall_ref(app.ref.format_ref())
        transaction.run()

    for app in new_synced_apps:
        app.write()
    for app in groups_changed:
        if app not in new_synced_apps:
            app.write()

    for app in rm_synced_apps:
        print(f'  Removing {app}')
        app.path.unlink()


if __name__ == '__main__':
    arg_parser = ArgumentParser(
        description='Sync Flatpak applications across machines using flatpakref files.')
    subparsers = arg_parser.add_subparsers(dest='command')

    sync_parser = subparsers.add_parser('sync', aliases=['s'], help='sync flatpak apps (default)')
    sync_parser.add_argument('--list', '-l', action='store_true',
        help='list synced and installed apps without making changes')
    sync_parser.add_argument('--ignore', '-i', action='append', metavar='APP',
        help='ignore an app so it is not installed or synced (partial name match)')
    sync_parser.add_argument('--unignore', action='append', metavar='APP',
        help='stop ignoring a previously ignored app (partial name match)')
    sync_parser.add_argument('--add-groups', action='append', metavar='[APP:]GROUP,GROUP,...',
        help='add groups globally or to a specific app (partial name match)')
    sync_parser.add_argument('--rm-groups', action='append', metavar='[APP:]GROUP,GROUP,...',
        help='remove groups globally or from a specific app (partial name match)')

    export_parser = subparsers.add_parser('export', aliases=['e'],
        help='export app data to an archive')
    export_parser.add_argument('apps', nargs='+', metavar='APP[:KIND,...]',
        help='apps to export with optional kinds: config, data, cache, state, perms, all '
             '(default: config,data,state,perms)')

    import_parser = subparsers.add_parser('import', aliases=['i'],
        help='import app data from an archive')
    import_parser.add_argument('apps', nargs='*', metavar='APP',
        help='apps to import (default: all apps in archive, partial name match)')

    subparsers.add_parser('list', aliases=['l'],
        help='shortcut for sync --list')

    args = arg_parser.parse_args()
    if args.command is None:
        args = sync_parser.parse_args()
        args.command = 'sync'
    elif args.command in ('list', 'l'):
        args = sync_parser.parse_args(['--list'])
        args.command = 'sync'
    synced_flatpakrefs = config_dir / 'sync-flatpak'

    if args.command in ('export', 'e'):
        export_data(args, synced_flatpakrefs)
    elif args.command in ('import', 'i'):
        import_data(args, synced_flatpakrefs)
    else:
        local_config = LocalConfig(synced_flatpakrefs, args)
        main(args, synced_flatpakrefs, local_config)
        local_config.write()
