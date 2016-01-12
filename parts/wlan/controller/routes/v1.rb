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

        route_report = '/v1/report'
        route_root   = '/v1'
        route_status = '/v1/status/:hostname'

        get_root = lambda do
          content_type 'text/html'

          erb :v1_root, :locals => {
            :route_status => route_status,
          }
        end

        delete_status = lambda do
          hostname = params[:hostname]

          TEMPSTORE.del_status(hostname)
          nil
        end

        post_report = lambda do
          body = request.body.read
          data = JSON.parse(body)

          PERMSTORE.add_report(data)
          nil
        end

        put_status = lambda do
          body     = request.body.read
          data     = JSON.parse(body)
          hostname = params[:hostname]

          TEMPSTORE.set_status(hostname, data)
          { :ping_interval_seconds => PING_INTERVAL_SECONDS }.to_json
        end

        app.delete(route_status, &delete_status)
        app.get(route_root,      &get_root)
        app.post(route_report,   &post_report)
        app.put(route_status,    &put_status)

      end

    end
  end
end
