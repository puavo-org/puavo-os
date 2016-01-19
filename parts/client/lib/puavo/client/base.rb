require "puavo/etc"

module Puavo
  module Client
    class Base
      attr_accessor :domain, :username, :password, :ssl

      def initialize(domain=nil, username=nil, password=nil, ssl=true)
        @domain = domain
        @username = username
        @password = password
        @ssl = ssl
      end

      def subdomain
        STDERR.puts "Puavo::Client::Base using legazy subdomain attribute"
        @domain
      end

      def self.new_by_ldap_entry(entry)
        raise "Entry is nil or empty" if entry.nil? || entry.empty?

        if entry["objectClass"].include?( "puavoSchool" )
          Puavo::Client::School.new_by_ldap_entry(entry)
        elsif entry["objectClass"].include?( "puavoEduOrg" )
          Puavo::Client::Organisation.new_by_ldap_entry(entry)
        elsif entry.has_key?("puavoDeviceType") && !["ltspserver", "bootserver"].include?(entry["puavoDeviceType"])
          Puavo::Client::Device.new_by_ldap_entry(entry)
        elsif entry.has_key?("puavoDeviceType") && ["ltspserver", "bootserver"].include?(entry["puavoDeviceType"])
          Puavo::Client::Server.new_by_ldap_entry(entry)
        else
          raise "Unknown object type"
        end
      end

      def organisation
        Puavo::Client::API::Organisation.new(domain, username, password, ssl)
      end

      def schools
        Puavo::Client::API::Schools.new(domain, username, password, ssl)
      end
      
      def groups
        Puavo::Client::API::Groups.new(domain, username, password, ssl)
      end

      def devices
        Puavo::Client::API::Devices.new(domain, username, password, ssl)
      end

      def users
        Puavo::Client::API::Users.new(domain, username, password, ssl)
      end

      def servers
        Puavo::Client::API::Servers.new(domain, username, password, ssl)
      end

      def external_files
        Puavo::Client::API::ExternalFiles.new(domain, username, password, ssl)
      end

    end
  end
end
