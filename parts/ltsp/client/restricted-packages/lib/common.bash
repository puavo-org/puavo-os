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
    local package_path=$1
    local pkgdir="${RESTRICTED_PKG_STATEDIR}/${package_path}"
    local upstream_pack="${pkgdir}/upstream.pack"
    local upstreamdir="${pkgdir}/upstream"

    if [ -x "${pkgdir}/PRP/configure" ]; then
        "${pkgdir}/PRP/configure" "${upstreamdir}" "${pkgdir}/PRP" || {
            echo "E: failed to configure package '${package_path}'" >&2
            return 1
        }
    fi

    return 0
}

unconfigure_package()
{
    local package_path=$1
    local pkgdir="${RESTRICTED_PKG_STATEDIR}/${package_path}"
    local upstream_pack="${pkgdir}/upstream.pack"
    local upstreamdir="${pkgdir}/upstream"

    if [ -x "${pkgdir}/PRP/unconfigure" ]; then
        "${pkgdir}/PRP/unconfigure" "${upstreamdir}" "${pkgdir}/PRP" || {
            echo "E: failed to unconfigure package '${package_path}'" >&2
            return 1
        }
    fi

    return 0
}

unpack_package()
{
    local package_path=$1
    local pkgdir="${RESTRICTED_PKG_STATEDIR}/${package_path}"
    local upstream_pack="${pkgdir}/upstream.pack"
    local upstreamdir="${pkgdir}/upstream"

    if [ -d "${upstreamdir}" ]; then
        echo "I: upstream pack is already unpacked" >&2
        return 0
    fi

    check_md5sum "${pkgdir}/PRP/upstream.pack.md5sum" "${upstream_pack}" || {
        echo "E: upstream pack has incorrect checksum, " \
            "perhaps you should purge the package and download it again?" >&2
        return 1
    }

    rm -rf "${upstreamdir}.tmp"
    mkdir "${upstreamdir}.tmp" || return 1

    if [ -x "${pkgdir}/PRP/unpack" ]; then
        "${pkgdir}/PRP/unpack" "${upstream_pack}" "${upstreamdir}.tmp" || {
            rm -rf "${upstreamdir}.tmp"
            return 1
        }
    fi

    mv -T "${upstreamdir}.tmp" "${upstreamdir}" || {
        rm -rf "${upstreamdir}.tmp"
        return 1
    }

    return 0
}

check_md5sum()
{
    local md5sum_file=$1
    local file=$2

    [ -r "${md5sum_file}" ] || return 0
    local md5sum_str=$(cat "${md5sum_file}") || return 1

    md5sum --check --status 2>/dev/null <<<"${md5sum_str}  ${file}"
}

download_package()
{
    local package_path=$1
    local pkgdir="${RESTRICTED_PKG_STATEDIR}/${package_path}"
    local upstream_pack="${pkgdir}/upstream.pack"

    if check_md5sum "${pkgdir}/PRP/upstream.pack.md5sum" "${upstream_pack}"; then
        echo "I: upstream pack is already downloaded" >&2
        return 0
    fi

    if [ -x "${pkgdir}/PRP/download" ]; then
        "${pkgdir}/PRP/download" "${pkgdir}/PRP/upstream.pack.url" "${upstream_pack}.tmp" || {
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
            --input-file "${pkgdir}/PRP/upstream.pack.url" \
            --output-document "${upstream_pack}.tmp" || {
            rm -rf "${upstream_pack}.tmp"
            return 1
        }
    fi

    check_md5sum "${pkgdir}/PRP/upstream.pack.md5sum" "${upstream_pack}.tmp" || {
        echo "E: downloaded upstream pack has incorrect checksum" >&2
        rm -rf "${upstream_pack}.tmp"
        return 1
    }

    mv "${upstream_pack}.tmp" "${upstream_pack}" || {
        rm -rf "${upstream_pack}.tmp"
        return 1
    }

    return 0
}

download_packagelicense()
{
    local package=$1
    local custom_script="${RESTRICTED_PKG_SHAREDIR}/${package}/downloadlicense"
    local packagedir=$(packagedir "$package") || return 1
    local upstream_pack_md5sum=$(upstream_pack_md5sum "$package") || return 1
    local upstream_license="${packagedir}/upstream.license"
    local cache_path=$(upstream_license_cache_path "$package") || return 1

    mkdir -p "$packagedir" || return 1

    if [ -e "$cache_path" -a ! "$cache_path" -ef "$upstream_license" ]; then
        cp -u "$cache_path" "$upstream_license" || return 1
    fi

    if [ -r "$upstream_license" ]; then
        echo "License file is already in place for '${package}'" >&2
        return 0
    fi

    local url="$(jq -r .url ${RESTRICTED_PKG_SHAREDIR}/${package}/license.json)" || return 1

    if [ -z "$url" ]; then
        echo "No license url could be found for '${package}'" >&2
        return 1
    fi

    if [ -x "${custom_script}" ]; then
        "${custom_script}" "${url}" "${upstream_license}.tmp" || {
            rm -rf "${upstream_license}.tmp"
            return 1
        }
    else
        wget \
            --no-use-server-timestamps \
            --no-verbose \
            --no-check-certificate \
            --no-cookies \
            --output-document "${upstream_license}.tmp" \
            --quiet \
            "${url}" || {
            rm -rf "${upstream_license}.tmp"
            return 1
        }
    fi

    mv "${upstream_license}.tmp" "${upstream_license}" || {
        rm -rf "${upstream_license}.tmp"
        return 1
    }

    return 0
}

get_md5sum()
{
    local package_file=$1
    local output=$(md5sum "${package_file}") || return 1

    awk '{print $1}' <<<"${output}"
}

extract_package_file()
{
    local package_file=$1
    local package_md5sum=$(get_md5sum "${package_file}") || return 1
    local package_name=$(basename "${package_file}" .tar.gz) || return 1
    local package_path="${package_name}/${package_md5sum}"

    local package_base="${RESTRICTED_PKG_STATEDIR}/${package_name}"
    local package_dir="${package_base}/${package_md5sum}"

    if [ -d "${package_dir}" ]; then
        echo "I: package is already extracted" >&2
        echo "${package_path}"
        return
    fi

    mkdir -p "${package_base}" || return 1
    mkdir "${package_dir}" || return 1
    mkdir "${package_dir}/PRP" || {
        rm -rf "${package_dir}"
        return 1
    }

    tar -z -x -f "${package_file}" -C "${package_dir}/PRP" --strip-components=1 || {
        rm -rf "${package_dir}"
        return 1
    }

    echo "${package_path}"
}
