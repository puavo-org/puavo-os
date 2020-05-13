# Welcome to PuavoMenu!

PuavoMenu is the new menu component for PuavoOS and OpinsysOS. It is written in Python 3 and it uses GTK3 to create the user interface.

## TODO

### General
This list must be empty or nearly empty before PuavoMenu can be considered "done".

* (partially done) Fix the keyboard focus issues
* Prevent "special" characters like * and ? from being typed in the search box. Currently the search box accepts them, but they're ignored when searching for programs.
* Larger "back" button for returning to top-level menus
* Fix desktop icon creation:
    * Use the original .desktop file if available
    * Force GNOME to refresh the desktop after an icon has been created so that it works immediately
* Improve robustness: the menu must NOT crash, EVER, under any condition.
* Finish SV/DE localisations
* Startup speed optimisations (see below)
* Runtime speed optimisations (for example, searching is slow-ish because we must instantiate hundreds of Gtk.Button objects in order to display the results)
* Use gettext for strings

### Startup speed optimisations

One of the most important considerations for PuavoMenu is the startup speed. It must not slow down the system as much as Webmenu did. PuavoMenu already is noticeably faster than Webmenu, but we can do even better:

* Cache the .desktop files in JSON format at system image build time. If the .desktop file is not in this cached file, then try locate and load it. This way we don't have to traverse the filesystem, looking for .desktop files.
* Prebuild the icon atlas(es) at system image build time.
    * Again, minimises filesystem traversal
    * It's generally faster to load one or two large images than hundreds of smaller. Less disk/network traffic.
    * Image resizing won't slow down loading anymore
    * Use high-quality SVG icons for everything? Currently too slow for production, but if the atlas is pre-built, then spending 3-5 seconds to build an icon cache does not matter.
* Compile everything to .pyc? This improves parsing speed.

### Future

Nice to have

* Tweak the UI further. If we ever get compositing support, add a blurry background effect.
* "Emergency" mode? This would be used when no menu data can be loaded for some reason. It would list some of the most often-used programs in a hardcoded list, for a backup.
* (partially done) Lint the source code thoroughly
* Add Python 3.5/3.6/3.7 type hints and run the whole program through a type checker
