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
const St = imports.gi.St;
const Gio = imports.gi.Gio;
const GLib = imports.gi.GLib;
const Shell = imports.gi.Shell;

const Signals = imports.signals;

const Layout = imports.ui.layout;
const Main = imports.ui.main;
const BoxPointer = imports.ui.boxpointer;
const PopupMenu = imports.ui.popupMenu;
const GrabHelper = imports.ui.grabHelper;

const ExtensionUtils = imports.misc.extensionUtils;
const Me = ExtensionUtils.getCurrentExtension();
const CreateFolderDialog = Me.imports.createFolderDialog;
const Extension = Me.imports.extension;
const FileItem = Me.imports.fileItem;
const Prefs = Me.imports.prefs;
const DBusUtils = Me.imports.dbusUtils;
const DesktopIconsUtil = Me.imports.desktopIconsUtil;
const Util = imports.misc.util;

const Clipboard = St.Clipboard.get_default();
const CLIPBOARD_TYPE = St.ClipboardType.CLIPBOARD;
const Gettext = imports.gettext.domain('desktop-icons');

const _ = Gettext.gettext;


/* From NautilusFileUndoManagerState */
var UndoStatus = {
    NONE: 0,
    UNDO: 1,
    REDO: 2,
};

var StoredCoordinates = {
    PRESERVE: 0,
    OVERWRITE:1,
};

class Placeholder extends St.Bin {
    constructor() {
        super();
    }
}

