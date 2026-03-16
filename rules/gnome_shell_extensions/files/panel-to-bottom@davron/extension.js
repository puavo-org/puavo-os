import St from 'gi://St';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const PANEL_POSITION = {
    TOP: 0,
    BOTTOM: 1,
};

export default class PanelToBottomExtension extends Extension {
    enable() {
        this._panelPosition = PANEL_POSITION.TOP;
        this._workareasChangedSignal = null;
        this._panelHeightSignal = null;
        
        // Move panel to bottom
        this._panelSetPosition(PANEL_POSITION.BOTTOM);
    }
    
    /**
     * Move panel position (from Just Perfection)
     * 
     * @param {number} position - PANEL_POSITION.TOP or PANEL_POSITION.BOTTOM
     * @param {boolean} force - force repositioning even if already at target position
     */
    _panelSetPosition(position, force = false) {
        let monitorInfo = this._monitorGetInfo();
        let panelBox = Main.layoutManager.panelBox;

        // Skip if already at target position (unless forced)
        if (!force && position === this._panelPosition) {
            return;
        }

        // Moving panel to TOP
        if (position === PANEL_POSITION.TOP) {
            this._panelPosition = PANEL_POSITION.TOP;
            
            // Disconnect signals that monitor changes
            if (this._workareasChangedSignal) {
                global.display.disconnect(this._workareasChangedSignal);
                this._workareasChangedSignal = null;
            }
            if (this._panelHeightSignal) {
                panelBox.disconnect(this._panelHeightSignal);
                this._panelHeightSignal = null;
            }
            
            // Set panel to top position
            let topX = (monitorInfo) ? monitorInfo.x : 0;
            let topY = (monitorInfo) ? monitorInfo.y : 0;
            panelBox.set_position(topX, topY);
            
            // Remove bottom panel styling
            this._UIStyleClassRemove('just-perfection-api-bottom-panel');
            
            // Fix popup menus to open downward from top
            this._fixPanelMenuSide(St.Side.TOP);
            return;
        }

        // Moving panel to BOTTOM
        this._panelPosition = PANEL_POSITION.BOTTOM;

        if (monitorInfo) {
            let BottomX = monitorInfo.x;
            let BottomY = monitorInfo.y + monitorInfo.height - Main.panel.height;

            panelBox.set_position(BottomX, BottomY);
            
            // Add bottom panel styling
            this._UIStyleClassAdd('just-perfection-api-bottom-panel');
        }

        // Connect signal to reposition panel when screen layout changes
        if (!this._workareasChangedSignal) {
            this._workareasChangedSignal = global.display.connect('workareas-changed', () => {
                this._panelSetPosition(PANEL_POSITION.BOTTOM, true);
            });
        }

        // Connect signal to reposition panel when panel height changes
        if (!this._panelHeightSignal) {
            this._panelHeightSignal = panelBox.connect('notify::height', () => {
                this._panelSetPosition(PANEL_POSITION.BOTTOM, true);
            });
        }

        // Fix popup menus to open upward from bottom
        this._fixPanelMenuSide(St.Side.BOTTOM);
    }

    /**
     * Get primary monitor information
     * 
     * @returns {Object|boolean} monitor info object or false if not available
     */
    _monitorGetInfo() {
        let pMonitor = Main.layoutManager.primaryMonitor;

        if (!pMonitor) {
            return false;
        }

        return {
            'x': pMonitor.x,
            'y': pMonitor.y,
            'width': pMonitor.width,
            'height': pMonitor.height,
            'geometryScale': pMonitor.geometry_scale,
        };
    }

    /**
     * Fix panel menu popup direction based on panel position
     * When panel is at bottom, menus should open upward
     * 
     * @param {St.Side} position - St.Side.TOP or St.Side.BOTTOM
     */
    _fixPanelMenuSide(position) {
        let PanelMenuButton = PanelMenu.Button;
        let PanelMenuButtonProto = PanelMenuButton.prototype;

        // Find all panel menus and set their arrow direction
        let findPanelMenus = (widget) => {
            if (widget instanceof PanelMenuButton && widget.menu?._boxPointer) {
                widget.menu._boxPointer._userArrowSide = position;
            }
            widget.get_children().forEach(subWidget => {
                findPanelMenus(subWidget);
            });
        };

        // Apply to all panel boxes (left, center, right)
        let panelBoxes = [
            Main.panel._centerBox,
            Main.panel._rightBox,
            Main.panel._leftBox,
        ];
        panelBoxes.forEach(panelBox => findPanelMenus(panelBox));

        // Restore original setMenu if moving back to top
        if (position === St.Side.TOP) {
            if (PanelMenuButtonProto._setMenuOld) {
                PanelMenuButtonProto.setMenu = PanelMenuButtonProto._setMenuOld;
            }
            return;
        }

        // Override setMenu to fix arrow direction for new menus
        if (!PanelMenuButtonProto._setMenuOld) {
            PanelMenuButtonProto._setMenuOld = PanelMenuButtonProto.setMenu;
        }

        PanelMenuButtonProto.setMenu = function (menu) {
            this._setMenuOld(menu);
            if (menu) {
                menu._boxPointer._userArrowSide = position;
            }
        };
    }

    /**
     * Add CSS class to UI group for styling
     */
    _UIStyleClassAdd(classname) {
        Main.layoutManager.uiGroup.add_style_class_name(classname);
    }

    /**
     * Remove CSS class from UI group
     */
    _UIStyleClassRemove(classname) {
        Main.layoutManager.uiGroup.remove_style_class_name(classname);
    }
    
    disable() {
        // Restore panel position to top
        this._panelSetPosition(PANEL_POSITION.TOP);
        
        // Disconnect all signals
        if (this._workareasChangedSignal) {
            global.display.disconnect(this._workareasChangedSignal);
            this._workareasChangedSignal = null;
        }
        if (this._panelHeightSignal) {
            Main.layoutManager.panelBox.disconnect(this._panelHeightSignal);
            this._panelHeightSignal = null;
        }
    }
}