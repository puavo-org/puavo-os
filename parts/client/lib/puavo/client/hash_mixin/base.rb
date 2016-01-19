module Puavo
  module Client
    module HashMixin
      module Base
        def ldap_prettify
          prettify_hash = {}
          
          prettify_attributes.each do |attr|
            begin
              attribute_value = self.send(attr[:original_attribute_name])
            rescue NoMethodError
              attribute_value = nil
            end

            prettify_hash[attr[:new_attribute_name]] = attr[:value_block].call(attribute_value)
          end
          return prettify_hash
        end
      end
    end
  end
end