var DesktopGrid = class {

    constructor(bgManager) {
        this._bgManager = bgManager;

        this._fileItemHandlers = new Map();
        this._fileItems = [];

        this.layout = new Clutter.GridLayout({
            orientation: Clutter.Orientation.VERTICAL,
            column_homogeneous: true,
            row_homogeneous: true
        });

        this._actorLayout = new Clutter.BinLayout({
            x_align: Clutter.BinAlignment.FIXED,
            y_align: Clutter.BinAlignment.FIXED
        });

        this.actor = new St.Widget({
            layout_manager: this._actorLayout
        });
        this.actor._delegate = this;

        this._grid = new St.Widget({
            name: 'DesktopGrid',
            layout_manager: this.layout,
            reactive: true,
            x_expand: true,
            y_expand: true,
            can_focus: true,
            opacity: 255
        });
        this.actor.add_child(this._grid);

        this._renamePopup = new RenamePopup(this);
        this.actor.add_child(this._renamePopup.actor);

        this._bgManager._container.add_child(this.actor);

        this.actor.connect('destroy', () => this._onDestroy());

        let monitorIndex = bgManager._monitorIndex;
        this._monitorConstraint = new Layout.MonitorConstraint({
            index: monitorIndex,
            work_area: true
        });
        this.actor.add_constraint(this._monitorConstraint);

        this._addDesktopBackgroundMenu();

        this._bgDestroyedId = bgManager.backgroundActor.connect('destroy',
            () => this._backgroundDestroyed());

        this._grid.connect('button-press-event', (actor, event) => this._onPressButton(actor, event));

        this._grid.connect('key-press-event', this._onKeyPress.bind(this));

        this._grid.connect('allocation-changed', () => Extension.desktopManager.scheduleReLayoutChildren());
    }

    _onKeyPress(actor, event) {
        if (global.stage.get_key_focus() != actor)
            return Clutter.EVENT_PROPAGATE;

        let symbol = event.get_key_symbol();
        let isCtrl = (event.get_state() & Clutter.ModifierType.CONTROL_MASK) != 0;
        let isShift = (event.get_state() & Clutter.ModifierType.SHIFT_MASK) != 0;
        if (isCtrl && isShift && [Clutter.Z, Clutter.z].indexOf(symbol) > -1) {
            this._doRedo();
            return Clutter.EVENT_STOP;
        }
        else if (isCtrl && [Clutter.Z, Clutter.z].indexOf(symbol) > -1) {
            this._doUndo();
            return Clutter.EVENT_STOP;
        }
        else if (isCtrl && [Clutter.C, Clutter.c].indexOf(symbol) > -1) {
            Extension.desktopManager.doCopy();
            return Clutter.EVENT_STOP;
        }
        else if (isCtrl && [Clutter.X, Clutter.x].indexOf(symbol) > -1) {
            Extension.desktopManager.doCut();
            return Clutter.EVENT_STOP;
        }
        else if (isCtrl && [Clutter.V, Clutter.v].indexOf(symbol) > -1) {
            this._doPaste();
            return Clutter.EVENT_STOP;
        }
        else if (symbol == Clutter.Return) {
            Extension.desktopManager.doOpen();
            return Clutter.EVENT_STOP;
        }
        else if (symbol == Clutter.Delete) {
            Extension.desktopManager.doTrash();
            return Clutter.EVENT_STOP;
        } else if (symbol == Clutter.F2) {
            // Support renaming other grids file items.
            Extension.desktopManager.doRename();
            return Clutter.EVENT_STOP;
        }

        return Clutter.EVENT_PROPAGATE;
    }

    _backgroundDestroyed() {
        this._bgDestroyedId = 0;
        if (this._bgManager == null)
            return;

        if (this._bgManager._backgroundSource) {
            this._bgDestroyedId = this._bgManager.backgroundActor.connect('destroy',
                () => this._backgroundDestroyed());
        } else {
            this.actor.destroy();
        }
    }

    _onDestroy() {
        if (this._bgDestroyedId && this._bgManager.backgroundActor != null)
            this._bgManager.backgroundActor.disconnect(this._bgDestroyedId);
        this._bgDestroyedId = 0;
        this._bgManager = null;
    }

    _onNewFolderClicked() {

        let dialog = new CreateFolderDialog.CreateFolderDialog();

        dialog.connect('response', (dialog, name) => {
            let dir = DesktopIconsUtil.getDesktopDir().get_child(name);
            DBusUtils.NautilusFileOperationsProxy.CreateFolderRemote(dir.get_uri(),
                (result, error) => {
                    if (error)
                        throw new Error('Error creating new folder: ' + error.message);
                }
            );
        });

        dialog.open();
    }

    _parseClipboardText(text) {
        let lines = text.split('\n');
        let [mime, action, ...files] = lines;

        if (mime != 'x-special/nautilus-clipboard')
            return [false, false, null];

        if (!(['copy', 'cut'].includes(action)))
            return [false, false, null];
        let isCut = action == 'cut';

        /* Last line is empty due to the split */
        if (files.length <= 1)
            return [false, false, null];
        /* Remove last line */
        files.pop();

        return [true, isCut, files];
    }

    _doPaste() {
        Clipboard.get_text(CLIPBOARD_TYPE,
            (clipboard, text) => {
                let [valid, is_cut, files] = this._parseClipboardText(text);
                if (!valid)
                    return;

                let desktopDir = `${DesktopIconsUtil.getDesktopDir().get_uri()}`;
                if (is_cut) {
                    DBusUtils.NautilusFileOperationsProxy.MoveURIsRemote(files, desktopDir,
                        (result, error) => {
                            if (error)
                                throw new Error('Error moving files: ' + error.message);
                        }
                    );
                } else {
                    DBusUtils.NautilusFileOperationsProxy.CopyURIsRemote(files, desktopDir,
                        (result, error) => {
                            if (error)
                                throw new Error('Error copying files: ' + error.message);
                        }
                    );
                }
            }
        );
    }

    _onPasteClicked() {
        this._doPaste();
    }

    _doUndo() {
        DBusUtils.NautilusFileOperationsProxy.UndoRemote(
            (result, error) => {
                if (error)
                    throw new Error('Error performing undo: ' + error.message);
            }
        );
    }

    _onUndoClicked() {
        this._doUndo();
    }

    _doRedo() {
        DBusUtils.NautilusFileOperationsProxy.RedoRemote(
            (result, error) => {
                if (error)
                    throw new Error('Error performing redo: ' + error.message);
            }
        );
    }

    _onRedoClicked() {
        this._doRedo();
    }

    _onOpenDesktopInFilesClicked() {
        Gio.AppInfo.launch_default_for_uri_async(DesktopIconsUtil.getDesktopDir().get_uri(),
            null, null,
            (source, result) => {
                try {
                    Gio.AppInfo.launch_default_for_uri_finish(result);
                } catch (e) {
                   log('Error opening Desktop in Files: ' + e.message);
                }
            }
        );
    }

    _onOpenTerminalClicked() {
        let desktopPath = DesktopIconsUtil.getDesktopDir().get_path();
        let command = DesktopIconsUtil.getTerminalCommand(desktopPath);

        Util.spawnCommandLine(command);
    }

    _syncUndoRedo() {
        this._undoMenuItem.actor.visible = DBusUtils.NautilusFileOperationsProxy.UndoStatus == UndoStatus.UNDO;
        this._redoMenuItem.actor.visible = DBusUtils.NautilusFileOperationsProxy.UndoStatus == UndoStatus.REDO;
    }

    _undoStatusChanged(proxy, properties, test) {
        if ('UndoStatus' in properties.deep_unpack())
            this._syncUndoRedo();
    }

    _createDesktopBackgroundMenu() {
        let menu = new PopupMenu.PopupMenu(Main.layoutManager.dummyCursor,
                                           0, St.Side.TOP);
        menu.addAction(_("New Folder"), () => this._onNewFolderClicked());
        menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        this._pasteMenuItem = menu.addAction(_("Paste"), () => this._onPasteClicked());
        this._undoMenuItem = menu.addAction(_("Undo"), () => this._onUndoClicked());
        this._redoMenuItem = menu.addAction(_("Redo"), () => this._onRedoClicked());
        menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        menu.addAction(_("Show Desktop in Files"), () => this._onOpenDesktopInFilesClicked());
        menu.addAction(_("Open in Terminal"), () => this._onOpenTerminalClicked());
        menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        menu.addSettingsAction(_("Change Background…"), 'gnome-background-panel.desktop');
        menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        menu.addSettingsAction(_("Display Settings"), 'gnome-display-panel.desktop');
        menu.addSettingsAction(_("Settings"), 'gnome-control-center.desktop');

        menu.actor.add_style_class_name('background-menu');

        Main.layoutManager.uiGroup.add_child(menu.actor);
        menu.actor.hide();

        menu._propertiesChangedId = DBusUtils.NautilusFileOperationsProxy.connect('g-properties-changed',
            this._undoStatusChanged.bind(this));
        this._syncUndoRedo();

        menu.connect('destroy',
            () => DBusUtils.NautilusFileOperationsProxy.disconnect(menu._propertiesChangedId));
        menu.connect('open-state-changed',
            (popupm, isOpen) => {
                if (isOpen) {
                    Clipboard.get_text(CLIPBOARD_TYPE,
                        (clipBoard, text) => {
                            let [valid, is_cut, files] = this._parseClipboardText(text);
                            this._pasteMenuItem.actor.visible = valid;
                        }
                    );
                }
            }
        );

        return menu;
    }

    _openMenu(x, y) {
        Main.layoutManager.setDummyCursorGeometry(x, y, 0, 0);
        this.actor._desktopBackgroundMenu.open(BoxPointer.PopupAnimation.NONE);
        /* Since the handler is in the press event it needs to ignore the release event
         * to not immediately close the menu on release
         */
        this.actor._desktopBackgroundManager.ignoreRelease();
    }

    _addFileItemTo(fileItem, column, row, overwriteCoordinates) {
        let placeholder = this.layout.get_child_at(column, row);
        placeholder.child = fileItem.actor;
        this._fileItems.push(fileItem);
        let selectedId = fileItem.connect('selected', this._onFileItemSelected.bind(this));
        let renameId = fileItem.connect('rename-clicked', this.doRename.bind(this));
        this._fileItemHandlers.set(fileItem, [selectedId, renameId]);

        /* If this file is new in the Desktop and hasn't yet
         * fixed coordinates, store the new possition to ensure
         * that the next time it will be shown in the same possition.
         * Also store the new possition if it has been moved by the user,
         * and not triggered by a screen change.
         */
        if ((fileItem.savedCoordinates == null) || (overwriteCoordinates == StoredCoordinates.OVERWRITE)) {
            let [fileX, fileY] = placeholder.get_transformed_position();
            fileItem.savedCoordinates = [Math.round(fileX), Math.round(fileY)];
        }
    }

    addFileItemCloseTo(fileItem, x, y, overwriteCoordinates) {
        let [column, row] = this._getEmptyPlaceClosestTo(x, y);
        this._addFileItemTo(fileItem, column, row, overwriteCoordinates);
    }

    _getEmptyPlaceClosestTo(x, y) {
        let maxColumns = this._getMaxColumns();
        let maxRows = this._getMaxRows();

        let [actorX, actorY] = this._grid.get_transformed_position();
        let actorWidth = this._grid.allocation.x2 - this._grid.allocation.x1;
        let actorHeight = this._grid.allocation.y2 - this._grid.allocation.y1;
        let placeX = Math.round((x - actorX) * maxColumns / actorWidth);
        let placeY = Math.round((y - actorY) * maxRows / actorHeight);

        placeX = DesktopIconsUtil.clamp(placeX, 0, maxColumns - 1);
        placeY = DesktopIconsUtil.clamp(placeY, 0, maxRows - 1);
        if (this.layout.get_child_at(placeX, placeY).child == null)
            return [placeX, placeY];
        let found = false;
        let resColumn = null;
        let resRow = null;
        let minDistance = Infinity;
        for (let column = 0; column < maxColumns; column++) {
            for (let row = 0; row < maxRows; row++) {
                let placeholder = this.layout.get_child_at(column, row);
                if (placeholder.child != null)
                    continue;

                let [proposedX, proposedY] = placeholder.get_transformed_position();
                let distance = DesktopIconsUtil.distanceBetweenPoints(proposedX, proposedY, x, y);
                if (distance < minDistance) {
                    found = true;
                    minDistance = distance;
                    resColumn = column;
                    resRow = row;
                }
            }
        }

        if (!found)
            throw new Error(`Not enough place at monitor ${this._bgManager._monitorIndex}`);

        return [resColumn, resRow];
    }

    removeFileItem(fileItem) {
        let index = this._fileItems.indexOf(fileItem);
        if (index > -1)
            this._fileItems.splice(index, 1);
        else
            throw new Error('Error removing children from container');

        let [column, row] = this._getPosOfFileItem(fileItem);
        let placeholder = this.layout.get_child_at(column, row);
        placeholder.child = null;
        let [selectedId, renameId] = this._fileItemHandlers.get(fileItem);
        fileItem.disconnect(selectedId);
        fileItem.disconnect(renameId);
        this._fileItemHandlers.delete(fileItem);
    }

    _fillPlaceholders() {
        for (let column = 0; column < this._getMaxColumns(); column++) {
            for (let row = 0; row < this._getMaxRows(); row++) {
                this.layout.attach(new Placeholder(), column, row, 1, 1);
            }
        }
    }

    reset() {
        let tmpFileItemsCopy = this._fileItems.slice();
        for (let fileItem of tmpFileItemsCopy)
            this.removeFileItem(fileItem);
        this._grid.remove_all_children();

        this._fillPlaceholders();
    }

    _onStageMotion(actor, event) {
        if (this._drawingRubberBand) {
            let [x, y] = event.get_coords();
            this._updateRubberBand(x, y);
            this._selectFromRubberband(x, y);
        }
        return Clutter.EVENT_PROPAGATE;
    }

    _onPressButton(actor, event) {
        let button = event.get_button();
        let [x, y] = event.get_coords();

        this._grid.grab_key_focus();

        if (button == 1) {
            let shiftPressed = !!(event.get_state() & Clutter.ModifierType.SHIFT_MASK);
            let controlPressed = !!(event.get_state() & Clutter.ModifierType.CONTROL_MASK);
            if (!shiftPressed && !controlPressed)
                Extension.desktopManager.clearSelection();
            let [gridX, gridY] = this._grid.get_transformed_position();
            Extension.desktopManager.startRubberBand(x, y, gridX, gridY);
            return Clutter.EVENT_STOP;
        }

        if (button == 3) {
            this._openMenu(x, y);

            return Clutter.EVENT_STOP;
        }

        return Clutter.EVENT_PROPAGATE;
    }

    _addDesktopBackgroundMenu() {
        this.actor._desktopBackgroundMenu = this._createDesktopBackgroundMenu();
        this.actor._desktopBackgroundManager = new PopupMenu.PopupMenuManager({ actor: this.actor });
        this.actor._desktopBackgroundManager.addMenu(this.actor._desktopBackgroundMenu);

        this.actor.connect('destroy', () => {
            this.actor._desktopBackgroundMenu.destroy();
            this.actor._desktopBackgroundMenu = null;
            this.actor._desktopBackgroundManager = null;
        });
    }

    _getMaxColumns() {
        let gridWidth = this._grid.allocation.x2 - this._grid.allocation.x1;
        return Math.floor(gridWidth / Prefs.get_desired_width(St.ThemeContext.get_for_stage(global.stage).scale_factor));
    }

    _getMaxRows() {
        let gridHeight = this._grid.allocation.y2 - this._grid.allocation.y1;
        return Math.floor(gridHeight / Prefs.get_desired_height(St.ThemeContext.get_for_stage(global.stage).scale_factor));
    }

    acceptDrop(source, actor, x, y, time) {
        /* Coordinates are relative to the grid, we want to transform them to
         * absolute coordinates to work across monitors */
        let [gridX, gridY] = this.actor.get_transformed_position();
        let [absoluteX, absoluteY] = [x + gridX, y + gridY];
        return Extension.desktopManager.acceptDrop(absoluteX, absoluteY);
    }

    _getPosOfFileItem(itemToFind) {
        if (itemToFind == null)
            throw new Error('Error at _getPosOfFileItem: child cannot be null');

        let found = false;
        let maxColumns = this._getMaxColumns();
        let maxRows = this._getMaxRows();
        let column = 0;
        let row = 0;
        for (column = 0; column < maxColumns; column++) {
            for (row = 0; row < maxRows; row++) {
                let item = this.layout.get_child_at(column, row);
                if (item.child && item.child._delegate.file.equal(itemToFind.file)) {
                    found = true;
                    break;
                }
            }

            if (found)
                break;
        }

        if (!found)
            throw new Error('Position of file item was not found');

        return [column, row];
    }

    _onFileItemSelected(fileItem, keepCurrentSelection, addToSelection) {
        this._grid.grab_key_focus();
    }

    doRename(fileItem) {
        this._renamePopup.onFileItemRenameClicked(fileItem);
    }
};

