// Copyright (C) 2011-2016 R M Yorston
// Licence: GPLv2+

const Clutter = imports.gi.Clutter;
const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;
const Lang = imports.lang;
const Shell = imports.gi.Shell;
const Signals = imports.signals;
const St = imports.gi.St;
const Mainloop = imports.mainloop;

const AppFavorites = imports.ui.appFavorites;
const Main = imports.ui.main;
const Panel = imports.ui.panel;
const PopupMenu = imports.ui.popupMenu;
const Tweener = imports.ui.tweener;

const _f = imports.gettext.domain('frippery-panel-favorites').gettext;

const PANEL_LAUNCHER_LABEL_SHOW_TIME = 0.15;
const PANEL_LAUNCHER_LABEL_HIDE_TIME = 0.1;
const PANEL_LAUNCHER_HOVER_TIMEOUT = 300;

const PanelLauncher = new Lang.Class({
    Name: 'PanelLauncher',

    _init: function(app) {
        this.actor = new St.Button({ style_class: 'panel-button',
                                     reactive: true });
        let scaleFactor = St.ThemeContext.get_for_stage(global.stage).scale_factor;
        scaleFactor = scaleFactor <= 0 ? 1 : scaleFactor;
        this.iconSize = 24 / scaleFactor;
        let icon = app.create_icon_texture(this.iconSize);
        this.actor.set_child(icon);
        this.actor._delegate = this;
        let text = app.get_name();
        if ( app.get_description() ) {
            text += '\n' + app.get_description();
        }

        this.label = new St.Label({ style_class: 'panel-launcher-label'});
        this.label.set_text(text);
        Main.layoutManager.addChrome(this.label);
        this.label.hide();
        this.actor.label_actor = this.label;

        this._app = app;
        this._menu = null;
        this._menuManager = new PopupMenu.PopupMenuManager(this);

        this.actor.connect('clicked', Lang.bind(this, function() {
            this._app.open_new_window(-1);
        }));
        this.actor.connect('notify::hover',
                Lang.bind(this, this._onHoverChanged));
        this.actor.connect('button-press-event',
                Lang.bind(this, this._onButtonPress));
        this.actor.opacity = 207;

        this.actor.connect('notify::allocation', Lang.bind(this, this._alloc));
    },

    _onHoverChanged: function(actor) {
        actor.opacity = actor.hover ? 255 : 207;
    },

    _onButtonPress: function(actor, event) {
        let button = event.get_button();
        if (button == 3) {
            this.popupMenu();
            return Clutter.EVENT_STOP;
        }
        return Clutter.EVENT_PROPAGATE;
    },

    // this code stolen from appDisplay.js
    popupMenu: function() {
        if (!this._menu) {
            this._menu = new AppIconMenu(this);
            this._menu.connect('activate-window', Lang.bind(this, function (menu, window) {
                if (window) {
                    Main.activateWindow(window);
                }
            }));
            this._menu.connect('open-state-changed', Lang.bind(this, function (menu, isPoppedUp) {
                if (!isPoppedUp)
                    this.actor.sync_hover();
            }));

            this._menuManager.addMenu(this._menu);
        }

        this.actor.set_hover(true);
        this._menu.popup();
        this._menuManager.ignoreRelease();

        return false;
    },

    _alloc: function() {
        let scaleFactor = St.ThemeContext.get_for_stage(global.stage).scale_factor;
        scaleFactor = scaleFactor <= 0 ? 1 : scaleFactor;
        let allocation = this.actor.allocation;
        let size = (allocation.y2 - allocation.y1 - 1)/scaleFactor - 2;
        if ( size >= 24 && size != this.iconSize ) {
            this.actor.get_child().destroy();
            this.iconSize = size;
            let icon = this._app.create_icon_texture(this.iconSize);
            this.actor.set_child(icon);
        }
    },

    showLabel: function() {
        this.label.opacity = 0;
        this.label.show();

        let [stageX, stageY] = this.actor.get_transformed_position();

        let itemHeight = this.actor.allocation.y2 - this.actor.allocation.y1;
        let itemWidth = this.actor.allocation.x2 - this.actor.allocation.x1;
        let labelWidth = this.label.get_width();

        let node = this.label.get_theme_node();
        let yOffset = node.get_length('-y-offset');

        let y = stageY + itemHeight + yOffset;
        let x = Math.floor(stageX + itemWidth/2 - labelWidth/2);

        let parent = this.label.get_parent();
        let parentWidth = parent.allocation.x2 - parent.allocation.x1;

        if ( Clutter.get_default_text_direction() == Clutter.TextDirection.LTR ) {
            // stop long tooltips falling off the right of the screen
            x = Math.min(x, parentWidth-labelWidth-6);
            // but whatever happens don't let them fall of the left
            x = Math.max(x, 6);
        }
        else {
            x = Math.max(x, 6);
            x = Math.min(x, parentWidth-labelWidth-6);
        }

        this.label.set_position(x, y);
        Tweener.addTween(this.label,
                         { opacity: 255,
                           time: PANEL_LAUNCHER_LABEL_SHOW_TIME,
                           transition: 'easeOutQuad',
                         });
    },

    hideLabel: function() {
        this.label.opacity = 255;
        Tweener.addTween(this.label,
                         { opacity: 0,
                           time: PANEL_LAUNCHER_LABEL_HIDE_TIME,
                           transition: 'easeOutQuad',
                           onComplete: Lang.bind(this, function() {
                               this.label.hide();
                           })
                         });
    },

    destroy: function() {
        this.label.destroy();
        this.actor.destroy();
    }
});

