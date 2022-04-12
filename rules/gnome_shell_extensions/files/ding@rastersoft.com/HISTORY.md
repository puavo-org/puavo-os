# History of versions #

* Version 43
  * Fixed another syntax mistake (Sergio Costas)
  * Unified syntax for DbusTimeoutId (Sergio Costas)

* Version 42
  * Fixed a bug due to the autocompletion (Sergio Costas)

* Version 41
  * Remove signals timeout when the extension is disabled (Sergio Costas)

* Version 40
  * Copy instead of Move if Shift or Control is pressed (Sergio Costas)
  * Redirect output to the logger in real time (Marco Trevisan)
  * Pass timestamps to avoid focus stealing (Marco Trevisan)
  * Now shows an emblem when a .desktop file is invalid (Sundeep Mediratta)
  * Use correct scaling factor during Drag'n'Drop (Daniel van Vugt)
  * Fixed rubberband after hot-change of the zoom value (Sergio Costas)
  * Added support for asynchronous thumbnail API (Sergio Costas)
  * Allows to disable the emblems in icons (Sergio Costas)
  * Now the icons won't disappear when minimizing all windows (Sergio Costas)
  * Better DBus management (Sundeep Mediratta)
  * Now shows a message when trying to use a feature that requires an external program (Sergio Costas)
  * Show a dialog when a .desktop file can't be launched (Sundeep Mediratta)
  * Allows to theme the menus (Marco Trevisan)
  * Fixed passing undefined classname (Daniel van Vugt)
  * Show preferences also in gnome-extensions-app (Sergio Costas)
  * Fixed high-CPU usage when moving windows on Ubuntu (Sergio Costas)
  * Added support for the new ActivatableServicesChanged signal in DBus (Sergio Costas)

* Version 39
  * Fixed "Allow launching" when the file doesn't have executable flag (Sergio Costas)
  * Ignore SPACE key to start a search (Laurentiu-Andrei Postole)
  * Use CSS to make the window transparent (Sundeep Mediratta)
  * Removed "ask to execute" dialog; now shows "Run as a program" (Sergio Costas)
  * Removed "run" mode for dialogs (Sundeep Mediratta)
  * Fix volume names (Sergio Costas)
  * Added support for Nemo file manager (Sergio Costas)
  * Fix transparency bug in the properties window (Sergio Costas)

* Version 38
  * Fixed Paste in Gnome Shell 3.38 (Sergio Costas)

* Version 37
  * Fixed DnD into folders of the desktop (Sergio Costas)

* Version 36
  * Fixed 'icon resize' when using stacked icons (Sundeep Mediratta)
  * Fixed typo (Davy Defaud)

* Version 35
  * Now Ctrl+Shift+N creates a folder, like in Nautilus (Sergio Costas)
  * Fixed bug when the extension was disabled (Sergio Costas)

* Version 34
  * Fix error popup when pressing arrow keys (Sundeep Mediratta)
  * Fix icons appearing during desktop change animation (Sundeep Mediratta)
  * Avoid relaunching DING when updating the window size (Sundeep Mediratta)
  * Fix scripts by passing file list as parameters (Sergio Costas)
  * Show extensions in Nautilus scripts (Sergio Costas)
  * Added support for "stacking" files, grouping files of the same type (Sundeep Mediratta)
  * Fix clipboard support for last version of Nautilus (Sergio Costas)

* Version 33
  * Synchronized version number with the one in Gnome Extensions
  * Fixed failure when TEMPLATES folder is not configured (Sergio Costas)
  * Other extensions can notify the usable work area (Sergio Costas)
  * Fix exception if File-Roller is not installed (Sergio Costas)

* Version 24
  * Fixed "Open in terminal" option in right-click menu (Sergio Costas)

