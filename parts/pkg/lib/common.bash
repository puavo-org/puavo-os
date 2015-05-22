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

unpack_package()
{
    local package=$1
    local packagedir=$(packagedir "$package") || return 1
    local installdir="${packagedir}/i"
    local prpdir="${packagedir}/PRP"
    local upstream_pack_md5sum=$(upstream_pack_md5sum "$package") || return 1

    has_install_link "$package" && return 0

    if [ -d "${installdir}" ]; then
        make_install_link "$packagedir" "$package" || return 1
        return 0
    fi

    [ ! -f "${packagedir}/upstream.pack" ] && {
        echo "E: cannot unpack package '${package}' because the upstream pack" \
            "is missing, download it first" >&2
        return 1
    }

    mkdir "${prpdir}"
    cp -a -T "${RESTRICTED_PKG_SHAREDIR}/${package}" "${prpdir}" || {
        rm -rf "${prpdir}"
        return 1
    }

    if is_md5sum_check_required "${package}"; then
        check_upstream_pack_md5sum "${upstream_pack_md5sum}" "${upstream_pack}" || {
            echo "E: md5 checksum of the upstream pack '${upstream_pack}' does not" \
                "match the known checksum ${upstream_pack_md5sum}," \
                "perhaps you should purge the package and download it again?" >&2
            rm -rf "${prpdir}"
            return 1
        }
    fi

    # We own this directory!
    rm -rf "${installdir}.tmp"
    mkdir "${installdir}.tmp" || {
        rm -rf "${prpdir}"
        return 1
    }

    if [ -x "${prpdir}/unpack" ]; then
        "${prpdir}/unpack" "${upstream_pack}" "${installdir}.tmp" || {
            rm -rf "${prpdir}"
            rm -rf "${installdir}.tmp"
            return 1
        }
    fi

    mv -T "${installdir}.tmp" "${installdir}" || {
        rm -rf "${prpdir}"
        rm -rf "${installdir}.tmp"
        return 1
    }

    make_install_link "$packagedir" "$package" || {
        rm -rf "${prpdir}"
        return 1
    }

    return 0
}

download_package()
{
    local package=$1
    local custom_script="${RESTRICTED_PKG_SHAREDIR}/${package}/download"
    local packagedir=$(packagedir "$package") || return 1
    local upstream_pack_md5sum=$(upstream_pack_md5sum "$package") || return 1
    local upstream_pack="${packagedir}/upstream.pack"
    local cache_path=$(upstream_pack_cache_path "$package") || return 1

    mkdir -p "$packagedir"

    if [ -e "$cache_path" -a ! "$cache_path" -ef "$upstream_pack" ]; then
        cp -u "$cache_path" "$upstream_pack" || return 1
    fi

    check_upstream_pack_md5sum "${upstream_pack_md5sum}" "${upstream_pack}" && {
        echo "I: upstream pack is already in place and has a correct checksum" >&2
        return 0
    }

    local url_file="${RESTRICTED_PKG_SHAREDIR}/${package}/upstream.pack.url"

    if [ -x "${custom_script}" ]; then
        "${custom_script}" "${url_file}" "${upstream_pack}.tmp" || {
            echo "E: package downloader returned an error!" >&2
            rm -rf "${upstream_pack}.tmp"
            return 1
        }
    else
        wget \
            --no-use-server-timestamps \
            --no-verbose \
            --no-check-certificate \
            --no-cookies \
            --input-file "${url_file}" \
            --output-document "${upstream_pack}.tmp" || {
            rm -rf "${upstream_pack}.tmp"
            return 1
        }
    fi

    if is_md5sum_check_required "${package}"; then
        check_upstream_pack_md5sum "${upstream_pack_md5sum}" "${upstream_pack}.tmp" || {
            echo "E: downloaded upstream pack has incorrect checksum" >&2
            rm -rf "${upstream_pack}.tmp"
            return 1
        }
    fi

    mv "${upstream_pack}.tmp" "${upstream_pack}" || {
        rm -rf "${upstream_pack}.tmp"
        return 1
    }

    return 0
}
