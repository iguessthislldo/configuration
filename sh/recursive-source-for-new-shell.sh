# Moves up from the current directory to find a specific file to source. Then
# runs a new instance of the current shell to run with the new environment.
# Run in a temp shell using:
#   $(/usr/bin/ps -cp "$$" -o command="") $CONFIG/sh/recursive-source-for-new-shell.sh SOURCE_PATH
# Where SOURCE_PATH is the path of the file relative to the directory being
# checked. This is used for setenv and activate aliases.

igtd_recursive_source="$1"

if [ ! -z "${2+x}" ]
then
    igtd_add_env_name "$2"
fi

igtd_recursive_source_orig_dir="$(pwd)"

while [[ ! -f "$igtd_recursive_source" && "$(pwd)" != "/" ]]
do
    cd ..
done
if [ ! -f "$igtd_recursive_source" ]
then
    echo "ERROR: Couldn't find any $igtd_recursive_source" 1>&2
    exit 1
fi

source "$igtd_recursive_source"
unset igtd_recursive_source
cd "$igtd_recursive_source_orig_dir"
unset igtd_recursive_source_orig_dir

exec $(/usr/bin/ps -cp "$$" -o command="") -i
