list_configured_packages()
{
    find "${PUAVO_PKG_STATEDIR}" -maxdepth 2 -mindepth 2 -type l \
        -name "${PUAVOLTSP_IMAGE_NAME}" -exec readlink -z -e {} \;    \
        | while read -d '' package_dir; do
        local package_basedir=$(dirname "${package_dir}") || return 1
        local package_name=$(basename "${package_basedir}") || return 1
        echo "${package_name}" || return 1
    done
}

get_package_basedir()
{
    local package_name=$1
    echo "${PUAVO_PKG_STATEDIR}/${package_name}"
}

get_package_link()
{
    local package_name=$1
    local package_basedir=$(get_package_basedir "${package_name}") || return 1

    echo "${package_basedir}/${PUAVOLTSP_IMAGE_NAME}"
}

get_package_dir()
{
    local package_name=$1
    local package_version=$2
    local package_basedir=$(get_package_basedir "${package_name}") || return 1

    echo "${package_basedir}/${package_version}"
}

get_configured_package_dir()
{
    local package_name=$1
    local package_link=$(get_package_link "${package_name}") || return 1

    readlink -e "${package_link}" || true
}

get_configured_package_version()
{
    local package_name=$1
    local package_dir=$(get_configured_package_dir "${package_name}") || return 1
    local package_version=$(basename "${package_dir}") || return 1

    echo "${package_version}"
}

configure_package()
{
    local package_name=$1
    local package_version=$2
    local package_dir=$(get_package_dir "${package_name}" "${package_version}") || return 1
    local upstream_dir="${package_dir}/upstream"
    local configured_package_dir=$(get_configured_package_dir "${package_name}") || return 1
    local package_link=$(get_package_link "${package_name}") || return 1

    if [ -n "${configured_package_dir}" ]; then
        if [ "${configured_package_dir}" != "${package_dir}" ]; then
            echo "E: another version of the package has already been configured, " \
                "unconfigure it before proceeding" >&2
            return 1
        fi
    fi

    if [ -x "${package_dir}/configure" ]; then
        "${package_dir}/configure" "${upstream_dir}" "${package_dir}" || {
            echo "E: failed to configure package '${package_name}'" >&2
            return 1
        }
    fi

    ln -sf "${package_version}" "${package_link}" || {
        echo "E: failed to create a package link" >&2
        return 1
    }

    echo "I: ${package_name}: configured succesfully" >&2 || true
}

reconfigure_package()
{
    local package_name=$1
    local package_version=$(get_configured_package_version "${package_name}") || return 1

    configure_package "${package_name}" "${package_version}"
}

unconfigure_package()
{
    local package_name=$1
    local package_link=$(get_package_link "${package_name}") || return 1
    local package_dir=$(readlink -e "${package_link}") || true
    local upstream_dir="${package_dir}/upstream"

    [ -n "${package_dir}" ] || return 0

    if [ -x "${package_dir}/unconfigure" ]; then
        "${package_dir}/unconfigure" "${upstream_dir}" "${package_dir}" >/dev/null || {
            echo "E: failed to unconfigure package '${package_name}'" >&2
            return 1
        }
    fi

    rm -f "${package_link}" || return 1

    echo "I: ${package_name}: unconfigured succesfully" >&2
    echo "${package_dir}"
}

