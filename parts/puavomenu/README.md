# Welcome to PuavoMenu!

PuavoMenu is the upcoming WebMenu replacement component. It is written in Python 3 and it uses GTK3 to create the user interface. At the moment, it imitates the old WebMenu UI pretty well, but this will change.

**CAUTION: THIS IS HIGHLY EXPERIMENTAL! USE AT YOUR OWN RISK! IT IS NOT USABLE IN PRODUCTION YET!**

## TODO

### General
This list must be empty or nearly empty before PuavoMenu can be considered good enough to be used in production.

* WebMenu parity: download and display user avatar images
* WebMenu parity: implement the "webwindow" style, don't open the system browser for doing things like password change
* Fix the keyboard focus issues
* Prevent "special" characters like * and ? from being typed in the box. Currently the search box accepts them, but they're ignored when searching for programs.
* Larger "back" button for returning to top-level menus
* Support loading extra menu data from puavoconf and other mechanisms
* Fix desktop icon creation:
    * Use the original .desktop file if available
    * Force GNOME to refresh the desktop after an icon has been created so that it works immediately
* More conditionals
* Improve robustness: the menu must NOT crash, EVER, under any condition.
* Finish SV/DE localisations
* See if memory consumption can be lowered. Currently, PuavoMenu uses roughly half of the memory WebMenu uses, but this number probably can be brought down even more.

### Startup speed optimisations

One of the most important considerations for PuavoMenu is the startup speed. It must not slow down the system as much as WebMenu does.

* When reloading menu data, don't reload it from scratch, but try to intelligently analyse what has changed, then apply those changes only
* "Compile" the YAML and .desktop files into some fast-to-load binary format
* Prebuild the icon atlas(es) at system image build time.
    * Use high-quality SVG icons for everything? Currently too slow for production, but if the atlas is pre-built, then spending 3-5 seconds to build an icon cache does not matter.
* Compile everything to .pyc

### Future

Nice to have

* More modern interface
* Remove faves (ie. "the most used programs"); if the user wants these, they can add the icons on the desktop or on the panel
* "Emergency" mode? This would be used when no menu data can be loaded for some reason. It would list some of the most often-used programs in a hardcoded list, for a backup.
* Lint the source code thoroughly
* Add Python 3.5/3.6/3.7 type hints and run the whole program through a typechecker
