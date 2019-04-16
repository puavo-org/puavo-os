/* Desktop Icons GNOME Shell extension
 *
 * Copyright (C) 2019 Andrea Azzaronea <andrea.azzarone@canonical.com>
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

const { Clutter, GObject, GLib, Gio, St } = imports.gi;

const Signals = imports.signals;

const Dialog = imports.ui.dialog;
const Gettext = imports.gettext.domain('desktop-icons');
const ModalDialog = imports.ui.modalDialog;
const ShellEntry = imports.ui.shellEntry;
const Tweener = imports.ui.tweener;

const ExtensionUtils = imports.misc.extensionUtils;
const Me = ExtensionUtils.getCurrentExtension();
const DesktopIconsUtil = Me.imports.desktopIconsUtil;
const Extension = Me.imports.extension;

const _ = Gettext.gettext;

const DIALOG_GROW_TIME = 0.1;

var CreateFolderDialog = class extends ModalDialog.ModalDialog {

    constructor() {
        super({ styleClass: 'create-folder-dialog' });

        this._buildLayout();
    }

    _buildLayout() {
        let label = new St.Label({ style_class: 'create-folder-dialog-label',
                                   text: _('New folder name') });
        this.contentLayout.add(label, { x_align: St.Align.START });

        this._entry = new St.Entry({ style_class: 'create-folder-dialog-entry',
                                     can_focus: true });
        this._entry.clutter_text.connect('activate', this._onEntryActivate.bind(this));
        this._entry.clutter_text.connect('text-changed', this._onTextChanged.bind(this));
        ShellEntry.addContextMenu(this._entry);
        this.contentLayout.add(this._entry);
        this.setInitialKeyFocus(this._entry);

        this._errorBox = new St.BoxLayout({ style_class: 'create-folder-dialog-error-box',
                                            visible: false });
        this.contentLayout.add(this._errorBox, { expand: true });

        this._errorMessage = new St.Label({ style_class: 'create-folder-dialog-error-label' });
        this._errorMessage.clutter_text.line_wrap = true;
        this._errorBox.add(this._errorMessage, { expand: true,
                                                 x_align: St.Align.START,
                                                 x_fill: false,
                                                 y_align: St.Align.MIDDLE,
                                                 y_fill: false });

        this._createButton = this.addButton({ action: this._onCreateButton.bind(this),
                                              label: _('Create') });
        this.addButton({ action: this.close.bind(this),
                         label: _('Cancel'),
                         key: Clutter.Escape });
        this._onTextChanged();
    }

    _showError(message) {
        this._errorMessage.set_text(message);

        if (!this._errorBox.visible) {
            let [errorBoxMinHeight, errorBoxNaturalHeight] = this._errorBox.get_preferred_height(-1);
            let parentActor = this._errorBox.get_parent();

            Tweener.addTween(parentActor,
                             { height: parentActor.height + errorBoxNaturalHeight,
                               time: DIALOG_GROW_TIME,
                               transition: 'easeOutQuad',
                               onComplete: () => {
                                   parentActor.set_height(-1);
                                   this._errorBox.show();
                               }
                             });
        }
    }

    _hideError() {
        if (this._errorBox.visible) {
            let [errorBoxMinHeight, errorBoxNaturalHeight] = this._errorBox.get_preferred_height(-1);
            let parentActor = this._errorBox.get_parent();

            Tweener.addTween(parentActor,
                             { height: parentActor.height - errorBoxNaturalHeight,
                               time: DIALOG_GROW_TIME,
                               transition: 'easeOutQuad',
                               onComplete: () => {
                                   parentActor.set_height(-1);
                                   this._errorBox.hide();
                                   this._errorMessage.set_text('');
                               }
                             });
        }
    }

    _onCreateButton() {
        this._onEntryActivate();
    }

    _onEntryActivate() {
        if (!this._createButton.reactive)
            return;

        this.emit('response', this._entry.get_text());
        this.close();
    }

    _onTextChanged() {
        let text = this._entry.get_text();
        let is_valid = true;

        let found_name = false;
        for(let name of Extension.desktopManager.getDesktopFileNames()) {
            if (name === text) {
                found_name = true;
                break;
            }
        }

        if (text.trim().length == 0) {
            is_valid = false;
            this._hideError();
        } else if (text.includes('/')) {
            is_valid = false;
            this._showError(_('Folder names cannot contain “/”.'));
        } else if (text === '.') {
            is_valid = false;
            this._showError(_('A folder cannot be called “.”.'));
        } else if (text === '..') {
            is_valid = false;
            this._showError(_('A folder cannot be called “..”.'));
        } else if (text.startsWith('.')) {
            this._showError(_('Folders with “.” at the beginning of their name are hidden.'));
        } else if (found_name) {
            this._showError(_('There is already a file or folder with that name.'));
            is_valid = false;
        } else {
            this._hideError();
        }

        this._createButton.reactive = is_valid;
    }
};
Signals.addSignalMethods(CreateFolderDialog.prototype);
