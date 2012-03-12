#!/usr/bin/ruby
#
# This script connects to LDAP master and reads all its configuration
# and database data. Data is written to local database.
#

require "erb"
require 'tempfile'
require 'fileutils'
require 'readline'

unless organisation_name = ARGV.first
  puts "Set organisation (clone_master.rb example) or use --all arguments (clone_master.rb --all)"
  exit
end

@binddn = "uid=admin,o=Puavo"

puts "Master server:"
@master_server = Readline.readline('> ', true)

puts "uid=admin,o=puavo password:"
@bindpw = Readline.readline('> ', true)

`/etc/init.d/slapd stop`
`killall -9 slapd`
`rm -rf /etc/ldap/slapd.d/* /var/lib/ldap/*`

tempfile = Tempfile.open("ldif")

config = `ldapsearch -LLL -x -H #{ @master_server } -D #{ @binddn } -w #{ @bindpw } -Z -b cn=config`
tempfile.puts config
tempfile.close

config.split("\n").each do |line|
  if line =~ /olcDbDirectory: (.*)/
#    puts "DIR: #{$1}"
    `mkdir #{$1}`
  end
end

puts "Importing cn=config"

system("slapadd -q -l #{tempfile.path} -F /etc/ldap/slapd.d -b 'cn=config'") \
  or raise 'Problem in importing ldap configuration'

contexts = `ldapsearch -LLL -x -H #{@master_server} -D #{@binddn} -w #{@bindpw} -s base -b "" "(objectclass=*)" namingContexts -Z`

@counter = 1;

contexts.split("\n").each do |line|
  if (line =~ /namingContexts: (.*)/)
    suffix = $1.to_s
    if organisation_name == "--all" ||
        suffix[/dc=edu,dc=#{organisation_name},dc=fi/] ||
        suffix== "o=puavo"

      puts "suffix: #{suffix}"
      data = `ldapsearch -LLL -x -H #{ @master_server } -D #{ @binddn } -w #{ @bindpw } -Z -b #{suffix}`

      tempfile = Tempfile.open("data")
      tempfile.puts data
      tempfile.close
      
      system("slapadd -q -l #{tempfile.path} -F /etc/ldap/slapd.d -b '#{suffix}'") \
      or raise 'Problem in importing data'
    end
  end
end

`chown -R openldap.openldap /etc/ldap/slapd.d /var/lib/ldap`
`chmod -R 0750 /var/lib/ldap`

`/etc/init.d/slapd start`

system('chown -R openldap.openldap /etc/ldap/slapd.d /var/lib/ldap') \
  or raise 'could not chown /etc/ldap/slapd.d /var/lib/ldap to openldap user'

system('chmod -R 0750 /var/lib/ldap') \
  or raise 'could not chmod /var/lib/ldap'

system('service slapd start') \
  or raise 'slapd start failed'
