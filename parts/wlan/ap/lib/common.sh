puavo_wlanap_fail()
{
    echo "$(basename $0): error: $1" >&2
    false
}

puavo_wlanap_usage_fail()
{
    puavo_wlanap_fail "$1" || true
    echo "Usage: $(basename $0) $2" >&2
    false
}

puavo_wlanap_report()
{
    local -r hostname=$(hostname)
    local -r date=$(date +%s)
    local -r eventfile=$(mktemp --tmpdir="${PUAVO_WLANAP_RUNDIR}")

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
    local -r output=$(hostapd_cli all_sta)
    local -r devices=$(echo -n "${output}" | sed -n 's/^dot11RSNAStatsSTAAddress=//p' | tr '\n' ',')

    puavo_wlanap_report <<EOF
wlan_event:hotspot_state
connected_devices:[${devices}]
EOF
}
