module Puavo
  module Client
    module HashMixin
      module School
        include Base

        def prettify_attributes
          [
           { :original_attribute_name => "cn",
             :new_attribute_name => "group_name",
             :value_block => lambda{ |value| Array(value).first } },
           
           { :original_attribute_name => "st",
             :new_attribute_name => "state",
             :value_block => lambda{ |value| Array(value).first } },
           
           { :original_attribute_name => "postalAddress",
             :new_attribute_name => "postal_address",
             :value_block => lambda{ |value| Array(value).first } },

           { :original_attribute_name => "telephoneNumber",
             :new_attribute_name => "phone_number",
             :value_block => lambda{ |value| Array(value).first } },

           { :original_attribute_name => "gidNumber",
             :new_attribute_name => "gid",
             :value_block => lambda{ |value| Array(value).first } },

           { :original_attribute_name => "displayName",
             :new_attribute_name => "name",
             :value_block => lambda{ |value| Array(value).first } },

           { :original_attribute_name => "street",
             :new_attribute_name => "street",
             :value_block => lambda{ |value| Array(value).first } },

           { :original_attribute_name => "puavoId",
             :new_attribute_name => "puavo_id",
             :value_block => lambda{ |value| Array(value).first } },

           { :original_attribute_name => "postalCode",
             :new_attribute_name => "postal_code",
             :value_block => lambda{ |value| Array(value).first } },

           { :original_attribute_name => "puavoSchoolHomePageURL",
             :new_attribute_name => "home_page",
             :value_block => lambda{ |value| Array(value).first } },

           { :original_attribute_name => "sambaSID",
             :new_attribute_name => "samba_SID",
             :value_block => lambda{ |value| Array(value).first } },

           { :original_attribute_name => "sambaGroupType",
             :new_attribute_name => "samba_group_type",
             :value_block => lambda{ |value| Array(value).first } },

           { :original_attribute_name => "postOfficeBox",
             :new_attribute_name => "post_office_box",
             :value_block => lambda{ |value| Array(value).first } },

           { :original_attribute_name => "puavoWlanChannel",
             :new_attribute_name => "wlan_channel",
             :value_block => lambda{ |value| Array(value).first } },

           { :original_attribute_name => "preferredLanguage",
             :new_attribute_name => "preferred_language",
             :value_block => lambda{ |value| Array(value).first } },

           { :original_attribute_name => "puavoWlanSSID",
             :new_attribute_name => "wlan_ssids",
             :value_block => lambda{ |value| Array(value) } } ]
        end
      end
    end
  end
end
