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
const Lang = imports.lang;

let logout_button, menu_button;

function make_button(icon_name, icon_size, spawn_command, is_right) {
    let button = new St.Bin({ can_focus:   true,
			      reactive:    true,
			      style_class: 'panel-button-webmenu',
			      track_hover: true,
			      x_fill:      true,
			      y_fill:      false });
    let icon = new St.Icon({ icon_name:   icon_name,
                             style_class: 'launcher-box-item-webmenu',
                             icon_size: icon_size});

    button.set_child(icon);

    button.connect("button-press-event", Lang.bind(this, function() {
        let [x, y] = button.get_transformed_position();

        // align to the right edge
        if (is_right)
            x += button.get_transformed_size()[0];

        let finalCmd = spawn_command.slice();  // slice=a new copy of the array

        finalCmd.push("--pos=" + Math.ceil(x) + "," + Math.ceil(y));
        Util.spawn(finalCmd);
    }));

    return button;
}

function init() {
    logout_button = make_button('system-shutdown-symbolic',
				'16',
				[ 'webmenu-spawn', '--logout' ], true);
    menu_button   = make_button('start-here-debian-symbolic',
				'28',
				[ 'webmenu-spawn' ], false);
}

function disable() {
    Main.panel._leftBox.remove_child(menu_button);
    Main.panel._rightBox.remove_child(logout_button);
}

function enable() {
    Main.panel._leftBox.insert_child_at_index(menu_button,    0);
    Main.panel._rightBox.insert_child_at_index(logout_button, -1);
}
