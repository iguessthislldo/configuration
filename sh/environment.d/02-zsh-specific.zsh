# It seems like some packages install completions here, but it's not included
# by default on Debian based systems.
# https://github.com/flox/flox/issues/2747
fpath=($fpath /usr/share/zsh/site-functions/)

function _igtd_warn_about_compinit {
  local -aU insecure_dirs
  insecure_dirs=( ${(f@):-"$(compaudit 2>/dev/null)"} )

  # If no such directories exist, get us out of here.
  [[ -z "${insecure_dirs}" ]] && return

  # List ownership and permissions of all insecure directories.
  print "Insecure completion-dependent directories detected:"
  ls -ld "${(@)insecure_dirs}"
}
_igtd_warn_about_compinit
