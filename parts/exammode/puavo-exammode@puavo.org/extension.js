const { Clutter, Gio, GLib, GObject, St } = imports.gi;
const Dialog = imports.ui.dialog;
const ExtensionUtils = imports.misc.extensionUtils;
const Gettext = imports.gettext;
const Main = imports.ui.main;
const ModalDialog = imports.ui.modalDialog;
const Util = imports.misc.util;

const { QuickMenuToggle, SystemIndicator } = imports.ui.quickSettings;

const exam_session_path = '/var/lib/puavo-exammode/session.json';

const { gettext: _, ngettext, pgettext, } = ExtensionUtils;

var control_info_label;
var indicator;

const QuitExamButton = GObject.registerClass(
class QuitExamButton extends QuickMenuToggle {
    constructor() {
        super({
            label: _('Quit exam'),
            hasMenu: true,
            canFocus: true,
            accessible_name: _('Quit exam'),
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
            console.log('could not make dbus call to quit exam session: ' + e);
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
  ExtensionUtils.initTranslations('puavo-exammode');

  let [ ok, exam_session_json ] = GLib.file_get_contents(exam_session_path);
  if (!ok) {
    throw new Error('could not read session information');
  }
  let utf8decoder = new TextDecoder();
  let exam_session_info = JSON.parse( utf8decoder.decode(exam_session_json) );

  control_text = _('adjust text scale with ctrl+ and ctrl- keys') +
                    '    |    ' + _('press F11 to toggle fullscreen');
  control_info_label = new St.Label({
                         text: control_text,
                         y_align: Clutter.ActorAlign.CENTER,
                       });

  indicator = new Indicator();
}

function enable() {
  Main.panel._centerBox.insert_child_at_index(control_info_label, 0);
} 

function disable() {
  Main.panel._centerBox.remove_child(control_info_label);
}
