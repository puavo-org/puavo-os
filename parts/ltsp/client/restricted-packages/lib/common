install_link() {
  echo "$(packagebase "$1")/${PUAVOLTSP_IMAGE_NAME}"
}

has_install_link() {
  # $1=package
  [ -h "$(install_link "$1")" ]
}

make_install_link() {
  # $1=packagedir
  ln -fns "$(basename "$1")" "$(install_link "$(basename "$(dirname "$1")")")"
}

remove_install_link() {
  # $1=package
  rm -f "$(install_link "$1")"
}

packagebase() {
  echo "${RESTRICTED_PKG_STATEDIR}/$1"
}

packagedir() {
  echo "$(packagebase "$1")/$(upstream_pack_md5sum "$1")"
}

packagecache() {
  # $1=package
  echo "/var/lib/puavo-ltsp-client-restricted-packages/$1/$(upstream_pack_md5sum "$1")"
}

upstream_license_cache_path() {
  # $1=package
  echo "$(packagecache "$1")/upstream.license"
}

upstream_pack_cache_path() {
  # $1=package
  echo "$(packagecache "$1")/upstream.pack"
}

upstream_pack_md5sum() {
  cat "${RESTRICTED_PKG_SHAREDIR}/$1/upstream.pack.md5sum"
}

check_upstream_pack_md5sum() {
  echo "$1  $2" | md5sum --check --status 2>/dev/null
}

is_md5sum_check_required() {
  test ! -f "${RESTRICTED_PKG_SHAREDIR}/$1/upstream.pack.md5sum.nocheck"
}

configure_package() {
    local package=$1
    local packagedir=$(packagedir "${package}") || return 1
    local installdir="${packagedir}/i"
    local prpdir="${packagedir}/PRP"

    has_install_link "$package" || {
        echo "E: failed to configure package '${package}' because it is not installed" >&2
        return 1
    }

    if [ -x "${prpdir}/configure" ]; then
        "${prpdir}/configure" "${installdir}" "${prpdir}" || {
            echo "E: failed to configure package '${package}' because '${prpdir}/configure' failed" >&2
            return 1
        }
    fi

    return 0
}

unconfigure_package()
{
    local package=$1
    local packagedir=$(packagedir "$package") || return 1
    local installdir="${packagedir}/i"
    local prpdir="${packagedir}/PRP"

    has_install_link "$package" || {
        echo "E: failed to unconfigure package '${package}' because it is not installed" >&2
        return 1
    }

    if [ -x "${prpdir}/unconfigure" ]; then
        "${prpdir}/unconfigure" "${installdir}" "${prpdir}" || {
            echo "E: failed to unconfigure package '${package}' because '${prpdir}/unconfigure' failed" >&2
            return 1
        }
    fi

    return 0
}

uninstall_package()
{
    local package=$1
    local packagedir=$(packagedir "$package") || return 1
    local installdir="${packagedir}/i"
    local prpdir="${packagedir}/PRP"

    remove_install_link "$package" || return 1

    for imglink in $(packagebase "$package")/*.img; do
        if [ ! -h "$imglink" ]; then
            # last install link removed, garbage collect this
            rm -rf "${installdir}" "${prpdir}"
            break
        fi
    done

    return 0
}
