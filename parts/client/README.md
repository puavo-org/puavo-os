# puavo-client

Ruby library for interacting with [Puavo](https://github.com/opinsys/puavo-users)

## Installation

From [opinsys/opinsys-debs](https://github.com/opinsys/opinsys-debs/tree/master/packages/puavo-client)

# HTTP API wrapper

## Usage

```ruby
require 'puavo/client'

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
```

# puavo-etc

Access [Puavo registration][] information from `/etc/puavo`

## Usage

For reading puavo-etc exposes single global object:

```ruby
require "puavo/etc"

puts PUAVO_ETC.id
```

Puavo data is read lazily from `/etc/puavo` which means that possible
permission exceptions ocur only when you actually try to access the attributes.
Eg. reading  `PUAVO_ETC.ldap_password` without root and if the corresponding
file in is missing `Errno::ENOENT` will be raised. `PUAVO_ETC.get(<attribute
symbol>)` can be used to get `Errno::ENOENT` errors as nils.

Writing happens using the `write` method

```ruby
PUAVO_ETC.write(:id, 1234)
```

Available attributes can be seen from `puavo_attr` calls in `lib/puavo/etc.rb`.

# puavo-lts

Development with

    ruby -Ilib/ bin/puavo-lts

# puavo-register

Register devices to Puavo from CLI

## Requirements

- system user and group 'puavo'
  - `sudo adduser --system --no-create-home --disabled-login --group puavo`

## Usage

    [sudo] puavo-register [options]

      --update update /etc/puavo files
      --copy-files copy external files from Puavo to /etc/puavo/external_files

## Development

Install build deps

    sudo make install-build-dep

Install deps

    make

Test

    ruby -Ilib/ bin/puavo-rest-client

Create package

    make deb

[Puavo registration]: https://github.com/opinsys/puavo-register
