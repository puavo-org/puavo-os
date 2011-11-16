## Overview

Simple ruby wrapper for the [Puavo API](https://github.com/opinsys/puavo-users)

## Installation

    # Ubuntu 10.04
    sudo apt-get install libjson-ruby libopenssl-ruby
    sudo gem install httparty gemcutter jeweler puavo-client

## Examples

    require 'rubygems'
    require 'puavo-client'

    puavo = Puavo::Client::Base.new('yourpuavoserver', 'yourusername', 'yourpassword')
    
    schools = puavo.schools.all
    
    puts "Devices by school"
    schools.each do |s|
      puts s.name
      puts puavo.devices.find_by_school_id(s.puavo_id).map{ |d| "\t#{d.puavoHostname}" }
    end
    
    puts "Groups by school"
    schools.each do |s|
      puts s.name
      puts puavo.groups.find_by_school_id(s.puavo_id).map{ |g| "\t#{g.abbreviation}" }
    end

## Copyright

Copyright © 2010 Opinsys Oy

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
