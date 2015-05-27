list_configured_packages()
{
    local package_dirs=$(find "${RESTRICTED_PKG_STATEDIR}" \
        -maxdepth 2 -mindepth 2                                   \
        -name "${PUAVOLTSP_IMAGE_NAME}" -type l                   \
        -exec readlink -e {} \;) || {
        echo "E: package search failed for an unknown reason" >&2
        return 1
    }

    while read package_dir; do
        local package_basedir=$(dirname "${package_dir}") || return 1
        local package_name=$(basename "${package_basedir}") || return 1

        echo "${package_name}" || return 1
    done <<<"${package_dirs}"

get_package_basedir()
{
    local package_name=$1
    echo "${RESTRICTED_PKG_STATEDIR}/${package_name}"
}

get_package_link()
{
    local package_name=$1
    echo "${RESTRICTED_PKG_STATEDIR}/${package_name}/${PUAVOLTSP_IMAGE_NAME}"
}

get_package_dir()
{
    local package_name=$1
    local package_version=$2
    local package_basedir=$(get_package_basedir "${package_name}") || return 1

    echo "${package_basedir}/${package_version}"
}

configure_package()
{
    local package_path=$1
    local package_dir="${RESTRICTED_PKG_STATEDIR}/${package_path}"
    local upstream_pack="${package_dir}/upstream.pack"
    local upstreamdir="${package_dir}/upstream"

    if [ -x "${package_dir}/PRP/configure" ]; then
        "${package_dir}/PRP/configure" "${upstreamdir}" "${package_dir}/PRP" || {
            echo "E: failed to configure package '${package_path}'" >&2
            return 1
        }
    fi

    return 0
}

unconfigure_package()
{
    local package_path=$1
    local package_dir="${RESTRICTED_PKG_STATEDIR}/${package_path}"
    local upstream_pack="${package_dir}/upstream.pack"
    local upstreamdir="${package_dir}/upstream"

    if [ -x "${package_dir}/PRP/unconfigure" ]; then
        "${package_dir}/PRP/unconfigure" "${upstreamdir}" "${package_dir}/PRP" || {
            echo "E: failed to unconfigure package '${package_path}'" >&2
            return 1
        }
    fi

    return 0
}

unpack_upstream_pack()
{
    local package_path=$1
    local package_dir="${RESTRICTED_PKG_STATEDIR}/${package_path}"
    local upstream_pack="${package_dir}/upstream.pack"
    local upstreamdir="${package_dir}/upstream"

    if [ -d "${upstreamdir}" ]; then
        echo "I: upstream pack is already unpacked" >&2
        return 0
    fi

    check_md5sum "${package_dir}/PRP/upstream.pack.md5sum" "${upstream_pack}" || {
        echo "E: upstream pack has incorrect checksum, " \
            "perhaps you should purge the package and download it again?" >&2
        return 1
    }

    rm -rf "${upstreamdir}.tmp"
    mkdir "${upstreamdir}.tmp" || return 1

    if [ -x "${package_dir}/PRP/unpack" ]; then
        "${package_dir}/PRP/unpack" "${upstream_pack}" "${upstreamdir}.tmp" || {
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

download_upstream_pack()
{
    local package_path=$1
    local package_dir="${RESTRICTED_PKG_STATEDIR}/${package_path}"
    local upstream_pack="${package_dir}/upstream.pack"

    if check_md5sum "${package_dir}/PRP/upstream.pack.md5sum" "${upstream_pack}"; then
        echo "I: upstream pack is already downloaded" >&2
        return 0
    fi

    if [ -x "${package_dir}/PRP/download" ]; then
        "${package_dir}/PRP/download" "${package_dir}/PRP/upstream.pack.url" "${upstream_pack}.tmp" || {
            echo "E: package downloader returned an error!" >&2
            rm -rf "${upstream_pack}.tmp"
            return 1
        }
    else
        wget \
            --no-use-server-timestamps \
            --no-check-certificate \
            --no-cookies \
            --input-file "${package_dir}/PRP/upstream.pack.url" \
            --output-document "${upstream_pack}.tmp" || {
            rm -rf "${upstream_pack}.tmp"
            return 1
        }
    fi

    check_md5sum "${package_dir}/PRP/upstream.pack.md5sum" "${upstream_pack}.tmp" || {
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

install_package_file()
{
    local package_file=$1
    local package_path=$(extract_package_file "${package_file}") || {
        echo "E: failed to extract '${package_file}'" >&2
        return 1
    }

    download_upstream_pack "${package_path}" || {
        echo "E: failed to download the upstream pack of package '${package_path}'" >&2
        return 1
    }

    unpack_upstream_pack "${package_path}" || {
        echo "E: failed to unpack the upstream pack of package '${package_path}'" >&2
        return 1
    }

    configure_package "${package_path}" || {
        echo "E: failed to configure package '${package_path}'" >&2
        return 1
    }

    return 0
}

remove_package()
{
    local package_name=$1

    unconfigure_package "${package_name}" || {
        echo "E: failed to unconfigure package '{package_name}'" >&2
        return 1
    }

    rm -rf "${RESTRICTED_PKG_STATEDIR}/${package_name}"
}
