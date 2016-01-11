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
      @key_prefix_status = 'puavo-wlancontroller:status'
      @key_prefix_host   = 'puavo-wlancontroller:host'
      @redis           = Redis.new
    end

    def add_ap(hostname, phymac, bssid, data)
      key = "#{@key_prefix_host}:#{hostname}:radio:#{phymac}:ap:#{bssid}"
      @redis.set(key, data.to_json)
      @redis.expire(key, STATUS_EXPIRATION_TIME)
    end

    def add_host(hostname, data)
      key = "#{@key_prefix_host}:#{hostname}"
      @redis.set(key, data.to_json)
      @redis.expire(key, STATUS_EXPIRATION_TIME)
    end

    def add_radio(hostname, phymac, data)
      key = "#{@key_prefix_host}:#{hostname}:radio:#{phymac}"
      @redis.set(key, data.to_json)
      @redis.expire(key, STATUS_EXPIRATION_TIME)
    end

    def get_ap(hostname, phymac, bssid)
      key  = "#{@key_prefix_host}:#{hostname}:radio:#{phymac}:ap:#{bssid}"
      json = @redis.get(key)
      json.nil? ? {} : JSON.parse(json)
    end

    def get_radio(hostname, phymac)
      key  = "#{@key_prefix_host}:#{hostname}:radio:#{phymac}"
      json = @redis.get(key)
      json.nil? ? {} : JSON.parse(json)
    end

    def del_ap(hostname, phymac, bssid)
      @redis.del("#{@key_prefix_host}:#{hostname}:radio:#{phymac}:ap:#{bssid}")
    end

    def del_radio(hostname, phymac)
      @redis.del("#{@key_prefix_host}:#{hostname}:radio:#{phymac}")
    end

    def del_host(hostname)
      @redis.del("#{@key_prefix_host}:#{hostname}")
    end

    def get_host(hostname)
      key = "#{@key_prefix_host}:#{hostname}"
      host_json = @redis.get(key)
      host_json.nil? ? {} : JSON.parse(host_json)
    end

    def update_status(hostname, data)
      key = "#{@key_prefix_status}:#{hostname}"
      @redis.set(key, data.to_json)
      @redis.expire(key, STATUS_EXPIRATION_TIME)
      @redis.expire("#{@key_prefix_host}:#{hostname}", STATUS_EXPIRATION_TIME)
      @redis.keys("#{@key_prefix_host}:#{hostname}:*").each do |subkey|
        @redis.expire(subkey, STATUS_EXPIRATION_TIME)
      end
    end

    def get_statuses
      keys = @redis.keys("#{@key_prefix_status}:*")
      return [] if keys.empty?
      @redis.mget(keys).map { |status_data_json| JSON.parse(status_data_json) }
    end

    def get_status_state(hostname)
      key = "#{@key_prefix_status}:#{hostname}"
      ttl = @redis.ttl(key)

      case ttl
      when -1
        nil
      when -2
        'dead'
      else
        STATUS_EXPIRATION_TIME - ttl > PING_INTERVAL_SECONDS + 5 ? 'dying' : 'alive'
      end
    end

    def delete_status(hostname)
      @redis.del("#{@key_prefix_status}:#{hostname}")
    end

  end

end
