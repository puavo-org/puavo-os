// Display host type, hostname and release name in the login screen

const St = imports.gi.St;
const Main = imports.ui.main;
const Shell = imports.gi.Shell;

let button;

function read_text_file(name)
{
    try {
        return Shell.get_file_contents_utf8_sync(name).trim();
    } catch (e) {
        return "<Can't read " + name + ": " + e.message + ">";
    }
}

function init()
{
    const host_type = read_text_file("/etc/puavo/hosttype"),
          host_name = read_text_file("/etc/puavo/hostname"),
          release_name = read_text_file("/etc/puavo-image/release");

    button = new St.Button({
        style_class: "hostinfo-label",
        reactive: true,
        can_focus: true,
        x_fill: true,
        y_fill: false,
        track_hover: true,
        label: host_type + " | " + release_name + " | " + host_name
    });
}

function enable()
{
    Main.panel._leftBox.insert_child_at_index(button, 0);
}

function disable()
{
   Main.panel._leftBox.remove_child(button);
}
