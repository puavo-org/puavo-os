module Puavo
  module Client
    module HashMixin
      module Organisation
        include Base

        def prettify_attributes
          [
           { :original_attribute_name => "dn",
             :new_attribute_name => "base",
             :value_block => lambda{ |value| Array(value).first } },

           { :original_attribute_name => "sambaDomainName",
             :new_attribute_name => "samba_domain_name",
             :value_block => lambda{ |value| Array(value).first } },
           
           { :original_attribute_name => "puavoDomain",
             :new_attribute_name => "domain",
             :value_block => lambda{ |value| Array(value).first } },

           { :original_attribute_name => "puavoPuppetHost",
             :new_attribute_name => "puppet_host",
             :value_block => lambda{ |value| Array(value).first } },

           { :original_attribute_name => "owner",
             :new_attribute_name => "owners",
             :value_block => lambda do |value|
               Array(value).select{|o| o.to_s.match(/puavoId/)}.map do |org|
                 org.to_s.match(/puavoId=([^, ]+)/)[1].to_i
               end
             end
           },

           { :original_attribute_name => "preferredLanguage",
             :new_attribute_name => "preferred_language",
             :value_block => lambda{ |value| Array(value).first } },

           { :original_attribute_name => "o",
             :new_attribute_name => "name",
             :value_block => lambda{ |value| Array(value).first } },

           { :original_attribute_name => "puavoDeviceAutoPowerOffMode",
             :new_attribute_name => "auto_power_off_mode",
             :value_block => lambda{ |value| Array(value).first } },

           { :original_attribute_name => "puavoDeviceOnHour",
             :new_attribute_name => "auto_power_on_hour",
             :value_block => lambda{ |value| Array(value).first } },

           { :original_attribute_name => "puavoDeviceOffHour",
             :new_attribute_name => "auto_power_off_hour",
             :value_block => lambda{ |value| Array(value).first } } ]
        end
      end
    end
  end
end
