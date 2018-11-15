/*
Login screen host information display
Copyright (C) 2017-2018 Opinsys Oy

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

Version 0.9.9
Author: Jarmo Pietiläinen (jarmo@opinsys.fi)
*/

const St = imports.gi.St;
const Main = imports.ui.main;
const Lang = imports.lang;
const Gtk = imports.gi.Gtk;
const Shell = imports.gi.Shell;
const PanelMenu = imports.ui.panelMenu;
const PopupMenu = imports.ui.popupMenu;
const Clutter = imports.gi.Clutter;
const Mainloop = imports.mainloop;
const Gio = imports.gi.Gio;

var hostType, hostName, releaseName;

// remember to catch and handle exceptions if you call this
function readTextFile(name)
{
    return Shell.get_file_contents_utf8_sync(name);
}

// the [] operator cannot be overloaded, so we have to do it the hard way
function jval(json, key, defaultValue = "<Unknown>")
{
    return (key in json && json[key] !== null) ? json[key] : defaultValue;
}

const HostInfoButton = new Lang.Class(
{
    Name: "HostInfoButton",
    Extends: PanelMenu.Button,

    _init: function()
    {
        this.parent(0.0);

        /*
        Rough schematic of the containers and other elements we're creating:

            +-baseMenuItem (PopupMenu.PopupBaseMenuItem)----------------------------------+
            |                                                                             |
            | +-mainContainer (St.BoxLayout)--------------------------------------------+ |
            | |                                                                         | |
            | | +-infoContainer (St.ScrollView)---------------------------------------+ | |
            | | |                                                                     | | |
            | | | +-infoTextBlock (St.BoxLayout)------------------------------------+ | | |
            | | | | Category1                                                       | | | |
            | | | |  Label1: Value1                                                 | | | |
            | | | |  Label2: Value2                                                 | | | |
            | | | |                                                                 | | | |
            | | | | Category2                                                       | | | |
            | | | |  Label3: Value3                                                 | | | |
            | | | |  ...                                                            | | | |
            | | | +-----------------------------------------------------------------+ | | |
            | | |                                                                     | | |
            | | +---------------------------------------------------------------------+ | |
            | |                                                                         | |
            | | +-buttonsContainer (St.BoxLayout)-------------------------------------+ | |
            | | |                                                                     | | |
            | | | +-updateButton (St.Button)-+                                        | | |
            | | | | <...>                    |                                        | | |
            | | | +--------------------------+                                        | | |
            | | |                                                                     | | |
            | | +---------------------------------------------------------------------+ | |
            | |                                                                         | |
            | +-------------------------------------------------------------------------+ |
            |                                                                             |
            +--+  +-----------------------------------------------------------------------+
                \/
        +-buttonContainer (St.BoxLayout)--------------------------------+
        |                                                               |
        | +-St.Label--------------------------+ +-PopupMenu.arrowIcon-+ |
        | | hostType | releaseName | hostName | |         ▲           | |
        | +-----------------------------------+ +---------------------+ |
        |                                                               |
        +---------------------------------------------------------------+

        The actual info texts are in a separate BoxLayout container, so we can destroy and
        recreate it at will. The scrollview also works better (less jumpy scrolling) if its
        content is just a single container box.
        */

        // -----------------------------------------------------------------------------------------
        // Create the panel button

        let buttonContainer = new St.BoxLayout({ style_class: "panel-status-menu-box" });

        buttonContainer.add_child(new St.Label({
            text: hostType + " | " + releaseName + " | " + hostName,
            y_expand: true,
            y_align: Clutter.ActorAlign.CENTER
        }));

        buttonContainer.add_child(new PopupMenu.arrowIcon(St.Side.TOP));

        this.actor.add_actor(buttonContainer);

        // -----------------------------------------------------------------------------------------
        // Construct the popup menu

        // Top-level container for everything in the popup menu. This is a pseudo-
        // menuitem; it cannot be clicked or interacted with in any way.
        this.baseMenuItem = new PopupMenu.PopupBaseMenuItem({
            style_class: "baseMenuItem",
            reactive: false
        });

        // Main container for the info text block and the buttons at the button
        this.mainContainer = new St.BoxLayout({
            style_class: "mainContainer",
            vertical: true
        });

        // The system info text container, initially empty and hidden
        this.infoContainer = new St.ScrollView({
            hscrollbar_policy: Gtk.PolicyType.NEVER,
            vscrollbar_policy: Gtk.PolicyType.AUTOMATIC,
            enable_mouse_scrolling: true,
            style_class: "infoContainer",
        });

        this.infoContainer.hide();

        // Container for the buttons at the bottom
        this.buttonsContainer = new St.BoxLayout({
            style_class: "buttonsContainer",
            vertical: false
        });

        // placeholder, will be created later
        this.infoTextBlock = null;

        // The update button
        this.updateButton = new St.Button({
            label: "Click to collect system information...",
            style_class: "updateButton"
        });

        this.buttonsContainer.add_actor(this.updateButton);

        // Build the final container hierarchy and finish the menu layout
        this.mainContainer.add_actor(this.infoContainer);
        this.mainContainer.add_actor(this.buttonsContainer);
        this.baseMenuItem.actor.add(this.mainContainer);
        this.menu.addMenuItem(this.baseMenuItem);

        // Setup a D-Bus proxy for system info queries
        // https://stackoverflow.com/questions/48933174/gdbus-call-when-click-on-panel-extension-icon
        try {
            this.proxy = new Gio.DBusProxy({
                g_connection: Gio.DBus.system,
                g_name: "org.puavo.client.systeminfocollectordaemon",
                g_object_path: "/systeminfocollector",
                g_interface_name: "org.puavo.client.systeminfocollector"
            });

            this.proxy.init(null);
        } catch (error) {
            this.buttonsContainer.remove_actor(this.updateButton);
            delete this.updateButton;
            this.updateButton = null;
            this.proxy = null;

            this.errorText(this.buttonsContainer,
                "D-Bus init error, can't display system info. Sorry :-(");
        }

        // Setup info retrieval/update logic
        if (this.updateButton && this.proxy) {
            this.updateButton.connect("clicked", Lang.bind(this, function() {
                this.updateButton.reactive = false;
                this.updateButton.opacity = 128;        // simulate a "disabled" look

                try {
                    // asynchronous D-Bus method call
                    this.proxy.call(
                        "org.puavo.client.systeminfocollector.CollectSysinfo",
                        null, 0, 5000, null,
                        Lang.bind(this, function(source, res, user_data) {
                            this.updateButton.reactive = true;
                            this.updateButton.opacity = 255;

                            if (this.infoTextBlock) {
                                // remove old contents first
                                this.infoContainer.hide();
                                this.infoContainer.remove_actor(this.infoTextBlock);
                                this.infoTextBlock = null;
                            }

                            if (!this.createInfoText())
                                this.updateButton.label = "Try again?";
                            else this.updateButton.label = "Update";

                            this.infoContainer.show();
                            this.infoContainer.add_actor(this.infoTextBlock);
                        }),
                        null    // userdata
                    );
                } catch (error) {
                    // UNTESTED
                    if (this.infoTextBlock) {
                        this.infoContainer.remove_actor(this.infoTextBlock);
                        this.infoTextBlock = null;
                    }

                    this.errorText(this.infoContainer, "Failed :-(");
                }
            }));
        }
    },

    // ---------------------------------------------------------------------------------------------
    // ---------------------------------------------------------------------------------------------

    createInfoText: function()
    {
        if (this.infoTextBlock) {
            // if the block already exists, do nothing because something is wrong
            return;
        }

        this.infoTextBlock = new St.BoxLayout({
            style_class: "infoTextBlock",
            vertical: true
        });

        let c = this.infoTextBlock;

        function pad(number)
        {
            return (number < 10) ? '0' + number : number;
        }

        try {
            // This JSON file is generated by /usr/sbin/puavo-sysinfo-collector when the button
            // is clicked. We get the same JSON back through D-Bus, but at the moment this data
            // is not used, because I don't know how to get the data from the async callback :-(
            const json = JSON.parse(readTextFile("/run/puavo/puavo-sysinfo.json"));

            // When was this information last updated? This is important!
            var timestamp = jval(json, "timestamp", -1);

            if (timestamp == -1)
                timestamp = "<ERROR>";
            else {
                const d = new Date(timestamp * 1000);

                timestamp = d.getUTCFullYear() + '-' +
                    pad(d.getUTCMonth() + 1) + '-' +
                    pad(d.getUTCDate()) + ' ' +
                    pad(d.getUTCHours()) + ':' +
                    pad(d.getUTCMinutes()) + ':' +
                    pad(d.getUTCSeconds()) + ' UTC';
            }

            let tsBox = new St.BoxLayout();

            tsBox.add_actor(new St.Label({
                text: "Last updated: " + timestamp,
                style_class: "infoTextTimestamp"
            }));

            c.add_actor(tsBox);
            this.spacer(c);

            // General release info
            this.category(c, "Release");
            this.titleValue(c, "Image", jval(json, "this_image"));
            this.titleValue(c, "Name", jval(json, "this_release"));
            this.titleValue(c, "Kernel", jval(json, "kernelrelease"));

            // Machine
            this.spacer(c);
            this.category(c, "Machine");
            this.titleValue(c, "Product name", jval(json, "productname"));
            this.titleValue(c, "BIOS",
                jval(json, "bios_vendor") + ", " +
                jval(json, "bios_version") + ", " +
                jval(json, "bios_release_date"));

            // CPU
            this.titleValue(c, "Processor",
                jval(json, "processorcount") + " CPU(s), " +
                jval(json, "processor0"));

            // Memory
            this.titleValue(c, "Memory",
                (parseFloat(jval(json, "memorysize_mb", 0.0)) / 1024.0).toFixed(2) + " GiB");

            const memory = jval(json, "memory", null);

            if (memory && memory.length > 0) {
                for (var i = 0; i < memory.length; i++) {
                    const size = memory[i].size;

                    // The texts here are indented using spaces, but we *really* should create
                    // a new St.BoxLayout() element to indent them... maybe one day...

                    var text = "";

                    if (size == 0)
                        text = "<empty>";
                    else {
                        text += "Size: " + size + " MiB; ";
                        text += "Slot: " + memory[i].slot + "; ";
                        text += "Product: " + memory[i].product + "; ";
                        text += "Vendor: " + memory[i].vendor;
                    }

                    this.titleValue(c, "    Slot #" + i, text);
                }
            }

            // Hard drive
            var hdText = "";

            if ("blockdevice_sda_model" in json && json["blockdevice_sda_model"]) {
                hdText = jval(json, "blockdevice_sda_model");

                hdText += ", ";
                hdText += (parseFloat(jval(json, "blockdevice_sda_size", 0)) /
                            (1024.0 * 1024.0 * 1024.0)).toFixed(0);
                hdText += " GiB";

                if (jval(json, "ssd") == "1")
                    hdText += " [SSD]";
            } else {
                // Juha's old Zotac helped me debug this path :-)
                hdText = "(no hard drive)";
            }

            this.titleValue(c, "Hard drive", hdText);

            // Network
            this.spacer(c);
            this.category(c, "Network");

            const network = jval(json, "network_interfaces", null);

            if (network && network.length > 0) {
                for (var i = 0; i < network.length; i++) {
                    var text = "";

                    text += "MAC=" + network[i].mac + "; ";
                    text += "IP=" + network[i].ip;

                    if (network[i].prefix > 0)
                        text += "/" + network[i].prefix.toString();

                    this.titleValue(c, "Interface " + network[i].name, text);
                }
            }


            this.titleValue(c, "WiFi", jval(json, "wifi"));

            // Serial numbers
            this.spacer(c);
            this.category(c, "Serial numbers");
            this.titleValue(c, "Machine", jval(json, "serialnumber"));
            this.titleValue(c, "Mainboard", jval(json, "boardserialnumber"));

            // lspci values, if present
            if ("lspci_values" in json && json["lspci_values"].length > 0) {
                this.spacer(c);
                this.category(c, "Some lspci values");

                // get around JS's variable scoping weirdness
                let self = this;

                json["lspci_values"].forEach(function(e) {
                    self.value(self.infoTextBlock, e);
                });
            } else {
                // this can happen, at least in theory...
                this.spacer(c);
                this.category(c, "No lspci output listed in the JSON");
            }

            // lsusb values, if present
            if ("lsusb_values" in json && json["lsusb_values"].length > 0) {
                this.spacer(c);
                this.category(c, "lsusb listing");

                // get around JS's variable scoping weirdness
                let self = this;

                json["lsusb_values"].forEach(function(e) {
                    self.value(self.infoTextBlock, e);
                });
            } else {
                // this can happen, at least in theory...
                this.spacer(c);
                this.category(c, "No lsusb output listed in the JSON");
            }
        } catch (e) {
            this.errorText(c,
                "Cannot display system information. Try clicking the \"Try again?\" button to see if\n" +
                "the problem fixes itself. If not, try rebooting the machine. If even that does not\n" +
                "help, please report this problem to Opinsys support.\n\n" + e.message);
            return false;
        }

        return true;
    },

    // Adds a text label in the container. "params" must contain the text value,
    // style class and possibly other, optional, arguments.
    addLabel: function(container, params)
    {
        container.add_actor(new St.Label(params));
    },

    // adds a category title
    category: function(where, value)
    {
        let r = new St.BoxLayout();

        this.addLabel(r, { text: value, style_class: "infoTextCategory" });
        where.add_actor(r);
    },

    // adds an empty spacer row (this used to be a CSS property,
    // but it was hard to control)
    spacer: function(where)
    {
        let r = new St.BoxLayout();

        this.addLabel(r, { text: " ", style_class: "infoTextSpacer" });
        where.add_actor(r);
    },

    // add a value without title
    value: function(where, value)
    {
        let r = new St.BoxLayout();

        this.addLabel(r, { text: value, style_class: "infoTextPlainValue" });
        where.add_actor(r);
    },

    // add a title with value
    titleValue: function(where, title, value)
    {
        let r = new St.BoxLayout();

        this.addLabel(r, { text: title + ":", style_class: "infoTextKey" });
        this.addLabel(r, { text: value, style_class: "infoTextValue" });

        where.add_actor(r);
    },

    // adds an error text, used in error conditions
    errorText: function(where, text)
    {
        where.add_actor(new St.Label({ text: text, style_class: "errorText" }));
    },
});

// -------------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------------

function init()
{
    // These are displayed on the button, so they must be read before doing
    // anything else. Fortunately they don't change during runtime.
    try {
        hostType = readTextFile("/etc/puavo/hosttype").trim();
    } catch (e) {
        hostType = "<Error>";
    }

    try {
        hostName = readTextFile("/etc/puavo/hostname").trim();
    } catch (e) {
        hostName = "<Error>";
    }

    try {
        releaseName = readTextFile("/etc/puavo-image/release").trim();
    } catch (e) {
        releaseName = "<Error>";
    }
}

let hostInfoMenuButton = null;

function enable()
{
    hostInfoMenuButton = new HostInfoButton();

    // the last argument indicates which panel box to use: left, center, right
    Main.panel.addToStatusArea("hostInfoButton", hostInfoMenuButton, 0, "left");
}

function disable()
{
    hostInfoMenuButton.destroy();
    hostInfoMenuButton = null;
}
