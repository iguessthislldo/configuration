#!/usr/bin/env python3

import re
import os
import sys
import time
import argparse
import signal
import subprocess
import threading
import pty
import select
import fcntl
import struct
import termios
import json
from dataclasses import dataclass, field, asdict
from pathlib import Path

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Gio', '2.0')
gi.require_version('Vte', '3.91')

from gi.repository import Gtk, Gio, GLib, Vte

sys.path.insert(0, str(Path(__file__).parent.parent / 'lib'))
from pyigtd.cli import Cli, cli_field


app_name = 'auto-sync-helper'
app_id = f'us.hornsey.{app_name}'
command_default = 'echo "MOUNT_PATH: $MOUNT_PATH"'
user_home = Path(os.path.expanduser('~'))
xdg_config_home = Path(os.environ.get('XDG_CONFIG_HOME', user_home / '.config'))
config_path = xdg_config_home / app_name / 'config.json'
xdg_data_home = Path(os.environ.get('XDG_DATA_HOME', user_home / '.local' / 'share'))
pid_file = xdg_data_home / app_name / 'app.pid'


@dataclass
class Device:
    name: str
    vendor_id: str
    product_id: str
    vendor_name: str
    product_name: str
    serial_number: str = field(default="Unknown")
    mount_path: str | None = None
    command: str = field(default=command_default)

    def usb_id(self):
        return f'{self.vendor_id}:{self.product_id}'

    def full_id(self):
        return f'{self.usb_id()}:{self.serial_number}'

    def full_name(self):
        return f'{self.vendor_name} - {self.product_name}'

    def path(self):
        return self.mount_path or '<not mounted>'

    def is_mounted(self):
        return self.mount_path is not None

    def __str__(self):
        return f'{self.name} ({self.full_name()})'

    def __repr__(self):
        return f'{self.path()} {self.usb_id()} ({self.full_name()} {self.serial_number}) {self.name}'

    def __hash__(self):
        return hash(repr(self))

    @classmethod
    def from_json(cls, obj):
        d = obj.copy()
        d['mount_path'] = None
        return Device(**d)

    def to_json(self):
        return {k: v for k, v in asdict(self).items() if k != 'mount_path'}


def get_usb_id(path, id_filename, name_filename):
    id_value = None
    name_value = None
    id_path = os.path.join(path, id_filename)
    if os.path.exists(id_path):
        with open(id_path) as f:
            id_value = f.read().strip()

        name_value = 'Unknown'
        name_path = os.path.join(path, name_filename)
        if os.path.exists(name_path):
            with open(name_path) as f:
                name_value = f.read().strip()

    return id_value, name_value


def get_usb_device(mount_path, name):
    """
    Get USB vendor and product IDs from a mount path by reading sysfs.
    Returns (vendor_id, product_id, vendor_name, product_name) or (None, None, None, None) if not USB
    """
    try:
        # Read /proc/mounts to find the device
        device = None
        with open('/proc/mounts', 'r') as f:
            for line in f:
                parts = line.split()
                if len(parts) >= 2:
                    # Unescape mount point (e.g., \040 -> space)
                    mount_point = parts[1].encode().decode('unicode_escape')
                    if mount_point == mount_path:
                        device = parts[0]
                        break

        print(f'Found device: {device} for mount_path: {mount_path}')

        if not device:
            print(f"Device not found in /proc/mounts. Mount path: {mount_path}")
            print("Available mounts:")
            with open('/proc/mounts', 'r') as f:
                for line in f:
                    parts = line.split()
                    if len(parts) >= 2:
                        print(f"  {parts[0]} -> {parts[1]}")
            return None

        # Strip partition number (e.g., /dev/sda1 -> /dev/sda)
        # Also handle /dev/nvmeXnYpZ format
        base_device = re.sub(r'(p?\d+)$', '', device)
        device_name = os.path.basename(base_device)

        # Look for the USB device in sysfs
        sys_block_path = f"/sys/block/{device_name}"
        if not os.path.exists(sys_block_path):
            print('No /sys/block entry')
            return None

        # Follow the device symlink to find the actual device
        device_link = os.path.join(sys_block_path, 'device')
        if os.path.islink(device_link):
            real_device_path = os.path.realpath(device_link)
        else:
            real_device_path = device_link

        # Walk up the device hierarchy to find USB device
        current_path = real_device_path
        max_iterations = 10
        while max_iterations > 0:
            vendor_id, vendor_name = get_usb_id(current_path, 'idVendor', 'manufacturer')
            product_id, product_name = get_usb_id(current_path, 'idProduct', 'product')
            if vendor_id is not None and product_id is not None:
                # Get serial number if available
                serial_number = 'Unknown'
                serial_path = os.path.join(current_path, 'serial')
                if os.path.exists(serial_path):
                    try:
                        with open(serial_path) as f:
                            serial_number = f.read().strip()
                    except:
                        pass

                return Device(name, vendor_id, product_id, vendor_name, product_name, serial_number, mount_path)

            parent = os.path.dirname(current_path)
            if parent == current_path or parent == '/':
                break
            current_path = parent
            max_iterations -= 1
            current_path = parent

        print('Could not find vendor/product info')

        return None

    except Exception as e:
        print(f"Error getting USB IDs: {e}")
        return None


