# Linux Configuration Files

My framework for my configuration/dot files.

## Setup

1. Make sure these programs are installed:
    - Zsh
    - Neovim
    - Git
    - GnuPG
    - xclip
   For Debian: `sudo apt install zsh gnupg git xclip`
2. Create a `/data` directory (TODO: Ability to have it somewhere else?)
3. Place this repository at `/data/configuration`.
4. `git submodule init && git submodule update`
5. `bash install_data.sh` to do the initial setup, clearing existing default
   stuff in the home directory and repeating the command as necessary until
   it's able to finish.
6. Set Zsh as the default shell, for example: `chsh -s /usr/bin/zsh`
7. At this point now or later we can either run `zsh` manually or relogin to
   have it take its place as the default shell.
7. `bash install_data.sh import HOST` where `HOST` is the ssh argument for
   the computer to copy private files from. Make sure an SSH server is
   installed and running.
8. `bash install_data.sh` one final time to have it take up the imported files.
9. Set terminal font if desired.
10. Run `(cd ~/cfg/git && bash setup.sh)` to setup Git.
11. Run scripts in `misc-setup` as needed.

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
