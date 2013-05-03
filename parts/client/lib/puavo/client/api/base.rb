require "puavo/etc"

module Puavo
  module Client
    module API

      class Error < Exception
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
        
        attr_accessor :domain, :username, :password, :ssl

        def initialize(
          domain = PUAVO_ETC.domain,
          username = PUAVO_ETC.ldap_dn,
          password = PUAVO_ETC.ldap_password,
          ssl = true
        )
          @domain, @username, @password, @ssl = domain, username, password, ssl
        end

        def subdomain
          STDERR.puts "Using legazy subdomain attribute"
          @domain
        end

        def basic_auth
          { :username => @username, :password => @password }
        end

        def url_prefix
          (ssl ? 'https' : 'http') + "://" + @domain
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
            raise APIError.new res
          end
          return res
        end
      end
    end
  end
end
