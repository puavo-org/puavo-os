# Welcome to PuavoMenu!

PuavoMenu is the new menu component for PuavoOS and OpinsysOS. It is written in Python 3 and it uses GTK3 to create the user interface. At the moment, it imitates the old WebMenu UI pretty well, but this will change as soon as the designs for the new UI are finalised.

**CAUTION: PUAVOMENU HAS SEEN PRODUCTION USE ALREADY, BUT IT IS STILL IN SOMEWHAT EXPERIMENTAL PHASE!**

## TODO

### General
This list must be empty or nearly empty before PuavoMenu can be considered "done".

* (partially done) Fix the keyboard focus issues
* Prevent "special" characters like * and ? from being typed in the box. Currently the search box accepts them, but they're ignored when searching for programs.
* Larger "back" button for returning to top-level menus
* Support loading extra menu data from puavoconf and other mechanisms
* Fix desktop icon creation:
    * Use the original .desktop file if available
    * Force GNOME to refresh the desktop after an icon has been created so that it works immediately
* More conditionals (document these!)
* Improve robustness: the menu must NOT crash, EVER, under any condition.
* Finish SV/DE localisations
* See if the memory consumption can be lowered. Currently, PuavoMenu uses roughly half of what WebMenu used, but this number probably can be brought down even more.
* Add a tiny "..." menu at the corner of program icons; if clicked, it opens the per-program popup menu. You can already open per-program popup menus by right-clicking the icons, but not many users know about this (consequently, they don't know that you can add programs to desktop and the bottom panel).

### Startup speed optimisations

One of the most important considerations for PuavoMenu is the startup speed. It must not slow down the system as much as WebMenu does/did. PuavoMenu already is noticeably faster than WebMenu, but we can do even better:

* "Compile" the YAML and .desktop files into some fast-to-load binary format at system image build time. 97%-98% of the programs and menus are visible to all users, so it'd make sense to compile them. puavo-pkg and other "dynamic" programs can be ignored.
* Prebuild the icon atlas(es) at system image build time.
    * Use high-quality SVG icons for everything? Currently too slow for production, but if the atlas is pre-built, then spending 3-5 seconds to build an icon cache does not matter.
* Compile everything to .pyc. This improves parsing speed.
* When reloading menu data, don't reload it from scratch, but try to intelligently analyse what has changed, then apply those changes only

### Future

Nice to have

* Use gettext() for localisation. There's no really any reason why we couldn't support any language.
* Use CSS for properly styling the custom buttons.
* More modern interface
* Remove faves (ie. "the most used programs"); if the user wants these, they can add the icons on the desktop or on the panel
* "Emergency" mode? This would be used when no menu data can be loaded for some reason. It would list some of the most often-used programs in a hardcoded list, for a backup.
* (partially done) Lint the source code thoroughly
* Add Python 3.5/3.6/3.7 type hints and run the whole program through a type checker
* Cairo (the graphics library) uses grayscale anti-aliasing when drawing button texts. Make it RGB anti-aliasing, because that's better.
