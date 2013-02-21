module Puavo
  module Lts
    class Fatclient < Base

      def initialize(organisation, school, device)
        @organisation = organisation
        @school = school
        @device = device

        @lts_data = {
          'NBD_SWAP'             => 'False',
          'SYSLOG'               => 'False',
          'XKBLAYOUT'            => 'fi',
          'LOCAL_APPS'           => 'False',
          'LOCALDEV'             => 'False',
          'LTSP_FATCLIENT'       => 'True',
          'USE_NFS_HOMES'        => 'True',
          'SCREEN_07'            => 'lightdm',
          'KEEP_SYSTEM_SERVICES' => '"gssd idmapd rpcbind-boot portmap"',
          'SERVER'               => boot_server_fqdn,
          'NFS_SERVER'           => boot_server_fqdn
        }
        
        @lts_data.merge!( define_tags )
        @lts_data.merge!( define_default_printer )
        @lts_data.merge!( define_xserver_driver )
        @lts_data.merge!( define_xrandrs )
        @lts_data.merge!( define_resolution )
        @lts_data.merge!( define_auto_power_off )
        @lts_data.merge!( define_wlan )
        @lts_data.merge!( define_system_services )
      end

    end
  end
end
