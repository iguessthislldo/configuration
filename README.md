# Linux Configuration Files

My framework for my configuration/dot files.

## Setup

1. Make sure these programs are installed:
    - Zsh
    - Neovim
    - Git
    - GnuPG
2. Create a `/data` directory (TODO: Ability to have it somewhere else?)
3. Place this repository at `/data/configuration`.
4. `git submodule init && git submodule update`
5. `bash install_data.sh` to do the initial setup, clearing existing default
   stuff in the home directory and repeating the command as necessary until
   it's able to finish.
6. Set Zsh as the default shell, for example: `chsh -s /usr/bin/zsh`
7. At this point now or later we can either run `zsh` mannually or relogin to
   have it take its place as the default shell.
7. `bash install_data.sh import HOST` where `HOST` is the ssh argument for
   the computer to copy private files from. Make sure an SSH server is
   installed and running.
8. `bash install_data.sh` one final time to have it take up the imported files.
9. Set terminal font if desired.
10. `cd ~/cfg/git ; bash setup.sh` to setup Git.

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