def kill_existing_instance():
    """Kill the existing running instance if it exists"""
    if pid_file.exists():
        try:
            pid = int(pid_file.read_text().strip())
            os.kill(pid, signal.SIGTERM)
            print(f"Killed existing instance (PID: {pid})")
            # Give it a moment to clean up
            time.sleep(0.5)
        except (ValueError, ProcessLookupError, OSError) as e:
            print(f"Could not kill existing instance: {e}")
        finally:
            try:
                pid_file.unlink()
            except OSError:
                pass


def write_pid_file():
    """Write the current process ID to the PID file"""
    pid_file.parent.mkdir(parents=True, exist_ok=True)
    pid_file.write_text(str(os.getpid()))


def cleanup_pid_file():
    """Remove the PID file on exit"""
    try:
        if pid_file.exists():
            pid_file.unlink()
    except OSError:
        pass


def count_list_items(list_box):
    """Count the number of items in a GTK ListBox"""
    count = 0
    child = list_box.get_first_child()
    while child is not None:
        count += 1
        child = child.get_next_sibling()
    return count


class TerminalWindow(Gtk.ApplicationWindow):
    """A window with an embedded VTE terminal for running sync commands"""
    def __init__(self, app, device):
        super().__init__(application=app)
        self.set_title(f"Syncing {device.name}")
        self.device = device
        self.main_window = app.window

        # Disable main window
        self.main_window.set_sensitive(False)

        # Create a main box with terminal and button
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.set_child(main_box)

        # Create a terminal widget
        self.terminal = Vte.Terminal()
        main_box.append(self.terminal)

        # Create close button (initially hidden)
        self.close_button = Gtk.Button(label="Close")
        self.close_button.set_visible(False)
        self.close_button.connect("clicked", lambda btn: self.close())
        main_box.append(self.close_button)

        # Connect close signal to re-enable main window
        self.connect("close-request", self.on_terminal_close)

        # Run the command
        self.run_command(device.command, device.mount_path)

    def run_command(self, command, mount_path):
        """Run a command in the terminal with the mount path available as an environment variable"""
        # Run command in background thread
        thread = threading.Thread(target=self._run_in_thread, args=(command, mount_path), daemon=True)
        thread.start()

    def _run_in_thread(self, command, mount_path):
        """Run the command in a background thread and feed output to terminal"""
        try:
            # Create a PTY pair
            master_fd, slave_fd = pty.openpty()

            # Set PTY size (80x24)
            fcntl.ioctl(master_fd, termios.TIOCSWINSZ, struct.pack('HHHH', 24, 80, 0, 0))

            # Set up environment with MOUNT_PATH
            env = os.environ.copy()
            env['MOUNT_PATH'] = mount_path

            # Spawn the process
            process = subprocess.Popen(
                ['/bin/bash', '-c', command],
                stdin=slave_fd,
                stdout=slave_fd,
                stderr=slave_fd,
                pass_fds=(slave_fd,),
                start_new_session=True,
                env=env
            )
            os.close(slave_fd)

            # Read from PTY until EOF
            while True:
                try:
                    chunk = os.read(master_fd, 4096)
                    if not chunk:
                        break
                    self.terminal.feed(chunk)
                except OSError:
                    break

            os.close(master_fd)
            process.wait()

            # Signal completion on the main thread
            GLib.idle_add(self.on_command_finished_callback)

        except Exception as e:
            self.terminal.feed(f"Error: {e}\n".encode())
            GLib.idle_add(self.on_command_finished_callback)

    def on_command_finished_callback(self):
        """Called when the command finishes (on main thread)"""
        # Print completion message
        self.println("=== Command finished ===")

        # Show close button
        self.close_button.set_visible(True)
        return False  # Don't call again

    def on_terminal_close(self, widget):
        """Re-enable main window when terminal closes"""
        self.main_window.set_sensitive(True)
        return False


