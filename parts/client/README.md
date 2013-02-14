# puavo-client

Ruby library for interacting with [Puavo](https://github.com/opinsys/puavo-users)

## Installation

From [opinsys/opinsys-debs](https://github.com/opinsys/opinsys-debs/tree/master/packages/puavo-client)

## HTTP API wrapper

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

# puavo-etc

Access [Puavo registration][] information from `/etc/puavo` using Ruby.

## Usage

For reading puavo-etc exposes single global object:

```ruby
require "puavo/etc"

puts PUAVO_ETC.id
```

Puavo data is read lazily from `/etc/puavo` which means that possible
permission exceptions ocur only when you actually try to access the attributes.
Eg. reading  `PUAVO_ETC.ldap_password` without root.

Writing happens using the `write` method

```ruby
PUAVO_ETC.write(:id, 1234)
```

Available attributes can be seen from `puavo_attr` calls in `puavo-etc.rb`.


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
