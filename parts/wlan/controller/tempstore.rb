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

module TempStore

  REDIS = Redis.new

  KEY_PREFIX_AP = 'puavo-wlancontroller:ap:'

  def self.add_accesspoint(hostname)
    key = "#{KEY_PREFIX_AP}#{hostname}"
    REDIS.set(key, hostname)
  end

  def self.expire_accesspoint(hostname, expire_seconds)
    key = "#{KEY_PREFIX_AP}#{hostname}"
    REDIS.expire(key, expire_seconds)
  end

  def self.del_accesspoint(hostname)
    key = "#{KEY_PREFIX_AP}#{hostname}"
    REDIS.del(key)
  end

  def self.get_accesspoints
    ap_keys = REDIS.keys("#{KEY_PREFIX_AP}*")
    ap_keys.empty? ? [] : REDIS.mget(ap_keys)
  end

end
