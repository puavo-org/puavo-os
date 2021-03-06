module Puavo
  module Client
    module HashMixin
      module DeviceBase
        include Base

        def booleanize(value)
	  v = Array(value).first
          (v && v != 'FALSE') ? true : false
        end

        def prettify_attributes
          # Note: value of attribute may be raw ldap value eg. { puavoHostname => ["device-01"] }
          [
           { :original_attribute_name => "objectClass",
             :new_attribute_name => "classes",
             :value_block => lambda{ |value| Array(value) } },
           { :original_attribute_name => "description",
             :new_attribute_name => "description",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "macAddress",
             :new_attribute_name => "mac_address",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoDefaultPrinter",
             :new_attribute_name => "default_printer",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoDeviceAutoPowerOffMode",
             :new_attribute_name => "auto_power_off_mode",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoDeviceOnHour",
             :new_attribute_name => "auto_power_on_hour",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoDeviceOffHour",
             :new_attribute_name => "auto_power_off_hour",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoDeviceBootMode",
             :new_attribute_name => "boot_mode",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoDeviceManufacturer",
             :new_attribute_name => "manufacturer",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoDeviceModel",
             :new_attribute_name => "model",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoLatitude",
             :new_attribute_name => "latitude",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoLocationName",
             :new_attribute_name => "location_name",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoLongitude",
             :new_attribute_name => "longitude",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoPurchaseDate",
             :new_attribute_name => "purchase_date",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoPurchaseLocation",
             :new_attribute_name => "purchase_location",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoPurchaseURL",
             :new_attribute_name => "purchase_url",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoSupportContract",
             :new_attribute_name => "support_contract",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoTag",
             :new_attribute_name => "tags",
             :value_block => lambda{ |value| Array(value) } },
           { :original_attribute_name => "puavoWarrantyEndDate",
             :new_attribute_name => "warranty_end_date",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "serialNumber",
             :new_attribute_name => "serialnumber",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoHostname",
             :new_attribute_name => "hostname",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoId",
             :new_attribute_name => "puavo_id",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoDeviceKernelVersion",
             :new_attribute_name => "kernel_version",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoDeviceKernelArguments",
             :new_attribute_name => "kernel_arguments",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoDeviceXrandr",
             :new_attribute_name => "xrandrs",
             :value_block => lambda{ |value| Array(value) } },
           { :original_attribute_name => "puavoDeviceXrandrDisable",
             :new_attribute_name => "xrandr_disable",
             :value_block => lambda{ |value| booleanize(value) } },
           { :original_attribute_name => "puavoDeviceType",
             :new_attribute_name => "device_type",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoDeviceImage",
             :new_attribute_name => "device_image",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoWlanChannel",
             :new_attribute_name => "wlan_channel",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoDeviceXserver",
             :new_attribute_name => "xserver_driver",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoDeviceResolution",
             :new_attribute_name => "resolution",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoDeviceHorzSync",
             :new_attribute_name => "horizontal_sync",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "preferredLanguage",
             :new_attribute_name => "preferred_language",
             :value_block => lambda{ |value| Array(value).first } },
           { :original_attribute_name => "puavoDeviceVertRefresh",
             :new_attribute_name => "vertical_refresh",
             :value_block => lambda{ |value| Array(value).first } } ]
        end
      end
    end
  end
end
