module Puavo
  module Client
    module HashMixin
      module Device
        include DeviceBase

        alias_method :base_prettify_attributes, :prettify_attributes

        def prettify_attributes
          attributes = []
          attributes.push( { :original_attribute_name => "puavoSchool",
                             :new_attribute_name => "school_id",
                             :value_block => lambda{ |value| value.to_s.match(/puavoId=([^, ]+)/)[1].to_i } } )

          if self.classes.include?("puavoPrinter")
            attributes.push( { :original_attribute_name => "puavoPrinterCartridge",
                               :new_attribute_name => "printer_cartridge",
                               :value_block => lambda{ |value| Array(value).first } } )
          end
          if self.classes.include?("puavoPrinter") || self.classes.include?("puavoOtherDevice")
            attributes.push( { :original_attribute_name => "ipHostNumber",
                               :new_attribute_name => "ip_address",
                               :value_block => lambda{ |value| Array(value).first } } )
          end
          base_prettify_attributes + attributes
        end
      end
    end
  end
end
