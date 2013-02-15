module Puavo
  module Lts
    class Fatclient < Base

      def initialize(organisation, school, device)
        @organisation = organisation
        @school = school
        @device = device

        @lts_data = {}
      end

    end
  end
end
