module Puavo
  module Lts
    class Unregistered < Base

      def initialize(organisation, school, device)
        @organisation = organisation
        @school = school
        @device = device

        @lts_data = {}
        @lts_data.merge!( define_auto_power_off )
      end

    end
  end
end
