#!/bin/bash
set -e

YEAR="${YEAR:-2022}"
SCHEME="${SCHEME:-full}"
ROOT="${ROOT:-${HOME}/.local/texlive}"

usage() {
    this="${1}"
    cat <<EOF
${this}: install portable texlive

Usage: ${this} [-t texlive_year] [-s scheme]
  -t texlive year, default is ${YEAR}
  -s texlive scheme, default is ${SCHEME}
  -d installation directory, default is ${ROOT}
EOF
    exit 2
}

download_texlive() {
    COUNTRY="$(curl -sSLk4 --max-time 2 https://ipinfo.io/country)"
    if [ "${COUNTRY}" = "CN" ]; then
        echo "Use GitHub proxy to download texlive."
        PROXY_URL="https://ghproxy.com/"
    else
        PROXY_URL=""
    fi
    mkdir -p "${DEST}"
    echo "Downloading from ${PROXY_URL}https://github.com/zydou/texlive-portable/releases/download/texlive-${YEAR}/portable-texlive-${YEAR}-${SCHEME}-$(uname -s)-$(uname -m).${SUFFIX} ..."
    echo "To ${DEST}/portable-texlive-${YEAR}-${SCHEME}-$(uname -s)-$(uname -m).${SUFFIX}"
    curl -Lfk -o "${DEST}/portable-texlive-${YEAR}-${SCHEME}-$(uname -s)-$(uname -m).${SUFFIX}" "${PROXY_URL}https://github.com/zydou/texlive-portable/releases/download/texlive-${YEAR}/portable-texlive-${YEAR}-${SCHEME}-$(uname -s)-$(uname -m).${SUFFIX}"
    curl -Lfk -o "${DEST}/portable-texlive-${YEAR}-${SCHEME}-$(uname -s)-$(uname -m).${SUFFIX}.sha256sum" "${PROXY_URL}https://github.com/zydou/texlive-portable/releases/download/texlive-${YEAR}/portable-texlive-${YEAR}-${SCHEME}-$(uname -s)-$(uname -m).${SUFFIX}.sha256sum"
    cd "${DEST}" || exit
    shasum -a 256 -c "${DEST}/portable-texlive-${YEAR}-${SCHEME}-$(uname -s)-$(uname -m).${SUFFIX}.sha256sum"

    echo "Extracting ${DEST}/portable-texlive-${YEAR}-${SCHEME}-$(uname -s)-$(uname -m).${SUFFIX} ..."
    if [ "${SUFFIX}" = "tar.xz" ]; then
        tar --no-xattrs -xJf "${DEST}/portable-texlive-${YEAR}-${SCHEME}-$(uname -s)-$(uname -m).${SUFFIX}" -C "${DEST}" --strip-components=1
    elif [ "${SUFFIX}" = "tar.gz" ]; then
        tar --no-xattrs -xzf "${DEST}/portable-texlive-${YEAR}-${SCHEME}-$(uname -s)-$(uname -m).${SUFFIX}" -C "${DEST}" --strip-components=1
    fi
    /bin/rm -f "${DEST}/portable-texlive-${YEAR}-${SCHEME}-$(uname -s)-$(uname -m).${SUFFIX}"
    /bin/rm -f "${DEST}/portable-texlive-${YEAR}-${SCHEME}-$(uname -s)-$(uname -m).${SUFFIX}.sha256sum"
}

parse_args() {
    while getopts "s:d:h?t:" arg; do
        case "${arg}" in
        s) SCHEME="${OPTARG}" ;;
        d) ROOT="${OPTARG}" ;;
        h | \?) usage "${0}" ;;
        t) YEAR="${OPTARG}" ;;
        *) return 1 ;;
        esac
    done
}

main() {
    parse_args "${@}"
    shift "$((OPTIND - 1))"
    DEST="${ROOT}/${YEAR}"
    if [ -d "${DEST}" ]; then
        echo "Found texlive at ${DEST}, please remove it first."
        exit 1
    fi

    # check if xz is installed
    if command -v xz > /dev/null; then
        SUFFIX="tar.xz"
    elif command -v gzip > /dev/null; then
        SUFFIX="tar.gz"
    else
        echo "xz or gzip is required to extract the texlive archive."
        exit 1
    fi

    download_texlive

    #　replace placeholder
    [ -f "${DEST}/tlpkg/texlive.profile" ] && perl -i -pe"s#TEXDIR_ROOT#${DEST}#g" "${DEST}/tlpkg/texlive.profile"
    [ -f "${DEST}/texmf-var/fonts/conf/texlive-fontconfig.conf" ] && perl -i -pe"s#TEXDIR_ROOT#${DEST}#g" "${DEST}/texmf-var/fonts/conf/texlive-fontconfig.conf"

    # Run post installation code
    if [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" = "linux" && "$(uname -m)" = "x86_64" ]]; then
        PLATFORM="x86_64-linux"
    elif [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" = "linux" && "$(uname -m)" = "aarch64" ]]; then
        PLATFORM="aarch64-linux"
    elif [[ "$(uname -s | tr '[:upper:]' '[:lower:]')" = "darwin" ]]; then
        # on macOS, texlive 2018 and 2019 only has x86_64 arch.
        if [[ "${YEAR}" = "2018" || "${YEAR}" = "2019" ]]; then
            PLATFORM="x86_64-darwin"
        else
            PLATFORM="universal-darwin"
        fi
    else
        echo "Unsupported platform: $(uname -s) $(uname -m)"
        exit 1
    fi


    echo "Running ${DEST}/bin/${PLATFORM}/fmtutil-sys --no-error-if-no-engine=luajithbtex,luajittex,mfluajit --no-strict --all"
    "${DEST}/bin/${PLATFORM}/fmtutil-sys" --no-error-if-no-engine=luajithbtex,luajittex,mfluajit --no-strict --all > /dev/null 2>&1 || true

    echo "Running ${DEST}/bin/${PLATFORM}/tlmgr generate --rebuild-sys language"
    "${DEST}/bin/${PLATFORM}/tlmgr" generate --rebuild-sys language

    echo "Running ${DEST}/bin/${PLATFORM}/updmap-sys --force"
    "${DEST}/bin/${PLATFORM}/updmap-sys" --force

    echo "Deleting log files ..."
    find "${DEST}/texmf-var/web2c" -type f -name "*.log" -exec /bin/rm -v {} \;

    echo "Symlink ${DEST} -> ${ROOT}/current"
    [ -e "${ROOT}/current" ] && /bin/rm -f "${ROOT}/current"
    ln -sf "${DEST}" "${ROOT}/current"
    echo "texlive-${YEAR}-${SCHEME} Done!"
}

main "${@}"
