puavo_wlanap_log()
{
    echo "$(basename $0): $1" >&2
}

puavo_wlanap_report()
{
    local -r hostname=$(hostname)
    local -r date=$(date +%s)
    local -r eventfile=${PUAVO_WLANAP_RUNDIR}/report

    cat <<EOF >"${eventfile}"
type:wlan
hostname:${hostname}
date:${date}
EOF

    cat >>"${eventfile}"

    nc -w 1 -u eventlog 3858 <"${eventfile}"
}

puavo_wlanap_report_status()
{
    local -r output=$(hostapd_cli -p "${PUAVO_WLANAP_RUNDIR}/hostapd" all_sta)
    local -r devices=$(echo -n "${output}" | sed -n 's/^dot11RSNAStatsSTAAddress=//p' | tr '\n' ',')

    puavo_wlanap_report <<EOF
wlan_event:hotspot_state
connected_devices:[${devices}]
EOF
}
