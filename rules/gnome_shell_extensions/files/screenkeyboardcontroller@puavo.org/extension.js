'use strict';
const Clutter = imports.gi.Clutter;
const GLib = imports.gi.GLib;
const ExtensionUtils = imports.misc.extensionUtils;
const Keyboard = imports.ui.keyboard;
const Main = imports.ui.main;

let _deviceAddedHandlerId;
let _deviceRemovedHandlerId;
let _originalLastDeviceIsTouchscreen;
let _seat;

function _auto_hide() {
    try {
        global.log('screenkeyboardcontroller@puavo.org: checking if the device has a real keyboard...');
        const [res, stdout, stderr, wait_status] = GLib.spawn_command_line_sync('/usr/lib/puavo-ltsp-client/has-real-keyboard');

        let stdout_str = new TextDecoder('utf-8').decode(stdout);
        let stderr_str = new TextDecoder('utf-8').decode(stderr);

        if (stderr_str.length > 0) {
            global.log(`screenkeyboardcontroller@puavo.org: has-real-keyboard printed to stderr: '${stderr_str}'`);
        }

        GLib.spawn_check_wait_status(wait_status); // Throws exception if has-real-keyboard failed.

        switch (stdout_str.trim()) {
        case 'yes':
            global.log("screenkeyboardcontroller@puavo.org: this device has a real keyboard, screen keyboard is disabled.");
            return false;
        case 'no':
            global.log("screenkeyboardcontroller@puavo.org: this device does not have a real keyboard, screen keyboard is enabled.");
            return true;
        default:
            throw new Error(`has-real-keyboard printed unexpected output: '${stdout_str.trim()}'`);
        }
    } catch (e) {
        logError(e);
    };

    // If something goes wrong, we fallback to the original logic,
    // i.e. act like this extension is not enabled at all.
    return _originalLastDeviceIsTouchscreen.call(this);
}

function _modifiedLastDeviceIsTouchscreen() {
    global.log('screenkeyboardcontroller@puavo.org: someone called me');

    const settings = ExtensionUtils.getSettings();
    const mode = settings.get_string('mode');

    switch (mode) {
    case 'auto_hide':
        return _auto_hide();
    case 'force_hide':
        return false;
    case 'do_nothing':
        break;
    default:
        global.log(`Unexpected mode ${mode}`);
        break;
    }

    global.log('screenkeyboardcontroller@puavo.org: doing nothing');

    return _originalLastDeviceIsTouchscreen.call(this);
}

function init() {
    global.log('screenkeyboardcontroller@puavo.org: initializing...');
    _seat = Clutter.get_default_backend().get_default_seat();
    global.log('screenkeyboardcontroller@puavo.org: initialized.');
}

function _on_device_added(clutter, device) {
    global.log('screenkeyboardcontroller@puavo.org: device added.');
    Main.keyboard._syncEnabled();
}

function _on_device_removed(clutter, device) {
    global.log('screenkeyboardcontroller@puavo.org: device removed.');
    Main.keyboard._syncEnabled();

    // This device might have been the last keyboard, we don't
    // know. Try to open the screen keyboard if it's enabled (i.e. no
    // other keyboards are available)..
    Main.keyboard.open(Main.layoutManager.focusIndex);
}

function enable() {
    global.log('screenkeyboardcontroller@puavo.org: enabling...');
    _originalLastDeviceIsTouchscreen = Keyboard.KeyboardManager.prototype._lastDeviceIsTouchscreen;
    Keyboard.KeyboardManager.prototype._lastDeviceIsTouchscreen = _modifiedLastDeviceIsTouchscreen;

    _deviceAddedHandlerId = _seat.connect('device-added', _on_device_added);
    _deviceRemovedHandlerId = _seat.connect('device-removed', _on_device_removed);

    global.log('screenkeyboardcontroller@puavo.org: enabled.');
}

function disable() {
    global.log('screenkeyboardcontroller@puavo.org: disabling...');

    if (_deviceRemovedHandlerId) {
        global.log('screenkeyboardcontroller@puavo.org: disconnecting device-removed handler...');
        _seat.disconnect(_deviceRemovedHandlerId);
        _deviceRemovedHandlerId = null;
        global.log('screenkeyboardcontroller@puavo.org: disconnected device-removed handler.');
    }

    if (_deviceAddedHandlerId) {
        global.log('screenkeyboardcontroller@puavo.org: disconnecting device-added handler...');
        _seat.disconnect(_deviceAddedHandlerId);
        _deviceAddedHandlerId = null;
        global.log('screenkeyboardcontroller@puavo.org: disconnected device-added handler.');
    }

    Keyboard.KeyboardManager.prototype._lastDeviceIsTouchscreen = _originalLastDeviceIsTouchscreen;
    _originalLastDeviceIsTouchscreen = null;

    global.log('screenkeyboardcontroller@puavo.org: disabled.');
}
