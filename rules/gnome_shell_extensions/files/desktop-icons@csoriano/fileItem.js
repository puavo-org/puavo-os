/* Desktop Icons GNOME Shell extension
 *
 * Copyright (C) 2017 Carlos Soriano <csoriano@redhat.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

const Gtk = imports.gi.Gtk;
const Clutter = imports.gi.Clutter;
const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;
const St = imports.gi.St;
const Pango = imports.gi.Pango;
const Meta = imports.gi.Meta;
const GdkPixbuf = imports.gi.GdkPixbuf;
const Cogl = imports.gi.Cogl;
const GnomeDesktop = imports.gi.GnomeDesktop;

const Mainloop = imports.mainloop;
const Signals = imports.signals;

const Background = imports.ui.background;
const Main = imports.ui.main;
const PopupMenu = imports.ui.popupMenu;
const Util = imports.misc.util;

const ExtensionUtils = imports.misc.extensionUtils;
const Me = ExtensionUtils.getCurrentExtension();
const Extension = Me.imports.extension;
const Prefs = Me.imports.prefs;
const DBusUtils = Me.imports.dbusUtils;
const DesktopIconsUtil = Me.imports.desktopIconsUtil;

const Gettext = imports.gettext.domain('desktop-icons');

const _ = Gettext.gettext;

const DRAG_TRESHOLD = 8;

var S_IXUSR = 0o00100;
var S_IWOTH = 0o00002;

var State = {
    NORMAL: 0,
    GONE: 1,
};

var FileItem = class {

    constructor(file, fileInfo, fileExtra) {
        this._fileExtra = fileExtra;
        this._loadThumbnailDataCancellable = null;
        this._thumbnailScriptWatch = 0;
        this._setMetadataCancellable = null;
        this._queryFileInfoCancellable = null;
        this._isSpecial = this._fileExtra != Prefs.FileType.NONE;

        this._file = file;

        this._savedCoordinates = null;
        let savedCoordinates = fileInfo.get_attribute_as_string('metadata::nautilus-icon-position');
        if (savedCoordinates != null)
            this._savedCoordinates = savedCoordinates.split(',').map(x => Number(x));

        this._state = State.NORMAL;

        this.actor = new St.Bin({ visible: true });
        this.actor.set_fill(true, true);
        let scaleFactor = St.ThemeContext.get_for_stage(global.stage).scale_factor;
        this.actor.set_height(Prefs.get_desired_height(scaleFactor));
        this.actor.set_width(Prefs.get_desired_width(scaleFactor));
        this.actor._delegate = this;
        this.actor.connect('destroy', () => this._onDestroy());

        this._container = new St.BoxLayout({ reactive: true,
                                             track_hover: true,
                                             can_focus: true,
                                             style_class: 'file-item',
                                             x_expand: true,
                                             y_expand: true,
                                             x_align: Clutter.ActorAlign.FILL,
                                             vertical: true });
        this.actor.set_child(this._container);
        this._icon = new St.Bin();
        this._icon.set_height(Prefs.get_icon_size() * scaleFactor);

        this._iconContainer = new St.Bin({ visible: true });
        this._iconContainer.child = this._icon;
        this._container.add_child(this._iconContainer);

        this._label = new St.Label({
            style_class: 'name-label'
        });

        this._container.add_child(this._label);
        let clutterText = this._label.get_clutter_text();
        /* TODO: Convert to gobject.set for 3.30 */
        clutterText.set_line_wrap(true);
        clutterText.set_line_wrap_mode(Pango.WrapMode.WORD_CHAR);
        clutterText.set_ellipsize(Pango.EllipsizeMode.END);

        this._container.connect('button-press-event', (actor, event) => this._onPressButton(actor, event));
        this._container.connect('motion-event', (actor, event) => this._onMotion(actor, event));
        this._container.connect('leave-event', (actor, event) => this._onLeave(actor, event));
        this._container.connect('button-release-event', (actor, event) => this._onReleaseButton(actor, event));

        /* Set the metadata and update relevant UI */
        this._updateMetadataFromFileInfo(fileInfo);

        if (this._isDesktopFile) {
            /* watch for the executable bit being removed or added */
            this._monitorDesktopFile = this._file.monitor_file(Gio.FileMonitorFlags.NONE, null);
            this._monitorDesktopFileId = this._monitorDesktopFile.connect('changed',
                (obj, file, otherFile, eventType) => {
                    switch(eventType) {
                        case Gio.FileMonitorEvent.ATTRIBUTE_CHANGED:
                            this._refreshMetadataAsync(true);
                            break;
                    }
                });
        }

        this._createMenu();
        this._updateIcon();

        this._isSelected = false;
        this._primaryButtonPressed = false;
        if (this._attributeCanExecute && !this._isDesktopFile)
            this._execLine = this.file.get_path();
        if (fileExtra == Prefs.FileType.USER_DIRECTORY_TRASH) {
            // if this icon is the trash, monitor the state of the directory to update the icon
            this._trashChanged = false;
            this._trashInitializeCancellable = null;
            this._scheduleTrashRefreshId = 0;
            this._monitorTrashDir = this._file.monitor_directory(Gio.FileMonitorFlags.WATCH_MOVES, null);
            this._monitorTrashId = this._monitorTrashDir.connect('changed', (obj, file, otherFile, eventType) => {
                switch(eventType) {
                    case Gio.FileMonitorEvent.DELETED:
                    case Gio.FileMonitorEvent.MOVED_OUT:
                    case Gio.FileMonitorEvent.CREATED:
                    case Gio.FileMonitorEvent.MOVED_IN:
                        if (this._queryTrashInfoCancellable || this._scheduleTrashRefreshId) {
                            if (this._scheduleTrashRefreshId)
                                GLib.source_remove(this._scheduleTrashRefreshId);
                            this._scheduleTrashRefreshId = Mainloop.timeout_add(200, () => this._refreshTrashIcon());
                        } else {
                            this._refreshTrashIcon();
                        }
                    break;
                }
            });
        }

        Extension.desktopManager.connect('notify::writable-by-others', () => {
            if (!this._isDesktopFile)
                return;
            this._refreshMetadataAsync(true);
        });
    }

    _onDestroy() {
        /* Regular file data */
        if (this._setMetadataCancellable)
            this._setMetadataCancellable.cancel();
        if (this._queryFileInfoCancellable)
            this._queryFileInfoCancellable.cancel();

        /* Thumbnailing */
        if (this._thumbnailScriptWatch)
            GLib.source_remove(this._thumbnailScriptWatch);
        if (this._loadThumbnailDataCancellable)
            this._loadThumbnailDataCancellable.cancel();

        /* Desktop file */
        if (this._monitorDesktopFileId)
            this._monitorDesktopFile.disconnect(this._monitorDesktopFileId);

        /* Trash */
        if (this._monitorTrashDir)
            this._monitorTrashDir.disconnect(this._monitorTrashId);
        if (this._queryTrashInfoCancellable)
            this._queryTrashInfoCancellable.cancel();
        if (this._scheduleTrashRefreshId)
            GLib.source_remove(this._scheduleTrashRefreshId);
    }

    _refreshMetadataAsync(rebuild) {
        if (this._queryFileInfoCancellable)
            this._queryFileInfoCancellable.cancel();
        this._queryFileInfoCancellable = new Gio.Cancellable();
        this._file.query_info_async(DesktopIconsUtil.DEFAULT_ATTRIBUTES,
                                    Gio.FileQueryInfoFlags.NONE,
                                    GLib.PRIORITY_DEFAULT,
                                    this._queryFileInfoCancellable,
            (source, result) => {
                try {
                    let newFileInfo = source.query_info_finish(result);
                    this._queryFileInfoCancellable = null;
                    this._updateMetadataFromFileInfo(newFileInfo);
                    if (rebuild) {
                        this._createMenu();
                        this._updateIcon();
                    }
                } catch(error) {
                    if (!error.matches(Gio.IOErrorEnum, Gio.IOErrorEnum.CANCELLED))
                        global.log("Error getting the file info: " + error);
                }
            });
    }

    _updateMetadataFromFileInfo(fileInfo) {
        this._fileInfo = fileInfo;

        let oldLabelText = this._label.text;

        this._displayName = fileInfo.get_attribute_as_string('standard::display-name');
        this._attributeCanExecute = fileInfo.get_attribute_boolean('access::can-execute');
        this._unixmode = fileInfo.get_attribute_uint32('unix::mode')
        this._writableByOthers = (this._unixmode & S_IWOTH) != 0;
        this._trusted = fileInfo.get_attribute_as_string('metadata::trusted') == 'true';
        this._attributeContentType = fileInfo.get_content_type();
        this._isDesktopFile = this._attributeContentType == 'application/x-desktop';

        if (this._isDesktopFile && this._writableByOthers)
            log(`desktop-icons: File ${this._displayName} is writable by others - will not allow launching`);

        if (this._isDesktopFile) {
            this._desktopFile = Gio.DesktopAppInfo.new_from_filename(this._file.get_path());
            if (!this._desktopFile) {
                log(`Couldn’t parse ${this._displayName} as a desktop file, will treat it as a regular file.`);
                this._isDesktopFile = false;
            }
        }

        if (this.displayName != oldLabelText) {
            this._label.text = this.displayName;
        }

        this._fileType = fileInfo.get_file_type();
        this._isDirectory = this._fileType == Gio.FileType.DIRECTORY;
        this._isSpecial = this._fileExtra != Prefs.FileType.NONE;
        this._isHidden = fileInfo.get_is_hidden() | fileInfo.get_is_backup();
        this._isSymlink = fileInfo.get_is_symlink();
        this._modifiedTime = this._fileInfo.get_attribute_uint64("time::modified");
        /*
         * This is a glib trick to detect broken symlinks. If a file is a symlink, the filetype
         * points to the final file, unless it is broken; thus if the file type is SYMBOLIC_LINK,
         * it must be a broken link.
         * https://developer.gnome.org/gio/stable/GFile.html#g-file-query-info
         */
        this._isBrokenSymlink = this._isSymlink && this._fileType == Gio.FileType.SYMBOLIC_LINK
    }

    onFileRenamed(file) {
        this._file = file;
        this._refreshMetadataAsync(false);
    }

    _updateIcon() {
        if (this._fileExtra == Prefs.FileType.USER_DIRECTORY_TRASH) {
            this._icon.child = this._createEmblemedStIcon(this._fileInfo.get_icon(), null);
            return;
        }

        let thumbnailFactory = GnomeDesktop.DesktopThumbnailFactory.new(GnomeDesktop.DesktopThumbnailSize.LARGE);
        if (thumbnailFactory.can_thumbnail(this._file.get_uri(),
                                           this._attributeContentType,
                                           this._modifiedTime)) {
            let thumbnail = thumbnailFactory.lookup(this._file.get_uri(), this._modifiedTime);
            if (thumbnail == null) {
                if (!thumbnailFactory.has_valid_failed_thumbnail(this._file.get_uri(),
                                                                 this._modifiedTime)) {
                    let argv = [];
                    argv.push(GLib.build_filenamev([ExtensionUtils.getCurrentExtension().path,
                                                   'createThumbnail.js']));
                    argv.push(this._file.get_path());
                    let [success, pid] = GLib.spawn_async(null, argv, null,
                                                          GLib.SpawnFlags.SEARCH_PATH | GLib.SpawnFlags.DO_NOT_REAP_CHILD, null);
                    if (this._thumbnailScriptWatch)
                        GLib.source_remove(this._thumbnailScriptWatch);
                    this._thumbnailScriptWatch = GLib.child_watch_add(GLib.PRIORITY_DEFAULT,
                                                                      pid,
                        (pid, exitCode) => {
                            if (exitCode == 0)
                                this._updateIcon();
                            else
                                global.log('Failed to generate thumbnail for ' + this._filePath);
                            GLib.spawn_close_pid(pid);
                            return false;
                        }
                    );
                }
            } else {
                if (this._loadThumbnailDataCancellable)
                    this._loadThumbnailDataCancellable.cancel();
                this._loadThumbnailDataCancellable = new Gio.Cancellable();
                let thumbnailFile = Gio.File.new_for_path(thumbnail);
                thumbnailFile.load_bytes_async(this._loadThumbnailDataCancellable,
                    (source, result) => {
                        try {
                            let [thumbnailData, etag_out] = source.load_bytes_finish(result);
                            let thumbnailStream = Gio.MemoryInputStream.new_from_bytes(thumbnailData);
                            let thumbnailPixbuf = GdkPixbuf.Pixbuf.new_from_stream(thumbnailStream, null);

                            if (thumbnailPixbuf != null) {
                                let scaleFactor = St.ThemeContext.get_for_stage(global.stage).scale_factor;
                                let thumbnailImage = new Clutter.Image();
                                thumbnailImage.set_data(thumbnailPixbuf.get_pixels(),
                                                        thumbnailPixbuf.has_alpha ? Cogl.PixelFormat.RGBA_8888 : Cogl.PixelFormat.RGB_888,
                                                        thumbnailPixbuf.width,
                                                        thumbnailPixbuf.height,
                                                        thumbnailPixbuf.rowstride
                                );
                                let icon = new Clutter.Actor();
                                icon.set_content(thumbnailImage);
                                let width = Prefs.get_desired_width(scaleFactor);
                                let height = Prefs.get_icon_size() * scaleFactor;
                                let aspectRatio = thumbnailPixbuf.width / thumbnailPixbuf.height;
                                if ((width / height) > aspectRatio)
                                    icon.set_size(height * aspectRatio, height);
                                else
                                    icon.set_size(width, width / aspectRatio);
                                this._icon.child = icon;
                            }
                        } catch (error) {
                            if (!error.matches(Gio.IOErrorEnum, Gio.IOErrorEnum.CANCELLED)) {
                                global.log('Error while loading thumbnail: ' + error);
                                this._icon.child = this._createEmblemedStIcon(this._fileInfo.get_icon(), null);
                            }
                        }
                    }
                );
            }
        }

        if (this._isBrokenSymlink) {
            this._icon.child = this._createEmblemedStIcon(null, 'text-x-generic');
        } else {
            if (this.trustedDesktopFile && this._desktopFile.has_key('Icon'))
                this._icon.child = this._createEmblemedStIcon(null, this._desktopFile.get_string('Icon'));
            else
                this._icon.child = this._createEmblemedStIcon(this._fileInfo.get_icon(), null);
        }
    }

    _refreshTrashIcon() {
        if (this._queryTrashInfoCancellable)
            this._queryTrashInfoCancellable.cancel();
        this._queryTrashInfoCancellable = new Gio.Cancellable();

        this._file.query_info_async(DesktopIconsUtil.DEFAULT_ATTRIBUTES,
                                    Gio.FileQueryInfoFlags.NONE,
                                    GLib.PRIORITY_DEFAULT,
                                    this._queryTrashInfoCancellable,
            (source, result) => {
                try {
                    this._fileInfo = source.query_info_finish(result);
                    this._queryTrashInfoCancellable = null;
                    this._updateIcon();
                } catch(error) {
                    if (!error.matches(Gio.IOErrorEnum, Gio.IOErrorEnum.CANCELLED))
                        global.log('Error getting the number of files in the trash: ' + error);
                }
            });

        this._scheduleTrashRefreshId = 0;
        return false;
    }

    get file() {
        return this._file;
    }

    get isHidden() {
        return this._isHidden;
    }

    _createEmblemedStIcon(icon, iconName) {
        if (icon == null) {
            if (GLib.path_is_absolute(iconName)) {
                let iconFile = Gio.File.new_for_commandline_arg(iconName);
                icon = new Gio.FileIcon({ file: iconFile });
            } else {
                icon = Gio.ThemedIcon.new_with_default_fallbacks(iconName);
            }
        }
        let itemIcon = Gio.EmblemedIcon.new(icon, null);

        if (this._isSymlink) {
            if (this._isBrokenSymlink)
                itemIcon.add_emblem(Gio.Emblem.new(Gio.ThemedIcon.new('emblem-unreadable')));
            else
                itemIcon.add_emblem(Gio.Emblem.new(Gio.ThemedIcon.new('emblem-symbolic-link')));
        } else if (this.trustedDesktopFile) {
            itemIcon.add_emblem(Gio.Emblem.new(Gio.ThemedIcon.new('emblem-symbolic-link')));
        }

        return new St.Icon({ gicon: itemIcon,
                             icon_size: Prefs.get_icon_size()
        });
    }

    doRename() {
        if (!this.canRename()) {
            log (`Error: ${this.file.get_uri()} cannot be renamed`);
            return;
        }

        this.emit('rename-clicked');
    }

    doOpen() {
        if (this._isBrokenSymlink) {
            log(`Error: Can’t open ${this.file.get_uri()} because it is a broken symlink.`);
            return;
        }

        if (this.trustedDesktopFile) {
            this._desktopFile.launch_uris_as_manager([], null, GLib.SpawnFlags.SEARCH_PATH, null, null);
            return;
        }

        if (this._attributeCanExecute && !this._isDirectory && !this._isDesktopFile) {
            if (this._execLine)
                Util.spawnCommandLine(this._execLine);
            return;
        }

        Gio.AppInfo.launch_default_for_uri_async(this.file.get_uri(),
            null, null,
            (source, result) => {
                try {
                    Gio.AppInfo.launch_default_for_uri_finish(result);
                } catch (e) {
                    log('Error opening file ' + this.file.get_uri() + ': ' + e.message);
                }
            }
        );
    }

    _onCopyClicked() {
        Extension.desktopManager.doCopy();
    }

    _onCutClicked() {
        Extension.desktopManager.doCut();
    }

    _onShowInFilesClicked() {

        DBusUtils.FreeDesktopFileManagerProxy.ShowItemsRemote([this.file.get_uri()], '',
            (result, error) => {
                if (error)
                    log('Error showing file on desktop: ' + error.message);
            }
        );
    }

    _onPropertiesClicked() {

        DBusUtils.FreeDesktopFileManagerProxy.ShowItemPropertiesRemote([this.file.get_uri()], '',
            (result, error) => {
                if (error)
                    log('Error showing properties: ' + error.message);
            }
        );
    }

    _onMoveToTrashClicked() {
        Extension.desktopManager.doTrash();
    }

    _onEmptyTrashClicked() {
        Extension.desktopManager.doEmptyTrash();
    }

    get _allowLaunchingText() {
        if (this.trustedDesktopFile)
            return _("Don’t Allow Launching");

        return _("Allow Launching");
    }

    get metadataTrusted() {
        return this._trusted;
    }

    set metadataTrusted(value) {
        this._trusted = value;

        let info = new Gio.FileInfo();
        info.set_attribute_string('metadata::trusted',
                                  value ? 'true' : 'false');
        this._file.set_attributes_async(info,
                                        Gio.FileQueryInfoFlags.NONE,
                                        GLib.PRIORITY_LOW,
                                        null,
            (source, result) => {
                try {
                    source.set_attributes_finish(result);
                    this._refreshMetadataAsync(true);
                } catch(e) {
                    log(`Failed to set metadata::trusted: ${e.message}`);
                }
        });
    }

    _onAllowDisallowLaunchingClicked() {
        this.metadataTrusted = !this.trustedDesktopFile;

        /*
         * we're marking as trusted, make the file executable too. note that we
         * do not ever remove the executable bit, since we don't know who set
         * it.
         */
        if (this.metadataTrusted && !this._attributeCanExecute) {
            let info = new Gio.FileInfo();
            let newUnixMode = this._unixmode | S_IXUSR;
            info.set_attribute_uint32(Gio.FILE_ATTRIBUTE_UNIX_MODE, newUnixMode);
            this._file.set_attributes_async(info,
                                            Gio.FileQueryInfoFlags.NONE,
                                            GLib.PRIORITY_LOW,
                                            null,
                (source, result) => {
                    try {
                        source.set_attributes_finish (result);
                    } catch(e) {
                        log(`Failed to set unix mode: ${e.message}`);
                    }
            });
            this._file.set_attributes_from_info(info,
                                                Gio.FileQueryInfoFlags.NONE,
                                                GLib.PRIORITY_LOW,
                                                null);
        }
    }

    canRename() {
        return !this.trustedDesktopFile && this._fileExtra == Prefs.FileType.NONE;
    }

    _doOpenWith() {
        DBusUtils.openFileWithOtherApplication(this.file.get_path());
    }

    _getSelectionStyle() {
        let rgba = DesktopIconsUtil.getGtkClassBackgroundColor('view', Gtk.StateFlags.SELECTED);
        let background_color =
            'rgba(' + rgba.red * 255 + ', ' + rgba.green * 255 + ', ' + rgba.blue * 255 + ', 0.6)';
        let border_color =
            'rgba(' + rgba.red * 255 + ', ' + rgba.green * 255 + ', ' + rgba.blue * 255 + ', 0.8)';

        return 'background-color: ' + background_color + ';' +
               'border-color: ' + border_color + ';'
    }

    _createMenu() {
        this._menuManager = new PopupMenu.PopupMenuManager({ actor: this.actor });
        let side = St.Side.LEFT;
        if (Clutter.get_default_text_direction() == Clutter.TextDirection.RTL)
            side = St.Side.RIGHT;
        this._menu = new PopupMenu.PopupMenu(this.actor, 0.5, side);
        this._menu.addAction(_('Open'), () => this.doOpen());
        switch (this._fileExtra) {
        case Prefs.FileType.NONE:
            if (!this._isDirectory)
                this._actionOpenWith = this._menu.addAction(_('Open With Other Application'), () => this._doOpenWith());
            else
                this._actionOpenWith = null;
            this._menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
            this._actionCut = this._menu.addAction(_('Cut'), () => this._onCutClicked());
            this._actionCopy = this._menu.addAction(_('Copy'), () => this._onCopyClicked());
            if (this.canRename())
                this._menu.addAction(_('Rename…'), () => this.doRename());
            this._actionTrash = this._menu.addAction(_('Move to Trash'), () => this._onMoveToTrashClicked());
            if (this._isDesktopFile && !Extension.desktopManager.writableByOthers && !this._writableByOthers) {
                this._menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
                this._allowLaunchingMenuItem = this._menu.addAction(this._allowLaunchingText,
                                                                    () => this._onAllowDisallowLaunchingClicked());

            }
            break;
        case Prefs.FileType.USER_DIRECTORY_TRASH:
            this._menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
            this._menu.addAction(_('Empty Trash'), () => this._onEmptyTrashClicked());
            break;
        default:
            break;
        }
        this._menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        this._menu.addAction(_('Properties'), () => this._onPropertiesClicked());
        this._menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        this._menu.addAction(_('Show in Files'), () => this._onShowInFilesClicked());
        if (this._isDirectory && this.file.get_path() != null)
            this._actionOpenInTerminal = this._menu.addAction(_('Open in Terminal'), () => this._onOpenTerminalClicked());

        this._menuManager.addMenu(this._menu);

        Main.layoutManager.uiGroup.add_child(this._menu.actor);
        this._menu.actor.hide();
    }

    _onOpenTerminalClicked () {
        let command = DesktopIconsUtil.getTerminalCommand(this.file.get_path());
        Util.spawnCommandLine(command);
    }

    _onPressButton(actor, event) {
        let button = event.get_button();
        if (button == 3) {
            if (!this.isSelected)
                this.emit('selected', false, true);
            this._menu.toggle();
            if (this._actionOpenWith) {
                let allowOpenWith = (Extension.desktopManager.getNumberOfSelectedItems() == 1);
                this._actionOpenWith.setSensitive(allowOpenWith);
            }
            let specialFilesSelected = Extension.desktopManager.checkIfSpecialFilesAreSelected();
            if (this._actionCut)
                this._actionCut.setSensitive(!specialFilesSelected);
            if (this._actionCopy)
                this._actionCopy.setSensitive(!specialFilesSelected);
            if (this._actionTrash)
                this._actionTrash.setSensitive(!specialFilesSelected);
            return Clutter.EVENT_STOP;
        } else if (button == 1) {
            if (event.get_click_count() == 1) {
                let [x, y] = event.get_coords();
                this._primaryButtonPressed = true;
                this._buttonPressInitialX = x;
                this._buttonPressInitialY = y;
                let shiftPressed = !!(event.get_state() & Clutter.ModifierType.SHIFT_MASK);
                let controlPressed = !!(event.get_state() & Clutter.ModifierType.CONTROL_MASK);
                if (!this.isSelected) {
                    this.emit('selected', shiftPressed || controlPressed, true);
                }
            }
            return Clutter.EVENT_STOP;
        }

        return Clutter.EVENT_PROPAGATE;
    }

    _onLeave(actor, event) {
        this._primaryButtonPressed = false;
    }

    _onMotion(actor, event) {
        let [x, y] = event.get_coords();
        if (this._primaryButtonPressed) {
            let xDiff = x - this._buttonPressInitialX;
            let yDiff = y - this._buttonPressInitialY;
            let distance = Math.sqrt(Math.pow(xDiff, 2) + Math.pow(yDiff, 2));
            if (distance > DRAG_TRESHOLD) {
                // Don't need to track anymore this if we start drag, and also
                // avoids reentrance here
                this._primaryButtonPressed = false;
                let event = Clutter.get_current_event();
                let [x, y] = event.get_coords();
                Extension.desktopManager.dragStart();
            }
        }

        return Clutter.EVENT_PROPAGATE;
    }

    _onReleaseButton(actor, event) {
        let button = event.get_button();
        if (button == 1) {
            // primaryButtonPressed is TRUE only if the user has pressed the button
            // over an icon, and if (s)he has not started a drag&drop operation
            if (this._primaryButtonPressed) {
                this._primaryButtonPressed = false;
                let shiftPressed = !!(event.get_state() & Clutter.ModifierType.SHIFT_MASK);
                let controlPressed = !!(event.get_state() & Clutter.ModifierType.CONTROL_MASK);
                if ((event.get_click_count() == 1) && Prefs.CLICK_POLICY_SINGLE && !shiftPressed && !controlPressed)
                    this.doOpen();
                this.emit('selected', shiftPressed || controlPressed, true);
                return Clutter.EVENT_STOP;
            }
            if ((event.get_click_count() == 2) && (!Prefs.CLICK_POLICY_SINGLE))
                this.doOpen();
        }
        return Clutter.EVENT_PROPAGATE;
    }

    get savedCoordinates() {
        return this._savedCoordinates;
    }

    _onSetMetadataFileFinished(source, result) {
        try {
            let [success, info] = source.set_attributes_finish(result);
        } catch (error) {
            if (!error.matches(Gio.IOErrorEnum, Gio.IOErrorEnum.CANCELLED))
                log('Error setting metadata to desktop files ', error);
        }
    }

    set savedCoordinates(pos) {
        if (this._setMetadataCancellable)
            this._setMetadataCancellable.cancel();

        this._setMetadataCancellable = new Gio.Cancellable();
        this._savedCoordinates = [pos[0], pos[1]];
        let info = new Gio.FileInfo();
        info.set_attribute_string('metadata::nautilus-icon-position',
                                  `${pos[0]},${pos[1]}`);
        this.file.set_attributes_async(info,
            Gio.FileQueryInfoFlags.NONE,
            GLib.PRIORITY_DEFAULT,
            this._setMetadataCancellable,
            (source, result) => this._onSetMetadataFileFinished(source, result)
        );
    }

    intersectsWith(argX, argY, argWidth, argHeight) {
        let rect = new Meta.Rectangle({ x: argX, y: argY, width: argWidth, height: argHeight });
        let [containerX, containerY] = this._container.get_transformed_position();
        let boundingBox = new Meta.Rectangle({ x: containerX,
                                               y: containerY,
                                               width: this._container.allocation.x2 - this._container.allocation.x1,
                                               height: this._container.allocation.y2 - this._container.allocation.y1 });
        let [intersects, _] = rect.intersect(boundingBox);

        return intersects;
    }

    set isSelected(isSelected) {
        isSelected = !!isSelected;
        if (isSelected == this._isSelected)
            return;

        if (isSelected) {
            this._container.set_style(this._getSelectionStyle());
        } else {
            this._container.set_style('background-color: transparent');
            this._container.set_style('border-color: transparent');
        }

        this._isSelected = isSelected;
    }

    get isSelected() {
        return this._isSelected;
    }

    get isSpecial() {
        return this._isSpecial;
    }

    get state() {
        return this._state;
    }

    set state(state) {
        if (state == this._state)
            return;

        this._state = state;
    }

    get isDirectory() {
        return this._isDirectory;
    }

    get trustedDesktopFile() {
        return this._isDesktopFile &&
               this._attributeCanExecute &&
               this.metadataTrusted &&
               !Extension.desktopManager.writableByOthers &&
               !this._writableByOthers;
    }

    get fileName() {
        return this._fileInfo.get_name();
    }

    get displayName() {
        if (this.trustedDesktopFile)
            return this._desktopFile.get_name();

        return this._displayName || null;
    }

    acceptDrop() {
        return Extension.desktopManager.selectionDropOnFileItem(this);
    }
};
Signals.addSignalMethods(FileItem.prototype);
