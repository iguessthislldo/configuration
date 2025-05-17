set -e

sudo snap remove firefox

# Prevent Firefox snap from coming back
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1001
' | sudo tee /etc/apt/preferences.d/mozilla-firefox
echo '
Package: firefox*
Pin: release o=Ubuntu*
Pin-Priority: -1
' | sudo tee /etc/apt/preferences.d/block-mozilla-firefox-snap

# Import mozilla's keys
sudo install -d -m 0755 /etc/apt/keyrings
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null
sudo apt-get update && sudo apt-get install firefox

# DRM can crash after this: https://askubuntu.com/a/1425488
# Also allow Firefox to use /data
dir=/etc/apparmor.d
filename=usr.bin.firefox
path="$dir/$filename"
apply="git -C $dir apply"
patch="$(realpath unsnap-firefox-apparmor.patch)"
if $apply --check --reverse "$patch"
then
    echo "Patch already applied to $path"
else
    sudo $apply "$patch"
    sudo apparmor_parser --replace $path
fi
