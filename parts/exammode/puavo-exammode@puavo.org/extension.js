import Clutter from 'gi://Clutter';
import Gio     from 'gi://Gio';
import GLib    from 'gi://GLib';
import GObject from 'gi://GObject';
import St      from 'gi://St';

import { Extension, gettext as _ } from 'resource:///org/gnome/shell/extensions/extension.js';
import { QuickMenuToggle, SystemIndicator } from "resource:///org/gnome/shell/ui/quickSettings.js";

import * as Dialog         from 'resource:///org/gnome/shell/ui/dialog.js';
import * as Main           from 'resource:///org/gnome/shell/ui/main.js'
import * as ModalDialog    from 'resource:///org/gnome/shell/ui/modalDialog.js';
import * as Util           from 'resource:///org/gnome/shell/misc/util.js';

const exam_session_path = '/var/lib/puavo-exammode/session.json';

var exam_session_info;

const QuitExamButton = GObject.registerClass(
class QuitExamButton extends QuickMenuToggle {
    constructor() {
        super({
            title: _('Quit exam'),
            hasMenu: true,
            canFocus: true,
        });

        this.menu.addAction(_('Quit, I want to exit the exam'),
                            () => { this._do_confirm_quit(this) });
    }

    // for some odd reason "this" is not available here
    _do_confirm_quit(_this) { _this._confirm_quit(); }

    _confirm_quit() {
        let testDialog = new ModalDialog.ModalDialog({
            destroyOnClose: false,
            styleClass: 'end-session-dialog',
        });

        let messageDialogContent = new Dialog.MessageDialogContent();
        messageDialogContent.title = _('Really quit exam?');
        messageDialogContent.description = _('Press "Yes, I quit" to actually exit the exam');
        testDialog.contentLayout.add_child(messageDialogContent);

        testDialog.setButtons([
            {
                label: _('No'),
                action: () => { testDialog.destroy(); },
            },
            {
                label: _('Yes, I quit'),
                isDefault: true,
                action: () => {
                  testDialog.close(global.get_current_time());
                  this._quit();
                },
            },
        ]);

        testDialog.open(global.get_current_time(), true, false);
    }

    _poweroff() {
        try {
            const dbus_call = Gio.DBus.system.call(
                                'org.freedesktop.login1',
                                '/org/freedesktop/login1',
                                'org.freedesktop.login1.Manager',
                                'PowerOff',
                                (new GLib.Variant('(b)', [ false ])),
                                null, Gio.DBusCallFlags.NONE, -1, null);
            dbus_call.then(() => {}, this._poweroff_error);
        } catch (e) {
            console.log('could not make dbus call to quit exam session: ' + e);
            return;
        }
    }

    _poweroff_error(e) {
      console.log('error sending PowerOff dbus call:' + e);
    }

    _quit() {
      if (exam_session_info.manager) {
        this._quit_session();
      } else {
        this._poweroff();
      }
    }

    _quit_session() {
        try {
            const dbus_call = Gio.DBus.system.call(
                                'org.puavo.Exam',
                                '/exammode',
                                 'org.puavo.Exam.exammode',
                                'QuitSession',
                                (new GLib.Variant('()', [])),
                                null, Gio.DBusCallFlags.NONE, -1, null);
            dbus_call.then(() => {}, this._quit_session_error);
        } catch (e) {
            console.log('could not make dbus call to quit exam session: ' + e);
            return;
        }
    }

    _quit_session_error(e) {
      console.log('error sending QuitSession dbus call:' + e);
    }
});

var Indicator = GObject.registerClass(
class Indicator extends SystemIndicator {
  _init() {
    super._init();
    let quit_exam_button = new QuitExamButton();
    this.quickSettingsItems.push(quit_exam_button);
    let qs = Main.panel.statusArea.quickSettings;
    qs.menu.addItem(quit_exam_button, 2);
  }
});

export default class DashToPanelExtension extends Extension {
  constructor(metadata) {
    super(metadata);
  }

  enable() {
    let [ ok, exam_session_json ] = GLib.file_get_contents(exam_session_path);
    if (!ok) {
      throw new Error('could not read session information');
    }
    let utf8decoder = new TextDecoder();
    // XXX should probably check exam_session_info contents in some way?
    exam_session_info = JSON.parse( utf8decoder.decode(exam_session_json) );

    if (exam_session_info['type'] === 'next-exam-session') {
      let control_text = _('Next-Exam')
    } else {
      let control_text = _('Exam mode');
    }

    this.control_info_label = new St.Label({
                                text: control_text,
                                y_align: Clutter.ActorAlign.CENTER,
                              });

    this.indicator = new Indicator();

    Main.panel._centerBox.insert_child_at_index(this.control_info_label, 0);
  } 

  disable() {
    Main.panel._centerBox.remove_child(this.control_info_label);
    this.control_info_label.destroy();
    this.control_info_label = null;
    this.indicator.destroy();
    this.indicator = null;
  }
}
