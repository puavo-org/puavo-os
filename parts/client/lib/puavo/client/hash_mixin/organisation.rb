module Puavo
  module Client
    module HashMixin
      module Organisation
        include Base

        def prettify_attributes
          [
           { :original_attribute_name => "puavoDomain",
             :new_attribute_name => "domain",
             :value_block => lambda{ |value| Array(value).first } } ]
        end
      end
      
    end
  end
end
