#!/usr/bin/env bash
# shellcheck disable=SC2268
#
# --- Script Version ---
# Name    : alpine_getting_start.sh
# Version : 07103cf (1 commit after this ref)
# Author  : IceCodeNew
# Date    : Fri Jan 13th, 2023
# Download: https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@master/alpine_getting_start.sh
readonly local_script_version='07103cf'

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
    /bin/rm -rf "$tmp_dir"
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
    sed -i -E -e 's!github.com/(.+/download/)!github.com.mirror.icecode.xyz/\1!g' "$HOME/alpine_getting_start.sh" &&
    git config --global url."https://ghproxy.com/https://github.com".insteadOf https://github.com
  [[ x"$local_script_version" = x"$remote_script_version" ]] &&
    install_binaries
  sleep $(( ( RANDOM % 10 ) + 1 ))s && curl -i "https://purge.jsdelivr.net/gh/IceCodeNew/go-collection@master/alpine_getting_start.sh"
  if [[ x"${geoip_is_cn:0:1}" = x'y' ]]; then
    curl -o "$HOME/alpine_getting_start.sh.tmp" -- 'https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@master/alpine_getting_start.sh'
    sed -i -E -e 's!github.com/(.+/download/)!github.com.mirror.icecode.xyz/\1!g' "$HOME/alpine_getting_start.sh.tmp"
  else
    curl -o "$HOME/alpine_getting_start.sh.tmp" -- 'https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@master/alpine_getting_start.sh'
  fi
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
      sed -E 's!github.com/(.+/download/)!github.com.mirror.icecode.xyz/\1!g')
  curl -- "$download_url" | bsdtar -xf- --strip-components 2 && \
    sudo make install PREFIX=/usr && \
    sudo make setuid PREFIX=/usr && \
    sudo strip /usr/bin/btop && \
  popd || exit 1
  /bin/rm -rf "$tmp_dir"
  dirs -c

   ########

   ### Even with the gcompat, pre-built mold still won't work on alpine.
   # mold_latest_tag_name="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
   # 'https://api.github.com/repos/rui314/mold/releases/latest' |
   # grep -F 'tag_name' | cut -d'"' -f4)" && \
   # export mold_latest_tag_name && \
   # curl -fsSL "https://github.com/rui314/mold/releases/download/${mold_latest_tag_name}/mold-${mold_latest_tag_name#v}-x86_64-linux. tar.gz" | sudo bsdtar -xf- --strip-components 1 -C /usr

  ########

  curl_to_dest "https://github.com/haampie/libtree/releases/latest/download/libtree_x86_64" '/usr/bin/libtree'

  ########

  if [[ x"$(echo "${install_ripgrep:=yes}" | cut -c1)" = x'y' ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/BurntSushi/ripgrep/releases/latest' |
        grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'ripgrep.*x86_64.*linux-musl.tar.gz$')"
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
      sed -E 's!github.com/(.+/download/)!github.com.mirror.icecode.xyz/\1!g')
    curl "$download_url" | bsdtar -xf- --strip-components 1
    cp complete/rg.bash /usr/share/bash-completion/completions/
    # mkdir /usr/share/doc/ripgrep/
    # cp doc/* /usr/share/doc/ripgrep/
    popd || exit 1
    /bin/rm -rf "$tmp_dir"
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/ripgrep" '/usr/bin/rg'
  fi

  if [[ x"$(echo "${install_bat:=yes}" | cut -c1)" = x'y' ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/bat" '/usr/bin/bat'
    git_clone https://github.com/eth-p/bat-extras.git &&
      pushd bat-extras || exit 1
      chmod +x build.sh &&
      ./build.sh --install --no-manuals
      popd || exit 1
    popd || exit 1
    /bin/rm -rf "$tmp_dir"
  fi

  if [[ x"$(echo "${install_fd:=yes}" | cut -c1)" = x'y' ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/sharkdp/fd/releases/latest' |
        grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'fd.*x86_64.*linux-musl.tar.gz$')"
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
      sed -E 's!github.com/(.+/download/)!github.com.mirror.icecode.xyz/\1!g')
    curl "$download_url" | bsdtar -xf- --strip-components 1
    cp autocomplete/fd.bash-completion /usr/share/bash-completion/completions/
    popd || exit 1
    /bin/rm -rf "$tmp_dir"
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/fd" '/usr/bin/fd'
  fi

  if [[ x"$(echo "${install_hexyl:=yes}" | cut -c1)" = x'y' ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/sharkdp/hexyl/releases/latest' |
        grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'hexyl.*x86_64.*linux-musl.tar.gz$')"
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
      sed -E 's!github.com/(.+/download/)!github.com.mirror.icecode.xyz/\1!g')
    curl "$download_url" | bsdtar -xf- --strip-components 1
    popd || exit 1
    /bin/rm -rf "$tmp_dir"
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/hexyl" '/usr/bin/hexyl'
  fi

  if [[ x"$(echo "${install_hugo_extended:=no}" | cut -c1)" = x'y' ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/gohugoio/hugo/releases/latest' |
        grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'hugo_extended.*Linux-64bit.tar.gz$')"
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
      sed -E 's!github.com/(.+/download/)!github.com.mirror.icecode.xyz/\1!g')
    curl "$download_url" | bsdtar -xf-
    # Need glibc runtime.
    sudo "$(type -P install)" -pvD './hugo' '/usr/local/bin/hugo'
    popd || exit 1
    /bin/rm -rf "$tmp_dir"
  fi

  tmp_dir=$(mktemp -d)
  pushd "$tmp_dir" || exit 1
  download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/tstack/lnav/releases/latest' |
      grep 'browser_download_url' | cut -d'"' -f4 | grep -E '[0-9]\/lnav-.+?-x86_64-linux-musl.zip$')"
  if curl "$download_url" | bsdtar -xf- --strip-components 1; then
    sudo "$(type -P install)" -pvD './lnav' '/usr/local/bin/lnav'
  fi
  popd || exit 1
  /bin/rm -rf "$tmp_dir"
  dirs -c

  ################

  curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/croc" '/usr/local/bin/croc'
  curl_to_dest 'https://cdn.jsdelivr.net/gh/schollz/croc@master/src/install/bash_autocomplete' '/usr/share/bash-completion/completions/croc' &&
    sudo chmod -x '/usr/share/bash-completion/completions/croc'

  if [[ x"$(echo "${install_shfmt:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/shfmt" '/usr/local/bin/shfmt'
  else
    sudo rm '/usr/local/bin/shfmt'
  fi

  if [[ x"$(echo "${install_sd:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/sd" '/usr/local/bin/sd'
  else
    sudo rm '/usr/local/bin/sd'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_github_release:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/github-release" '/usr/local/bin/github-release'
  else
    sudo rm '/usr/local/bin/github-release'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_go_mmproxy:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/go-mmproxy" '/usr/local/bin/go-mmproxy'
  else
    sudo rm '/usr/local/bin/go-mmproxy'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_nfpm:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/nfpm" '/usr/local/bin/nfpm'
  else
    sudo rm '/usr/local/bin/nfpm'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_mosdns:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/mosdns" '/usr/local/bin/mosdns'
  else
    sudo rm '/usr/local/bin/mosdns'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_ss_rust:=yes}" | cut -c1)" = x'y' ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    if ldd /bin/ls | grep -qF 'musl'; then
      export ss_rust_file_name='4limit-mem-server-only-ss-rust-linux-gnu-x64.tar.gz'
    else
      export ss_rust_file_name='ss-rust-linux-gnu-x64.tar.xz'
    fi
    if curl "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/${ss_rust_file_name}" | bsdtar -xf-; then
      if [[ x"$ss_rust_file_name" = x'ss-rust-linux-gnu-x64.tar.xz' ]]; then
        sudo "$(type -P install)" -pvD './ssservice' '/usr/local/bin/ssservice' &&
        sudo ln -fs '/usr/local/bin/ssservice' '/usr/local/bin/sslocal' &&
        sudo ln -fs '/usr/local/bin/ssservice' '/usr/local/bin/ssmanager' &&
        sudo ln -fs '/usr/local/bin/ssservice' '/usr/local/bin/ssserver' &&
        sudo "$(type -P install)" -pvD './ssurl' '/usr/local/bin/ssurl'
      else
        sudo "$(type -P install)" -pvD './ssmanager' '/usr/local/bin/ssmanager'
        sudo "$(type -P install)" -pvD './ssserver' '/usr/local/bin/ssserver'
        sudo "$(type -P install)" -pvD './ssurl' '/usr/local/bin/ssurl'
      fi
    fi
    popd || exit 1
    /bin/rm -rf "$tmp_dir"
  else
    sudo rm '/usr/local/bin/sslocal' '/usr/local/bin/ssmanager' '/usr/local/bin/ssserver' '/usr/local/bin/ssurl'
  fi

  if [[ x"$(echo "${install_go_shadowsocks:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/shadowsocks-go" '/usr/local/bin/shadowsocks-go'
  else
    sudo rm '/usr/local/bin/shadowsocks-go'
  fi
  sudo rm '/usr/local/bin/go-shadowsocks2' '/usr/local/bin/v2ray-plugin'

  if [[ x"$(echo "${install_naiveproxy:=yes}" | cut -c1)" = x'y' ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/klzgrad/naiveproxy/releases/latest' |
        grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'naiveproxy-.+-linux-x64.tar.xz$')"
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
      sed -E 's!github.com/(.+/download/)!github.com.mirror.icecode.xyz/\1!g')
    curl "$download_url" | bsdtar -xf- --strip-components 1
    # Need glibc runtime.
    sudo strip './naive' -o '/usr/local/bin/naive'
    popd || exit 1
    /bin/rm -rf "$tmp_dir"
  else
    sudo rm '/usr/local/bin/naive'
  fi

  sudo rm '/usr/local/bin/overmind'

  # # shellcheck disable=SC2154
  # if [[ x"$(echo "${install_frp:=no}" | cut -c1)" = x'y' ]]; then
  #   curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/frpc" '/usr/local/bin/frpc'
  #   curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/frps" '/usr/local/bin/frps'
  # else
  sudo rm '/usr/local/bin/frpc' '/usr/local/bin/frps'
  # fi

  # # shellcheck disable=SC2154
  # if [[ x"$(echo "${install_chisel:=no}" | cut -c1)" = x'y' ]]; then
  #   curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/chisel" '/usr/local/bin/chisel'
  # else
  sudo rm '/usr/local/bin/chisel'
  # fi

  sudo rm '/usr/local/bin/got'
  if [[ x"$(echo "${install_pget:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/pget" '/usr/local/bin/pget'
  else
    sudo rm '/usr/local/bin/pget'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_dive:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/dive" '/usr/local/bin/dive'
  else
    sudo rm '/usr/local/bin/dive'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_duf:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/duf" '/usr/local/bin/duf'
  else
    sudo rm '/usr/local/bin/duf'
  fi

  if [[ x"$(echo "${install_dnslookup:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/dnslookup" '/usr/local/bin/dnslookup'
  else
    sudo rm '/usr/local/bin/dnslookup'
  fi

  dog_latest_tag_name="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/ogham/dog/tags?per_page=100' |
      grep 'name' | cut -d'"' -f4 | grep -vE 'alpha|beta|rc|test|week|pre' |
      sort -rV | head -1)"
  curl "https://github.com/ogham/dog/releases/download/${dog_latest_tag_name}/dog-${dog_latest_tag_name}-x86_64-unknown-linux-gnu.zip" | sudo bsdtar -xf- -P -C /usr/local
  curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/dog" '/usr/local/bin/dog'

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_qft:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/qft" '/usr/local/bin/qft'
  else
    sudo rm '/usr/local/bin/qft'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_websocat:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/websocat" '/usr/local/bin/websocat'
  else
    sudo rm '/usr/local/bin/websocat'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_just:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/just" '/usr/local/bin/just'
  else
    sudo rm '/usr/local/bin/just'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_desed:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/desed" '/usr/local/bin/desed'
  else
    sudo rm '/usr/local/bin/desed'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_fnm:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/fnm" '/usr/local/bin/fnm'
  else
    sudo rm '/usr/local/bin/fnm'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_rsign:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/rsign" '/usr/local/bin/rsign'
  else
    sudo rm '/usr/local/bin/rsign'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_b3sum:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/b3sum" '/usr/local/bin/b3sum'
  else
    sudo rm '/usr/local/bin/b3sum'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_nali:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/nali" '/usr/local/bin/nali'
  else
    sudo rm '/usr/local/bin/nali'
  fi

  [[ -n "$(type -P apk)" ]] && curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/apk-file" '/usr/local/bin/apk-file'

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_age:=yes}" | cut -c1)" = x'y' ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    if curl "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/age-linux-amd64.tar.gz" | bsdtar -xf-; then
      sudo "$(type -P install)" -pvD './age' '/usr/local/bin/age'
      sudo "$(type -P install)" -pvD './age-keygen' '/usr/local/bin/age-keygen'
    fi
    popd || exit 1
    /bin/rm -rf "$tmp_dir"
  else
    sudo rm '/usr/local/bin/age' '/usr/local/bin/age-keygen'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_mtg:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/mtg" '/usr/local/bin/mtg'
  else
    sudo rm '/usr/local/bin/mtg'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_wuzz:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/wuzz" '/usr/local/bin/wuzz'
  else
    sudo rm '/usr/local/bin/wuzz'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_httpstat:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/httpstat" '/usr/local/bin/httpstat'
  else
    sudo rm '/usr/local/bin/httpstat'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_wgcf:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/wgcf" '/usr/local/bin/wgcf'
  else
    sudo rm '/usr/local/bin/wgcf'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_mmp_go:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/mmp-go" '/usr/local/bin/mmp-go'
  else
    sudo rm '/usr/local/bin/mmp-go'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_cloudflarest:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/CloudflareST" '/usr/local/bin/CloudflareST'
  else
    sudo rm '/usr/local/bin/CloudflareST'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_netflix_verify:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/nf" '/usr/local/bin/nf'
  else
    sudo rm '/usr/local/bin/nf'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_piknik:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/piknik" '/usr/local/bin/piknik'
  else
    sudo rm '/usr/local/bin/piknik'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_boringtun:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/boringtun-linux-musl-x64" '/usr/local/bin/boringtun'
  else
    sudo rm '/usr/local/bin/boringtun'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_cfnts:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/cfnts" '/usr/local/bin/cfnts'
  else
    sudo rm '/usr/local/bin/cfnts'
  fi

  ################

  apk add haproxy-openrc
  rc-update add haproxy
  curl_to_dest "https://github.com/IceCodeNew/haproxy_static/releases/latest/download/haproxy" '/usr/local/sbin/haproxy' &&
      sudo rm -f /usr/bin/haproxy &&
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

  sudo rm -f '/usr/sbin/caddy' '/usr/local/bin/caddy' '/usr/local/bin/xcaddy'
  curl -L "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/caddy.zst" |
    unzstd -q --no-progress -o './caddy' && sudo "$(type -P install)" -pvD './caddy' '/usr/local/sbin/caddy' &&
    sudo rm -f '/usr/bin/caddy' && sudo ln -s /usr/local/sbin/caddy /usr/bin/
  popd || exit 1
  /bin/rm -rf "$tmp_dir"

  # tmp_dir=$(mktemp -d)
  # pushd "$tmp_dir" || exit 1
  # if curl "https://github.com/tdewolff/minify/releases/latest/download/minify_linux_amd64.tar.gz" | bsdtar -xf-; then
  #   sudo "$(type -P install)" -pvD './minify' '/usr/bin/minify'
  #   sudo "$(type -P install)" -pvDm 644 './bash_completion' '/usr/share/bash-completion/completions/minify'
  # fi
  # popd || exit 1
  # /bin/rm -rf "$tmp_dir"
  # [[ -f /usr/share/caddy/index.html ]] && minify -o /usr/share/caddy/index.html /usr/share/caddy/index.html
  sudo rm -f '/usr/share/caddy/index.html' &&
    sudo mkdir -p '/usr/share/caddy' &&
    sudo "$(type -P curl)" -o '/usr/share/caddy/index.html' -- 'https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@master/usr/share/caddy/index.html'

  ################

  checksec --dir=/usr/local/bin
  checksec --listfile=<(echo -e '/usr/bin/bat\n/usr/bin/fd\n/usr/bin/hexyl\n/usr/bin/minify\n/usr/local/sbin/haproxy\n/usr/local/sbin/caddy')

  git config --global --unset url.https://ghproxy.com/https://github.com.insteadof
  git config --global --list
  exit 0
}

self_update
