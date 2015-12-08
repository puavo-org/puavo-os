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

module PuavoWlanController
  module Routes
    module Root

      PREFIX = ''

      def self.registered(app)
        root = lambda do
          content_type 'text/html'
          ap_statuses = TEMPSTORE.get_ap_statuses

          total_stations = 0
          total_rx_bytes = 0
          total_tx_bytes = 0
          stations = []
          interfaces = []
          ap_statuses.each do |ap_status|
            ap_status['interfaces'].each do |interface|
              total_stations += interface['stations'].length
              total_rx_bytes += interface['rx_bytes']
              total_tx_bytes += interface['tx_bytes']
              interface['hostname'] = ap_status['hostname']
              interface['last_ping'] = TEMPSTORE.seconds_since_last_ping(ap_status.fetch('hostname'))
              interface['stations'].each do |station|
                station['channel'] = interface['channel']
                station['bssid'] = interface['bssid']
                station['ssid'] = interface['ssid']
                stations << station
              end
              interfaces << interface
            end
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
    <p><%= Time.now %></p>
    <% unless interfaces.empty? %>
    <h2>Access points</h2>
    <table class="sortable" id="interfaces">
      <thead>
        <tr>
          <th>Host</th>
          <th>BSSID</th>
          <th>Channel</th>
          <th>SSID</th>
          <th>Last ping</th>
          <th>Age</th>
          <th>Stations</th>
          <th>Rx</th>
          <th>Tx</th>
        </tr>
      </thead>
      <tbody>
      <% interfaces.each do |interface| %>
        <tr>
          <td><%= interface.fetch('hostname') %></td>
          <td><%= interface.fetch('bssid') %></td>
          <td><%= interface.fetch('channel') %></td>
          <td><%= interface.fetch('ssid') %></td>
          <td><%= interface.fetch('last_ping') %>s ago</td>
          <td><%= prettify_seconds(interface.fetch('age')) %></td>
          <td><%= interface.fetch('stations').length %></td>
          <td><%= prettify_bytes(interface.fetch('rx_bytes')) %></td>
          <td><%= prettify_bytes(interface.fetch('tx_bytes')) %></td>
        </tr>
      <% end %>
      </tbody>
      <tfoot>
        <tr>
        <th colspan="6">Totals</th>
        <td><%= total_stations %></td>
        <td><%= prettify_bytes(total_rx_bytes) %></td>
        <td><%= prettify_bytes(total_tx_bytes) %></td>
        </tr>
      </tfoot>
    </table>
    <% end %>

    <% unless stations.empty? %>
    <h2>Stations</h2>
    <table class="sortable" id="interfaces">
      <thead>
        <tr>
          <th>MAC</th>
          <th>BSSID</th>
          <th>Channel</th>
          <th>SSID</th>
          <th>Rx</th>
          <th>Tx</th>
          <th>Connection age</th>
        </tr>
      </thead>
      <tbody>
      <% stations.each do |station| %>
        <tr>
          <td><%= station.fetch('mac') %></td>
          <td><%= station.fetch('bssid') %></td>
          <td><%= station.fetch('channel') %></td>
          <td><%= station.fetch('ssid') %></td>
          <td><%= prettify_bytes(station.fetch('rx_bytes')) %></td>
          <td><%= prettify_bytes(station.fetch('tx_bytes')) %></td>
          <td><%= prettify_seconds(station.fetch('connected_time')) %></td>
        </tr>
      <% end %>
      </tbody>
    </table>
    <% end %>
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
