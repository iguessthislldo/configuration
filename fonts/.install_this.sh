if command -v fc-cache &> /dev/null
then
    InstallLink --xdg-data fonts
    InstallRun fc-cache -f -v .
    ExportFiles "-name '*.otf' -o -name '*.ttf'"
else
    echo "fc-cache command not available"
fi
