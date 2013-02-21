module Puavo
  module Lts
    class Thinclient < Base

      def initialize(organisation, school, device)
        @organisation = organisation
        @school = school
        @device = device

        @lts_data = {
          'NBD_SWAP'             => 'False',
          'SYSLOG'               => 'False',
          'XKBLAYOUT'            => 'fi',
          'LDM_AUTOLOGIN'        => 'False',
          'LDM_DIRECTX'          => 'True',
          'LOCAL_APPS'           => 'False',
          'LOCALDEV'             => 'True',
          'LTSP_FATCLIENT'       => 'False',
          'SCREEN_07'            => 'lightdm',
          'X_COLOR_DEPTH'        => '16',
          'SERVER'               => boot_server_fqdn,
          'NFS_SERVER'           => boot_server_fqdn,
          'LDM_SERVER'           => PUAVO_ETC.primary_ltsp_server,
          'LDM_SESSION'          => '"gnome-session --session=gnome-fallback"',
          'SSH_OVERRIDE_PORT'    => '222'
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
