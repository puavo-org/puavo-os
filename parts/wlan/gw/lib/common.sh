puavo_wlangw_warn()
{
    echo "$(basename $0): warn: $1" >&2
}

puavo_wlangw_fail()
{
    echo "$(basename $0): fail: $1" >&2
    false
}

puavo_wlangw_usage_fail()
{
    puavo_wlangw_fail "$1" || true
    echo "Usage: $(basename $0) $2" >&2
    false
}
