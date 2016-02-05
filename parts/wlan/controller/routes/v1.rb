#!/usr/bin/ruby
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

        get_root = lambda do
          content_type 'text/html'

          erb :v1_root, :locals => {
            :route_report => route_report,
          }
        end

        post_report = lambda do
          content_type 'application/json'

          body_json = request.body.read
          body      = JSON.parse(body_json)

          name      = body.fetch('name')
          hostname  = body.fetch('hostname')
          timestamp = body.fetch('timestamp')
          data      = body.fetch('data')

          case name
          when 'bye'
            TEMPSTORE.del_status(hostname)
          when 'status'
            TEMPSTORE.set_status(hostname, data)
          end

          { :max_report_interval => MAX_REPORT_INTERVAL }.to_json
        end

        app.get(route_root,      &get_root)
        app.post(route_report,   &post_report)

      end

    end
  end
end