var RenamePopup = class {

    constructor(grid) {
        this._source = null;
        this._isOpen = false;

        this._renameEntry = new St.Entry({ hint_text: _("Enter file name…"),
                                           can_focus: true,
                                           x_expand: true });
        this._renameEntry.clutter_text.connect('activate', this._onRenameAccepted.bind(this));
        this._renameOkButton= new St.Button({ label: _("OK"),
                                              style_class: 'app-view-control button',
                                              button_mask: St.ButtonMask.ONE | St.ButtonMask.THREE,
                                              reactive: true,
                                              can_focus: true,
                                              x_expand: true });
        this._renameCancelButton = new St.Button({ label: _("Cancel"),
                                                   style_class: 'app-view-control button',
                                                   button_mask: St.ButtonMask.ONE | St.ButtonMask.THREE,
                                                   reactive: true,
                                                   can_focus: true,
                                                   x_expand: true });
        this._renameCancelButton.connect('clicked', () => { this._onRenameCanceled(); });
        this._renameOkButton.connect('clicked', () => { this._onRenameAccepted(); });
        let renameButtonsBoxLayout = new Clutter.BoxLayout({ homogeneous: true });
        let renameButtonsBox = new St.Widget({ layout_manager: renameButtonsBoxLayout,
                                               x_expand: true });
        renameButtonsBox.add_child(this._renameCancelButton);
        renameButtonsBox.add_child(this._renameOkButton);

        let renameContentLayout = new Clutter.BoxLayout({ spacing: 6,
                                                          orientation: Clutter.Orientation.VERTICAL });
        let renameContent = new St.Widget({ style_class: 'rename-popup',
                                            layout_manager: renameContentLayout,
                                            x_expand: true });
        renameContent.add_child(this._renameEntry);
        renameContent.add_child(renameButtonsBox);

        this._boxPointer = new BoxPointer.BoxPointer(St.Side.TOP, { can_focus: false, x_expand: false });
        this.actor = this._boxPointer.actor;
        this.actor.style_class = 'popup-menu-boxpointer';
        this.actor.add_style_class_name('popup-menu');
        this.actor.visible = false;
        this._boxPointer.bin.set_child(renameContent);

        this._grabHelper = new GrabHelper.GrabHelper(grid.actor, { actionMode: Shell.ActionMode.POPUP });
        this._grabHelper.addActor(this.actor);
    }

    _popup() {
        if (this._isOpen)
            return;

        this._isOpen = this._grabHelper.grab({ actor: this.actor,
                                               onUngrab: this._popdown.bind(this) });

        if (!this._isOpen) {
            this._grabHelper.ungrab({ actor: this.actor });
            return;
        }

        this._boxPointer.setPosition(this._source.actor, 0.5);
        this._boxPointer.show(BoxPointer.PopupAnimation.FADE |
                              BoxPointer.PopupAnimation.SLIDE,
                              null);

        this.emit('open-state-changed', true);
    }

    _popdown() {
        if (!this._isOpen)
            return;

        this._grabHelper.ungrab({ actor: this.actor });

        this._boxPointer.hide(BoxPointer.PopupAnimation.FADE |
                              BoxPointer.PopupAnimation.SLIDE);
        this._isOpen = false;
        this.emit('open-state-changed', false);
    }

    onFileItemRenameClicked(fileItem) {
        this._source = fileItem;

        this._renameEntry.text = fileItem.displayName;

        this._popup();
        this._renameEntry.grab_key_focus();
        this._renameEntry.navigate_focus(null, Gtk.DirectionType.TAB_FORWARD, false);
        let extensionOffset = DesktopIconsUtil.getFileExtensionOffset(fileItem.displayName, fileItem.isDirectory);
        this._renameEntry.clutter_text.set_selection(0, extensionOffset);
    }

    _onRenameAccepted() {
        this._popdown();
        DBusUtils.NautilusFileOperationsProxy.RenameFileRemote(this._source.file.get_uri(),
                                                               this._renameEntry.get_text(),
            (result, error) => {
                if (error)
                    throw new Error('Error renaming file: ' + error.message);
            }
        );
    }

    _onRenameCanceled() {
        this._popdown();
    }
};
Signals.addSignalMethods(RenamePopup.prototype);
