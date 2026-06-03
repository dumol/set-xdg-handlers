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

# Choose a setup below by uncommenting it while keeping the others commented.
# App ordering matters, the associations of latter apps override previous rules.

## Simple setup using native GTK3 apps.
#declare -a apps=(
#    firefox thunderbird
#    pcmanfm lxshortcut xarchiver
#    abiword org.gnumeric.gnumeric
#    org.gnome.Evince org.gnome.gedit
#    org.gnome.eog org.gnome.Totem
#)

# Intermediate setup with native GNOME apps.
# Most apps can also be installed as Flatpak.
#declare -a apps=(
#    org.gnome.Epiphany org.gnome.Evolution org.gnome.Calls
#    org.gnome.Nautilus org.gnome.FileRoller
#    libreoffice-writer libreoffice-calc libreoffice-draw libreoffice-impress
#    org.gnome.Papers com.github.johnfactotum.Foliate org.gnome.TextEditor
#    org.gnome.Loupe org.gnome.Showtime
#)

## Complex setup using only Flatpak apps.
#declare -a apps=(
#    org.mozilla.firefox org.mozilla.Thunderbird
#    org.telegram.desktop org.signal.Signal org.gnome.Calls
#    org.gnome.Maps org.gnome.FileRoller
#    org.libreoffice.LibreOffice.writer org.libreoffice.LibreOffice.calc
#    org.libreoffice.LibreOffice.draw org.libreoffice.LibreOffice.impress
#    org.gnome.Papers com.github.johnfactotum.Foliate org.gnome.TextEditor
#    org.gnome.Loupe org.gnome.Showtime
#)

# Real-world setup.
declare -a apps=(
    firefox-esr org.gnome.Evolution
    org.signal.Signal org.gnome.Fractal org.gnome.Calls
    org.gnome.Nautilus org.gnome.FileRoller
    com.collaboraoffice.Office
    org.gnome.Papers com.github.johnfactotum.Foliate org.gnome.TextEditor
    org.gnome.Loupe mpv
    org.gnome.font-viewer
)

# Here's how to override what is set above for any MIME type.
# Using _ instead of / because of shell limitations.
mime_types_with_custom_handlers=(
    application_json
    text_xml
    font_collection
)
# Define the app handling each MIME type above.
application_json="org.gnome.TextEditor"
text_xml="org.gnome.TextEditor"
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
            if grep -q 'MimeType=' $desktop_file; then
                mime_types="$(grep 'MimeType=' $desktop_file | sed -e 's/.*=//' -e 's/;/ /g')"
                echo "    Setting default MIME types for ${app}: $mime_types"
                # Do not quote $mime_types.
                xdg-mime default "$desktop_file" $mime_types
            else
                echo "    No MIME types found for ${app}"
            fi
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
