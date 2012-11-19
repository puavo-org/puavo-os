#!/bin/sh

puavo_wlanap_get_conf()
{
    sed -n "s/^$1=\(.*\)\$/\1/p" /etc/puavo-wlanap/run.conf
}

puavo_wlanap_write_hostapd_conf()
{
    tapif=$1
    cat - <<EOF >/etc/puavo-wlanap/hostapd.conf
interface=$(puavo_wlanap_get_conf wlanif)
bridge=br.$tapif
driver=nl80211
ssid=$(puavo_wlanap_get_conf ssid)
country_code=FI
hw_mode=g
#channel=$(puavo_wlanap_get_conf wlanch)
channel=6
max_num_sta=1000
wmm_enabled=1
ctrl_interface=/var/run/hostapd
ieee80211n=1
ht_capab=[HT40-]
#rsn_preauth_interfaces=eth0 br.$tapif
wds_sta=1
#peerkey=1
EOF
    case $(puavo_wlanap_get_conf wlantype) in
	open)
	    cat - <<EOF >>/etc/puavo-wlanap/hostapd.conf
wpa=0
EOF
	    ;;
	eap)
	    cat - <<EOF >>/etc/puavo-wlanap/hostapd.conf
ieee8021x=1
auth_server_addr=$(puavo_wlanap_get_conf serverip)
auth_server_port=$(puavo_wlanap_get_conf eap_auth_server_port)
auth_server_shared_secret=$(puavo_wlanap_get_conf eap_auth_server_secret)
acct_server_addr=$(puavo_wlanap_get_conf eap_acct_server_addr)
acct_server_port=$(puavo_wlanap_get_conf eap_acct_server_port)
acct_server_shared_secret=$(puavo_wlanap_get_conf eap_acct_server_secret)
wpa=2
auth_algs=3
#wpa_pairwise=TKIP CCMP
rsn_pairwise=CCMP
wpa_key_mgmt=WPA-EAP
eapol_version=1
eapol_key_index_workaround=1
eap_reauth_period=0
wpa_strict_rekey=0
wpa_group_rekey=0
rsn_preauth=1
wpa_gmk_rekey=0
EOF
	    ;;
	psk)
	    cat - <<EOF >>/etc/puavo-wlanap/hostapd.conf
wpa=2
auth_algs=3
wpa_passphrase=$(puavo_wlanap_get_conf password)
#wpa_pairwise=TKIP CCMP
rsn_pairwise=CCMP
wpa_key_mgmt=WPA-PSK
eapol_version=1
eapol_key_index_workaround=1
eap_reauth_period=0
wpa_strict_rekey=0
wpa_group_rekey=0
#rsn_preauth=1
wpa_gmk_rekey=0
EOF
	    ;;
	*)
	    ;;
    esac
}
