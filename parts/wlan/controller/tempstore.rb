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

# Third-party modules.
require 'redis'

module PuavoWlanController

  class TempStore

    def initialize
      @key_prefix_ap = 'puavo-wlancontroller:ap:'
      @redis         = Redis.new
    end

    def add_accesspoint(hostname)
      key = "#{@key_prefix_ap}#{hostname}"
      @redis.set(key, hostname)
    end

    def expire_accesspoint(hostname, expire_seconds)
      key = "#{@key_prefix_ap}#{hostname}"
      @redis.expire(key, expire_seconds)
    end

    def del_accesspoint(hostname)
      key = "#{@key_prefix_ap}#{hostname}"
      @redis.del(key)
    end

    def get_accesspoints
      ap_keys = @redis.keys("#{@key_prefix_ap}*")
      ap_keys.empty? ? [] : @redis.mget(ap_keys)
    end

  end

end
