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
        report = lambda do
          content_type 'application/json'
          body = request.body.read
          data = body.empty? ? {} : JSON.parse(body)
          host = params[:host]
          name = params[:name]
          PERMSTORE.add_report(name, host, data.to_json)

          case name
          when 'ap_hearbeat'
            TEMPSTORE.expire_accesspoint(host, AP_EXPIRATION_TIME)
          when 'ap_start'
            TEMPSTORE.add_accesspoint(host)
            TEMPSTORE.expire_accesspoint(host, AP_EXPIRATION_TIME)
            { :ap_expiration_time => AP_EXPIRATION_TIME }.to_json
          when 'ap_stop'
            TEMPSTORE.del_accesspoint(host)
          when 'sta_associate'
            TEMPSTORE.add_station(host, data.fetch('mac'))
            TEMPSTORE.expire_accesspoint(host, AP_EXPIRATION_TIME)
          when 'sta_disassociate'
            TEMPSTORE.del_station(host, data.fetch('mac'))
            TEMPSTORE.expire_accesspoint(host, AP_EXPIRATION_TIME)
          end
        end

        status = lambda do
          content_type 'application/json'
          TEMPSTORE.get_accesspoints.to_json
        end

        app.put("#{PREFIX}/report/:name/:host", &report)
        app.get("#{PREFIX}/status"            , &status)
      end

    end
  end
end
