#!/bin/bash

YEAR="${YEAR:-2022}"
SCHEME="${SCHEME:-full}"
ROOT="${HOME}/.local/texlive-src"
DEST="${HOME}/.local/texlive"
# Download texlive src
mkdir -p "${ROOT}"

if [[ ! -f "${ROOT}/install-tl" ]]; then
    echo -e "\033[1;92mDownloading texlive_part00 ...\033[0m"
    curl -qLf -o "${ROOT}/texlive_part00" "https://github.com/zydou/texlive/releases/download/texlive-${YEAR}/texlive_${YEAR}_part00"

    echo -e "\033[1;92mDownloading texlive_part01 ...\033[0m"
    curl -qLf -o "${ROOT}/texlive_part01" "https://github.com/zydou/texlive/releases/download/texlive-${YEAR}/texlive_${YEAR}_part01"

    echo -e "\033[1;92mDownloading texlive_part02 ...\033[0m"
    curl -qLf -o "${ROOT}/texlive_part02" "https://github.com/zydou/texlive/releases/download/texlive-${YEAR}/texlive_${YEAR}_part02"

    echo -e "\033[1;92mDownloading texlive_part03 ...\033[0m"
    curl -qLf -o "${ROOT}/texlive_part03" "https://github.com/zydou/texlive/releases/download/texlive-${YEAR}/texlive_${YEAR}_part03"

    echo -e "\033[1;92mConcatenating to archive.tar ...\033[0m"
    /bin/cat "${ROOT}"/texlive_part* > "${ROOT}"/archive.tar
    /bin/rm -f "${ROOT}"/texlive_part*

    echo -e "\033[1;92mExtracting archive.tar ...\033[0m"
    tar -xf "${ROOT}"/archive.tar -C "${ROOT}" --strip-components=1
    /bin/rm -f "${ROOT}"/archive.tar
fi

# Install texlive
if [[ "${SCHEME}" = "large" ]]; then
    SCHEME="tetex"
fi

/bin/cat <<EOF > "${ROOT}/texlive.profile"
selected_scheme scheme-$SCHEME
TEXDIR $DEST
TEXMFLOCAL $DEST/texmf-local
TEXMFSYSVAR $DEST/texmf-var
TEXMFSYSCONFIG $DEST/texmf-config
TEXMFHOME \$TEXMFLOCAL
TEXMFVAR \$TEXMFSYSVAR
TEXMFCONFIG \$TEXMFSYSCONFIG
instopt_adjustpath 0
instopt_adjustrepo 0
instopt_letter 0
instopt_portable 1
instopt_write18_restricted 1
tlpdbopt_autobackup 0
tlpdbopt_create_formats 0
tlpdbopt_desktop_integration 0
tlpdbopt_file_assocs 0
tlpdbopt_generate_updmap 0
tlpdbopt_install_docfiles 0
tlpdbopt_install_srcfiles 0
tlpdbopt_post_code 1
tlpdbopt_w32_multi_user 0
EOF

/bin/cat "${ROOT}/texlive.profile"

if [[ ! -d "${DEST}" ]]; then
    echo -e "\033[1;92mInstalling texlive-${YEAR} ...\033[0m"
    TEXLIVE_INSTALL_ENV_NOCHECK=1 \
    TEXLIVE_INSTALL_NO_CONTEXT_CACHE=1 \
    TEXLIVE_INSTALL_NO_DISKCHECK=1 \
    TEXLIVE_INSTALL_NO_RESUME=1 \
    "${ROOT}/install-tl" --profile "${ROOT}"/texlive.profile --repository "${ROOT}" -logfile "${ROOT}"/install-tl.log -no-verify-downloads
    echo -e "\033[1;92mFinished texlive-${YEAR} installation\033[0m"
fi

cd "${DEST}" || exit

find texmf-var/web2c -type f -name "*.log" -exec /bin/rm -v {} \;

# Replace ${DEST} with TEXDIR_ROOT
[[ -f "tlpkg/texlive.profile" ]] && perl -i -pe"s#${DEST}#TEXDIR_ROOT#g" tlpkg/texlive.profile
[[ -f "texmf-var/fonts/conf/texlive-fontconfig.conf" ]] && perl -i -pe"s#${DEST}#TEXDIR_ROOT#g" texmf-var/fonts/conf/texlive-fontconfig.conf

# Replace ${ROOT} with TEXDIR_ROOT
[[ -f "texmf-dist/web2c/fmtutil.cnf" ]] && perl -i -pe"s#${ROOT}#TEXDIR_ROOT#g" texmf-dist/web2c/fmtutil.cnf
[[ -f "texmf-dist/web2c/updmap.cfg" ]] && perl -i -pe"s#${ROOT}#TEXDIR_ROOT#g" texmf-dist/web2c/updmap.cfg
[[ -f "tlpkg/texlive.tlpdb" ]] && perl -i -pe"s#${ROOT}#TEXDIR_ROOT#g" tlpkg/texlive.tlpdb
[[ -f "texmf-var/tex/generic/config/language.def" ]] && perl -i -pe"s#${ROOT}#TEXDIR_ROOT#g" texmf-var/tex/generic/config/language.def
[[ -f "texmf-var/tex/generic/config/language.dat" ]] && perl -i -pe"s#${ROOT}#TEXDIR_ROOT#g" texmf-var/tex/generic/config/language.dat
[[ -f "texmf-var/tex/generic/config/language.dat.lua" ]] && perl -i -pe"s#${ROOT}#TEXDIR_ROOT#g" texmf-var/tex/generic/config/language.dat.lua


# Download ripgrep
if [[ ! -x "${HOME}/.local/bin/rg" ]]; then

    if [[ "$(uname -s)" == "Linux" && "$(uname -m)" == "x86_64" ]]; then
        VARIANT="x86_64-unknown-linux-musl"
    elif [[ "$(uname -s)" == "Linux" && "$(uname -m)" == "aarch64" ]]; then
        VARIANT="aarch64-unknown-linux-gnu"
    elif [[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "x86_64" ]]; then
        VARIANT="x86_64-apple-darwin"
    elif [[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]]; then
        VARIANT="aarch64-apple-darwin"
    else
        echo "Unsupported ripgrep for: $(uname -s) $(uname -m)"
        exit 1
    fi
    echo -e "\033[1;92mDownloading ripgrep from https://github.com/zydou/ripgrep/releases/download/13.0.0/ripgrep-13.0.0-${VARIANT}.tar.gz\033[0m"
    mkdir -p "${HOME}/.local/bin"
    curl -qLf -o "${HOME}/.local/bin/rg.tar.gz" "https://github.com/zydou/ripgrep/releases/download/13.0.0/ripgrep-13.0.0-${VARIANT}.tar.gz"
    tar -xzf "${HOME}/.local/bin/rg.tar.gz" -C "${HOME}/.local/bin"
    /bin/rm -f "${HOME}/.local/bin/rg.tar.gz"
fi
"${HOME}/.local/bin/rg" -uu -l -0 "${DEST}" texmf-var | xargs -0 /bin/rm -f -v
/bin/rm -rf "${ROOT}"
echo -e "\033[1;92mtexlive-${YEAR}-${SCHEME} Done!\033[0m"
