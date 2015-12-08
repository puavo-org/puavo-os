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

          ERB.new(<<'EOF'
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <meta http-equiv="refresh" content="5" >
    <link rel="stylesheet" type="text/css" href="default.css">
    <title>Puavo's WLAN Controller - Status</title>
    <script src="sorttable.js"></script>
  </head
  <body>
    <h1>Status</h1>
    <p><%= Time.now %></p>
    <% ap_statuses.each do |ap_status| %>
      <table class="sortable" id="interfaces">
        <thead>
          <tr>
            <th>Host</th>
            <th>BSSID</th>
            <th>Channel</th>
            <th>SSID</th>
            <th>Stations</th>
          </tr>
        </thead>
        <tbody>
        <% ap_status.fetch('interfaces').each do |interface| %>
          <tr>
            <td><%= ap_status.fetch('hostname') %></td>
            <td><%= interface.fetch('bssid') %></td>
            <td><%= interface.fetch('channel') %></td>
            <td><%= interface.fetch('ssid') %></td>
            <td><%= interface.fetch('stations').length %></td>
          </tr>
        <% end %>
        </tbody>
        <tfoot>
          <tr>
          <th colspan="4">Totals</th>
          <td><%= ap_status.fetch('interfaces').map { |interface| interface.fetch('stations').length }.reduce(:+) %></td>
          </tr>
        </tfoot>
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
