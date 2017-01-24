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

const Clutter             = imports.gi.Clutter;
const Gio                 = imports.gi.Gio;
const Main                = imports.ui.main;
const St                  = imports.gi.St;
const Util                = imports.misc.util;

const activities_actor    = Main.panel.statusArea.activities.actor;
const aggregateMenu_actor = Main.panel.statusArea.aggregateMenu.actor;
const appMenu_actor       = Main.panel.statusArea.appMenu.actor;
const dateMenu            = Main.panel.statusArea.dateMenu;
const keyboard_actor      = Main.panel.statusArea.keyboard.actor;

const OnboardInterface = '                        \
<node>                                            \
  <interface name="org.onboard.Onboard.Keyboard"> \
    <method name="ToggleVisible">                 \
    </method>                                     \
    <method name="Show">                          \
    </method>                                     \
    <method name="Hide">                          \
    </method>                                     \
  </interface>                                    \
</node>                                           \
'

let old_state;
let launcherBox;
let onboardProxy;

function _toggleOverview()
{
    if (Main.overview.visible)
        Main.overview.hide();
    else
        Main.overview.show();
}

function init() {
    onboardProxy = new Gio.DBusProxy.makeProxyWrapper(OnboardInterface)(
        Gio.DBus.session,
        "org.onboard.Onboard",
        "/org/onboard/Onboard/Keyboard"
    );
}

function enable() {
    let primaryMonitor = Main.layoutManager.primaryMonitor;

    launcherBox = new St.BoxLayout(
        {
            name: "launcherBox",
            vertical: true
        });

    let launchGnomeCalculatorIcon = new St.Icon(
        {
            icon_name: "gnome-calculator",
            reactive: true,
            track_hover: true,
            style_class: "launcher-box-item"
        });
    launchGnomeCalculatorIcon.connect('button-press-event',
                                  function() { Util.spawn(["gnome-calculator"]) });

    let launchCheeseIcon = new St.Icon(
        {
            icon_name: "org.gnome.Cheese",
            reactive: true,
            track_hover: true,
            style_class: "launcher-box-item"
        });
    launchCheeseIcon.connect('button-press-event',
                                  function() { Util.spawn(["cheese"]) });

    let launchOpenboardIcon = new St.Icon(
        {
            icon_name: "OpenBoard",
            reactive: true,
            track_hover: true,
            style_class: "launcher-box-item"
        });
    launchOpenboardIcon.connect('button-press-event',
                                  function() { Util.spawn(["openboard"]) });


    let launchChromeIcon = new St.Icon(
        {
            icon_name: "google-chrome",
            reactive: true,
            track_hover: true,
            style_class: "launcher-box-item"
        });
    launchChromeIcon.connect('button-press-event',
                               function() { Util.spawn(["google-chrome-stable"]) });

    let launchGnomeClocksIcon = new St.Icon(
        {
            icon_name: "org.gnome.clocks",
            reactive: true,
            track_hover: true,
            style_class: "launcher-box-item"
        });
    launchGnomeClocksIcon.connect('button-press-event',
                                  function() { Util.spawn(["gnome-clocks"]) });

    let launchNautilusIcon = new St.Icon(
        {
            icon_name: "system-file-manager",
            reactive: true,
            track_hover: true,
            style_class: "launcher-box-item"
        });
    launchNautilusIcon.connect('button-press-event',
                               function() { Util.spawn(["nautilus"]) });

    let launchQuitIcon = new St.Icon(
        {
            icon_name: "system-log-out",
            reactive: true,
            track_hover: true,
            style_class: "launcher-box-item"
        });
    launchQuitIcon.connect('button-press-event',
                              function() { Util.spawn(["gnome-session-quit"]) });

    let toggleOnboardIcon = new St.Icon(
        {
            icon_name: "input-keyboard-symbolic",
            reactive: true,
            track_hover: true,
            style_class: "launcher-box-item"
        });
    toggleOnboardIcon.connect('button-press-event',
                              function() { onboardProxy.ToggleVisibleSync() });

    let toggleOverviewIcon = new St.Icon(
        {
            icon_name: "preferences-system-windows",
            reactive: true,
            track_hover: true,
            style_class: "launcher-box-item"
        });
    toggleOverviewIcon.connect('button-press-event', _toggleOverview);

    launcherBox.add_child(launchGnomeCalculatorIcon);
    launcherBox.add_child(launchCheeseIcon);
    launcherBox.add_child(launchChromeIcon);
    launcherBox.add_child(launchGnomeClocksIcon);
    launcherBox.add_child(launchNautilusIcon);
    launcherBox.add_child(launchQuitIcon);
    launcherBox.add_child(toggleOnboardIcon);
    launcherBox.add_child(toggleOverviewIcon);

    Main.layoutManager.addChrome(launcherBox, { affectsStruts: true });
    launcherBox.set_anchor_point_from_gravity(Clutter.Gravity.EAST);
    launcherBox.set_position(primaryMonitor.width, primaryMonitor.height / 2);

    // Save the original state so that we can rollback when this
    // extension is disabled.
    old_state = {
        activities_visibility    : activities_actor.visible,
        aggregateMenu_visibility : aggregateMenu_actor.visible,
        appMenu_parent           : appMenu_actor.get_parent(),
        dateMenu_parent          : dateMenu.actor.get_parent(),
        dateMenu_sensitivity     : dateMenu.actor.can_focus,
        dashVisible              : Main.overview._dash.actor.visible,
        keyboard_parent          : keyboard_actor.get_parent(),
        searchEntryVisibility    : Main.overview._searchEntry.visible,
        keyboard_show_function   : Main.keyboard.Show
    };

    // Unnecessary elements must go. Less is more.
    activities_actor.hide();
    aggregateMenu_actor.hide();
    dateMenu.setSensitive(false);
    Main.overview._searchEntry.hide();
    Main.overview._dash.actor.hide();
    Main.panel.actor.hide();
    // XXX Uncomment following code if top panel is needed back
    // appMenu_actor.reparent(Main.panel._rightBox);
    // dateMenu.actor.reparent(Main.panel._centerBox);
    // keyboard_actor.reparent(Main.panel._leftBox);

    global.stage.get_actions().forEach(function(action) {
        if (action instanceof imports.ui.edgeDragAction.EdgeDragAction)
            action.enabled = false;
    });

    Main.keyboard.Show = function() {};
}

function disable() {
    Main.layoutManager.removeChrome(launcherBox);

    if (old_state.activities_visibility)
        activities_actor.show();

    if (old_state.aggregateMenu_visibility)
        aggregateMenu_actor.show();

    if (old_state.searchEntry_visibility)
        Main.overview._searchEntry.show();

    if (old_state.dashVisible)
        Main.overview._dash.actor.show();

    dateMenu.setSensitive(old_state.dateMenu_sensitivity);
    dateMenu.actor.reparent(old_state.dateMenu_parent);
    appMenu_actor.reparent(old_state.appMenu_parent);
    keyboard_actor.reparent(old_state.keyboard_parent);

    Main.keyboard.Show = old_state.keyboard_show_function;
}
