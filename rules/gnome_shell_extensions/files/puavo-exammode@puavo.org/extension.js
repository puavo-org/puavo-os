const { Clutter, Gio, GLib, GObject, St } = imports.gi;
const Main = imports.ui.main;
const Util = imports.misc.util;

const PanelMenu = imports.ui.panelMenu;
const PopupMenu = imports.ui.popupMenu;

const exam_session_path = '/var/lib/puavo-exammode/session.json';
const quit_icon_path = '/usr/share/icons/Adwaita/64x64/actions/application-exit-symbolic.symbolic.png'

var exam_name_label;
var fullscreen_info_label;

class ExamMenu extends PanelMenu.Button {
  static { GObject.registerClass(this); }

  constructor() {
    super(0.0, 'Exam menu');

    let icon = new St.Icon();
    let gicon = Gio.icon_new_for_string(quit_icon_path.toString());
    icon.set_gicon(gicon);
    this.add_child(icon);

    this.menu.addAction('Quit Exam', event => {
      // XXX could there be a dbus-module to use instead of Util.spawn?
      let cmd = [ '/usr/bin/dbus-send', '--dest=org.puavo.Exam',
                    '--print-reply=literal', '--reply-timeout=30000',
                    '--system', '/exammode',
                    'org.puavo.Exam.exammode.QuitSession' ];
      Util.spawn(cmd);
    });
  }
}

function init() {
  let [ ok, exam_session_json ] = GLib.file_get_contents(exam_session_path);
  if (!ok) {
    throw new Error('could not read session information');
  }
  let utf8decoder = new TextDecoder();
  let exam_session_info = JSON.parse( utf8decoder.decode(exam_session_json) );

  exam_name_label = new St.Label({
                      text:    exam_session_info['name'],
                      y_align: Clutter.ActorAlign.CENTER,
                    });

  fullscreen_info_label = new St.Label({
                            text: 'adjust text scale with ctrl+ and ctrl-  |  press F11 to toggle fullscreen',
                            y_align: Clutter.ActorAlign.CENTER,
                          });
}

function enable() {
  exam_menu = new ExamMenu();
  Main.panel._centerBox.insert_child_at_index(exam_name_label, 0);
  Main.panel._rightBox.insert_child_at_index(fullscreen_info_label, 0);
  Main.panel.addToStatusArea('exam-menu', exam_menu, -1, 'right');
} 

function disable() {
  Main.panel._rightBox.remove_child(exam_name_label);
  exam_menu.destroy();
}
