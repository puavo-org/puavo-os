module Puavo
  module Lts
    class Fatclient < Base

      def initialize(organisation, school, device)
        @organisation = organisation
        @school = school
        @device = device

        @lts_data = {
          'LOCAL_APPS'         => 'False',
          'LOCALDEV'           => 'False',
          'LTSP_FATCLIENT'     => 'True',
          'NBD_SWAP'           => 'False',
          'NFS_SERVER'         => boot_server_fqdn,
          'RM_SYSTEM_SERVICES' => 'network-manager',
          'SCREEN_07'          => 'lightdm',
          'SERVER'             => boot_server_fqdn,
          'SYSLOG'             => 'False',
          'USE_NFS_HOMES'      => 'True',
          'XKBLAYOUT'          => 'fi',
        }
        
        @lts_data.merge!( define_tags )
        @lts_data.merge!( define_default_printer )
        @lts_data.merge!( define_xserver_driver )
        @lts_data.merge!( define_xrandrs )
        @lts_data.merge!( define_resolution )
        @lts_data.merge!( define_auto_power_off )
        @lts_data.merge!( define_wlan )
      end

    end
  end
end
