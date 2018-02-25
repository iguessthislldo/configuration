# PATH
export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.gem/ruby/2.4.0/bin:$PATH"

# Aliases
source $CONFIG/aliases

# Profile
for f in $CONFIG/profile.d/*
do
    source $f
done
unset f
