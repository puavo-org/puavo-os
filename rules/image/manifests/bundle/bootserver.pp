class image::bundle::bootserver {
  include ::bootserver_autopoweron
  include ::bootserver_backup
  include ::bootserver_cups
  include ::bootserver_cron
  include ::bootserver_ddns
  include ::bootserver_firewall
  include ::bootserver_helpers
  include ::bootserver_inetd
  include ::bootserver_krb5kdc
  include ::bootserver_ltspimages
  include ::bootserver_munin
  include ::bootserver_nagios
  include ::bootserver_network_interfaces
  include ::bootserver_nfs
  include ::bootserver_nginx
  include ::bootserver_nss
  include ::bootserver_pxe
  include ::bootserver_samba
  include ::bootserver_slapd
  include ::google_cloud_print
  include ::packages

  # include ::bootserver_dummywlan              # XXX needs work
  # include ::bootserver_pam                    # XXX needs work
  # include ::bootserver_ssh_server             # XXX needs work

  Package <| tag == tag_debian_bootserver
          or tag == tag_puavo_bootserver |>
}
