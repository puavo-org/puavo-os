module Puavo
  module Client
    module API
      class Organisation < Base
        model_name 'Puavo::Client::Organisation'

        def find
          Puavo::Client::Organisation.new( self, rest("#{url_prefix}#{self.model_name.model_path}").parsed_response )
        end
      end
    end
  end
end
