const Main                = imports.ui.main;
const St                  = imports.gi.St;
const Util                = imports.misc.util;

const panelBox            = Main.layoutManager.panelBox;
const activities_actor    = Main.panel.statusArea.activities.actor;
const aggregateMenu_actor = Main.panel.statusArea.aggregateMenu.actor;
const appMenu_actor       = Main.panel.statusArea.appMenu.actor;
const dateMenu            = Main.panel.statusArea.dateMenu;
const keyboard_actor      = Main.panel.statusArea.keyboard.actor;

let old_state;
let launcherBox;

function init() {
}

function enable() {
    let primaryMonitor = Main.layoutManager.primaryMonitor;

    let launcherBox = new St.BoxLayout(
        {
            name: "launcherBox",
            vertical: true
        });

    let launchChromiumIcon = new St.Icon(
        {
            icon_name: "chromium",
            reactive: true,
            track_hover: true,
            style_class: "launcher-box-item"
        });
    launchChromiumIcon.connect('button-press-event',
                               function() { Util.spawn(["chromium"]) });

    let launchGnomeClocksIcon = new St.Icon(
        {
            icon_name: "gnome-clocks",
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

    let launchWebmenuIcon = new St.Icon(
        {
            icon_name: "webmenu",
            reactive: true,
            track_hover: true,
            style_class: "launcher-box-item"
        });
    launchWebmenuIcon.connect('button-press-event',
                              function() { Util.spawn(["webmenu-spawn"]) })

    launcherBox.add_child(launchChromiumIcon);
    launcherBox.add_child(launchGnomeClocksIcon);
    launcherBox.add_child(launchNautilusIcon);
    launcherBox.add_child(launchWebmenuIcon);

    Main.layoutManager.addChrome(launcherBox);
    launcherBox.width = 80;
    launcherBox.set_position(primaryMonitor.width - launcherBox.width, 100);

    // Save the original state so that we can rollback when this
    // extension is disabled.
    old_state = {
        activities_visibility    : activities_actor.visible,
        aggregateMenu_visibility : aggregateMenu_actor.visible,
        appMenu_parent           : appMenu_actor.get_parent(),
        dateMenu_parent          : dateMenu.actor.get_parent(),
        dateMenu_sensitivity     : dateMenu.actor.can_focus,
        keyboard_parent          : keyboard_actor.get_parent(),
        panelBox_anchor_point    : panelBox.get_anchor_point(),
        searchEntryVisibility    : Main.overview._searchEntry.visible
    };

    // Unnecessary elements must go. Less is more.
    activities_actor.hide();
    aggregateMenu_actor.hide();
    dateMenu.setSensitive(false);
    Main.overview._searchEntry.hide();

    appMenu_actor.reparent(Main.panel._rightBox);
    dateMenu.actor.reparent(Main.panel._centerBox);
    keyboard_actor.reparent(Main.panel._leftBox);
}

function disable() {
    panelBox.set_anchor_point(old_state.panelBox_anchor_point[0],
                              old_state.panelBox_anchor_point[1]);

    if (old_state.activities_visibility)
        activities_actor.show();

    if (old_state.aggregateMenu_visibility)
        aggregateMenu_actor.show();

    if (old_state.searchEntry_visibility)
        Main.overview._searchEntry.show();

    dateMenu.setSensitive(old_state.dateMenu_sensitivity);
    dateMenu.actor.reparent(old_state.dateMenu_parent);
    appMenu_actor.reparent(old_state.appMenu_parent);
    keyboard_actor.reparent(old_state.keyboard_parent);
}
