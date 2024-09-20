const { Clutter, Gio, GLib, GObject, St } = imports.gi;
const Main = imports.ui.main;
const Util = imports.misc.util;

const { QuickMenuToggle, SystemIndicator } = imports.ui.quickSettings;

const exam_session_path = '/var/lib/puavo-exammode/session.json';

var control_info_label;
var exam_name_label;
var indicator;

const QuitExamButton = GObject.registerClass(
class QuitExamButton extends QuickMenuToggle {
    _init() {
        super._init({
            label: _('Quit exam'),
            hasMenu: true,
            canFocus: true,
            accessible_name: _('Quit'),
        });

        this.menu.addAction(_('Quit, because I am done now'), this.quit);
    }

    // XXX do not use dbus-send
    quit() {
      let cmd = [ '/usr/bin/dbus-send', '--dest=org.puavo.Exam',
                    '--print-reply=literal', '--reply-timeout=30000',
                    '--system', '/exammode',
                    'org.puavo.Exam.exammode.QuitSession' ];
      Util.spawn(cmd);
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
