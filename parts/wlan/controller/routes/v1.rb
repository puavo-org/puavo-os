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

          TEMPSTORE.update_host_status(data)
          { :ping_interval_seconds => PING_INTERVAL_SECONDS }.to_json
        end

        delete_host = lambda do
          hostname = params[:hostname]

          TEMPSTORE.delete_host(hostname)
          nil
        end

        root = lambda do
          content_type 'text/html'

          erb :v1_index, :locals => {
            :ping_route => ping_route,
          }
        end

        app.delete("#{PREFIX}/host/:hostname", &delete_host)

        app.get("#{PREFIX}"  , &root)
        app.get("#{PREFIX}/" , &root)

        app.post(ping_route  , &ping)

      end

    end
  end
end