* Version 23
  * Use the system bell sound instead of GSound (Sergio Costas)
  * Transformed DING into a Gtk.Application (Sergio Costas)
  * Code cleaning (Sundeep Mediratta and Sergio Costas)
  * Fixed loss of focus when an application goes full screen (Sergio Costas)
  * Fixed translation problems when installed system-wide (Sergio Costas)
  * Fixed pictures preview (Sundeep Mediratta)
  * Removed some warnings in the log (Sergio Costas)
  * Don't reload the desktop when a window changes to FullScreen (Daniel van Vugt)
  * Catch Gio exceptions from extra folders (Daniel van Vugt)

* Version 22
  * GSound is now optional (Sergio Costas)

* Version 21
  * New folders get a default name and, then, are renamed if the user wants (Sundeep Mediratta)
  * Several fixes for DnD (Sergio Costas and Sundeep Mediratta)
  * Removed odd symbols from windows title (Sergio Costas)
  * Added support for search files in the desktop (Sundeep Mediratta)
  * Support nested folders in scripts and templates (Sergio Costas)
  * Fixed a crash if a file is created and deleted too quickly (Sundeep Mediratta)
  * The desktop now receives the focus when there are no other windows in the current workspace (Sergio Costas)
  * Better error management in several places (Sundeep Mediratta and Sergio Costas)

* Version 20
  * Removed gir1.2-clutter dependency (Sergio Costas)
  * Added compatibility with Gnome Shell 41 (Daniel van Vugt)

* Version 19
  * Alt+Enter shows properties like Nautilus (Sundeep Mediratta)
  * Hide error windows, new folder window, dialog window and preferences from taskbar and pager (Sundeep Mediratta)
  * "Extract" menu item (Sundeep Mediratta)
  * Ignore distance in double-clicks, needed for touch screens (Kai-Heng Feng)
  * Dont draw green highlight around desktop when dragging and dropping files on it (Sundeep Mediratta)
  * Global rubberband (Sundeep Mediratta)
  * Smaller icon targets to allow more usable space for right click, and extra padding around rendered icons (Sundeep Mediratta)
  * Allows to arrange and sort icons (Sundeep Mediratta)
  * Don't unselect the icons after moving them (Sergio Costas)
  * Fixed the default location in network mounts (Juha Erkkilä)
  * Use the new Nautilus.FileOperations2 API (Marco Trevisan)

* Version 0.18.0
  * Pretty selection (Daniel Van Vugt)
  * Don't draw green rectangle on screen (Sundeep Mediratta)
  * Support for High DPI rendering of icons (Daniel Van Vugt)
  * Added "Extract" and "Extract to" options (Sundeep Mediratta)
  * Update desktop via DBus metadata change notification (Sundeep Mediratta)

* Version 0.17.0
  * Now the preferences are shown in Gnome Shell 40 (Sergio Costas)

* Version 0.16.0
  * Simple shadow to improve appearance (Daniel van Vugt)
  * Compatibility with Gnome Shell 40 (Sergio Costas)
  * Don't show "Email" option if a folder is selected (Sundeep Mediratta)
  * Changed the text for "Preferences", to make easier to identify it as "Desktop icons preferences"
  * Make new folders near the place where the user did right click (Sundeep Mediratta)

* Version 0.15.0
  * Allow to create a folder from a selection of files (Sundeep Mediratta)
  * Allow to compress a selection of files (Sundeep Mediratta)
  * Allow to send by mail a selection of files (Sundeep Mediratta)
  * Allow to show properties of a selection of files (Sundeep Mediratta)
  * Added support for scripts (Sundeep Mediratta)
  * Updates the desktop icons when the icon theme has changed (Artyom Zorin)
  * Now adds new icons to the main screen (Sergio Costas)
  * Added hotkey to show/hide hidden files in the desktop (Sergio Costas)
  * Added support for dual GPUs (Sergio Costas)
  * Improved readability (Ivailo Iliev)
  * Now doesn't maximize a minimized window when closing a popup menu (Sergio Costas)
  * Keep selected a new file created from templates (Sergio Costas)

