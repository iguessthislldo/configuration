#!/bin/bash

set -ex

WINTERM_SETTINGS="$LOCALAPPDATA\\Packages\\Microsoft.WindowsTerminal_8wekyb3d8bbwe\\LocalState\\settings.json"
cp "$WINTERM_SETTINGS" "$WINTERM_SETTINGS.backup"
jq --slurpfile p "$CONFIG/misc-setup/msys2-win-term-profile.json" \
    '.profiles.list += $p | .defaultProfile = $p[0].guid' "$WINTERM_SETTINGS" > "$TEMP/settings.json"
mv "$TEMP/settings.json" "$WINTERM_SETTINGS"
