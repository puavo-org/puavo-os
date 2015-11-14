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

  AP_EXPIRATION_TIME = 20

  class App < Sinatra::Base

    register PuavoWlanController::Routes::Root
    register PuavoWlanController::Routes::V1

  end

end
