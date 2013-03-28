module Puavo
  module Lts
    class LtspServer < Base

      def initialize(organisation, school, device)
        @organisation = organisation
        @school = school
        @device = device

        @lts_data = {
          'NFS_SERVER' => boot_server_fqdn,
          'SERVER'     => boot_server_fqdn,
        }
        
        @lts_data.merge!( define_tags )
        @lts_data.merge!( define_default_printer )
      end

    end
  end
end
