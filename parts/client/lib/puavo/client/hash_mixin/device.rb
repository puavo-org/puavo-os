module Puavo
  module Client
    module HashMixin
      module Device
        include DeviceBase

        alias_method :base_json_attributes, :json_attributes

        def json_attributes
          base_json_attributes.push( { :original_attribute_name => "puavoSchool",
                                       :new_attribute_name => "school_id",
                                       :value_block => lambda{ |value| value.to_s.match(/puavoId=([^, ]+)/)[1].to_i } } )
        end
      end
    end
  end
end