unpack_upstream_pack()
{
    local package_dir=$1
    local upstream_pack="${package_dir}/upstream.pack"
    local upstream_dir="${package_dir}/upstream"
    local upstream_tmpdir="${upstream_dir}.tmp"

    if [ -d "${upstream_dir}" ]; then
        return 0
    fi

    check_md5sum "${package_dir}/upstream.pack.md5sum" "${upstream_pack}" || {
        echo "E: upstream pack has incorrect checksum, " \
            "perhaps you should purge the package and download it again?" >&2
        return 1
    }

    rm -rf "${upstream_tmpdir}"
    mkdir "${upstream_tmpdir}" || return 1

    if [ -x "${package_dir}/unpack" ]; then
        "${package_dir}/unpack" "${upstream_pack}" "${upstream_tmpdir}" || {
            rm -rf "${upstream_tmpdir}"
            return 1
        }
    fi

    mv -T "${upstream_tmpdir}" "${upstream_dir}" || {
        rm -rf "${upstream_tmpdir}"
        return 1
    }
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
    local package_dir=$1
    local upstream_pack="${package_dir}/upstream.pack"
    local upstream_tmppack="${upstream_pack}.tmp"

    if check_md5sum "${package_dir}/upstream.pack.md5sum" "${upstream_pack}"; then
        return 0
    fi

    if [ -x "${package_dir}/download" ]; then
        "${package_dir}/download" "${package_dir}/upstream.pack.url" "${upstream_tmppack}" || {
            echo "E: package downloader returned an error!" >&2
            rm -rf "${upstream_tmppack}"
            return 1
        }
    else
        wget \
            --no-use-server-timestamps \
            --no-check-certificate \
            --no-cookies \
            --input-file "${package_dir}/upstream.pack.url" \
            --output-document "${upstream_tmppack}" || {
            rm -rf "${upstream_tmppack}"
            return 1
        }
    fi

    check_md5sum "${package_dir}/upstream.pack.md5sum" "${upstream_tmppack}" || {
        echo "E: downloaded upstream pack has incorrect checksum" >&2
        rm -rf "${upstream_tmppack}"
        return 1
    }

    mv -T "${upstream_tmppack}" "${upstream_pack}" || {
        rm -rf "${upstream_pack}"
        return 1
    }
}

get_md5sum()
{
    local file=$1
    local output=$(md5sum "${file}") || return 1

    awk '{print $1}' <<<"${output}"
}

extract_installer_file()
{
    local installer_file=$1
    local package_name=$(basename "${installer_file}" .tar.gz) || return 1
    local package_version=$(get_md5sum "${installer_file}") || return 1

    local package_dir=$(get_package_dir "${package_name}" "${package_version}")
    local package_tmpdir="${package_dir}.tmp"

    if [ -d "${package_dir}" ]; then
        echo "${package_dir}"
        return
    fi

    mkdir -p "${package_tmpdir}" || return 1

    tar -z -x -f "${installer_file}" -C "${package_tmpdir}" --strip-components=1 || {
        rm -rf "${package_tmpdir}"
        return 1
    }

    mv -T "${package_tmpdir}" "${package_dir}" || {
        rm -rf "${package_tmpdir}"
        return 1
    }

    echo "I: ${package_name}: extracted installer file succesfully" >&2

    echo "${package_dir}"
}

install_package_with_installer()
{
    local installer_file=$1
    local package_dir=$(extract_installer_file "${installer_file}") || {
        echo "E: failed to extract '${installer_file}'" >&2
        return 1
    }

    local package_basedir=$(dirname "${package_dir}") || return 1
    local package_name=$(basename "${package_basedir}") || return 1
    local package_version=$(basename "${package_dir}") || return 1

    unconfigure_package "${package_name}" >/dev/null || {
        echo "E: failed to unconfigure package '${package_name}'" >&2
        return 1
    }

    download_upstream_pack "${package_dir}" || {
        echo "E: failed to download the upstream pack of package '${package_name}'" >&2
        return 1
    }

    unpack_upstream_pack "${package_dir}" || {
        echo "E: failed to unpack the upstream pack of package '${package_name}'" >&2
        return 1
    }

    configure_package "${package_name}" "${package_version}" || {
        echo "E: failed to configure package '${package_name}' of version '${package_version}'" >&2
        return 1
    }

    echo "I: ${package_name}: installed succesfully" >&2
}

remove_package()
{
    local package_name=$1

    local package_dir=$(unconfigure_package "${package_name}") || {
        echo "E: failed to unconfigure package '${package_name}'" >&2
        return 1
    }

    if [ -n "${package_dir}" ]; then
        rm -rf "${package_dir}" || return 1
        echo "I: removed package '${package_name}'" >&2
        return 0
    fi

    echo "E: package '${package_name}' is not installed" >&2
    return 1
}
