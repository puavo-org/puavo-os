// Copyright (C) 2017 Opinsys Oy
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


const Gio = imports.gi.Gio;
const Main = imports.ui.main;

var enabled = false;
var gsettings = null;

function enable() {
    enabled = true;

    gsettings = new Gio.Settings({ schema_id: 'org.gnome.puavo' });
    gsettings.connect('changed::show-power-indicator', update_status);

    update_status();
}

function update_status() {
    if (!enabled)
	return;

    if (gsettings.get_boolean('show-power-indicator')) {
        Main.panel.statusArea.aggregateMenu._power.indicators.show();
    } else {
        Main.panel.statusArea.aggregateMenu._power.indicators.hide();
    }
}

function disable() {
    enabled = false;
    Main.panel.statusArea.aggregateMenu._power.indicators.show();
}
