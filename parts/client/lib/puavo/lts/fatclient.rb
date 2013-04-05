module Puavo
  module Lts
    class Fatclient < Base

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
        @lts_data.merge!( define_xserver_driver )
        @lts_data.merge!( define_xrandrs )
        @lts_data.merge!( define_resolution )
        @lts_data.merge!( define_auto_power_off )
        @lts_data.merge!( define_wlan )
        @lts_data.merge!( define_default_locale )
      end

    end
  end
end
