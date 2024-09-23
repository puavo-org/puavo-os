const { Clutter, Gio, GLib, GObject, St } = imports.gi;
const Main = imports.ui.main;
const Dialog = imports.ui.dialog;
const ModalDialog = imports.ui.modalDialog;
const Util = imports.misc.util;

const { QuickMenuToggle, SystemIndicator } = imports.ui.quickSettings;

const exam_session_path = '/var/lib/puavo-exammode/session.json';

var control_info_label;
var exam_name_label;
var indicator;

const QuitExamButton = GObject.registerClass(
class QuitExamButton extends QuickMenuToggle {
    constructor() {
        super({
            label: _('Quit exam'),
            hasMenu: true,
            canFocus: true,
            accessible_name: _('Quit'),
        });

        this.menu.addAction(_('Quit, because I am done now'),
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
        messageDialogContent.description = _('QUIT QUIT QUIT');
        testDialog.contentLayout.add_child(messageDialogContent);

        testDialog.setButtons([
            {
                label: _('No, get back'),
                action: () => { testDialog.destroy(); },
            },
            {
                label: _('Yes, quit'),
                isDefault: true,
                action: () => {
                  testDialog.close(global.get_current_time());
                  this._quit();
                },
            },
        ]);

        testDialog.open(global.get_current_time(), true, false);
    }

    _quit() {
        try {
            const dbus_call = Gio.DBus.system.call(
                                'org.puavo.Exam',
                                '/exammode',
                                 'org.puavo.Exam.exammode',
                                'QuitSession',
                                (new GLib.Variant('()', [])),
                                null, Gio.DBusCallFlags.NONE, -1, null);
            dbus_call.then(() => {}, this._quit_error);
        } catch (e) {
            console.log('Could not make dbus call to quit exam session: ' + e);
            return;
        }
    }

    _quit_error(e) {
      console.log('error sending QuitSession dbus call:' + e);
    }
});

var Indicator = GObject.registerClass(
class Indicator extends SystemIndicator {
    _init() {
        super._init();
        this.quickSettingsItems.push(new QuitExamButton());
        let qs = Main.panel.statusArea.quickSettings;
        qs._addItems(this.quickSettingsItems, 2);
    }
});

function init() {
  let [ ok, exam_session_json ] = GLib.file_get_contents(exam_session_path);
  if (!ok) {
    throw new Error('could not read session information');
  }
  let utf8decoder = new TextDecoder();
  let exam_session_info = JSON.parse( utf8decoder.decode(exam_session_json) );

  info_text = 'adjust text scale with ctrl+ and ctrl-'
                + '  |  press F11 to toggle fullscreen';
  control_info_label = new St.Label({
                         text: info_text,
                         y_align: Clutter.ActorAlign.CENTER,
                       });

  exam_name_label = new St.Label({
                      text:    exam_session_info['name'],
                      y_align: Clutter.ActorAlign.CENTER,
                    });

  indicator = new Indicator();
}

function enable() {
  Main.panel._centerBox.insert_child_at_index(exam_name_label, 0);
  Main.panel._rightBox.insert_child_at_index(control_info_label, 0);
} 

function disable() {
  Main.panel._rightBox.remove_child(exam_name_label);
}
