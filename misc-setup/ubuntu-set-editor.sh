set -e

editor="$(which "$EDITOR")"
echo "$editor"
sudo update-alternatives --install /usr/bin/editor editor "$editor" 1
sudo update-alternatives --set editor "$editor"
