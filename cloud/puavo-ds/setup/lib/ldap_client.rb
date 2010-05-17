#!/usr/bin/ruby
# -*- coding: utf-8 -*-

module PuavoSetup

  # SLAPD handles all configuration related to OpenLDAP (slapd).
  # 
  # This module uses Ldapmapper:
  #
  # http://raa.ruby-lang.org/project/ldapmapper/1.0.0
  # http://ldapmapper.rubyforge.org/
  #
  # Copyright Ultragreen (c) 2005-2007
  #

  class LdapClient
    require "ldap"
    require 'rubygems'
    require "socket"
    require "./lib/settings.rb"

    def self.check_ldap_client_conf
      content = ""

      puts "Checking ldap client configuration in /etc/ldap/ldap.conf:"
      
      f = File.open("/etc/ldap/ldap.conf", "r") 
      f.each_line do |line|
        if ! /^\#/.match(line)
          content += line
        end
      end
      
      if /BASE\s*(.*?)\n/.match(content)
        suffix = $1
        
        puts "* BASE: #{suffix}"
      else
        puts "* ERROR: BASE not defined in /etc/ldap/ldap.conf"
        result = false
      end
      
      #  puts "LDAP client configuration (/etc/ldap/ldap.conf):"
      
      if /URI\s*(.*?)\n/.match(content)
        uris = $1
        
        uris.split.each do |uri|
          if /ldap[s]*:\/\/(.*?)[$\/]/.match(uri)
            hostname = $1
            
            begin
              ip = IPSocket.getaddress(hostname)
              puts "* URI: #{uri} OK (IP: #{ip})"
            rescue => e
              puts "* ERROR: hostname #{hostname} in URI #{uri} not found!"
              result = false
            end
            
            if /ldaps:\/\/(.*?)[$\/]/.match(uri)
              use_tls = false
              port = 636
              method = "SSL"
            else
              use_tls = true
              port = 389
              method = "StartTLS"
            end
            
            begin
              conn = LDAP::SSLConn.new(host=hostname, port=port, use_tls)
              conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
              conn.search(suffix, LDAP::LDAP_SCOPE_SUBTREE, "(objectclass=*)"){|e|}
              
              puts "* Connection to #{hostname}:#{port} with #{method} OK"
            rescue => e
              puts e.inspect
              puts "* ERROR: Failed to connect to #{uri} using #{method}"
            end
          end
        end
      end
      
      if /TLS_CACERT\s*(.*?)\n/.match(content)
        ca_cert_file = $1
        
        puts "* CA certificate file: #{ca_cert_file}"
        
        cacertdump = `certtool --certificate-info --infile #{ca_cert_file}`
        
        if /Subject: .*,CN=(.*?)\n/.match(cacertdump)
          cacert_hostname = $1
          
          puts "* CA certificate has hostname #{cacert_hostname}"
        end
      else
        puts "* ERROR: CA certificate file not defined (TLS_CACERT)!"
      end
    end
  end
end
