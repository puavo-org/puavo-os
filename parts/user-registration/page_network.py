# The network setup page

import subprocess
import fcntl
import os
import gettext
import logging
import gi

gi.require_version('Gtk', '3.0')
from gi.repository import GLib, Gtk, GObject

from page_definition import PageDefinition

gettext.bindtextdomain('puavo-user-registration', '/usr/share/locale')
gettext.textdomain('puavo-user-registration')
_tr = gettext.gettext


class PageNetwork(PageDefinition):
    def __init__(self, application, parent_window, parent_container, data_dir, main_builder):
        super().__init__(application, parent_window, parent_container, data_dir, main_builder)

        self.load_file('network.glade', 'network_container')

        self.networks = {}

        self.network_ssid = None

        self.wifi_connect_pid = None

        self.network_choice_widget = self.builder.get_object('networks_list')
        self.network_choice_widget.connect('row-activated', self.wifi_connection_chosen)
        self.searching_for_networks = True

        self.password_label = self.builder.get_object('network_password_label')
        self.password_entry = self.builder.get_object('network_password_entry')
        self.password_entry.connect('activate', self.connect_to_wifi)
        self.password_entry.connect('changed', self.password_changed)

        self.spinner = self.builder.get_object('network_connector_spinner')
        self.connection_status = self.builder.get_object('network_connection_status')

        self.wifi_title = self.builder.get_object('wifi_connector_description')
        self.wifi_title.set_justify(Gtk.Justification.CENTER)

        self.connect_button = self.builder.get_object('network_connect_button')
        self.connect_button.connect('clicked', self.connect_to_wifi)

        self.button_to_account_page \
            = self.builder.get_object('network_go_to_account_page_button')
        self.button_to_account_page.set_sensitive(False)
        self.button_to_account_page.connect('clicked',
                                            self.go_to_account_setup)


    def get_main_title(self):
        return _tr('Network Setup')


    def activate(self):
        super().activate()

        # Don't start doing any networking stuff until the page is
        # actually shown
        self.prepare_ui()


    def go_to_account_setup(self, *args):
        self.application.next_page()


    def prepare_ui(self):
        cmd = ['nmcli', 'radio', 'wifi', 'on']
        output = subprocess.run(cmd)

        wireless_active = False
        self.update_networks_info()

        # Are we already connected?
        for network_ssid, network_info in self.networks.items():
            if network_info['active']:
                wireless_active = True

                if self.ask_if_wifi_network_is_okay(self.parent_window, network_ssid):
                    # We already have a WiFi connection, so nothing
                    # needs to be done here
                    logging.info('We already have a WiFi connection, moving on')
                    self.application.next_page()
                    return

                break

        if not wireless_active and self.check_network_connectivity():
            # Ask if a wired connection is okay
            if not self.ask_if_wireless_network_is_wanted(self.parent_window):
                logging.info('We already have a connection, moving on')
                self.application.next_page()
                return

        # Update the list every few seconds
        GObject.timeout_add_seconds(5, self.update_networks_info)


    def update_networks_info(self):
        new_networks = {}

        cmd = ['env', 'LANG=C', 'nmcli', '-t', '-f',
               'SSID,ACTIVE,SIGNAL,SECURITY', 'dev', 'wifi', 'list']

        output = subprocess.check_output(cmd).decode('utf-8').strip()

        for network_line in output.split('\n'):
            network_line_fields = network_line.split(':')

            if len(network_line_fields) != 4:
                continue

            (ssid, active_str, signal, security) = network_line_fields
            active = False

            if active_str == 'yes':
                active = True

            if not ssid in new_networks:
                new_networks[ssid] = {
                    'active': active,
                    'signal': 0,
                    'security': security
                }

            if not new_networks[ssid]['active']:
                new_networks[ssid]['active'] = active

            if not new_networks[ssid]['security']:
                new_networks[ssid]['security'] = security

            try:
                max_signal = max(int(signal), new_networks[ssid]['signal'])
                new_networks[ssid]['signal'] = max_signal
            except ValueError:
                pass

        sorted_by_signal = sorted(new_networks,
                                  key=lambda x: new_networks.get(x)['signal'],
                                  reverse=True)

        # Add new interface elements
        for network_ssid in sorted_by_signal:
            if network_ssid in self.networks:
                continue

            network = new_networks[network_ssid]

            row_container = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)

            ssid_label = Gtk.Label(network_ssid)

            security = network['security']

            if security is None or len(security) == 0:
                security = '?'

            signal = str(network['signal'])

            if len(signal) == 0:
                signal = '?'

            signal_label = Gtk.Label('%s (%s%%)' % (security, signal))

            row_container.pack_start(ssid_label, False, False, 0)
            row_container.pack_end(signal_label, False, False, 0)

            row = Gtk.ListBoxRow()
            row.add(row_container)

            self.network_choice_widget.add(row)
            self.networks[network_ssid] = new_networks[network_ssid]
            self.networks[network_ssid]['widget'] = row

        # remove old interface elements
        for network_ssid in self.networks.copy():
            if network_ssid in new_networks:
                continue

            self.networks[network_ssid]['widget'].destroy()
            del self.networks[network_ssid]

            if self.network_ssid == network_ssid:
                self.network_ssid = None

        # Choose the first network in case self.network_ssid is not set
        for network_ssid in sorted_by_signal:
            if not self.network_ssid:
                row = self.networks[network_ssid]['widget']
                self.network_choice_widget.select_row(row)
                # this sets self.network_ssid:
                self.wifi_connection_chosen(self.network_choice_widget, row)

        if len(self.networks) == 0:
            self.spinner.start()
            self.connection_status.set_text(_tr('Searching for networks...'))
            self.searching_for_networks = True
        elif self.searching_for_networks:
            self.spinner.stop()
            self.connection_status.set_text('')
            self.searching_for_networks = False

        self.network_choice_widget.show_all()

        return True


    def password_changed(self, widget):
        wifi_password = self.password_entry.get_text()

        if wifi_password:
            self.connect_button.set_sensitive(True)
        else:
            self.connect_button.set_sensitive(False)


    def remove_all_wireless_connections(self):
        cmd = ['env', 'LANG=C', 'nmcli', '-t', '-f', 'NAME,TYPE',
               'connection', 'show']

        output = subprocess.check_output(cmd).decode('utf-8').strip()

        for connection_line in output.split('\n'):
            connection_line_fields = connection_line.split(':')

            if len(connection_line_fields) != 2:
                continue

            (connection_name, connection_type) = connection_line_fields

            if 'wireless' in connection_type:
                cmd = ['nmcli', 'connection', 'delete', connection_name]
                subprocess.run(cmd)


    def connect_to_wifi(self, widget):
        if not self.network_ssid:
            return

        if self.wifi_connect_pid:
            return

        logging.info('Trying to connect to network "%s"', self.network_ssid)

        self.connection_status.set_text(_tr('Connecting to "%s"...') % self.network_ssid)
        self.connect_button.set_sensitive(False)
        self.spinner.start()

        # The connect operation always creates a new connection to
        # NetworkManager configuration even if it fails.  Clear up all
        # previous wireless connections (yes this is a big hammer).
        self.remove_all_wireless_connections()

        wifi_password = self.password_entry.get_text()

        cmd = ['/usr/bin/env', 'LANG=C', 'nmcli', 'device', 'wifi', 'connect',
               self.network_ssid]

        if wifi_password:
            cmd += ['password', wifi_password]

        self.wifi_connect_output = ''

        flags = GLib.SPAWN_DO_NOT_REAP_CHILD | GObject.SPAWN_STDERR_TO_DEV_NULL

        (self.wifi_connect_pid, stdin, stdout, stderr) \
            = GObject.spawn_async(cmd, flags=flags, standard_output=True)

        fl = fcntl.fcntl(stdout, fcntl.F_GETFL)
        fcntl.fcntl(stdout, fcntl.F_SETFL, fl | os.O_NONBLOCK)

        GObject.io_add_watch(stdout,
                             GObject.IO_HUP | GObject.IO_IN,
                             self.wifi_connect_callback,
                             os.fdopen(stdout))


    def wifi_connect_callback(self, fd, condition, channel):
        if condition & GObject.IO_IN:
            self.wifi_connect_output += channel.read()

        if condition & GObject.IO_HUP:
            channel.close()
            (pid, status) = os.waitpid(self.wifi_connect_pid, 0)
            self.wifi_connect_pid = None
            self.spinner.stop()

            # Status should be > 0 in case of error, but it is not,
            # so instead we look at the output :-(
            if 'successfully activated' in self.wifi_connect_output:
                self.connection_status.set_text(_tr('Connection successful!'))
                logging.info('Network connection successful!')
                # TODO: automatically go to the next page here?
                #self.application.next_page()
                self.button_to_account_page.set_sensitive(True)
            else:
                logging.info('Network connection failed')
                self.connection_status.set_text(_tr('Connection failed'))
                self.remove_all_wireless_connections()

            self.wifi_connect_output = ''

            return False

        return True


    def wifi_connection_chosen(self, listbox, row):
        for network_ssid, network_info in self.networks.items():
            if network_info['widget'] == row:
                self.network_ssid = network_ssid
                break

        self.wifi_title.set_label(_tr('Connect to network') + '\n"' + network_ssid + '"')

        network_info = self.networks[self.network_ssid]
        self.password_entry.set_text('')

        if network_info['security']:
            self.connect_button.set_sensitive(False)
            self.password_entry.grab_focus()
            self.password_entry.set_sensitive(True)
            self.password_label.set_sensitive(True)
        else:
            self.connect_button.grab_focus()
            self.connect_button.set_sensitive(True)
            self.password_entry.set_sensitive(False)
            self.password_label.set_sensitive(False)


    def ask_if_wifi_network_is_okay(self, parent, network_ssid):
        short_msg = _tr('Use network "%s"?') % network_ssid

        long_msg = _tr('You are connected to network "%s", ' \
                       'do you want to use this network?') % network_ssid

        dialog = Gtk.MessageDialog(parent, 0, Gtk.MessageType.QUESTION,
                                   Gtk.ButtonsType.YES_NO, short_msg)

        dialog.format_secondary_text(long_msg)
        response = dialog.run()
        dialog.destroy()

        return response == Gtk.ResponseType.YES


    def ask_if_wireless_network_is_wanted(self, parent):
        short_msg = _tr('Join wireless network?')

        long_msg = _tr('You are connected to a network that is not a ' \
                        'wireless network.  Do you want to join ' \
                        'a wireless network anyway?')

        dialog = Gtk.MessageDialog(parent, 0, Gtk.MessageType.QUESTION,
                                   Gtk.ButtonsType.YES_NO, short_msg)

        dialog.format_secondary_text(long_msg)
        response = dialog.run()
        dialog.destroy()

        return response == Gtk.ResponseType.YES


    def check_network_connectivity(self):
        # XXX how are exceptions handled here?
        cmd = ['env', 'LANG=C', 'nmcli', 'networking', 'connectivity']
        output = subprocess.check_output(cmd).decode('utf-8').strip()
        return output == 'full'
