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

require_relative './routes/root.rb'
require_relative './routes/v1.rb'

module PuavoWlanController

  PERMSTORE = PermStore.new
  TEMPSTORE = TempStore.new

  PING_INTERVAL_SECONDS = 20
  HOST_STATUS_EXPIRATION_TIME = PING_INTERVAL_SECONDS * 2

  class App < Sinatra::Base

    register PuavoWlanController::Routes::Root
    register PuavoWlanController::Routes::V1

    def prettify_bytes(bytes)
      return "NaN" if bytes.nil?

      return "#{(bytes / 1024.0**2).round(1)} TiB" if bytes >= 1024**4
      return "#{(bytes / 1024.0**2).round(1)} GiB" if bytes >= 1024**3
      return "#{(bytes / 1024.0**2).round(1)} MiB" if bytes >= 1024**2
      return "#{(bytes / 1024.0**1).round(1)} KiB" if bytes >= 1024**1

      "#{bytes} B"
    end

    def prettify_seconds(seconds)
      seconds = seconds.to_i

      minutes = seconds / 60
      seconds = seconds % 60
      result = "#{seconds}s"

      hours = minutes / 60
      minutes = minutes % 60
      result.prepend("#{minutes}m ") if minutes > 0

      days = hours / 24
      hours = hours % 24
      result.prepend("#{hours}h ") if hours > 0

      result.prepend("#{days}d ") if days > 0

      result
    end

    def get_arp_table
      arp_table = {}
      IO.popen(['arp', '-a']) do |io|
        io.each_line do |line|
          fields = line.split
          fqdn = fields[0]
          ipaddr = fields[1][1..-2] # Omit leading and trailing parens.
          mac = fields[3]
          next if mac == '<incomplete>'
          hostname = fqdn == '?' ? '?' : fqdn.split('.')[0]
          arp_table[mac] = [hostname, fqdn, ipaddr]
        end
      end
      arp_table
    end

  end

end
