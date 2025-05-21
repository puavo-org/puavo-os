// Copyright (C) 2016-2025 Opinsys Oy
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

import St from 'gi://St';

import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as Util from 'resource:///org/gnome/shell/misc/util.js';

export default class DashToPanelExtension extends Extension {
    constructor(metadata) {
        super(metadata);
        this._menu_button = this.make_button(
            'start-here-debian-symbolic', '28',
            [ '/opt/puavomenu/puavomenu-spawn' ]
        );
    }

    make_button(icon_name, icon_size, spawn_command) {
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

        button.connect("button-press-event", () => {
            // The top-left corner of the panel button is the
            // lower-right corner of the menu
            let [x, y] = button.get_transformed_position();

            // slice=a new copy of the array
            let finalCmd = spawn_command.slice();

            finalCmd.push("toggle");
            finalCmd.push("corner");
            finalCmd.push(Math.ceil(x).toString());
            finalCmd.push(Math.ceil(y).toString());

            Util.spawn(finalCmd);
        });

        return button;
    }

    disable() {
        Main.panel._leftBox.remove_child(this._menu_button);
    }

    enable() {
        Main.panel._leftBox.insert_child_at_index(this._menu_button, 0);
    }
}
