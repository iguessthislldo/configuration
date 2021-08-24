alias venv='python3 -m venv .venv'
alias activate='$(/usr/bin/ps -cp "$$" -o command="") $CONFIG/sh/recursive-source-for-new-shell.sh .venv/bin/activate venv'
