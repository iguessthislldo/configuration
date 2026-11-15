#!/usr/bin/env python3

import json
from pathlib import Path
from argparse import ArgumentParser
from configparser import RawConfigParser

import gi
gi.require_version('Flatpak', '1.0')
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


def setup_transaction(installation):
    transaction = Flatpak.Transaction.new_for_installation(installation)

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
        # some reason, so avoid double saying the app id.
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
        self.new_ignore_apps = {app_id: True for app_id in (args.ignore or [])}
        self.unignore_apps = {app_id: False for app_id in (args.unignore or [])}
        if self.path.exists():
            with self.path.open() as f:
                local_config = json.load(f)
            self.ignore_apps = local_config.get('ignore_apps', {})
            self.groups = set(local_config.get('groups', []))
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
        if self.new_ignore_apps or self.unignore_apps:
            with self.path.open('w') as f:
                json.dump(dict(
                    ignore_apps={k: v for k, v in self._ignore_apps.items() if v},
                ), f, indent=2)


def parse_group_args(arg_list):
    result = {}
    for entry in (arg_list or []):
        app_id, _, groups = entry.partition(':')
        result.setdefault(app_id, set()).update(g.strip() for g in groups.split(',') if g.strip())
    return result


def main(args, synced_flatpakrefs, local_config):
    if local_config.groups:
        print(f'Active groups: {", ".join(sorted(local_config.groups))}')
    add_groups = parse_group_args(args.add_groups)
    rm_groups = parse_group_args(args.rm_groups)
    install = {}
    groups_changed = []
    user_installation = Flatpak.Installation.new_user()
    for ref_path in synced_flatpakrefs.iterdir():
        if ref_path.suffix == '.flatpakref':
            app = App(synced_flatpakrefs, user_installation, path=ref_path)
            if app.app_id in add_groups or app.app_id in rm_groups:
                app.groups |= add_groups.get(app.app_id, set())
                app.groups -= rm_groups.get(app.app_id, set())
                app.write()
            if local_config.should_ignore(app):
                if args.list:
                    print(f'  Skipping {app}')
                continue
            install[app.app_id] = app

    decide = []
    rm_synced_apps = []
    print('Installed:')
    for app in get_all_installed_apps(synced_flatpakrefs, user_installation):
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

    local_config.write()


if __name__ == '__main__':
    arg_parser = ArgumentParser()
    arg_parser.add_argument('--list', '-l', action='store_true')
    arg_parser.add_argument('--ignore', '-i', action='append')
    arg_parser.add_argument('--unignore', action='append')
    arg_parser.add_argument('--add-groups', action='append', metavar='APP_ID:GROUP,GROUP,...')
    arg_parser.add_argument('--rm-groups', action='append', metavar='APP_ID:GROUP,GROUP,...')
    args = arg_parser.parse_args()

    synced_flatpakrefs = config_dir / 'sync-flatpak'
    local_config = LocalConfig(synced_flatpakrefs, args)
    main(args, synced_flatpakrefs, local_config)
