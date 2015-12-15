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

require 'json'

# Third-party modules.
require 'redis'

module PuavoWlanController

  class TempStore

    def initialize
      @key_prefix_host = 'puavo-wlancontroller:host'
      @redis           = Redis.new
    end

    def update_host(hostname, data)
      key = "#{@key_prefix_host}:#{hostname}"
      @redis.set(key, data.to_json)
      @redis.expire(key, HOST_EXPIRATION_TIME)
    end

    def get_hosts
      keys = @redis.keys("#{@key_prefix_host}:*")
      return [] if keys.empty?
      @redis.mget(keys).map { |host_data_json| JSON.parse(host_data_json) }
    end

    def get_host_state(hostname)
      key = "#{@key_prefix_host}:#{hostname}"
      ttl = @redis.ttl(key)

      case ttl
      when -1
        nil
      when -2
        'dead'
      else
        HOST_EXPIRATION_TIME - ttl > PING_INTERVAL_SECONDS + 5 ? 'dying' : 'alive'
      end
    end

    def delete_host(hostname)
      @redis.del("#{@key_prefix_host}:#{hostname}")
    end

  end

end
