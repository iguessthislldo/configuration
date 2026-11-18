#!/bin/bash

set -e

# Disable wakeup on input devices (keyboard, touchpad, etc.) except power/sleep buttons
sudo cp $CONFIG/misc-setup/disable-wake.sh /usr/local/bin/disable-wake.sh
sudo cp $CONFIG/misc-setup/disable-wake.service /etc/systemd/system
sudo systemctl daemon-reload
sudo systemctl enable disable-wake.service
sudo systemctl start disable-wake.service

# Ignore lid closing
sudo sed -E --in-place -e 's/^#?(HandleLidSwitch\w*)=\w+$/\1=ignore/g' /etc/systemd/logind.conf
echo "logind.conf changed — reboot for it to take effect"
