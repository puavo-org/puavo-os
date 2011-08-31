module Puavo
  module Client
    class Base
      attr_accessor :subdomain, :username, :password, :ssl

      def initialize(subdomain, username, password, ssl = true)
        @subdomain, @username, @password, @ssl = subdomain, username, password, ssl
      end

      def organisation
        Puavo::Client::API::Organisation.new(subdomain, username, password, ssl)
      end

      def schools
        Puavo::Client::API::Schools.new(subdomain, username, password, ssl)
      end
      
      def groups
        Puavo::Client::API::Groups.new(subdomain, username, password, ssl)
      end

      def devices
        Puavo::Client::API::Devices.new(subdomain, username, password, ssl)
      end

      def users
        Puavo::Client::API::Users.new(subdomain, username, password, ssl)
      end
    end
  end
end