const PanelFavorites = new Lang.Class({
    Name: 'PanelFavorites',

    _init: function() {
        this._showLabelTimeoutId = 0;
        this._resetHoverTimeoutId = 0;
        this._labelShowing = false;

        this.actor = new St.BoxLayout({ name: 'panelFavorites',
                                        x_expand: true, y_expand: true,
                                        style_class: 'panel-favorites' });
        this._display();

        this.container = new St.Bin({ y_fill: true,
                                      x_fill: true,
                                      child: this.actor });

        this.actor.connect('destroy', Lang.bind(this, this._onDestroy));
        this._installChangedId = Shell.AppSystem.get_default().connect('installed-changed', Lang.bind(this, this._redisplay));
        this._changedId = AppFavorites.getAppFavorites().connect('changed', Lang.bind(this, this._redisplay));
    },

    _redisplay: function() {
        for ( let i=0; i<this._buttons.length; ++i ) {
            this._buttons[i].destroy();
        }

        this._display();
    },

    _display: function() {
        let launchers = global.settings.get_strv(AppFavorites.getAppFavorites().FAVORITE_APPS_KEY);

        this._buttons = [];
        let j = 0;
        for ( let i=0; i<launchers.length; ++i ) {
            let app = Shell.AppSystem.get_default().lookup_app(launchers[i]);

            if ( app == null ) {
                continue;
            }

            let launcher = new PanelLauncher(app);
            this.actor.add(launcher.actor);
            launcher.actor.connect('notify::hover',
                        Lang.bind(this, function() {
                            this._onHover(launcher);
                        }));
            this._buttons[j] = launcher;
            ++j;
        }
    },

    // this routine stolen from dash.js
    _onHover: function(launcher) {
        if ( launcher.actor.hover ) {
            if (this._showLabelTimeoutId == 0) {
                let timeout = this._labelShowing ?
                                0 : PANEL_LAUNCHER_HOVER_TIMEOUT;
                this._showLabelTimeoutId = Mainloop.timeout_add(timeout,
                    Lang.bind(this, function() {
                        this._labelShowing = true;
                        launcher.showLabel();
                        this._showLabelTimeoutId = 0;
                        return GLib.SOURCE_REMOVE;
                    }));
                if (this._resetHoverTimeoutId > 0) {
                    Mainloop.source_remove(this._resetHoverTimeoutId);
                    this._resetHoverTimeoutId = 0;
                }
            }
        } else {
            if (this._showLabelTimeoutId > 0) {
                Mainloop.source_remove(this._showLabelTimeoutId);
                this._showLabelTimeoutId = 0;
            }
            launcher.hideLabel();
            if (this._labelShowing) {
                this._resetHoverTimeoutId = Mainloop.timeout_add(
                    PANEL_LAUNCHER_HOVER_TIMEOUT,
                    Lang.bind(this, function() {
                        this._labelShowing = false;
                        this._resetHoverTimeoutId = 0;
                        return GLib.SOURCE_REMOVE;
                    }));
            }
        }
    },

    _onDestroy: function() {
        if ( this._installChangedId != 0 ) {
            Shell.AppSystem.get_default().disconnect(this._installChangedId);
            this._installChangedId = 0;
        }

        if ( this._changedId != 0 ) {
            AppFavorites.getAppFavorites().disconnect(this._changedId);
            this._changedId = 0;
        }
    }
});
Signals.addSignalMethods(PanelFavorites.prototype);

