module Puavo
  module Client
    module API
      class Base
        include HTTParty
        
        attr_accessor :subdomain, :username, :password, :ssl

        def initialize(subdomain, username, password, ssl = true)
          @subdomain, @username, @password, @ssl = subdomain, username, password, ssl
        end

        def basic_auth
          { :username => @username, :password => @password }
        end

        def url_prefix
          (ssl ? 'https' : 'http') + "://" + @subdomain
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

        def rest(url)
          self.class.get(url,
                         :basic_auth => basic_auth,
                         :headers => {
                           "Accept" => "application/json",
                           "Content-Type" => "application/json; charset=utf-8",
                           "User-Agent" => "PuavoClient/0.01" })
          # FIXME: version number
        end
      end
    end
  end
end
