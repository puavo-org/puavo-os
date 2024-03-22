const Clutter = imports.gi.Clutter;
const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;
const Main = imports.ui.main;
const St = imports.gi.St;
const Util = imports.misc.util;

const exam_session_path = '/var/lib/puavo-exammode/session.json';

const quit_icon_path = '/usr/share/icons/Adwaita/64x64/actions/application-exit-symbolic.symbolic.png'

var exam_name_label, quit_button;

function init() {
  let [ ok, exam_session_json ] = GLib.file_get_contents(exam_session_path);
  if (!ok) {
    throw new Error('could not read session information');
  }
  // XXX This triggers a warning:
  // XXX Some code called array.toString() on a Uint8Array instance.
  let exam_session_info = JSON.parse(exam_session_json);

  exam_name_label = new St.Label({
                      text:    exam_session_info['name'],
                      y_align: Clutter.ActorAlign.CENTER,
                    });

  quit_button = new St.Button({});

  let icon = new St.Icon();
  let gicon = Gio.icon_new_for_string(quit_icon_path.toString());
  icon.set_gicon(gicon);
  quit_button.set_child(icon);
  quit_button.connect('clicked', () => {
    cmd = [ '/usr/bin/gnome-session-quit', '--force', '--logout',
              '--no-prompt' ];
    Util.spawn(cmd);
  });
}

function enable() {
  Main.panel._centerBox.insert_child_at_index(exam_name_label, 0);
  Main.panel._rightBox.insert_child_at_index(quit_button, -1);
} 

function disable() {
  Main.panel._rightBox.remove_child(exam_name_label);
  Main.panel._centerBox.remove_child(quit_button);
}
