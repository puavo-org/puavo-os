/*********************************************************************
* The LogOutButton is Copyright (C) 2016 Kyle Robbertze
* African Institute for Mathematical Sciences, South Africa
*
* LogOutButton is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License version 3 as
* published by the Free Software Foundation.
*
* LogOutButton is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with LogOutButton.  If not, see <http://www.gnu.org/licenses/>.
**********************************************************************/

const Gettext = imports.gettext;
const ExtensionUtils = imports.misc.extensionUtils;
const Main = imports.ui.main;
const Me = ExtensionUtils.getCurrentExtension();
const Convenience = Me.imports.convenience;
const _ = Gettext.gettext;
const PopupMenu = imports.ui.popupMenu;
const System = Main.panel.statusArea.aggregateMenu._system;
const Clutter = imports.gi.Clutter;
const St = imports.gi.St;

let _logoutButton = null;

/**
 * Initialises the extension
function init() {
    Convenience.initTranslations();
}

/*
 * Enables the extension
 */
function enable () {

     // If a separator line is the last item in a menu, GNOME automatically hides it.
     // This isn't what we want, so create a zero-sized "fake" menuitem after the
     // separator, so it won't be the last. Thanks, GNOME.
     var foof = new PopupMenu.PopupBaseMenuItem({
         reactive: false,
         can_focus: false,
         style_class: "foof",
     });

     // Hide the user switcher menu item
     Main.panel.statusArea.aggregateMenu._system._switchUserSubMenu.actor.destroy();

     // Add the fake menuitem at the end, so the separator won't be the last
     Main.panel.statusArea.aggregateMenu._system.menu.addMenuItem(foof, 0);

    _logoutButton = System._createActionButton('application-exit-symbolic', _("Log Out"));
    _logoutButton.connect('button-press-event', _logout);
    if (System._session === undefined) { // GNOME >=3.26
        System._actionsItem.actor.add_child(_logoutButton);
    } else {
        System._actionsItem.actor.add_child(_logoutButton, { expand: true, x_fill: false });
    }
}

/*
 * Disables the extension
 */
function disable () {
    System._actionsItem.actor.remove_child(_logoutButton);
}

/*
 * Initiates a log out when the log out button is clicked
 */
function _logout () {
    System.menu.itemActivated();
    Main.overview.hide();
    if (System._session === undefined) { // GNOME >=3.26
        System._systemActions.activateLogout();
    } else {
        System._session.LogoutRemote(0)
    }
}
