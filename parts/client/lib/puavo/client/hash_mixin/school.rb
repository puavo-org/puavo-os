module Puavo
  module Client
    module HashMixin
      module School
        include Base

        def prettify_attributes
          [
           { :original_attribute_name => "puavoId",
             :new_attribute_name => "puavo_id",
             :value_block => lambda{ |value| Array(value).first } } ]
        end
      end
      
    end
  end
end
