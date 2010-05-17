#!/usr/bin/ruby

require './lib/slapd.rb'

puts "Checking slapd settings:"

slapd = PuavoSetup::SLAPD.new
result = PuavoSetup::SLAPD.check_schemas("cosine nis inetorgperson misc ppolicy samba autofs kerberos eduorg eduperson edumember puppet dnsdomain2 printer puavo".split)
puts "* Installed schemas: #{result[:installed_schemas].join(', ')}"
puts "* Missing schemas: #{result[:missing_schemas].join(', ')}"

puts "Checking modules:"
result = PuavoSetup::SLAPD.check_modules("back_hdb dynlist unique ppolicy syncprov memberof valsort auditlog refint".split)
puts "* Installed modules: #{result[:installed_modules].join(', ')}"
puts "* Missing modules: #{result[:missing_modules].join(', ')}"

puts "Configured databases:"

PuavoSetup::SLAPD.list_configured_databases.each do |database|
  puts "* #{database}"
end

puts "Checking certificates:"
PuavoSetup::SLAPD.check_certificates
