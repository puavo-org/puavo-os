// Copyright (C) 2026 Opinsys Oy
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

import * as Extension from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

export default class HideOverviewSearchExtension extends Extension.Extension {
    enable() {
        const controls = Main.overview._overview.controls;

        this._searchController = controls._searchController;

        // store original methods
        this._origStartSearch = this._searchController.startSearch;
        this._origSetSearchActive = this._searchController.setSearchActive;

        // disable search activation
        this._searchController.startSearch = () => {};
        this._searchController.setSearchActive = () => {};

        // hide entry
        Main.overview._overview._controls._searchEntry.hide();
    }

    disable() {
        Main.overview._overview._controls._searchEntry.show();

        if (this._origStartSearch)
            this._searchController.startSearch = this._origStartSearch;

        if (this._origSetSearchActive)
            this._searchController.setSearchActive = this._origSetSearchActive;
    }
}
