const ShellVersion = imports.misc.config.PACKAGE_VERSION.split(".");
const Main = imports.ui.main;
const Lang    = imports.lang;
const PanelMenu = imports.ui.panelMenu;
const St = imports.gi.St;
const HIGHT_SPEED = 0.01;

const OverviewButton = new Lang.Class({
    Name: 'QuickOverview.OverviewButton',
    Extends: PanelMenu.Button,
    _init: function() {
        this.parent(0.0,'QuickOverview');
        this.buttonIcon = new St.Icon({ style_class: 'system-status-icon', 'icon_size': 32 });
        this.actor.add_actor(this.buttonIcon);
        this.buttonIcon.icon_name='puavo-multitasking-view';
        this.actor.connect('button-press-event', Lang.bind(this, this._refresh));
        this.original_speed = St.get_slow_down_factor();
        this.modified_speed = HIGHT_SPEED;
    },

    _refresh: function() {

        this.original_speed = St.get_slow_down_factor();
        St.set_slow_down_factor(this.modified_speed);
        if (Main.overview._shown)
            Main.overview.hide();
        else
            {
            Main.overview.show();
            }
        St.set_slow_down_factor(this.original_speed);

    }

});

function init(extensionMeta) {
    let theme = imports.gi.Gtk.IconTheme.get_default();
    theme.append_search_path(extensionMeta.path + "/icons");
}

let QuickOverviewButton;

function enable() {
    QuickOverviewButton = new OverviewButton();
    global.log('DEBUG ShellVersion='+ShellVersion[1]);
    if (ShellVersion[1]>4) {
        Main.panel.addToStatusArea('quickoverview-menu', QuickOverviewButton, 1, 'left');
        let indicator = Main.panel.statusArea['activities'];
        if(indicator != null)
        indicator.container.hide();
    } else {
        Main.panel._leftBox.insert_child_at_index(QuickOverviewButton.actor,0);
        Main.panel._menus.addMenu(QuickOverviewButton.menu);
        Main.panel._activitiesButton.actor.hide();
    }

}

function disable() {

    QuickOverviewButton.destroy();

    if (ShellVersion[1]>4) {
        let indicator = Main.panel.statusArea['activities'];
        if(indicator != null)
        indicator.container.show();
    } else {
        Main.panel._activitiesButton.actor.show();
    }

}

