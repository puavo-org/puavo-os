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

        status_route = "#{PREFIX}/status/:hostname"
        host_route   = "#{PREFIX}/host/:hostname"
        radio_route  = "#{PREFIX}/host/:hostname/radio/:phymac"
        ap_route     = "#{PREFIX}/host/:hostname/radio/:phymac/ap/:bssid"

        put_host = lambda do
          body     = request.body.read
          data     = JSON.parse(body)
          hostname = params[:hostname]

          TEMPSTORE.add_host(hostname, data)
          nil
        end

        delete_host = lambda do
          hostname = params[:hostname]

          TEMPSTORE.del_host(hostname)
          nil
        end

        get_host = lambda do
          content_type 'application/json'

          hostname = params[:hostname]

          TEMPSTORE.get_host(hostname).to_json
        end

        put_radio = lambda do
          body     = request.body.read
          data     = JSON.parse(body)
          hostname = params[:hostname]
          phymac   = params[:phymac]

          TEMPSTORE.add_radio(hostname, phymac, data)
          nil
        end

        get_radio = lambda do
          content_type 'application/json'

          hostname = params[:hostname]
          phymac   = params[:phymac]

          TEMPSTORE.get_radio(hostname, phymac).to_json

        delete_radio = lambda do
          hostname = params[:hostname]
          phymac   = params[:phymac]

          TEMPSTORE.del_radio(hostname, phymac)
          nil
        end

        put_ap = lambda do
          body     = request.body.read
          data     = JSON.parse(body)
          hostname = params[:hostname]
          phymac   = params[:phymac]
          bssi     = params[:bssid]

          TEMPSTORE.add_ap(hostname, phymac, bssid, data)
          nil
        end

        get_ap = lambda do
          content_type 'application/json'

          hostname = params[:hostname]
          phymac   = params[:phymac]
          bssid    = params[:bssid]

          TEMPSTORE.get_ap(hostname, phymac, bssid).to_json
        end

        delete_ap = lambda do
          hostname = params[:hostname]
          phymac   = params[:phymac]
          bssid    = params[:bssid]

          TEMPSTORE.del_ap(hostname, phymac, bssid)
          nil
        end

        put_status = lambda do
          body     = request.body.read
          data     = JSON.parse(body)
          hostname = params[:hostname]

          TEMPSTORE.update_status(hostname, data)
          { :ping_interval_seconds => PING_INTERVAL_SECONDS }.to_json
        end

        delete_status = lambda do
          hostname = params[:hostname]

          TEMPSTORE.delete_status(hostname)
          nil
        end

        get_index = lambda do
          content_type 'text/html'

          erb :v1_index, :locals => {
            :status_route => status_route,
          }
        end

        app.delete(status_route, &delete_status)
        app.delete(host_route,   &delete_host)
        app.delete(radio_route,  &delete_radio)
        app.delete(ap_route,     &delete_ap)

        app.get("#{PREFIX}",     &get_index)
        app.get("#{PREFIX}/",    &get_index)
        app.get(host_route,      &get_host)
        app.get(radio_route,     &get_radio)
        app.get(ap_route,        &get_ap)

        app.put(status_route,    &put_status)
        app.put(host_route,      &put_host)
        app.put(radio_route,     &put_radio)
        app.put(ap_route,        &put_ap)

      end

    end
  end
end
