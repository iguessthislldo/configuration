# Linux Configuration Files

My framework for my configuration/dot files.

## Setup

- Install [Flox](https://flox.dev/docs/install-flox/)
- Make sure these programs are installed:
    - Zsh
    - GnuPG
    - xclip (optional?)
    - git
    - Ex: `sudo apt install zsh gnupg xclip git`
- Create a `/data` directory (TODO: Ability to have it somewhere else?)
    - `cd /`
    - `sudo mkdir /data`
    - `sudo chown $USER:$USER /data`
- Place/clone this repository at `/data/configuration`.
    - `cd /data`
    - `git clone --recurse-submodules https://github.com/iguessthislldo/configuration`
    - `cd configuration`
- `bash install_data.sh` to do the initial setup, clearing existing default
  stuff in the home directory and repeating the command as necessary until
  it's able to finish.
    - If the destination system is running a SSH server you're using to do
      this, it could make new logins impossible:
      (`Permission denied (publickey)`) because the `.ssh` directory was
      replaced with a symlink.
- Set Zsh as the default shell, for example: `chsh -s /usr/bin/zsh`
- At this point now or later we can either run `zsh` manually or relogin to
  have it take its place as the default shell.
- If copying from an existing `/data` on a source system:
    - To copy files using SSH:
        - Make sure an SSH server is installed and running on the source
          system.
        - Run `bash install_data.sh import HOST` where `HOST` on the
          destination system.
    - To copy files manually:
        - Run `bash install_data.sh export` on the source system.
        - Copy **`/data/configuration/export.txz` to `/data/export.txz`** on
          the destination system.
        - Run `bash install_data.sh import` on destination system.
    - `bash install_data.sh` one final time to have it take up the imported
      files.
- Set terminal font if desired.
- Run `(cd ~/cfg/git && bash setup.sh)` to setup Git.
- Run scripts in `misc-setup` as needed.

## Directory Structure

- `data`: Used for `$DATA`, Linked as `$HOME\dat`
    - `configuration`: Used for `$CONFIG`, Linked as `$HOME/cfg`
        - `install_data.sh`
        - `sh`
        - `bin`
        - `fonts`
        - `ssh`
        - `vim`
        - `git`
        - `tmux`
        - `vim`
        - `gnupg`

## Usage

### Aliases and Scripts Added to `PATH`

This doesn't include `sh/rc.d/50_aliases.sh` or aliases added by oh-my-zsh in
`sh/rc.d/00_oh-my-zsh.zsh`.

#### `u`

Usage: `u [COUNT]`

Move up COUNT number of directories, like `cd (../)*COUNT`. COUNT is 1 by
default.

#### `e`

Usage: `e [ARGS...]`

Python script that passes arguments through to `$EDITOR`.

If the `$EDITOR` has `vi` in the name, then it assumes it's vi-compatible and
will change arguments of the form `FILENAME:NUMBER` to `FILENAME +NUMBER`.

#### `gitid`

Set predefined git commit identity information for a repository.

See `gitid -h` for usage.

TODO: Info on how to setup identities

#### `new`

Create copies of a template directory, optionally automatically replacing
macros and executing scripts.

See `new -h` for usage.

TODO: More info, like how to setup templates

#### `makej`

Usage: `makej [ARGS...]`

Run `make` with `ARGS`, but also pass `-j` and the number of CPU cores plus 1.

#### `setenv`

Command checks the current directory and all of its parents for `setenv.sh`,
and starts an instance of the current shell with that `setenv.sh` sourced.

#### `activate`

Command checks the current directory and all of its parents for a Python
virtualenv, and starts an instance of the current shell with that virtualenv
activated.

#### `rrun`

Recursively check the current directory and all of its parents for a file with
an execute permission on it and executes it.

#### `args`

Usage: `args [ARGS...]`

Simple python script that lists the arguments it was passed. Use to see how the
shell is passing arguments to a program.

#### `h`

Usage: `h DAYS`

Print the shell history for the given number of days ago, which can be 0 for
today.

NOTE: Only works with zsh
