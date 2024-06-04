if command -v fc-cache &> /dev/null
then
    InstallDir .local/share
    InstallLink .local/share/fonts
    InstallRun fc-cache -f -v .
    ExportFiles "-name '*.otf' -o -name '*.ttf'"
else
    echo "fc-cache command not available"
fi
