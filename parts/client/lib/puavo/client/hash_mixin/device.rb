module Puavo
  module Client
    module HashMixin
      module Device
        include DeviceBase

        alias_method :base_prettify_attributes, :prettify_attributes

        def prettify_attributes
          base_prettify_attributes.push( { :original_attribute_name => "puavoSchool",
                                           :new_attribute_name => "school_id",
                                           :value_block => lambda{ |value| value.to_s.match(/puavoId=([^, ]+)/)[1].to_i } } )
        end
      end
    end
  end
end
