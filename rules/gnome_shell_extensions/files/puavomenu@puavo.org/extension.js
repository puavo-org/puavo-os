// Copyright (C) 2016-2020 Opinsys Oy
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
const St = imports.gi.St;
const Util = imports.misc.util;
const Lang = imports.lang;

let menu_button;

function make_button(icon_name, icon_size, spawn_command)
{
    let button = new St.Bin({
        can_focus: true,
        reactive: true,
        style_class: 'panel-button-puavomenu',
        track_hover: true,
        x_expand: true,
        y_expand: false
    });

    let icon = new St.Icon({
        icon_name: icon_name,
        style_class: 'launcher-box-item-puavomenu',
        icon_size: icon_size
    });

    button.set_child(icon);

    button.connect("button-press-event", Lang.bind(this, function() {
        // The top-left corner of the panel button is the
        // lower-right corner of the menu
        let [x, y] = button.get_transformed_position();

        let finalCmd = spawn_command.slice();  // slice=a new copy of the array

        finalCmd.push("toggle");
        finalCmd.push("corner");
        finalCmd.push(Math.ceil(x).toString());
        finalCmd.push(Math.ceil(y).toString());

        Util.spawn(finalCmd);
    }));

    return button;
}

function init()
{
    menu_button = make_button(
        'start-here-debian-symbolic', '28',
        ['/opt/puavomenu/puavomenu-spawn' ]
    );
}

function disable()
{
    Main.panel._leftBox.remove_child(menu_button);
}

function enable()
{
    Main.panel._leftBox.insert_child_at_index(menu_button, 0);
}
