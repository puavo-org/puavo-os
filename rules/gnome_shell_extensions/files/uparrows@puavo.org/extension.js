/*
Change the popup menu arrows in the bottom panel to point upwards
This is used on the desktop and in the login screen, but *NOT*
in the screen lock screen.

Copyright (C) 2017 Opinsys Oy

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

Version 1.0
Author: Jarmo Pietiläinen (jarmo@opinsys.fi)
*/

const Main = imports.ui.main;

/*
To demonstrate how this extension works, here's a schematic of the
keyboard layout panel button, with their variable names listed:

    +- _hbox -------------------------------+
    | +- _container -+ +- PopupMenuArrow -+ |
    | |      fi      | |        ▼         | |
    | +--------------+ +------------------+ |
    +---------------------------------------+

Reference:
    gnome-shell/js/ui/keyboard.js, function _init() for class
    InputSourceIndicator, around row 792:

We want to locate the PopupMenuArrow widgets and change their icon
names. That's what this extension does. You could also locate each
arrow element, destroy and recreate it by creating a
PopupMenu.arrowIcon(St.Side.TOP) element. But that's clunky.

The other buttons have similar structures, they just have other number
of child items we have to skip over.

For example, you can access the keyboard layout indicator button arrow
by typing this in Looking Glass:

Main.panel.statusArea.keyboard.actor.get_first_child().get_first_child().get_next_sibling();
*/

function reorientArrows(parent, from, to)
{
    if (parent.constructor.name === "St_Icon" &&
        parent.style_class === "popup-menu-arrow") {
        if (parent.icon_name == from)
            parent.icon_name = to
    }

    // recurse if there are child elements
    if (typeof parent.get_children !== "undefined") {
        parent.get_children().forEach(function(child) {
            reorientArrows(child, from, to);
        });
    }
};

function init()
{
}

function enable()
{
    for (let id in Main.panel.statusArea) {
        reorientArrows(Main.panel.statusArea[id].actor.get_first_child(),
            "pan-down-symbolic",
            "pan-up-symbolic")
    }
}

function disable()
{
    for (let id in Main.panel.statusArea) {
        reorientArrows(Main.panel.statusArea[id].actor.get_first_child(),
            "pan-up-symbolic",
            "pan-down-symbolic")
    }
}
