## Overview

Simple ruby wrapper for the [Puavo API](https://github.com/opinsys/puavo-user])

## Installation

    sudo gem install httparty gemcutter jeweler
    git clone https://<username>@github.com/opinsys/puavo-client.git
    cd puavo-client
    sudo rake install

## Examples

    require 'rubygems'
    require 'puavo-client'

    puavo = Puavo::Client::Base.new('yourpuavoserver', 'yourusername', 'yourpassword')
    
    schools = puavo.schools.all

    puts "Devices by school"
    schools.each do |s|
      puts s.displayName
      puts puavo.devices.find_by_school_id(s.puavoId).map{ |d| "\t#{d.puavoHostname}" }
    end

    puts "Groups by school"
    schools.each do |s|
      puts s.displayName
      puts puavo.groups.find_by_school_id(s.puavoId).map{ |g| "\t#{g.cn}" }
    end


## Copyright

Copyright © 2010 Opinsys Oy

This program is free software; you can redistribute it and/or modify it 
under the terms of the GNU General Public License as published by the 
Free Software Foundation; either version 2 of the License, or (at your 
option) any later version.

This program is distributed in the hope that it will be useful, but 
WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General 
Public License for more details.

You should have received a copy of the GNU General Public License along 
with this program; if not, write to the Free Software Foundation, Inc., 
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
