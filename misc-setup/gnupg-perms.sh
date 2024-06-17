#!/bin/bash
set -e

sudo chown -R $(whoami) gnupg
sudo find gnupg -type f | xargs -I {} chmod 600 {}
sudo find gnupg -type d | xargs -I {} chmod 700 {}
