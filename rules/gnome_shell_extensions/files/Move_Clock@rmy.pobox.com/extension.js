// Copyright (C) 2011-2024 R M Yorston
// Licence: GPLv2+

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as SessionMode from 'resource:///org/gnome/shell/ui/sessionMode.js';

export default class FripperyMoveClock {
    enable() {
        // do nothing if the clock isn't centred in this mode
        if ( Main.sessionMode.panel.center.indexOf('dateMenu') == -1 ) {
            return;
        }

        let centerBox = Main.panel._centerBox;
        let rightBox = Main.panel._rightBox;
        let dateMenu = Main.panel.statusArea['dateMenu'];
        let children = centerBox.get_children();

        // only move the clock if it's in the centre box
        if ( children.indexOf(dateMenu.container) != -1 ) {
            centerBox.remove_child(dateMenu.container);

            children = rightBox.get_children();
            rightBox.insert_child_at_index(dateMenu.container,
                                            children.length-1);
       }
    }

    disable() {
        // do nothing if the clock isn't centred in this mode
        if ( Main.sessionMode.panel.center.indexOf('dateMenu') == -1 ) {
            return;
        }

        let centerBox = Main.panel._centerBox;
        let rightBox = Main.panel._rightBox;
        let dateMenu = Main.panel.statusArea['dateMenu'];
        let children = rightBox.get_children();

        // only move the clock back if it's in the right box
        if ( children.indexOf(dateMenu.container) != -1 ) {
            rightBox.remove_child(dateMenu.container);
            centerBox.add_child(dateMenu.container);
        }
    }
}
