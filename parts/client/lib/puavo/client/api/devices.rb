module Puavo
  module Client
    module API
      class Devices < Base
        model_name "Device"


        def find_by_hostname(hostname)
          self.model_name.new( self,
                               rest( "#{url_prefix}#{self.model_name.model_path}/by_hostname/#{ hostname }"
                                     ).parsed_response )
        end
      end
    end
  end
end
