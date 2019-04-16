/* Desktop Icons GNOME Shell extension
 *
 * Copyright (C) 2017 Carlos Soriano <csoriano@redhat.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

const Main = imports.ui.main;

const ExtensionUtils = imports.misc.extensionUtils;
const Me = ExtensionUtils.getCurrentExtension();
const Prefs = Me.imports.prefs;
const { DesktopManager } = Me.imports.desktopManager;
const DBusUtils = Me.imports.dbusUtils;

var desktopManager = null;
var addBackgroundMenuOrig = null;
var _startupPreparedId;
var lockActivitiesButton = false;

var oldShouldToggleByCornerOrButtonFunction = null;

function init() {
    addBackgroundMenuOrig = Main.layoutManager._addBackgroundMenu;

    Prefs.initTranslations();
}

function newShouldToggleByCornerOrButton() {
    if (lockActivitiesButton)
        return false;
    else
        return oldShouldToggleByCornerOrButtonFunction.bind(Main.overview);
}

function enable() {
    // register a new function to allow to lock the Activities button when doing a rubberband selection
    oldShouldToggleByCornerOrButtonFunction = Main.overview.shouldToggleByCornerOrButton;
    Main.overview.shouldToggleByCornerOrButton = newShouldToggleByCornerOrButton;
    // wait until the startup process has ended
    if (Main.layoutManager._startingUp)
        _startupPreparedId = Main.layoutManager.connect('startup-complete', () => innerEnable(true));
    else
        innerEnable(false);
}

function innerEnable(disconnectSignal) {
    if (disconnectSignal)
        Main.layoutManager.disconnect(_startupPreparedId);
    DBusUtils.init();
    Prefs.init();
    Main.layoutManager._addBackgroundMenu = function() {};
    desktopManager = new DesktopManager();
}

function disable() {
    desktopManager.destroy();
    Main.layoutManager._addBackgroundMenu = addBackgroundMenuOrig;
    Main.overview.shouldToggleByCornerOrButton = oldShouldToggleByCornerOrButtonFunction;
}
