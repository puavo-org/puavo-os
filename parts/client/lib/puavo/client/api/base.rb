require "puavo/etc"

module Puavo
  module Client
    module API

      class Error < StandardError
        attr_accessor :response
        def initialize(response)
          @response = response
        end
        def to_s
          "<#{ self.class.name } error: #{ @response.code }>"
        end
      end


      class Base
        include HTTParty
        
        attr_accessor :username, :password, :ssl

        def initialize(domain=nil, username=nil, password=nil, ssl=true)
          @domain = domain
          @username = username || PUAVO_ETC.ldap_dn
          @password = password || PUAVO_ETC.ldap_password
          @ssl = ssl
        end

        def subdomain
          STDERR.puts "Puavo::Client::API::Base using legazy subdomain attribute"
          @domain
        end

        def basic_auth
          { :username => @username, :password => @password }
        end

        def url_prefix
          if @domain
            (ssl ? 'https' : 'http') + "://" + @domain
          else
            PUAVO_ETC.resolve_puavo_url
          end
        end

        class << self
          def model_name(klass)
            class_eval("def model_name() #{klass} end")
          end
        end

        def all
          self.model_name.parse( self, rest("#{url_prefix}#{self.model_name.model_path}").parsed_response )
        end
        def find_by_school_id(id)
          self.model_name.parse( self, rest("#{url_prefix}#{self.model_name.model_path(:school_id => id)}").parsed_response )
        end

        def find_all_by_memberUid(uid)
          self.model_name.parse( self, rest("#{url_prefix}#{self.model_name.model_path}?memberUid=#{uid}").parsed_response )
        end

        def find_by_id(id)
          self.model_name.new( self,
                               rest( "#{url_prefix}#{self.model_name.model_path( :id => id )}"
                                     ).parsed_response )
        end

        def rest(url)
          res = self.class.get(url,
                         :basic_auth => basic_auth,
                         :headers => {
                           "Accept" => "application/json",
                           "Content-Type" => "application/json; charset=utf-8",
                           "User-Agent" => "PuavoClient/0.01" })
          # FIXME: version number
          if res.code != 200
            raise Error.new res
          end
          return res
        end
      end
    end
  end
end
