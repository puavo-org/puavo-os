pwap_log()
{
    echo "$(basename $0): $1" >&2
}

pwap_report()
{
    local -r hostname=$(hostname)
    local -r date=$(date +%s)
    local -r eventfile=${PWAP_RUNDIR}/report

    cat <<EOF >"${eventfile}"
type:wlan
hostname:${hostname}
date:${date}
EOF

    cat >>"${eventfile}"

    nc -w 1 -u eventlog 3858 <"${eventfile}"
}
