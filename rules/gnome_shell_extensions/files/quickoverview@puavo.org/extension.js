// forked from quickoverview@kirby_33@hotmail.fr
// https://extensions.gnome.org/extension/614/quick-overview-launcher/

import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import GObject from 'gi://GObject';
import St from 'gi://St';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';

const HIGH_SPEED = 0.01;

const OverviewButton = GObject.registerClass(
class OverviewButton extends PanelMenu.Button{
    constructor(extension) {
        super(0.0, 'QuickOverview', false);

        this._extension = extension;
        this._modifiedSpeed = HIGH_SPEED;

        // Load a custom icon directly from the extension directory
        const iconFile = Gio.File.new_for_path(
            `${extension.path}/icons/quickoverview-symbolic.svg`);

        this._icon = new St.Icon({
            gicon: new Gio.FileIcon({file: iconFile}),
            style_class: 'system-status-icon',
            icon_size: 32,
        });

        this.add_child(this._icon);

        this.connect('button-press-event', () => {
            this._toggleOverview();
            return Clutter.EVENT_STOP;
        });
    }

    _toggleOverview() {
        const originalSpeed = St.Settings.get().slow_down_factor;

        try {
            St.Settings.get().slow_down_factor = this._modifiedSpeed;

            if (Main.overview.visible)
                Main.overview.hide();
            else
                Main.overview.show();
        } finally {
            St.Settings.get().slow_down_factor = originalSpeed;
        }
    }
});

export default class QuickOverviewExtension extends Extension {
    enable() {
        this._button = new OverviewButton(this);

        Main.panel.addToStatusArea(this.uuid, this._button, 1, 'left');

        this._activities = Main.panel.statusArea['activities'];
        if (this._activities?.container)
            this._activities.container.hide();
    }

    disable() {
        this._button?.destroy();
        this._button = null;

        if (this._activities?.container)
            this._activities.container.show();

        this._activities = null;
    }
}
