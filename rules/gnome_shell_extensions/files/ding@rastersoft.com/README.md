# DING Desktop Icons New Generation

## What  is it

Desktop Icons NG for GNOME Shell. It is a fork/rewrite of the official 'Desktop Icons' extension,
with these advantages:

* Drag'n'Drop, both inside the desktop, between desktop and applications, and nautilus windows
* Allows to use "Open with..." option with several files
* When hovering or clicking on an icon with a name too large to fit, it shows the full name
* Doesn't hang the compositor when there is too much activity in the desktop folder
* And much more...

## Requirements

* GNOME Shell >= 3.38
* Nautilus >= 3.38
* File-roller >= 3.38

## Manual installation

The easiest way of installing DING is to run the `local_install.sh` script. It performs the build steps
specified in the next section.

In Ubuntu, unfortunately, it is not possible to use it directly because the internal desktop-icons-ng
extension interferes. The only way to update to the newest one is to install the package "gnome-session"
to be able to use the standard gnome shell session, and there install the following extensions from
extensions.gnome.org:

* Desktop icons ng
* Dash to dock
* Appindicator and KstatusNotifierItem support

That will allow to have the same experience than the original Ubuntu desktop, but with the most recent
versions of the extensions.

## Internal architecture

The code is divided in two parts: a classic Gtk3 program that manages the whole desktop, and a little
extension (comprised only by the files 'extension.js', 'gnomeShellOverride.js', 'visibleArea.js' and
'emulateX11WindowType.js') that have these roles:

* Launch the desktop program at startup, relaunch it if it dies, and kill it if the extension is disabled
* Identify the desktop windows and keep it at the bottom of the windows stack, in all desktops
* Detect changes in the desktop/monitors geometry and notify the main desktop program of them

These two last items are paramount in Wayland systems, because there an application can neither set its
role as freely as in X11, nor get that information.

Of course, to avoid breaking the security model of Wayland, it is paramount to ensure that no other
program can pose as DING. In old versions, the process for identifying the window was quite convoluted,
passing an UUID through STDIN and putting it in the window title. But since Gnome Shell 3.38 there is
a new API that allows to check whether a window belongs to an specific process launched from an
extension, which makes the code much cleaner and straightforward.

The extension monitors all 'map' signals, and when a window from the DING process previously
launched is mapped, it knows that it is the desktop window. It stores that window object, sends it to
the bottom of the stack, and connects to three signals:

* raised: it is called every time the window is sent to the front, so in the callback, the extension
sends it again to the bottom.
* position-changed: although the window doesn't have titlebar, it still is possible to move it using
Alt+F7, or pressing Super and dragging it with the mouse, so this callback returns the window to the
right possition every time the user tries to move it.
* unmanaged: called when the window disappears. It deletes the UUID, and waits for the desktop program
to be killed (it will be relaunched again by the extension, and, of course, a new UUID will be used).

It also monitors other signals to ensure that the desktop receives the focus only when there are no
other windows in the current desktop, and to keep the icons in the right screen, no matter if the
user changes to another virtual desktop.

The extension also intercepts three Gnome Shell system calls, in order to hide the desktop windows
from the tab switcher and the Activities mode. These are 'Meta.Display.get_tab_list()',
'Shell.Global.get_window_actors()', and 'Meta.Workspace.list_windows()'.

## Launching the Desktop Icons application stand-alone

It is possible to launch the desktop icons application in stand-alone mode to do debugging and
testing, but, of course, it will behave as a classic Gtk program: there will be a window with its
titlebar, and the background won't be transparent (it could be, but since the idea is to do debug,
it is better this way). To do so, just launch './ding.js' from the repository directory. If it can't
find the schemas file, just enter the 'schemas' folder and type 'glib-compile-schemas .', and retry.

It accepts the following command line parameters:

* -P: specifies the working path. If not set, it will default to './', which means that all the other
files must be in the current path.
* -D: specifies a monitor. It is followed by another parameter in the form: X:Y:W:H:Z being each letter
      a number with, respectively:
  * X: the X coordinate of this monitor
  * Y: the Y coordinate of this monitor
  * W: the width in pixels of this monitor
  * H: the height in pixels of this monitor
  * Z: the zoom value for this monitor
  you can set several -D parameters in the same command line, one for each monitor. A single window
  will be created for each monitor. If no -D parameter is specified, it will create a single monitor
  with a size of 1280x720 pixels.
* -M: specifies which monitor is the primary index, to add there any new file icon.

## Build with Meson

The project uses a build system called [Meson](https://mesonbuild.com/). You can install
in most Linux distributions as "meson". You also need "ninja" and xgettext.

It's possible to read more information in the Meson docs to tweak the configuration if needed.

For a regular use and local development these are the steps to build the
project and install it:

```bash
meson --prefix=$HOME/.local/ --localedir=share/gnome-shell/extensions/ding@rastersoft.com/locale .build
ninja -C .build install
```

It is strongly recommended to delete the destination folder
($HOME/.local/share/gnome-shell/extensions/ding@rastersoft.com) before doing this, to ensure that no old
data is kept.

## Export extension ZIP file for extensions.gnome.org

To create a ZIP file with the extension, just run:

```bash
./export-zip.sh
```

This will create the file `ding@rastersoft.com.zip` with the extension, following the rules for publishing at extensions.gnome.org.

## Source code and contacting the author

Sergio Costas  
<https://gitlab.com/rastersoft/desktop-icons-ng>  
rastersoft@gmail.com  
