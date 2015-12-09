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

require 'time'

module PuavoWlanController
  module Routes
    module Root

      PREFIX = ''

      def self.registered(app)
        root = lambda do
          content_type 'text/html'
          ap_statuses = TEMPSTORE.get_ap_statuses

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

          total_station_count = 0
          total_interface_count = 0
          total_ap_rx_bytes = 0
          total_ap_tx_bytes = 0
          total_sta_rx_bytes = 0
          total_sta_tx_bytes = 0
          stations = []
          interfaces = []
          hosts = []
          ap_statuses.each do |ap_status|
            host_rx_bytes = 0
            host_tx_bytes = 0
            total_interface_count += ap_status['interfaces'].length
            ap_status['interfaces'].each do |interface|
              total_station_count += interface['stations'].length
              total_ap_rx_bytes += interface['rx_bytes']
              total_ap_tx_bytes += interface['tx_bytes']
              host_rx_bytes += interface['rx_bytes']
              host_tx_bytes += interface['tx_bytes']
              interface['hostname'] = ap_status['hostname']
              interface['uptime'] = Time.now - Time.parse(interface.fetch('start_time'))
              interface['stations'].each do |station|
                station['bssid'] = interface['bssid']
                station['hostname'], station['fqdn'], station['ipaddr'] = arp_table.fetch(station['mac'], [nil, nil, nil])
                total_sta_rx_bytes += station['rx_bytes']
                total_sta_tx_bytes += station['tx_bytes']
                stations << station
              end
              interfaces << interface
            end
            hosts << {
              'hostname'        => ap_status['hostname'],
              'interface_count' => ap_status['interfaces'].length,
              'rx_bytes'        => host_rx_bytes,
              'tx_bytes'        => host_tx_bytes,
            }
          end

          erb :index, :locals => {
            :hosts                 => hosts,
            :interfaces            => interfaces,
            :stations              => stations,
            :total_ap_rx_bytes     => total_ap_rx_bytes,
            :total_ap_tx_bytes     => total_ap_tx_bytes,
            :total_interface_count => total_interface_count,
            :total_sta_rx_bytes    => total_sta_rx_bytes,
            :total_sta_tx_bytes    => total_sta_tx_bytes,
            :total_station_count   => total_station_count,
          }

        end

        app.get("#{PREFIX}/", &root)
      end

    end
  end
end