class AutoSyncHelperApp(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app)
        self.set_title(app_name)
        self.set_default_size(400, 300)
        self.connect("close-request", self.on_close_request)

        # Create header bar
        header_bar = Gtk.HeaderBar()
        self.set_titlebar(header_bar)

        # Refresh button
        refresh_btn = Gtk.Button()
        refresh_btn.set_icon_name("view-refresh-symbolic")
        refresh_btn.set_tooltip_text("Refresh devices")
        refresh_btn.connect("clicked", lambda btn: self.refresh_devices())
        header_bar.pack_start(refresh_btn)

        # Exit button
        exit_btn = Gtk.Button()
        exit_btn.set_icon_name("application-exit-symbolic")
        exit_btn.set_tooltip_text("Exit Completely")
        exit_btn.connect("clicked", lambda btn: self.get_application().quit())
        header_bar.pack_end(exit_btn)

        # Create main box
        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        vbox.set_margin_top(10)
        vbox.set_margin_bottom(10)
        vbox.set_margin_start(10)
        vbox.set_margin_end(10)

        # Status label
        self.status_label = Gtk.Label()
        self.status_label.set_text("Waiting for devices...")
        vbox.append(self.status_label)

        # Scrolled window with device list
        scroll = Gtk.ScrolledWindow()
        scroll.set_hexpand(True)
        scroll.set_vexpand(True)
        vbox.append(scroll)

        self.device_list = Gtk.ListBox()
        scroll.set_child(self.device_list)

        # Set the main vbox as the window's child
        self.set_child(vbox)

        # Set up volume monitor
        self.volume_monitor = Gio.VolumeMonitor.get()
        self.volume_monitor.connect("volume-added", self.on_volume_added)
        self.volume_monitor.connect("volume-removed", self.on_volume_removed)
        self.volume_monitor.connect("mount-added", self.on_mount_added)
        self.volume_monitor.connect("mount-removed", self.on_mount_removed)

        self.load_config()

        # Populate initial volumes
        self.refresh_devices()

    def load_config(self):
        with config_path.open() as f:
            self.config = json.load(f)

    def save_config(self):
        with open(config_path, 'w') as f:
            json.dump(self.config, f, indent=2)


    def refresh_devices(self, want_path=None):
        self.mounted_devices = {}
        want_device = None

        # Remove all existing rows
        while True:
            row = self.device_list.get_first_child()
            if row is None:
                break
            self.device_list.remove(row)

        # Add current mounts
        volume_monitor = Gio.VolumeMonitor.get()
        mounts = volume_monitor.get_mounts()
        if mounts:
            for mount in mounts:
                device = self.add_mounted_device_to_list(mount)
                if device is not None:
                    self.mounted_devices[device.full_id()] = device
                    if device.mount_path == want_path:
                        want_device = device
            self.status_label.set_text(f"Found {len(self.mounted_devices)} mounted device(s)")
        else:
            self.status_label.set_text("No devices mounted")

        for full_id, device in self.config['devices'].items():
            if full_id not in self.mounted_devices:
                self.add_device_to_list(Device.from_json(device))

        return want_device

    def add_device_to_list(self, device):
        print(repr(device))

        # Create row widget
        row_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        row_box.set_margin_top(5)
        row_box.set_margin_bottom(5)
        row_box.set_margin_start(10)
        row_box.set_margin_end(10)

        # Create info box (name and path)
        info_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=3)

        # Device name
        name_label = Gtk.Label()
        name_label.set_markup(f"<b>{device.name}</b> ({device.product_name})")
        name_label.set_halign(Gtk.Align.START)
        if not device.is_mounted():
            name_label.add_css_class("dim-label")
        info_box.append(name_label)

        # Mount path
        path_label = Gtk.Label()
        path_label.set_text(f"Path: {device.path()}")
        path_label.set_halign(Gtk.Align.START)
        if not device.is_mounted():
            path_label.add_css_class("dim-label")
        info_box.append(path_label)

        row_box.append(info_box)

        # Create button box
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)

        # Save/Delete button
        is_saved = device.full_id() in self.config['devices']
        save_btn = Gtk.Button()
        if is_saved:
            save_btn.set_icon_name("user-trash-symbolic")
            save_btn.set_tooltip_text("Delete saved device")
            save_btn.connect("clicked", lambda btn: self.on_delete_device(device))
        else:
            save_btn.set_icon_name("document-save-symbolic")
            save_btn.set_tooltip_text("Save device")
            save_btn.connect("clicked", lambda btn: self.on_save_device(device))
        button_box.append(save_btn)

        # Sync button
        sync_btn = Gtk.Button()
        sync_btn.set_icon_name("emblem-synchronizing-symbolic")
        sync_btn.set_tooltip_text("Sync device")
        sync_btn.set_sensitive(device.is_mounted())
        sync_btn.connect("clicked", lambda btn: self.on_sync_device(device))
        button_box.append(sync_btn)

        row_box.append(button_box)

        # Store device object on the widget as a Python attribute
        row_box.device = device

        self.device_list.append(row_box)

    def add_mounted_device_to_list(self, mount):
        """Add a mount to the device list"""
        name = mount.get_name()
        root = mount.get_root()
        path = root.get_path() if root else "Unknown"
        print(f"Mount: {name} at {path}")

        device = get_usb_device(path, name)
        if device is None:
            print("Couldn't get device info")
            return None
        full_id = device.full_id()
        self.mounted_devices[full_id] = device

        if full_id in self.config['devices']:
            saved = self.config['devices'][full_id]
            device.command = saved['command']
            self.config['devices'][full_id] = device.to_json()
        self.add_device_to_list(device)

        return device

    def on_volume_added(self, monitor, volume):
        """Called when a volume is added (but not necessarily mounted)"""
        print(f"Volume added: {volume.get_name()}")

    def on_volume_removed(self, monitor, volume):
        """Called when a volume is removed"""
        print(f"Volume removed: {volume.get_name()}")

    def on_mount_added(self, monitor, mount):
        """Called when a filesystem is mounted"""
        device = self.refresh_devices(mount.get_root().get_path())
        if device is not None:
            self.show_device_dialog(device)

    def on_mount_removed(self, monitor, mount):
        """Called when a filesystem is unmounted"""
        name = mount.get_name()
        print(f"Mount removed: {name}")

        # Refresh the list
        self.refresh_devices()

    def show_device_dialog(self, device):
        """Show a dialog when a device is detected"""
        dialog = Gtk.AlertDialog()
        dialog.set_message("Device Detected")

        details = f"Device: {device.name}\nPath: {device.mount_path}"
        details += f"\n\nUSB ID: {device.usb_id()}"
        details += f"\n{device.full_name()}"

        details += "\n\nWould you like to sync files?"
        dialog.set_detail(details)
        dialog.set_buttons(["Cancel", "Sync Files"])
        dialog.set_default_button(1)

        dialog.choose(self, None, self.on_dialog_response, device)

    def on_dialog_response(self, dialog, result, device):
        """Handle dialog response"""
        try:
            button = dialog.choose_finish(result)
            if button == 1:
                print(f"User chose to sync files for {device.name}")
                # Open terminal window to run sync command
                term_window = TerminalWindow(self.get_application(), device)
                term_window.present()
            else:
                print("Sync cancelled")
        except GLib.Error as e:
            print(f"Dialog error: {e}")

    def on_save_device(self, device):
        """Save a device to the config"""
        self.config['devices'][device.full_id()] = device.to_json()
        self.save_config()
        print(f"Saved device: {device.name}")
        self.refresh_devices()

    def on_delete_device(self, device):
        """Show confirmation and delete a device from the config"""
        dialog = Gtk.AlertDialog()
        dialog.set_message("Delete Saved Device?")
        dialog.set_detail(f"Are you sure you want to delete the saved configuration for {device.name}?")
        dialog.set_buttons(["Cancel", "Delete"])
        dialog.set_default_button(0)

        dialog.choose(self, None, self.on_delete_confirmation, device)

    def on_delete_confirmation(self, dialog, result, device):
        """Handle delete confirmation response"""
        try:
            button = dialog.choose_finish(result)
            if button == 1:
                if device.full_id() in self.config['devices']:
                    del self.config['devices'][device.full_id()]
                    self.save_config()
                    print(f"Deleted device: {device.name}")
                    self.refresh_devices()
        except GLib.Error as e:
            print(f"Delete dialog error: {e}")

    def on_sync_device(self, device):
        """Sync a device"""
        if device.is_mounted():
            self.show_device_dialog(device)

    def on_close_request(self, widget):
        """Hide window instead of closing when close button is clicked"""
        self.set_visible(False)
        return True  # Prevent the window from actually closing


