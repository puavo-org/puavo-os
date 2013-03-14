module Puavo
  module Lts
    class LtspServer < Base

      def initialize(organisation, school, device)
        @organisation = organisation
        @school = school
        @device = device

        @lts_data = {
          'LOCAL_APPS'     => 'False',
          'LOCALDEV'       => 'False',
          'LTSP_FATCLIENT' => 'False',
          'LTSP_SERVER'    => 'True',
          'SERVER'         => boot_server_fqdn,
          'USE_NFS_HOMES'  => 'True',
          'NFS_SERVER'     => boot_server_fqdn,
        }
        
        @lts_data.merge!( define_tags )
        @lts_data.merge!( define_default_printer )
        @lts_data.merge!( define_xserver_driver )
        @lts_data.merge!( define_xrandrs )
        @lts_data.merge!( define_resolution )
        @lts_data.merge!( define_auto_power_off )
      end

    end
  end
end
