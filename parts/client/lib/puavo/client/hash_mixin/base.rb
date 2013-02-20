module Puavo
  module Client
    module HashMixin
      module Base
        def ldap_prettify(ldap_data)
          prettify_hash = {}
          
          prettify_attributes = self.json_attributes
          
          prettify_attributes.each do |attr|
            attribute_value = ldap_data.class == Hash ? ldap_data[attr[:original_attribute_name]] : ldap_data.send(attr[:original_attribute_name])
            prettify_hash[attr[:new_attribute_name]] = attr[:value_block].call(attribute_value)
          end
          return prettify_hash
        end
      end
    end
  end
end