class AutoSyncHelperApplication(Gtk.Application):
    def __init__(self, start_hidden=False):
        super().__init__(application_id=app_id)
        self.window = None
        self.start_hidden = start_hidden

    def do_activate(self):
        """Create the main window or show existing one"""
        if self.window is None:
            # First activation - create window and hold app alive
            self.hold()
            write_pid_file()
            self.connect("shutdown", lambda app: cleanup_pid_file())
            self.window = AutoSyncHelperApp(self)
            print(f"{app_name} started - listening for devices")
            if self.start_hidden:
                self.window.set_visible(False)
            else:
                self.window.present()
        else:
            # Subsequent activation - just show window
            self.window.present()


def install_desktop_entries():
    """Install .desktop files for application menu and autostart"""
    desktop_dir = xdg_data_home / "applications"
    autostart_dir = xdg_config_home / "autostart"

    # Create directories
    desktop_dir.mkdir(parents=True, exist_ok=True)
    autostart_dir.mkdir(parents=True, exist_ok=True)

    # Desktop entry for application menu
    desktop_entry = f"""[Desktop Entry]
Type=Application
Name=Auto Sync Helper
Comment=Monitor USB devices and sync files
Exec=auto-sync-helper.py
Icon=drive-removable-media
Categories=Utility;
Keywords=usb;sync;storage;
"""

    desktop_file = desktop_dir / f"{app_id}.desktop"
    desktop_file.write_text(desktop_entry)
    print(f"Created: {desktop_file}")

    # Autostart entry (runs with --hide flag)
    autostart_entry = f"""[Desktop Entry]
Type=Application
Name=Auto Sync Helper
Exec=auto-sync-helper.py --hide
Icon=drive-removable-media
X-GNOME-Autostart-enabled=true
"""

    autostart_file = autostart_dir / f"{app_id}.desktop"
    autostart_file.write_text(autostart_entry)
    print(f"Created: {autostart_file}")

    # Update desktop database
    try:
        subprocess.run(["update-desktop-database", str(desktop_dir)], check=False)
        print(f"Updated desktop database")
    except FileNotFoundError:
        print("Note: update-desktop-database not found, but entries are installed")

    print("\nInstallation complete!")


@dataclass
class CliApp(Cli):
    '''
    Monitor USB devices and sync files
    '''

    hide: bool = cli_field('--hide', '-H', help='Start hidden in background')
    kill: bool = cli_field('--kill', '-K', help='Kill existing instance')
    install: bool = cli_field('--install', help='Install desktop entries')


if __name__ == "__main__":
    args = CliApp().parse_args()
    if args.install:
        install_desktop_entries()
    elif args.kill:
        kill_existing_instance()
    else:
        app = AutoSyncHelperApplication(start_hidden=args.hide)
        sys.exit(app.run(None))
