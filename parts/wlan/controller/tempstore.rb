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
      @key_prefix_ap_status  = 'puavo-wlancontroller:ap-status'
      @redis                 = Redis.new
    end

    def update_ap_status(ap_status)
      ap_hostname = ap_status.fetch('hostname')
      key = "#{@key_prefix_ap_status}:#{ap_hostname}"
      @redis.set(key, ap_status.to_json)
      @redis.expire(key, AP_STATUS_EXPIRATION_TIME)
    end

    def get_ap_statuses
      keys = @redis.keys("#{@key_prefix_ap_status}:*")
      return [] if keys.empty?
      @redis.mget(keys).map { |ap_status_json| JSON.parse(ap_status_json) }
    end

  end

end
