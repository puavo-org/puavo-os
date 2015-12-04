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
        ap_start_route = "#{PREFIX}/ap/:hostname"
        ap_start = lambda do
          content_type 'application/json'
          body = request.body.read
          data = body.empty? ? {} : JSON.parse(body)
          host = params[:hostname]

          PERMSTORE.add_report('ap_start', host, data.to_json)
          TEMPSTORE.add_accesspoint(host)
          TEMPSTORE.expire_accesspoint(host, AP_EXPIRATION_TIME)
          { :ping_interval_seconds => AP_EXPIRATION_TIME }.to_json
        end

        ap_stop_route = "#{PREFIX}/ap/:hostname"
        ap_stop = lambda do
          content_type 'application/json'
          body = request.body.read
          data = body.empty? ? {} : JSON.parse(body)
          host = params[:hostname]

          PERMSTORE.add_report('ap_stop', host, data.to_json)
          TEMPSTORE.del_accesspoint(host)
        end

        ap_ping_route = "#{PREFIX}/ap/:hostname/ping"
        ap_ping = lambda do
          content_type 'application/json'
          body = request.body.read
          data = body.empty? ? {} : JSON.parse(body)
          host = params[:hostname]

          PERMSTORE.add_report('ap_ping', host, data.to_json)
          TEMPSTORE.expire_accesspoint(host, AP_EXPIRATION_TIME)
        end

        sta_associate_route = "#{PREFIX}/ap/:hostname/sta/:mac"
        sta_associate = lambda do
          content_type 'application/json'
          body = request.body.read
          data = body.empty? ? {} : JSON.parse(body)
          host = params[:hostname]

          PERMSTORE.add_report('sta_associate', host, data.to_json)
          TEMPSTORE.add_station(host, data.fetch('mac'))
          TEMPSTORE.expire_accesspoint(host, AP_EXPIRATION_TIME)
        end

        sta_disassociate_route = "#{PREFIX}/ap/:hostname/sta/:mac"
        sta_disassociate = lambda do
          content_type 'application/json'
          body = request.body.read
          data = body.empty? ? {} : JSON.parse(body)
          host = params[:hostname]

          PERMSTORE.add_report('sta_disassociate', host, data.to_json)
          TEMPSTORE.del_station(host, data.fetch('mac'))
          TEMPSTORE.expire_accesspoint(host, AP_EXPIRATION_TIME)
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
    <h2>PUT <%= ap_start_route %></h2>
    <p>Create an access point entry. Must be call when an access point starts.</p>
    <dl>
      <dt>:hostname</dt>
      <dd>Hostname of the access point.</dd>
    </dl>
    <h3>Response data</h3>
    <p>Content-Type: application/json</p>
    <pre><code>
{
  "ping_interval_seconds": INT,
}
    </code></pre>
    <h2>DELETE <%= ap_stop_route %></h2>
    <p>Delete an access point entry. Must be called when an access point stops.</p>
    <dl>
      <dt>:hostname</dt>
      <dd>Hostname of the access point.</dd>
    </dl>
    <h2>POST <%= ap_ping_route %></h2>
    <p>Inform the controller that the access point is still alive. Must be called periodically.</p>
    <dl>
      <dt>:hostname</dt>
      <dd>Hostname of the access point.</dd>
    </dl>
    <h2>PUT <%= sta_associate_route %></h2>
    <p>Create a station entry. Must be called when a station associates with an access point</p>
    <dl>
      <dt>:hostname</dt>
      <dd>Hostname of the access point.</dd>
      <dt>:mac</dt>
      <dd>MAC address of the station.</dd>
    </dl>
    <h2>DELETE <%= sta_disassociate_route %></h2>
    <p>Delete a station entry. Must be called when a station disassociates with an access point</p>
    <dl>
      <dt>:hostname</dt>
      <dd>Hostname of the access point.</dd>
      <dt>:mac</dt>
      <dd>MAC address of the station.</dd>
    </dl>
  </body>
</html>
EOF
                  ).result(binding)
        end

        app.delete(ap_stop_route          , &ap_stop)
        app.delete(sta_disassociate_route , &sta_disassociate)

        app.get("#{PREFIX}"               , &root)
        app.get("#{PREFIX}/"              , &root)

        app.post(ap_ping_route            , &ap_ping)

        app.put(ap_start_route            , &ap_start)
        app.put(sta_associate_route       , &sta_associate)

      end

    end
  end
end
