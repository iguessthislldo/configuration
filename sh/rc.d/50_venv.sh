alias venv='virtualenv -p /usr/bin/python3 .venv'
alias activate='dir=$(pwd); while [[ ! -f .venv/bin/activate && "$(pwd)" != "/" ]]; do; cd ..; done; source .venv/bin/activate; cd $dir; unset dir'
