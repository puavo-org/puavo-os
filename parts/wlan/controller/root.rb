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

# Standard library modules.
require 'json'

# Third-party modules.
require 'sinatra'

# Local modules.
require_relative './permstore.rb'
require_relative './tempstore.rb'

module PuavoWlanController

  PERMSTORE = PermStore.new
  TEMPSTORE = TempStore.new

  class Root < Sinatra::Base

    before do
      content_type 'application/json'
    end

    put '/v1/report/:name/:host' do
      data = request.body.read
      json = data.empty? ? {}.to_json : JSON.parse(data).to_json
      host = params[:host]
      name = params[:name]
      PERMSTORE.add_report(name, host, json)

      case name
      when 'ap_hearbeat'
        TEMPSTORE.expire_accesspoint(host, 20)
      when 'ap_start'
        TEMPSTORE.add_accesspoint(host)
        TEMPSTORE.expire_accesspoint(host, 20)
      when 'ap_stop'
        TEMPSTORE.del_accesspoint(host)
      end
    end

    get '/v1/status' do
      accesspoints = TEMPSTORE.get_accesspoints

      case request.preferred_type.entry
      when 'application/json'
        accesspoints.to_json
      when 'text/html'
        content_type 'text/html'
        ERB.new(<<'EOF'
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Puavo's WLAN Controller - Status</title>
  </head
  <body>
    <h1>Status</h1>
    <h2>Access points (<%= accesspoints.length %>)</h2><% unless accesspoints.empty? %>
    <ul><% accesspoints.each do |ap| %>
        <li><%= ap %></li><% end %>
    </ul><% end %>
  </body>
</html>
EOF
                ).result(binding)
      else
        content_type 'text/plain'
        accesspoints.join('\n')
      end
    end

  end

end
