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
require 'redis'

module PuavoWlanController

  class TempStore

    def initialize
      @key_prefix = 'puavo-wlancontroller'
      @redis      = Redis.new
    end

    def set_status(hostname, data)
      redis_set(get_key_for_status(hostname), data)
    end

    def del_status(hostname)
      @redis.del(get_key_for_status(hostname))
    end

    def get_status_state(hostname)
      key = get_key_for_status(hostname)
      ttl = @redis.ttl(key)

      case ttl
      when -1
        nil
      when -2
        'dead'
      else
        STATUS_EXPIRATION_TIME - ttl > MAX_REPORT_INTERVAL + 5 ? 'dying' : 'alive'
      end
    end

    def get_statuses
      keys = @redis.keys(get_key_for_status('*')).sort
      return [] if keys.empty?
      @redis.mget(keys).map { |status_data_json| JSON.parse(status_data_json) }
    end

    private

    def get_key_for_status(hostname)
      "#{@key_prefix}:status:#{hostname}"
    end

    def redis_get(key)
      json = @redis.get(key)
      json.nil? ? {} : JSON.parse(json)
    end

    def redis_set(key, data)
      @redis.set(key, data.to_json)
      @redis.expire(key, STATUS_EXPIRATION_TIME)
    end

  end

end