* Version 0.14.0
  * Now RETURN key in "New folder" and "Rename" only works when the "OK" button is enabled
  * Now doesn't use 100% of CPU when an external drive has been mounted by another user

* Version 0.13.0
  * added support for fractional zoom
  * fixed bug when closing Gedit without saving
  * ensures that new icons are added in the right corner always
  * shows the destination of a DnD operation
  * fix bug when showing drives
  * don't show an error when aborting a DnD operation

* Version 0.12.0
  * Don't fail if there is no TEMPLATES folder
  * Support Ctrl+A for 'select all'
  * Use "Home" as the name of the user's personal folder
  * Show mounted drives in the desktop
  * Re-read the desktop on error
  * Custom icons support
  * Detect changes in the size of the working area
  * Preserves the drop place for remote places
  * Better detection for focus loss

* Version 0.11.0 (2020/04/17)
  * Copy files instead of move when using DnD into another drive
  * Removed flicker when a file is created or removed
  * Fix DnD for Chrome and other programs
  * Template support
  * Allow to choose the align corner for the icons
  * Added "Select all" option
  * Added support for preview
  * Creates folders in the place where the mouse cursor is

* Version 0.10.0 (2020/02/22)
  * Added 'tiny' icon size
  * Doesn't allow to use an existing name when renaming or creating a new folder
  * Fixed the DnD positioning (finally)

* Version 0.9.1 (2020/02/06)
  * Now "Delete permanently" works again

* Version 0.9.0 (2020/01/31)
  * Fix bug that prevented it to work with Gnome Shell 3.30

* Version 0.8.0 (2020/01/19)
  * Fix memory leak when using the rubber band too fast
  * Add finally full support for multimonitor and HiDPI combined
  * Better precision in DnD

* Version 0.7.0 (2019/12/09)
  * Don't show ".desktop" in enabled .desktop files
  * Appearance more consistent with Nautilus
  * Allows to permanently delete files
  * When clicking on a text script, honors "executable-text-activation" setting and, if set, asks what to do
  * Honors "show-image-thumbnails" setting
  * .desktop files are now launched with the $HOME folder as the current folder
  * Allows to run script files with blank spaces in the file name
  * Shows an error if Nautilus is not available in the system
  * Shows an error if a file or folder can't be permanently deleted
  * Added note about configuration

* Version 0.6.0 (2019/10/29)
  * Fix icon distribution in the desktop
  * Show the "Name" field in the .desktop files
  * Better wrap of the names
  * Show a tooltip with the filename
  * Show a hand mouse cursor on "single click" policy
  * Add "delete permanently" option
  * Shift + Delete do "delete permanently"
  * Better detection of screen size change
  * Show symlink emblem also in .desktop files and in files with preview
  * Fix "symlink in all icons" bug
  * Ensure that all the emblems fit in the icon

* Version 0.5.0 (2019/10/15)
  * Fix right-click menu in trash not showing sometimes
  * Fix opening a file during New folder operation
  * Changed license to GPLv3 only

* Version 0.4.0 (2019/10/04)
  * Fix Drag'n'Drop in some special cases
  * Don't relaunch the desktop process when disabling and enabling fast
  * Temporary fix for X11 size

* Version 0.3.0 (2019/09/17)
  * Separate Wayland and X11 paths
  * When a file is dropped from another window, it is done at the cursor
  * Fixed bug when dragging several files into a Nautilus window

* Version 0.2.0 (2019/08/19)
  * Shows the full filename if selected
  * Use theme color for selections
  * Sends debug info to the journal
  * Now kills fine old, unneeded processes
  * Allows to launch the desktop app as standalone
  * Ensures that the desktop is kept at background when switching workspaces
  * Honors the Scale value (for retina-like monitors)
  * Hotkeys
  * Check if the desktop folder is writable by others
  * Now the settings window doesn't block the icons
  * Don't show hidden files

* Version 0.1.0 (2019/08/13)
  * First semi-working version version
  * Has everything supported by Desktop Icons, plus Drag'n'Drop
