// Copyright (C) 2016 Opinsys Oy
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

const Main = imports.ui.main;
const St   = imports.gi.St;
const Util = imports.misc.util;

let logout_button, menu_button;

function make_button(icon_name, spawn_command) {
    let button = new St.Bin({ can_focus:   true,
			      reactive:    true,
			      style_class: 'panel-button',
			      track_hover: true,
			      x_fill:      true,
			      y_fill:      false });
    let icon = new St.Icon({ icon_name:   icon_name,
                             style_class: 'launcher-box-item' });

    button.set_child(icon);
    button.connect('button-press-event',
		  function() { Util.spawn(spawn_command); });

    return button;
}

function init() {
    logout_button = make_button('webmenu',
				[ 'webmenu-spawn', '--logout' ]);
    menu_button   = make_button('webmenu-logout',
				[ 'webmenu-spawn' ]);
}

function disable() {
    Main.panel._leftBox.remove_child(menu_button);
    Main.panel._rightBox.remove_child(logout_button);
}

function enable() {
    Main.panel._leftBox.insert_child_at_index(menu_button,    0);
    Main.panel._rightBox.insert_child_at_index(logout_button, -1);
}
