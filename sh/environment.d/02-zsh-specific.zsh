# It seems like some packages install completions here, but it's not included
# by default on Debian based systems.
# https://github.com/flox/flox/issues/2747
fpath=($fpath /usr/share/zsh/site-functions/)
