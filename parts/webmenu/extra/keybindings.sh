#!/bin/sh

KEY=org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/
gsettings set $KEY binding '<Super>space'
gsettings set $KEY name 'Webmenu'
gsettings set $KEY command 'webmenu-spawn'
