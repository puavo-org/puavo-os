module Puavo
  module Lts
    class Laptop < Base

      def initialize(organisation, school, device)
        @organisation = organisation
        @school = school
        @device = device

        @lts_data = {}
        
        @lts_data.merge!( define_tags )
        @lts_data.merge!( define_default_printer )
        @lts_data.merge!( define_xserver_driver )
        @lts_data.merge!( define_xrandrs )

      end

    end
  end
end

