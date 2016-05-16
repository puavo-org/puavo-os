const Gio                 = imports.gi.Gio;
const Main                = imports.ui.main;
const St                  = imports.gi.St;

const panelBox            = Main.layoutManager.panelBox;
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
';

let old_state;
let onboardProxy;
let toggleKeyboardButton;

function _toggleOnboard() {
    onboardProxy.ToggleVisibleSync();
}

function init() {
    toggleKeyboardButton = new St.Button(
    {
            style_class : 'panel-status-button'
    });
    let icon = new St.Icon(
        {
            icon_name   : 'input-keyboard-symbolic',
            style_class : 'system-status-icon'
        });

    toggleKeyboardButton.set_child(icon);
    toggleKeyboardButton.connect('clicked', _toggleOnboard);

    onboardProxy = new Gio.DBusProxy.makeProxyWrapper(OnboardInterface)(
        Gio.DBus.session,
        "org.onboard.Onboard",
        "/org/onboard/Onboard/Keyboard"
    );
}

function enable() {
    let primaryMonitorHeight = Main.layoutManager.primaryMonitor.height;

    // Save the original state so that we can rollback when this
    // extension is disabled.
    old_state = {
        activities_visibility    : activities_actor.get_paint_visibility(),
        aggregateMenu_visibility : aggregateMenu_actor.get_paint_visibility(),
        appMenu_parent           : appMenu_actor.get_parent(),
        dateMenu_parent          : dateMenu.actor.get_parent(),
        dateMenu_sensitivity     : dateMenu.actor.can_focus,
        keyboard_parent          : keyboard_actor.get_parent(),
        panelBox_anchor_point    : panelBox.get_anchor_point()
    };

    // Bottom is the best for big/huge screens, short users might not
    // be able to reach the top.
    panelBox.set_anchor_point(0, -primaryMonitorHeight + panelBox.height);

    // Unnecessary elements must go. Less is more.
    activities_actor.hide();
    aggregateMenu_actor.hide();
    dateMenu.setSensitive(false);

    appMenu_actor.reparent(Main.panel._rightBox);
    dateMenu.actor.reparent(Main.panel._leftBox);
    keyboard_actor.reparent(Main.panel._centerBox);

    Main.panel._centerBox.add_child(toggleKeyboardButton);
}

function disable() {
    panelBox.set_anchor_point(old_state.panelBox_anchor_point[0],
                              old_state.panelBox_anchor_point[1]);

    if (old_state.activities_visibility)
        activities_actor.show();

    if (old_state.aggregateMenu_visibility)
        aggregateMenu_actor.show();

    dateMenu.setSensitive(old_state.dateMenu_sensitivity);
    dateMenu.actor.reparent(old_state.dateMenu_parent);
    appMenu_actor.reparent(old_state.appMenu_parent);
    keyboard_actor.reparent(old_state.keyboard_parent);

    Main.panel._centerBox.remove_child(toggleKeyboardButton);
}
