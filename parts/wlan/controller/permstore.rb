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
require 'sqlite3'

module PuavoWlanController

  class PermStore

    def initialize
      @db = SQLite3::Database.new(ENV.fetch('PUAVO_WLANCONTROLLER_DB_SQLITE3', 'controller.sqlite3'))
      begin
        @db.execute <<'EOF'
CREATE TABLE IF NOT EXISTS Report (
  name TEXT NOT NULL,
  host TEXT NOT NULL,
  json TEXT NOT NULL,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);
EOF
      rescue SQLite3::BusyException
        sleep 1
        retry
      end
    end

    def add_report(name, host, data)
      sql = 'INSERT INTO Report(name, host, json) VALUES (?, ?, ?);'
      @db.execute(sql, name, host, data.to_json)
    end

  end

end
