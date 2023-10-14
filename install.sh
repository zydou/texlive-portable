#!/bin/sh
set -e

YEAR="${YEAR:-2022}"
SCHEME="${SCHEME:-basic}"
DEST="${DEST:-${HOME}/.local/texlive}"

usage() {
    this="${1}"
    cat <<EOF
${this}: install portable texlive

Usage: ${this} [-t texlive_year] [-s scheme]
  -t texlive year, default is ${YEAR}.
  -s texlive scheme, default is ${SCHEME}.
  -d installation directory, default is ${DEST}.
EOF
    exit 2
}

download_texlive() {
    COUNTRY="$(curl -sSLkq4 --max-time 2 --proxy '' https://ipinfo.io/country)"
    if [ "${COUNTRY}" = "CN" ]; then
        echo "Use GitHub proxy to download texlive."
        PROXY_URL="https://ghproxy.com/"
    else
        PROXY_URL=""
    fi
    mkdir -p "${DEST}"
    echo "Downloading from ${PROXY_URL}https://github.com/zydou/texlive-portable/releases/download/texlive-${YEAR}/portable-texlive-${YEAR}-${SCHEME}-$(uname -s)-$(uname -m).${SUFFIX} ..."
    echo "To ${DEST}/texlive-${YEAR}.${SUFFIX}"
    curl -Lfk -o "${DEST}/texlive-${YEAR}.${SUFFIX}" "${PROXY_URL}https://github.com/zydou/texlive-portable/releases/download/texlive-${YEAR}/portable-texlive-${YEAR}-${SCHEME}-$(uname -s)-$(uname -m).${SUFFIX}"

    echo "Extracting ${DEST}/texlive-${YEAR}.${SUFFIX} ..."
    if [ "${SUFFIX}" = "tar.xz" ]; then
        tar -xJf "${DEST}/texlive-${YEAR}.${SUFFIX}" -C "${DEST}" --strip-components=1
    elif [ "${SUFFIX}" = "tar.gz" ]; then
        tar -xzf "${DEST}/texlive-${YEAR}.${SUFFIX}" -C "${DEST}" --strip-components=1
    fi
    /bin/rm -f "${DEST}/texlive-${YEAR}.${SUFFIX}"
}

parse_args() {
    while getopts "s:d:h?t:" arg; do
        case "${arg}" in
        s) SCHEME="${OPTARG}" ;;
        d) DEST="${OPTARG}" ;;
        h | \?) usage "${0}" ;;
        t) YEAR="${OPTARG}" ;;
        *) return 1 ;;
        esac
    done
}

main() {
    parse_args "${@}"
    shift "$((OPTIND - 1))"

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
    if [ "$(uname -s | tr '[:upper:]' '[:lower:]')" = "darwin" ]; then
        PLATFORM="universal-darwin"
    elif [ "$(uname -m)" = "x86_64" ]; then
        PLATFORM="x86_64-linux"
    elif [ "$(uname -m)" = "aarch64" ]; then
        PLATFORM="aarch64-linux"
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

    echo "texlive-${YEAR}-${SCHEME} Done!"
}

main "${@}"
