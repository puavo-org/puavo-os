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
    module V1

      PREFIX = '/v1'

      def self.registered(app)

        ping_route = "#{PREFIX}/ping"
        ping = lambda do
          body = request.body.read
          data = JSON.parse(body)

          TEMPSTORE.update_ap_status(data)
          { :ping_interval_seconds => PING_INTERVAL_SECONDS }.to_json
        end

        root = lambda do
          content_type 'text/html'

          ERB.new(<<'EOF'
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Puavo's WLAN Controller - <%= PREFIX %></title>
  </head
  <body>
    <h1>API</h1>
    <h2>POST <%= ping_route %></h2>
    <p>Send a status notification to the controller. Must be called periodically.</p>
    <h3>Request data</h3>
    <p>Content-Type: application/json</p>
    <h4>Example</h4>
    <pre><code>
{
  "hostname": "accesspoint-01",
  "interfaces": [
    {
      "bssid": "01:02:03:04:05:06",
      "channel": 11,
      "ssid": "MyNet",
      "stations": [
        {
          "mac": "06:05:04:03:02:01",
          "connected_time": 232,
          "rx_bytes": 32322,
          "tx_bytes": 11323,
        }
      ]
    }
  ]
}
    </code></pre>
    <h3>Response data</h3>
    <p>Content-Type: application/json</p>
    <h4>Example</h4>
    <pre><code>
{
  "ping_interval_seconds": 20
}
    </code></pre>
  </body>
</html>
EOF
                  ).result(binding)
        end

        app.get("#{PREFIX}"  , &root)
        app.get("#{PREFIX}/" , &root)

        app.post(ping_route  , &ping)

      end

    end
  end
end
