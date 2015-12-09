#!/usr/bin/env ruby1.9.1
# coding: utf-8

# = Puavo's WLAN Controller
#
# Author    :: Tuomas Räsänen <tuomasjjrasanen@tjjr.fi>
# Copyright :: Copyright (C) 2015 Opinsys Oy
# License   :: GPLv2+
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 USA.

require 'time'

module PuavoWlanController
  module Routes
    module Root

      PREFIX = ''

      def self.registered(app)
        root = lambda do
          content_type 'text/html'
          ap_statuses = TEMPSTORE.get_ap_statuses

          arp_table = {}
          IO.popen(['arp', '-a']) do |io|
            io.each_line do |line|
              fields = line.split
              fqdn = fields[0]
              ipaddr = fields[1][1..-2] # Omit leading and trailing parens.
              mac = fields[3]
              next if mac == '<incomplete>'
              hostname = fqdn == '?' ? '?' : fqdn.split('.')[0]
              arp_table[mac] = [hostname, fqdn, ipaddr]
            end
          end

          total_station_count = 0
          total_interface_count = 0
          total_ap_rx_bytes = 0
          total_ap_tx_bytes = 0
          total_sta_rx_bytes = 0
          total_sta_tx_bytes = 0
          stations = []
          interfaces = []
          hosts = []
          ap_statuses.each do |ap_status|
            host_rx_bytes = 0
            host_tx_bytes = 0
            total_interface_count += ap_status['interfaces'].length
            ap_status['interfaces'].each do |interface|
              total_station_count += interface['stations'].length
              total_ap_rx_bytes += interface['rx_bytes']
              total_ap_tx_bytes += interface['tx_bytes']
              host_rx_bytes += interface['rx_bytes']
              host_tx_bytes += interface['tx_bytes']
              interface['hostname'] = ap_status['hostname']
              interface['uptime'] = Time.now - Time.parse(interface.fetch('start_time'))
              interface['stations'].each do |station|
                station['channel'] = interface['channel']
                station['bssid'] = interface['bssid']
                station['ssid'] = interface['ssid']
                station['hostname'], station['fqdn'], station['ipaddr'] = arp_table.fetch(station['mac'], [nil, nil, nil])
                total_sta_rx_bytes += station['rx_bytes']
                total_sta_tx_bytes += station['tx_bytes']
                stations << station
              end
              interfaces << interface
            end
            hosts << {
              'hostname'        => ap_status['hostname'],
              'interface_count' => ap_status['interfaces'].length,
              'rx_bytes'        => host_rx_bytes,
              'tx_bytes'        => host_tx_bytes,
            }
          end

          ERB.new(<<'EOF'
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <link rel="stylesheet" type="text/css" href="default.css">
    <title>Puavo's WLAN Controller - Status</title>
    <script src="sorttable.js"></script>
  </head
  <body>
    <h1>Status</h1>
    <% unless hosts.empty? %>
    <h2>Hosts</h2>
    <table class="sortable">
      <thead>
        <tr>
          <th>Host</th>
          <th>Access points</th>
          <th>Rx</th>
          <th>Tx</th>
        </tr>
      </thead>
      <tbody>
      <% hosts.each do |host| %>
        <tr id="host-<%= host.fetch('hostname') %>">
          <td><%= host.fetch('hostname') %></td>
          <td><%= host.fetch('interface_count') %></td>
          <td sorttable_customkey="<%= host.fetch('rx_bytes') %>"><%= prettify_bytes(host.fetch('rx_bytes')) %></td>
          <td sorttable_customkey="<%= host.fetch('tx_bytes') %>"><%= prettify_bytes(host.fetch('tx_bytes')) %></td>
        </tr>
      <% end %>
      </tbody>
      <tfoot>
        <tr>
        <th colspan="1">Totals</th>
        <td><%= total_interface_count %></td>
        <td><%= prettify_bytes(total_ap_rx_bytes) %></td>
        <td><%= prettify_bytes(total_ap_tx_bytes) %></td>
        </tr>
      </tfoot>
    </table>
    <% end %>

    <% unless interfaces.empty? %>
    <h2>Access points</h2>
    <table class="sortable">
      <thead>
        <tr>
          <th>Host</th>
          <th>BSSID</th>
          <th>Channel</th>
          <th>SSID</th>
          <th>Stations</th>
          <th>Rx</th>
          <th>Tx</th>
        </tr>
      </thead>
      <tbody>
      <% interfaces.each do |interface| %>
        <tr id="ap-<%= interface.fetch('bssid') %>">
          <td><a href="#host-<%= interface.fetch('hostname') %>"><%= interface.fetch('hostname') %></a></td>
          <td><%= interface.fetch('bssid') %></td>
          <td><%= interface.fetch('channel') %></td>
          <td><%= interface.fetch('ssid') %></td>
          <td><%= interface.fetch('stations').length %></td>
          <td sorttable_customkey="<%= interface.fetch('rx_bytes') %>"><%= prettify_bytes(interface.fetch('rx_bytes')) %></td>
          <td sorttable_customkey="<%= interface.fetch('tx_bytes') %>"><%= prettify_bytes(interface.fetch('tx_bytes')) %></td>
        </tr>
      <% end %>
      </tbody>
      <tfoot>
        <tr>
        <th colspan="4">Totals</th>
        <td><%= total_station_count %></td>
        <td><%= prettify_bytes(total_ap_rx_bytes) %></td>
        <td><%= prettify_bytes(total_ap_tx_bytes) %></td>
        </tr>
      </tfoot>
    </table>
    <% end %>

    <% unless stations.empty? %>
    <h2>Stations</h2>
    <table class="sortable">
      <thead>
        <tr>
          <th>Host</th>
          <th>MAC</th>
          <th>IPv4 address</th>
          <th>BSSID</th>
          <th>Channel</th>
          <th>SSID</th>
          <th>Uptime</th>
          <th>Rx</th>
          <th>Tx</th>
        </tr>
      </thead>
      <tbody>
      <% stations.each do |station| %>
        <tr id="sta-<%= station.fetch('mac') %>">
          <td><%= station.fetch('hostname') %></td>
          <td><%= station.fetch('mac') %></td>
          <td><%= station.fetch('ipaddr') %></td>
          <td><a href="#ap-<%= station.fetch('bssid') %>"><%= station.fetch('bssid') %></a></td>
          <td><%= station.fetch('channel') %></td>
          <td><%= station.fetch('ssid') %></td>
          <td sorttable_customkey="<%= station.fetch('connected_time') %>"><%= prettify_seconds(station.fetch('connected_time')) %></td>
          <td sorttable_customkey="<%= station.fetch('rx_bytes') %>"><%= prettify_bytes(station.fetch('rx_bytes')) %></td>
          <td sorttable_customkey="<%= station.fetch('tx_bytes') %>"><%= prettify_bytes(station.fetch('tx_bytes')) %></td>
        </tr>
      <% end %>
      </tbody>
      <tfoot>
        <tr>
        <th colspan="7">Totals</th>
        <td><%= prettify_bytes(total_sta_rx_bytes) %></td>
        <td><%= prettify_bytes(total_sta_tx_bytes) %></td>
        </tr>
      </tfoot>
    </table>
    <% end %>
    <p id="timestamp"><%= Time.now %></p>
  </body>
</html>
EOF
                  ).result(binding)
        end

        app.get("#{PREFIX}/", &root)
      end

    end
  end
end
