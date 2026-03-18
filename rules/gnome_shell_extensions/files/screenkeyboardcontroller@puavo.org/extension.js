'use strict';

import Clutter from 'gi://Clutter';
import GLib from 'gi://GLib';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as Keyboard from 'resource:///org/gnome/shell/ui/keyboard.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

export default class ScreenKeyboardControllerExtension extends Extension {
    constructor(metadata) {
        super(metadata);

        this._deviceAddedHandlerId = null;
        this._deviceRemovedHandlerId = null;
        this._originalLastDeviceIsTouchscreen = null;
        this._seat = null;
    }

    _auto_hide() {
        try {
            console.log('screenkeyboardcontroller@puavo.org: checking if device has real keyboard...');

            const [res, stdout, stderr, wait_status] =
                GLib.spawn_command_line_sync('/usr/lib/puavo-ltsp-client/has-real-keyboard');

            const stdout_str = new TextDecoder().decode(stdout);
            const stderr_str = new TextDecoder().decode(stderr);

            if (stderr_str.length > 0) {
                console.log(`screenkeyboardcontroller@puavo.org: stderr: ${stderr_str}`);
            }

            GLib.spawn_check_wait_status(wait_status);

            switch (stdout_str.trim()) {
                case 'yes':
                    console.log('screenkeyboardcontroller@puavo.org: this device has a real keyboard, screen keyboard is disabled.');
                    return false;
                case 'no':
                    console.log('screenkeyboardcontroller@puavo.org: this device does not have a real keyboard, screen keyboard is enabled.');
                    return true;
                default:
                    throw new Error(`Unexpected output: ${stdout_str}`);
            }
        } catch (e) {
            console.error(e);
        }

        // If something goes wrong, we fallback to the original logic,
        // i.e. act like this extension is not enabled at all.
        return this._originalLastDeviceIsTouchscreen.call(this);
    }

    _modifiedLastDeviceIsTouchscreen() {
        console.log('screenkeyboardcontroller@puavo.org: modified touchscreen check called');

        const settings = this.getSettings();
        const mode = settings.get_string('mode');

        switch (mode) {
            case 'auto_hide':
                return this._auto_hide();
            case 'force_hide':
                return false;
            case 'do_nothing':
                break;
            default:
                console.log(`screenkeyboardcontroller@puavo.org: unexpected mode ${mode}`);
        }

        global.log('screenkeyboardcontroller@puavo.org: doing nothing');

        return this._originalLastDeviceIsTouchscreen.call(this);
    }

    _on_device_added() {
        console.log('screenkeyboardcontroller@puavo.org: device added');
        Main.keyboard._syncEnabled();
    }

    _on_device_removed() {
        console.log('screenkeyboardcontroller@puavo.org: device removed');
        Main.keyboard._syncEnabled();

        // This device might have been the last keyboard, we don't
        // know. Try to open the screen keyboard if it's enabled (i.e. no
        // other keyboards are available)..
        Main.keyboard.open(Main.layoutManager.focusIndex);
    }

    enable() {
        console.log('screenkeyboardcontroller@puavo.org: enabling extension');

        this._seat = Clutter.get_default_backend().get_default_seat();

        this._originalLastDeviceIsTouchscreen =
            Keyboard.KeyboardManager.prototype._lastDeviceIsTouchscreen;

        Keyboard.KeyboardManager.prototype._lastDeviceIsTouchscreen =
            this._modifiedLastDeviceIsTouchscreen.bind(this);

        this._deviceAddedHandlerId =
            this._seat.connect('device-added', this._on_device_added.bind(this));

        this._deviceRemovedHandlerId =
            this._seat.connect('device-removed', this._on_device_removed.bind(this));

        console.log('screenkeyboardcontroller@puavo.org: enabled.');
    }

    disable() {
        console.log('screenkeyboardcontroller@puavo.org: disabling extension');

        if (this._deviceRemovedHandlerId) {
            console.log('screenkeyboardcontroller@puavo.org: disconnecting device-removed handler...');
            this._seat.disconnect(this._deviceRemovedHandlerId);
            this._deviceRemovedHandlerId = null;
            console.log('screenkeyboardcontroller@puavo.org: disconnected device-removed handler.');
        }

        if (this._deviceAddedHandlerId) {
            console.log('screenkeyboardcontroller@puavo.org: disconnecting device-added handler...');
            this._seat.disconnect(this._deviceAddedHandlerId);
            this._deviceAddedHandlerId = null;
            console.log('screenkeyboardcontroller@puavo.org: disconnected device-added handler.');
        }

        if (this._originalLastDeviceIsTouchscreen) {
            Keyboard.KeyboardManager.prototype._lastDeviceIsTouchscreen =
                this._originalLastDeviceIsTouchscreen;
            this._originalLastDeviceIsTouchscreen = null;
        }

        console.log('screenkeyboardcontroller@puavo.org: disabled.');
    }
}
