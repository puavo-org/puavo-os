const Main                = imports.ui.main;

const panelBox            = Main.layoutManager.panelBox;
const activities_actor    = Main.panel.statusArea.activities.actor;
const aggregateMenu_actor = Main.panel.statusArea.aggregateMenu.actor;
const dateMenu_actor      = Main.panel.statusArea.dateMenu.actor;

let old_state;

function init() {
}

function enable() {
    let primaryMonitorHeight = Main.layoutManager.primaryMonitor.height;

    // Save the original state so that we can rollback when this
    // extension is disabled.
    old_state = {
        activities_visibility    : activities_actor.get_paint_visibility(),
        aggregateMenu_visibility : aggregateMenu_actor.get_paint_visibility(),
        dateMenu_visibility      : dateMenu_actor.get_paint_visibility(),
        panelBox_anchor_point    : panelBox.get_anchor_point()
    };

    // Bottom is the best for big/huge screens, short users might not
    // be able to reach the top.
    panelBox.set_anchor_point(0, -primaryMonitorHeight + panelBox.height);

    // Unnecessary elements must go. Less is more.
    activities_actor.hide();
    aggregateMenu_actor.hide();
    dateMenu_actor.hide();
}

function disable() {
    panelBox.set_anchor_point(old_state.panelBox_anchor_point[0],
                              old_state.panelBox_anchor_point[1]);

    if (old_state.activities_visibility)
        activities_actor.show();

    if (old_state.aggregateMenu_visibility)
        aggregateMenu_actor.show();

    if (old_state.dateMenu_visibility)
        dateMenu_actor.show();

}
