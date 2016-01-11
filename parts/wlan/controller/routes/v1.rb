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

      def self.registered(app)

        route_root   = '/v1'

        route_host   = '/v1/host/:hostname'
        route_radio  = '/v1/host/:hostname/radio/:phymac'
        route_ap     = '/v1/host/:hostname/radio/:phymac/ap/:bssid'
        route_sta    = '/v1/host/:hostname/radio/:phymac/ap/:bssid/sta/:mac'

        route_status = '/v1/status/:hostname'

        get_ap = lambda do
          content_type 'application/json'

          hostname = params[:hostname]
          phymac   = params[:phymac]
          bssid    = params[:bssid]

          TEMPSTORE.get_ap(hostname, phymac, bssid).to_json
        end

        get_host = lambda do
          content_type 'application/json'

          hostname = params[:hostname]

          TEMPSTORE.get_host(hostname).to_json
        end

        get_radio = lambda do
          content_type 'application/json'

          hostname = params[:hostname]
          phymac   = params[:phymac]

          TEMPSTORE.get_radio(hostname, phymac).to_json
        end

        get_root = lambda do
          content_type 'text/html'

          erb :v1_root, :locals => {
            :route_status => route_status,
          }
        end

        get_sta = lambda do
          content_type 'application/json'

          hostname = params[:hostname]
          phymac   = params[:phymac]
          bssid    = params[:bssid]
          mac      = params[:mac]

          TEMPSTORE.get_sta(hostname, phymac, bssid, mac).to_json
        end

        delete_ap = lambda do
          hostname = params[:hostname]
          phymac   = params[:phymac]
          bssid    = params[:bssid]

          TEMPSTORE.del_ap(hostname, phymac, bssid)
          nil
        end

        delete_host = lambda do
          hostname = params[:hostname]

          TEMPSTORE.del_host(hostname)
          nil
        end

        delete_radio = lambda do
          hostname = params[:hostname]
          phymac   = params[:phymac]

          TEMPSTORE.del_radio(hostname, phymac)
          nil
        end

        delete_sta = lambda do
          hostname = params[:hostname]
          phymac   = params[:phymac]
          bssid    = params[:bssid]
          mac      = params[:mac]

          TEMPSTORE.del_sta(hostname, phymac, bssid, mac)
          nil
        end

        delete_status = lambda do
          hostname = params[:hostname]

          TEMPSTORE.del_status(hostname)
          nil
        end

        put_ap = lambda do
          body     = request.body.read
          data     = JSON.parse(body)
          hostname = params[:hostname]
          phymac   = params[:phymac]
          bssi     = params[:bssid]

          TEMPSTORE.set_ap(hostname, phymac, bssid, data)
          nil
        end

        put_host = lambda do
          body     = request.body.read
          data     = JSON.parse(body)
          hostname = params[:hostname]

          TEMPSTORE.set_host(hostname, data)
          nil
        end

        put_radio = lambda do
          body     = request.body.read
          data     = JSON.parse(body)
          hostname = params[:hostname]
          phymac   = params[:phymac]

          TEMPSTORE.set_radio(hostname, phymac, data)
          nil
        end

        put_sta = lambda do
          body     = request.body.read
          data     = JSON.parse(body)
          hostname = params[:hostname]
          phymac   = params[:phymac]
          bssid    = params[:bssid]
          mac      = params[:mac]

          TEMPSTORE.set_sta(hostname, phymac, bssid, mac, data)
          nil
        end

        put_status = lambda do
          body     = request.body.read
          data     = JSON.parse(body)
          hostname = params[:hostname]

          TEMPSTORE.set_status(hostname, data)
          { :ping_interval_seconds => PING_INTERVAL_SECONDS }.to_json
        end

        app.delete(route_ap,     &delete_ap)
        app.delete(route_host,   &delete_host)
        app.delete(route_radio,  &delete_radio)
        app.delete(route_sta,    &delete_sta)
        app.delete(route_status, &delete_status)

        app.get(route_ap,        &get_ap)
        app.get(route_host,      &get_host)
        app.get(route_radio,     &get_radio)
        app.get(route_root,      &get_root)
        app.get(route_sta,       &get_sta)

        app.put(route_ap,        &put_ap)
        app.put(route_host,      &put_host)
        app.put(route_radio,     &put_radio)
        app.put(route_sta,       &put_sta)
        app.put(route_status,    &put_status)

      end

    end
  end
end
