#!/usr/bin/env bash
# shellcheck disable=SC2268
#
# --- Script Version ---
# Name    : alpine_getting_start.sh
# Version : 0b90cc9 (1 commit after this ref)
# Author  : IceCodeNew
# Date    : Fri Jan 13th, 2023
# Download: https://raw.githubusercontents.com/IceCodeNew/go-collection/master/alpine_getting_start.sh
readonly local_script_version='0b90cc9'

# Shell functions are only known to the shell. External commands like `find`, `xargs`, `su` and `sudo` do not recognize shell functions.
# Instead, the function contents can be executed in a shell, either through sh -c or by creating a separate shell script as an executable file.
## Refer: https://github.com/koalaman/shellcheck/wiki/SC2033

cd() {
  command cd "$@" || exit 1
}
cp() {
  sudo "$(type -P cp)" -f "$@"
}
mv() {
  sudo "$(type -P mv)" -f "$@"
}
rm() {
  sudo "$(type -P rm)" -f "$@"
}
install() {
  sudo "$(type -P install)" "$@"
}

curl_path="$(type -P curl)"
# geo_country="$(curl 'https://api.myip.la/en?json' | jq . | grep country_code | cut -d'"' -f4)"
# [[ x"$geo_country" = x'CN' ]] && curl_path="$(type -P curl) --retry-connrefused"
myip_ipip_response="$(curl -sS 'http://myip.ipip.net' | grep -E '来自于：中国' | grep -vE '香港|澳门|台湾')"
echo "$myip_ipip_response" | grep -qE '来自于：中国' && readonly geoip_is_cn='yes' && curl_path="$(type -P curl) --retry-connrefused"
curl() {
  # It is OK for the system which has cURL's version greater than `7.76.0` to use `--fail-with-body` instead of `-f`.
  ## Refer to: https://superuser.com/a/1626376
  $curl_path -LRq --retry 5 --retry-delay 10 --retry-max-time 60 --fail-with-body "$@"
}
curl_to_dest() {
  if [[ $# -eq 2 ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    if curl -OJ "$1"; then
      find . -maxdepth 1 -type f -print0 | xargs -0 -I {} -r -s 2000 sudo "$(type -P install)" -pvD "{}" "$2"
    fi
    popd || exit 1
    rm -rf "$tmp_dir"
  fi
}
git_clone() {
  if [[ -z "$GIT_PROXY" ]]; then
    $(type -P git) clone -v -j "$(nproc)" --no-tags --shallow-submodules --recurse-submodules --depth 1 --single-branch "$@"
  else
    $(type -P git) -c "$GIT_PROXY" clone -v -j "$(nproc)" --no-tags --shallow-submodules --recurse-submodules --depth 1 --single-branch "$@"
  fi
}

################

self_update() {
  remote_script_version="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/IceCodeNew/go-collection/commits?per_page=2&path=alpine_getting_start.sh' |
      jq .[1] | grep -Fm1 'sha' | cut -d'"' -f4 | head -c7)"
  readonly remote_script_version
  # Should any error occured during quering `api.github.com`, do not execute this script.
  [[ x"${geoip_is_cn:0:1}" = x'y' ]] &&
    git config --global url."https://ghproxy.com/https://github.com".insteadOf https://github.com
  [[ x"$local_script_version" = x"$remote_script_version" ]] &&
    install_binaries
  sleep $(( ( RANDOM % 10 ) + 1 ))s && curl -i "https://purge.jsdelivr.net/gh/IceCodeNew/go-collection@master/alpine_getting_start.sh"
  curl -o "$HOME/alpine_getting_start.sh.tmp" -- 'https://raw.githubusercontents.com/IceCodeNew/go-collection/master/alpine_getting_start.sh' &&
    dos2unix "$HOME/alpine_getting_start.sh.tmp" && mv -f "$HOME/alpine_getting_start.sh.tmp" "$HOME/alpine_getting_start.sh" &&
    echo 'Upgrade successful!' && exit 1
}

install_binaries() {
  sudo mkdir -p /usr/local/bin /usr/local/sbin

  ########

  tmp_dir=$(mktemp -d) && pushd "$tmp_dir" || exit 1
  download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/aristocratos/btop/releases/latest' |
      grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'linux-musl.tbz$' | grep -iE 'x86_64')" && \
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
      sed -E 's!(github.com/.+/download/)!ghproxy.com/https://\1!g')
  curl -- "$download_url" | bsdtar -xf- --strip-components 2 && \
    sudo make install PREFIX=/usr && \
    sudo make setuid PREFIX=/usr && \
    sudo strip /usr/bin/btop && \
  popd || exit 1
  rm -rf "$tmp_dir"
  dirs -c

  ########

  download_url="https://github.com/haampie/libtree/releases/latest/download/libtree_x86_64" && \
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
      sed -E 's!(github.com/.+/download/)!ghproxy.com/https://\1!g')
  curl_to_dest "$download_url" '/usr/bin/libtree'

  ########

  if [[ x"$(echo "${install_ripgrep:=yes}" | cut -c1)" = x'y' ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/BurntSushi/ripgrep/releases/latest' |
        grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'ripgrep.*x86_64.*linux-musl.tar.gz$')"
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
      sed -E 's!(github.com/.+/download/)!ghproxy.com/https://\1!g')
    curl "$download_url" | bsdtar -xf- --strip-components 1
    cp complete/rg.bash /usr/share/bash-completion/completions/
    # mkdir /usr/share/doc/ripgrep/
    # cp doc/* /usr/share/doc/ripgrep/
    popd || exit 1
    rm -rf "$tmp_dir"
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/rust-collection/latest-release/assets/ripgrep" '/usr/bin/rg'
  fi

  if [[ x"$(echo "${install_bat:=yes}" | cut -c1)" = x'y' ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/rust-collection/latest-release/assets/bat" '/usr/bin/bat'
    git_clone https://github.com/eth-p/bat-extras.git &&
      pushd bat-extras || exit 1
      chmod +x build.sh &&
      ./build.sh --install --no-manuals
      popd || exit 1
    popd || exit 1
    rm -rf "$tmp_dir"
  fi

  if [[ x"$(echo "${install_fd:=yes}" | cut -c1)" = x'y' ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/sharkdp/fd/releases/latest' |
        grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'fd.*x86_64.*linux-musl.tar.gz$')"
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
      sed -E 's!(github.com/.+/download/)!ghproxy.com/https://\1!g')
    curl "$download_url" | bsdtar -xf- --strip-components 1
    cp autocomplete/fd.bash-completion /usr/share/bash-completion/completions/
    popd || exit 1
    rm -rf "$tmp_dir"
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/rust-collection/latest-release/assets/fd" '/usr/bin/fd'
  fi

  if [[ x"$(echo "${install_hexyl:=yes}" | cut -c1)" = x'y' ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/sharkdp/hexyl/releases/latest' |
        grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'hexyl.*x86_64.*linux-musl.tar.gz$')"
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
      sed -E 's!(github.com/.+/download/)!ghproxy.com/https://\1!g')
    curl "$download_url" | bsdtar -xf- --strip-components 1
    popd || exit 1
    rm -rf "$tmp_dir"
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/rust-collection/latest-release/assets/hexyl" '/usr/bin/hexyl'
  fi

  if [[ x"$(echo "${install_hugo_extended:=no}" | cut -c1)" = x'y' ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/gohugoio/hugo/releases/latest' |
        grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'hugo_extended.*Linux-64bit.tar.gz$')"
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
      sed -E 's!(github.com/.+/download/)!ghproxy.com/https://\1!g')
    curl "$download_url" | bsdtar -xf-
    # Need glibc runtime.
    install -pvD './hugo' '/usr/local/bin/hugo'
    popd || exit 1
    rm -rf "$tmp_dir"
  fi

  tmp_dir=$(mktemp -d)
  pushd "$tmp_dir" || exit 1
  download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/tstack/lnav/releases/latest' |
      grep 'browser_download_url' | cut -d'"' -f4 | grep -E '[0-9]\/lnav-.+?-x86_64-linux-musl.zip$')"
  [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
    sed -E 's!(github.com/.+/download/)!ghproxy.com/https://\1!g')
  if curl "$download_url" | bsdtar -xf- --strip-components 1; then
    install -pvD './lnav' '/usr/local/bin/lnav'
  fi
  popd || exit 1
  rm -rf "$tmp_dir"
  dirs -c

  ################

  curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/go-collection/latest-release/assets/croc" '/usr/local/bin/croc'
  curl_to_dest 'https://raw.githubusercontents.com/schollz/croc/master/src/install/bash_autocomplete' '/usr/share/bash-completion/completions/croc' &&
    sudo chmod -x '/usr/share/bash-completion/completions/croc'

  if [[ x"$(echo "${install_shfmt:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/go-collection/latest-release/assets/shfmt" '/usr/local/bin/shfmt'
  else
    rm '/usr/local/bin/shfmt'
  fi

  if [[ x"$(echo "${install_sd:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/rust-collection/latest-release/assets/sd" '/usr/local/bin/sd'
  else
    rm '/usr/local/bin/sd'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_github_release:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/go-collection/latest-release/assets/github-release" '/usr/local/bin/github-release'
  else
    rm '/usr/local/bin/github-release'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_go_mmproxy:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/go-collection/latest-release/assets/go-mmproxy" '/usr/local/bin/go-mmproxy'
  else
    rm '/usr/local/bin/go-mmproxy'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_nfpm:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/go-collection/latest-release/assets/nfpm" '/usr/local/bin/nfpm'
  else
    rm '/usr/local/bin/nfpm'
  fi

  rm -f '/usr/local/bin/mosdns'

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_ss_rust:=yes}" | cut -c1)" = x'y' ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    if ldd /bin/ls | grep -qF 'musl'; then
      export ss_rust_file_name='4limit-mem-server-only-ss-rust-linux-gnu-x64.tar.gz'
    else
      export ss_rust_file_name='ss-rust-linux-gnu-x64.tar.xz'
    fi
    if curl "https://raw.githubusercontents.com/IceCodeNew/rust-collection/latest-release/assets/${ss_rust_file_name}" | bsdtar -xf-; then
      if [[ x"$ss_rust_file_name" = x'ss-rust-linux-gnu-x64.tar.xz' ]]; then
        install './ssservice' '/usr/local/bin/ssservice' &&
        sudo ln -fs '/usr/local/bin/ssservice' '/usr/local/bin/sslocal' &&
        sudo ln -fs '/usr/local/bin/ssservice' '/usr/local/bin/ssmanager' &&
        sudo ln -fs '/usr/local/bin/ssservice' '/usr/local/bin/ssserver' &&
        install -pvD './ssurl' '/usr/local/bin/ssurl'
      else
        install -pvD './ssmanager' '/usr/local/bin/ssmanager'
        install -pvD './ssserver' '/usr/local/bin/ssserver'
        install -pvD './ssurl' '/usr/local/bin/ssurl'
      fi
    fi
    popd || exit 1
    rm -rf "$tmp_dir"
  else
    rm '/usr/local/bin/sslocal' '/usr/local/bin/ssmanager' '/usr/local/bin/ssserver' '/usr/local/bin/ssurl'
  fi

  if [[ x"$(echo "${install_go_shadowsocks:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/go-collection/latest-release/assets/shadowsocks-go" '/usr/local/bin/shadowsocks-go'
  else
    rm '/usr/local/bin/shadowsocks-go'
  fi
  rm '/usr/local/bin/go-shadowsocks2' '/usr/local/bin/v2ray-plugin'

  if [[ x"$(echo "${install_naiveproxy:=yes}" | cut -c1)" = x'y' ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/klzgrad/naiveproxy/releases/latest' |
        grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'naiveproxy-.+-linux-x64.tar.xz$')"
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
      sed -E 's!(github.com/.+/download/)!ghproxy.com/https://\1!g')
    curl "$download_url" | bsdtar -xf- --strip-components 1
    # Need glibc runtime.
    sudo strip './naive' -o '/usr/local/bin/naive'
    popd || exit 1
    rm -rf "$tmp_dir"
  else
    rm '/usr/local/bin/naive'
  fi

  rm '/usr/local/bin/overmind'

  rm -f '/usr/local/bin/frpc' '/usr/local/bin/frps'

  # # shellcheck disable=SC2154
  # if [[ x"$(echo "${install_chisel:=no}" | cut -c1)" = x'y' ]]; then
  #   curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/go-collection/latest-release/assets/chisel" '/usr/local/bin/chisel'
  # else
  rm '/usr/local/bin/chisel'
  # fi

  rm '/usr/local/bin/got'
  if [[ x"$(echo "${install_pget:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/go-collection/latest-release/assets/pget" '/usr/local/bin/pget'
  else
    rm '/usr/local/bin/pget'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_dive:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/go-collection/latest-release/assets/dive" '/usr/local/bin/dive'
  else
    rm '/usr/local/bin/dive'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_duf:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/go-collection/latest-release/assets/duf" '/usr/local/bin/duf'
  else
    rm '/usr/local/bin/duf'
  fi

  rm -f '/usr/local/bin/dnslookup'

  ################

  tmp_dir=$(mktemp -d) && pushd "$tmp_dir" || exit 1
  q_latest_tag_name=$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    "${GITHUB_API_BASEURL:=https://api.github.com}/repos/natesales/q/releases/latest" | \
    grep -F 'tag_name' | cut -d'"' -f4) \
    && _filename="q_${q_latest_tag_name#v}_linux_amd64.tar.gz" \
    && download_url="https://github.com/natesales/q/releases/download/${q_latest_tag_name}/${_filename}" \
    && [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(sed -E 's!(github.com/.+/download/)!ghproxy.com/https://\1!g' <<< "$download_url") \
    && if curl "$download_url" | \
      bsdtar -xf- -- ./q; then
      install -pvD './q' '/usr/local/bin/'
    fi
  popd || exit 1
  rm -rf "$tmp_dir"
  dirs -c

  rm /usr/local/bin/dog \
    /usr/local/completions/dog.bash \
    /usr/local/completions/dog.fish \
    /usr/local/completions/dog.zsh \
    /usr/local/man/dog.1 \

  ################

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_qft:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/rust-collection/latest-release/assets/qft" '/usr/local/bin/qft'
  else
    rm '/usr/local/bin/qft'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_websocat:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/rust-collection/latest-release/assets/websocat" '/usr/local/bin/websocat'
  else
    rm '/usr/local/bin/websocat'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_just:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/rust-collection/latest-release/assets/just" '/usr/local/bin/just'
  else
    rm '/usr/local/bin/just'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_desed:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/rust-collection/latest-release/assets/desed" '/usr/local/bin/desed'
  else
    rm '/usr/local/bin/desed'
  fi

  rm '/usr/local/bin/fnm'

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_rsign:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/rust-collection/latest-release/assets/rsign" '/usr/local/bin/rsign'
  else
    rm '/usr/local/bin/rsign'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_b3sum:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/rust-collection/latest-release/assets/b3sum" '/usr/local/bin/b3sum'
  else
    rm '/usr/local/bin/b3sum'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_nali:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/go-collection/latest-release/assets/nali" '/usr/local/bin/nali'
  else
    rm '/usr/local/bin/nali'
  fi

  [[ -n "$(type -P apk)" ]] && curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/go-collection/latest-release/assets/apk-file" '/usr/local/bin/apk-file'

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_age:=yes}" | cut -c1)" = x'y' ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    if curl "https://raw.githubusercontents.com/IceCodeNew/go-collection/latest-release/assets/age-linux-amd64.tar.gz" | bsdtar -xf-; then
      install -pvD './age' '/usr/local/bin/age'
      install -pvD './age-keygen' '/usr/local/bin/age-keygen'
    fi
    popd || exit 1
    rm -rf "$tmp_dir"
  else
    rm '/usr/local/bin/age' '/usr/local/bin/age-keygen'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_mtg:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/go-collection/latest-release/assets/mtg" '/usr/local/bin/mtg'
  else
    rm '/usr/local/bin/mtg'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_wuzz:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/go-collection/latest-release/assets/wuzz" '/usr/local/bin/wuzz'
  else
    rm '/usr/local/bin/wuzz'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_httpstat:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/go-collection/latest-release/assets/httpstat" '/usr/local/bin/httpstat'
  else
    rm '/usr/local/bin/httpstat'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_wgcf:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/go-collection/latest-release/assets/wgcf" '/usr/local/bin/wgcf'
  else
    rm '/usr/local/bin/wgcf'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_mmp_go:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/go-collection/latest-release/assets/mmp-go" '/usr/local/bin/mmp-go'
  else
    rm '/usr/local/bin/mmp-go'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_cloudflarest:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/go-collection/latest-release/assets/CloudflareST" '/usr/local/bin/CloudflareST'
  else
    rm '/usr/local/bin/CloudflareST'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_netflix_verify:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/go-collection/latest-release/assets/nf" '/usr/local/bin/nf'
  else
    rm '/usr/local/bin/nf'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_piknik:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/go-collection/latest-release/assets/piknik" '/usr/local/bin/piknik'
  else
    rm '/usr/local/bin/piknik'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_boringtun:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/rust-collection/latest-release/assets/boringtun-linux-musl-x64" '/usr/local/bin/boringtun'
  else
    rm '/usr/local/bin/boringtun'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_cfnts:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://raw.githubusercontents.com/IceCodeNew/rust-collection/latest-release/assets/cfnts" '/usr/local/bin/cfnts'
  else
    rm '/usr/local/bin/cfnts'
  fi

  ################

  apk add haproxy-openrc
  rc-update add haproxy

  download_url="https://github.com/IceCodeNew/haproxy_static/releases/latest/download/haproxy" && \
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
      sed -E 's!(github.com/.+/download/)!ghproxy.com/https://\1!g')
  curl_to_dest "$download_url" '/usr/local/sbin/haproxy' &&
      rm -f /usr/bin/haproxy &&
      sudo ln -s /usr/local/sbin/haproxy /usr/bin/

  tmp_dir=$(mktemp -d)
  pushd "$tmp_dir" || exit 1
  if [[ ! -f /etc/caddy/Caddyfile ]]; then
    apk add caddy caddy-openrc
    rc-update add caddy
    if [[ x"$(echo "${donot_need_caddy_autorun:=no}" | cut -c1)" = x'y' ]]; then
      rc-update del caddy
    else
      sudo sed -i -E 's/^:80/:19600/' /etc/caddy/Caddyfile
    fi
  fi

  rm -f '/usr/sbin/caddy' '/usr/local/bin/caddy' '/usr/local/bin/xcaddy'
  curl -L "https://raw.githubusercontents.com/IceCodeNew/go-collection/latest-release/assets/caddy.zst" |
    unzstd -q --no-progress -o './caddy' && install -pvD './caddy' '/usr/local/sbin/caddy' &&
    rm -f '/usr/bin/caddy' && sudo ln -s /usr/local/sbin/caddy /usr/bin/
  popd || exit 1
  rm -rf "$tmp_dir"

  rm -f '/usr/share/caddy/index.html' &&
    sudo mkdir -p '/usr/share/caddy' &&
    sudo "$(type -P curl)" -o '/usr/share/caddy/index.html' -- 'https://raw.githubusercontents.com/IceCodeNew/go-collection/master/usr/share/caddy/index.html'

  ################

  checksec --dir=/usr/local/bin
  checksec --listfile=<(echo -e '/usr/bin/bat\n/usr/bin/fd\n/usr/bin/hexyl\n/usr/local/sbin/haproxy\n/usr/local/sbin/caddy')

  git config --global --unset url.https://ghproxy.com/https://github.com.insteadof
  git config --global --list
  exit 0
}

git config --global --unset url.https://hub.fastgit.xyz/https://github.com.insteadof
self_update
