#!/usr/bin/env bash
# 
# Script to associate file types to desired apps using:
#   * their .desktop files
#   * in a custom order (last to be set overrides previous ones)
#   * with custom associations, if so desired.
# See the configuration below for practical examples.

# Bash checks
set -o nounset    # always check if variables exist
set -o errexit    # always exit on error
set -o pipefail   # don't ignore exit codes when piping output

# System-specific locations of .desktop files, hopefully covering all scenarios.
declare -a xdg_dirs=(
    "/usr/share/applications"
    "/usr/local/share/applications"
    "/var/lib/flatpak/exports/share/applications"
    "$HOME/.local/share/flatpak/exports/share/applications"
)

## Simple setup using native GTK+ 3.x apps.
declare -a apps=(
    firefox thunderbird pcmanfm lxshortcut mpv deadbeef xarchiver
    abiword org.onlyoffice.desktopeditors org.gnumeric.gnumeric
    org.gnome.font-viewer org.gnome.Evince org.gnome.eog org.gnome.gedit
)

# Intermediate setup with a mix of native GTK+ 3 / GTK 4 apps.
#declare -a apps=(
#    firefox thunderbird mpv deadbeef
#    libreoffice-writer libreoffice-calc libreoffice-draw libreoffice-impress
#    org.gnome.Nautilus org.gnome.Papers org.gnome.Loupe org.gnome.FileRoller
#    org.gnome.font-viewer org.gnome.TextEditor
#)

## Complex setup using only Flatpak apps.
#declare -a apps=(
#    org.telegram.desktop org.signal.Signal
#    org.libreoffice.LibreOffice.writer org.libreoffice.LibreOffice.calc
#    org.libreoffice.LibreOffice.draw org.libreoffice.LibreOffice.impress
#    org.mozilla.firefox org.mozilla.Thunderbird org.gnome.Totem
#    org.gnome.Calls org.gnome.Maps org.gnome.Evince
#    com.github.johnfactotum.Foliate org.gnome.Loupe org.gnome.FileRoller
#    org.gnome.font-viewer org.gnome.TextEditor
#)

# Here's how to override what is set above for any MIME type.
# Using _ instead of / because of shell limitations.
mime_types_with_custom_handlers=(
    application_json
    text_xml
    font_collection
)
# Define the app handling each MIME type above.
application_json="org.gnome.org.gnome.gedit"
text_xml="org.gnome.org.gnome.gedit"
font_collection="org.gnome.font-viewer"


# This is where the action begins, no more configuration.
if [ -f  ~/.config/mimeapps.list ]; then
    echo "Backing up old list to ~/.config/mimeapps.list.bak ..."
    mv ~/.config/mimeapps.list ~/.config/mimeapps.list.bak
fi

for app in "${apps[@]}"; do
    desktop_file="$app".desktop
    app_found=0
    for xdg_dir in "${xdg_dirs[@]}"; do
        if [ -r "$xdg_dir"/"$desktop_file" ]; then
            app_found=1
            cd "$xdg_dir"
            mime_types="$(grep 'MimeType=' $desktop_file | sed -e 's/.*=//' -e 's/;/ /g')"
            echo "    Setting default MIME types for ${app}: $mime_types"
            # Do not quote $mime_types.
            xdg-mime default "$desktop_file" $mime_types
            break
        fi
    done
    if [ $app_found -eq 0 ]; then
        (>&2 echo -e "    No desktop file found for $app at:\n    ${xdg_dirs[*]}")
        exit 13
    fi
done

for mime_type in "${mime_types_with_custom_handlers[@]}"; do
    # Reconstruct the MIME type from the variable name.
    real_mime_type=${mime_type//_/\/}
    echo "    Setting custom MIME type for ${!mime_type}: $real_mime_type"
    # This uses Bash indirection.
    xdg-mime default "${!mime_type}".desktop "$real_mime_type"
done
