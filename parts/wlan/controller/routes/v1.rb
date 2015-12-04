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
        ap_start = lambda do
          content_type 'application/json'
          body = request.body.read
          data = body.empty? ? {} : JSON.parse(body)
          host = params[:host]

          PERMSTORE.add_report('ap_start', host, data.to_json)
          TEMPSTORE.add_accesspoint(host)
          TEMPSTORE.expire_accesspoint(host, AP_EXPIRATION_TIME)
          { :ap_expiration_time => AP_EXPIRATION_TIME }.to_json
        end

        ap_stop = lambda do
          content_type 'application/json'
          body = request.body.read
          data = body.empty? ? {} : JSON.parse(body)
          host = params[:host]

          PERMSTORE.add_report('ap_stop', host, data.to_json)
          TEMPSTORE.del_accesspoint(host)
        end

        ap_ping = lambda do
          content_type 'application/json'
          body = request.body.read
          data = body.empty? ? {} : JSON.parse(body)
          host = params[:host]

          PERMSTORE.add_report('ap_ping', host, data.to_json)
          TEMPSTORE.expire_accesspoint(host, AP_EXPIRATION_TIME)
        end

        sta_associate = lambda do
          content_type 'application/json'
          body = request.body.read
          data = body.empty? ? {} : JSON.parse(body)
          host = params[:host]

          PERMSTORE.add_report('sta_associate', host, data.to_json)
          TEMPSTORE.add_station(host, data.fetch('mac'))
          TEMPSTORE.expire_accesspoint(host, AP_EXPIRATION_TIME)
        end

        sta_disassociate = lambda do
          content_type 'application/json'
          body = request.body.read
          data = body.empty? ? {} : JSON.parse(body)
          host = params[:host]

          PERMSTORE.add_report('sta_disassociate', host, data.to_json)
          TEMPSTORE.del_station(host, data.fetch('mac'))
          TEMPSTORE.expire_accesspoint(host, AP_EXPIRATION_TIME)
        end

        app.delete("#{PREFIX}/ap/:host"          , &ap_stop)
        app.delete("#{PREFIX}/ap/:host/sta/:mac" , &sta_disassociate)

        app.post("#{PREFIX}/ap/:host/ping"       , &ap_ping)

        app.put("#{PREFIX}/ap/:host"             , &ap_start)
        app.put("#{PREFIX}/ap/:host/sta/:mac"    , &sta_associate)

      end

    end
  end
end
