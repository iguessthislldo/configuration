set -e

sudo snap remove firefox

# Prevent Firefox snap from coming back
echo '
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
' | sudo tee /etc/apt/preferences.d/mozilla-firefox
echo '
Package: firefox*
Pin: release o=Ubuntu*
Pin-Priority: -1
' | sudo tee /etc/apt/preferences.d/block-mozilla-firefox-snap

# Allow automatic updates
echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:${distro_codename}";' | \
    sudo tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox

# Install Firefox from Mozilla's PPA
sudo add-apt-repository ppa:mozillateam/ppa
sudo apt install firefox

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
