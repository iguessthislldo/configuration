InstallDir .local/share
InstallLink .local/share/fonts
InstallRun fc-cache -f -v .
ExportFiles "-name '*.otf' -o -name '*.ttf'"
