# Run in a temp shell using:
#   $(/usr/bin/ps -cp "$$" -o command="") setenv-shell.sh

dir="$(pwd)"
while [[ ! -f setenv.sh && "$(pwd)" != "/" ]]
do
    cd ..
done
if [ ! -f setenv.sh ]
then
    echo "ERROR: Couldn't find a setenv.sh" 1>&2
    exit 1
fi
source setenv.sh
cd "$dir"
unset dir

exec $(/usr/bin/ps -cp "$$" -o command="") -i