// this code stolen from appDisplay.js
const AppIconMenu = new Lang.Class({
    Name: 'AppIconMenu',
    Extends: PopupMenu.PopupMenu,

    _init: function(source) {
        this.parent(source.actor, 0.5, St.Side.TOP);

        // We want to keep the item hovered while the menu is up
        this.blockSourceEvents = true;

        this._source = source;

        this.actor.add_style_class_name('panel-menu');

        // Chain our visibility and lifecycle to that of the source
        source.actor.connect('notify::mapped', Lang.bind(this, function () {
            if (!source.actor.mapped)
                this.close();
        }));
        source.actor.connect('destroy', Lang.bind(this, function () { this.actor.destroy(); }));

        Main.uiGroup.add_actor(this.actor);
    },

    _redisplay: function() {
        this.removeAll();

        // find windows on current and other workspaces
        let activeWorkspace = global.screen.get_active_workspace();

        let w_here = this._source._app.get_windows().filter(function(w) {
            return !w.skip_taskbar && w.get_workspace() == activeWorkspace;
        });

        let w_there = this._source._app.get_windows().filter(function(w) {
            return !w.skip_taskbar && w.get_workspace() != activeWorkspace;
        });

        // if we have lots of windows use submenus in both cases to
        // avoid confusion
        let use_submenu = w_here.length + w_there.length > 10;

        this._appendWindows(use_submenu, _f('This Workspace'), w_here);

        if (w_here.length && !use_submenu) {
            this._appendSeparator();
        }

		this._appendWindows(use_submenu, _f('Other Workspaces'), w_there);

        if (!this._source._app.is_window_backed()) {
            if (w_there.length && !use_submenu) {
                this._appendSeparator();
            }

            let appInfo = this._source._app.get_app_info();
            let actions = appInfo.list_actions();
            if (this._source._app.can_open_new_window() &&
                actions.indexOf('new-window') == -1) {
                let item = this._appendMenuItem(_("New Window"));
                item.connect('activate', Lang.bind(this, function() {
                    this._source._app.open_new_window(-1);
                    this.emit('activate-window', null);
                }));
            }

            for (let i = 0; i < actions.length; i++) {
                let action = actions[i];
                let item = this._appendMenuItem(appInfo.get_action_name(action));
                item.connect('activate', Lang.bind(this, function(emitter, event) {
                    this._source._app.launch_action(action, event.get_time(), -1);
                    this.emit('activate-window', null);
                }));
            }

            let canFavorite = global.settings.is_writable('favorite-apps');

            if (canFavorite) {
                let isFavorite = AppFavorites.getAppFavorites().isFavorite(this._source._app.get_id());

                if (isFavorite) {
                    let item = this._appendMenuItem(_("Remove from Favorites"));
                    item.connect('activate', Lang.bind(this, function() {
                        let favs = AppFavorites.getAppFavorites();
                        favs.removeFavorite(this._source._app.get_id());
                    }));
                }
            }

            if (Shell.AppSystem.get_default().lookup_app('org.gnome.Software.desktop')) {
                let item = this._appendMenuItem(_("Show Details"));
                item.connect('activate', Lang.bind(this, function() {
                    let id = this._source._app.get_id();
                    let args = GLib.Variant.new('(ss)', [id, '']);
                    Gio.DBus.get(Gio.BusType.SESSION, null,
                        function(o, res) {
                            let bus = Gio.DBus.get_finish(res);
                            bus.call('org.gnome.Software',
                                     '/org/gnome/Software',
                                     'org.gtk.Actions', 'Activate',
                                     GLib.Variant.new('(sava{sv})',
                                                      ['details', [args], null]),
                                     null, 0, -1, null, null);
                            Main.overview.hide();
                        });
                }));
            }
        }
    },

    _appendWindows: function(use_submenu, text, windows) {
        let parent = this;
        if (windows.length && use_submenu) {
            // if we have lots of activatable windows create a submenu
            let item = new PopupMenu.PopupSubMenuMenuItem(text);
            this.addMenuItem(item);
            parent = item.menu;
        }
        for (let i = 0; i < windows.length; i++) {
            let window = windows[i];
            let item = new PopupMenu.PopupMenuItem(window.title);
            parent.addMenuItem(item);
            item.connect('activate', Lang.bind(this, function() {
                this.emit('activate-window', window);
            }));
        }
    },

    _appendSeparator: function () {
        let separator = new PopupMenu.PopupSeparatorMenuItem();
        this.addMenuItem(separator);
    },

    _appendMenuItem: function(labelText) {
        let item = new PopupMenu.PopupMenuItem(labelText);
        this.addMenuItem(item);
        return item;
    },

    popup: function(activatingButton) {
        // this code stolen from PanelMenuButton
        // limit height of menu:  the menu should have scrollable submenus
        // for this to make sense
        let workArea = Main.layoutManager.getWorkAreaForMonitor(
                            Main.layoutManager.primaryIndex);
        let verticalMargins = this.actor.margin_top + this.actor.margin_bottom;
        this.actor.style = ('max-height: ' + Math.round(workArea.height -
                            verticalMargins) + 'px;');

        this._source.label.hide();
        this._redisplay();
        this.open();
    }
});
Signals.addSignalMethods(AppIconMenu.prototype);

let myAddToStatusArea;
let panelFavorites;

function enable() {
    Panel.Panel.prototype.myAddToStatusArea = myAddToStatusArea;

    // place panel to left of app menu, or failing that at right end of box
    let siblings = Main.panel._leftBox.get_children();
    let appMenu = Main.panel.statusArea['appMenu'];
    let pos = appMenu ? siblings.indexOf(appMenu.container) : siblings.length;

    panelFavorites = new PanelFavorites();
    Main.panel.myAddToStatusArea('panel-favorites', panelFavorites,
                                pos, 'left');
}

function disable() {
    delete Panel.Panel.prototype.myAddToStatusArea;

    panelFavorites.actor.destroy();
    panelFavorites.emit('destroy');
    panelFavorites = null;
}

function init() {
    myAddToStatusArea = function(role, indicator, position, box) {
        if (this.statusArea[role])
            throw new Error('Extension point conflict: there is already a status indicator for role ' + role);

        position = position || 0;
        let boxes = {
            left: this._leftBox,
            center: this._centerBox,
            right: this._rightBox
        };
        let boxContainer = boxes[box] || this._rightBox;
        this.statusArea[role] = indicator;
        this._addToPanelBox(role, indicator, position, boxContainer);
        return indicator;
    };
}
