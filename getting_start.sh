#!/usr/bin/env bash
# shellcheck disable=SC2268
#
# --- Script Version ---
# Name    : getting_start.sh
# Version : aff87d8 (1 commit after this ref)
# Author  : IceCodeNew
# Date    : Wed Oct 20th, 2021
# Download: https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@master/getting_start.sh
readonly local_script_version='aff87d8'

# IMPORTANT!
# `apt` does not have a stable CLI interface. Use with caution in scripts.
## Refer: https://askubuntu.com/a/990838
export DEBIAN_FRONTEND=noninteractive

## Refer: https://unix.stackexchange.com/a/356759
export PAGER='cat'
export SYSTEMD_PAGER=cat

# Shell functions are only known to the shell. External commands like `find`, `xargs`, `su` and `sudo` do not recognize shell functions.
# Instead, the function contents can be executed in a shell, either through sh -c or by creating a separate shell script as an executable file.
## Refer: https://github.com/koalaman/shellcheck/wiki/SC2033

cd() {
  command cd "$@" || exit 1
}
cp() {
  $(type -P cp) "$@"
}
mv() {
  $(type -P mv) "$@"
}

curl_path="$(type -P curl)"
# geo_country="$(curl 'https://api.myip.la/en?json' | jq . | grep country_code | cut -d'"' -f4)"
# [[ x"$geo_country" = x'CN' ]] && curl_path="$(type -P curl) --retry-connrefused"
myip_ipip_response="$(curl -sS 'http://myip.ipip.net' | grep -E '来自于：中国' | grep -vE '香港|澳门|台湾')"
echo "$myip_ipip_response" | grep -qE '来自于：中国' && readonly geoip_is_cn='yes' && curl_path="$(type -P curl) --retry-connrefused"
curl() {
  # It is OK for the system which has cURL's version greater than `7.76.0` to use `--fail-with-body` instead of `-f`.
  ## Refer to: https://superuser.com/a/1626376
  $curl_path -LRq --retry 5 --retry-delay 10 --retry-max-time 60 -f "$@"
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
    dirs -c
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
    'https://api.github.com/repos/IceCodeNew/go-collection/commits?per_page=2&path=getting_start.sh' |
      jq .[1] | grep -Fm1 'sha' | cut -d'"' -f4 | head -c7)"
  readonly remote_script_version
  # Should any error occured during quering `api.github.com`, do not execute this script.
  [[ x"${geoip_is_cn:0:1}" = x'y' ]] &&
    sed -i -E -e 's!github.com/(.+/download/)!github.com.mirror.icecode.xyz/\1!g' "$HOME/getting_start.sh" &&
    git config --global url."https://hub.fastgit.org".insteadOf https://github.com
  [[ x"$local_script_version" = x"$remote_script_version" ]] &&
    install_binaries
  sleep $(( ( RANDOM % 10 ) + 1 ))s && curl -i "https://purge.jsdelivr.net/gh/IceCodeNew/go-collection@master/getting_start.sh"
  if [[ x"${geoip_is_cn:0:1}" = x'y' ]]; then
    curl -o "$HOME/getting_start.sh.tmp" -- 'https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@master/getting_start.sh'
    sed -i -E -e 's!github.com/(.+/download/)!github.com.mirror.icecode.xyz/\1!g' "$HOME/getting_start.sh.tmp"
  else
    curl -o "$HOME/getting_start.sh.tmp" -- 'https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@master/getting_start.sh'
  fi
  dos2unix "$HOME/getting_start.sh.tmp" && mv -f "$HOME/getting_start.sh.tmp" "$HOME/getting_start.sh" &&
  echo 'Upgrade successful!' && exit 1
}

install_binaries() {
  # sudo mkdir -p /usr/local/bin /usr/local/sbin
  sudo mkdir -p /usr/local/bin

  ########

  tmp_dir=$(mktemp -d) && pushd "$tmp_dir" || exit 1
  download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/aristocratos/btop/releases/latest' |
      grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'linux-musl.tbz$' | grep -iE 'x86_64')" && \
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
      sed -E 's!github.com/(.+/download/)!github.com.mirror.icecode.xyz/\1!g')
  curl -- "$download_url" | bsdtar -xf- && \
    sudo make install PREFIX=/usr && \
    sudo make setuid PREFIX=/usr && \
    sudo strip /usr/bin/btop && \
  popd || exit 1
  /bin/rm -rf "$tmp_dir"
  dirs -c

  ########

  if [[ x"$(echo "${install_ripgrep:=yes}" | cut -c1)" = x'y' ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/BurntSushi/ripgrep/releases/latest' |
        grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'amd64.deb$')"
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
      sed -E 's!github.com/(.+/download/)!github.com.mirror.icecode.xyz/\1!g')
    curl -o 'ripgrep_amd64.deb' -- "$download_url" &&
      sudo dpkg -i 'ripgrep_amd64.deb' && apt-mark hold ripgrep
    popd || exit 1
    /bin/rm -rf "$tmp_dir"
    dirs -c
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/rg" '/usr/bin/rg'
  fi

  if [[ x"$(echo "${install_bat:=yes}" | cut -c1)" = x'y' ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/sharkdp/bat/releases/latest' |
        grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'musl.+amd64.deb$')"
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
      sed -E 's!github.com/(.+/download/)!github.com.mirror.icecode.xyz/\1!g')
    curl -o 'bat-musl_amd64.deb' -- "$download_url" &&
      sudo dpkg -i 'bat-musl_amd64.deb'
    git_clone https://github.com/eth-p/bat-extras.git &&
      pushd bat-extras || exit 1
      chmod +x build.sh &&
      ./build.sh --install --no-manuals
      popd || exit 1
    popd || exit 1
    /bin/rm -rf "$tmp_dir"
    dirs -c
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/bat" '/usr/bin/bat'
  fi

  if [[ x"$(echo "${install_fd:=yes}" | cut -c1)" = x'y' ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/sharkdp/fd/releases/latest' |
        grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'musl.+amd64.deb$')"
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
      sed -E 's!github.com/(.+/download/)!github.com.mirror.icecode.xyz/\1!g')
    curl -o 'fd-musl_amd64.deb' -- "$download_url" &&
      sudo dpkg -i 'fd-musl_amd64.deb'
    popd || exit 1
    /bin/rm -rf "$tmp_dir"
    dirs -c
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/fd" '/usr/bin/fd'
  fi

  if [[ x"$(echo "${install_hexyl:=yes}" | cut -c1)" = x'y' ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/sharkdp/hexyl/releases/latest' |
        grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'musl.+amd64.deb$')"
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
      sed -E 's!github.com/(.+/download/)!github.com.mirror.icecode.xyz/\1!g')
    curl -o 'hexyl-musl_amd64.deb' -- "$download_url" &&
      sudo dpkg -i 'hexyl-musl_amd64.deb'
    popd || exit 1
    /bin/rm -rf "$tmp_dir"
    dirs -c
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/hexyl" '/usr/bin/hexyl'
  fi

  if [[ x"$(echo "${install_hugo_extended:=no}" | cut -c1)" = x'y' ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/gohugoio/hugo/releases/latest' |
        grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'extended.+linux-64bit.deb$')"
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
      sed -E 's!github.com/(.+/download/)!github.com.mirror.icecode.xyz/\1!g')
    curl -o 'hugo_extended_Linux-64bit.deb' -- "$download_url" &&
      sudo dpkg -i 'hugo_extended_Linux-64bit.deb'
    popd || exit 1
    /bin/rm -rf "$tmp_dir"
    dirs -c
  fi

  ################

  curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/croc" '/usr/local/bin/croc'
  curl_to_dest 'https://cdn.jsdelivr.net/gh/schollz/croc@master/src/install/bash_autocomplete' '/etc/bash_completion.d/croc' &&
    sudo chmod -x '/etc/bash_completion.d/croc'

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
    if grep -qw avx2 /proc/cpuinfo && grep -qw sha /proc/cpuinfo; then
      export ss_rust_file_name='ss-rust-linux-gnu-x64.tar.xz'
    else
      export ss_rust_file_name='4limit-mem-server-only-ss-rust-linux-gnu-x64.tar.gz'
    fi
    if curl "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/${ss_rust_file_name}" | bsdtar -xf-; then
      [[ x"$ss_rust_file_name" = x'ss-rust-linux-gnu-x64.tar.xz' ]] &&
        sudo "$(type -P install)" -pvD './sslocal' '/usr/local/bin/sslocal' &&
        sudo "$(type -P install)" -pvD './ssurl' '/usr/local/bin/ssurl'
      sudo "$(type -P install)" -pvD './ssmanager' '/usr/local/bin/ssmanager'
      sudo "$(type -P install)" -pvD './ssserver' '/usr/local/bin/ssserver'
    fi
    popd || exit 1
    /bin/rm -rf "$tmp_dir"
    dirs -c
  else
    sudo rm '/usr/local/bin/sslocal' '/usr/local/bin/ssmanager' '/usr/local/bin/ssserver' '/usr/local/bin/ssurl'
  fi

  if [[ x"$(echo "${install_go_shadowsocks:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/go-shadowsocks2" '/usr/local/bin/go-shadowsocks2'
    curl_to_dest "https://github.com/IceCodeNew/v2ray-plugin/releases/latest/download/v2ray-plugin_linux_amd64" '/usr/local/bin/v2ray-plugin'
  else
    sudo rm '/usr/local/bin/go-shadowsocks2' '/usr/local/bin/v2ray-plugin'
  fi

  if [[ x"$(echo "${install_naiveproxy:=yes}" | cut -c1)" = x'y' ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/klzgrad/naiveproxy/releases/latest' |
        grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'linux-x64.tar.xz$')"
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

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_overmind:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/overmind" '/usr/local/bin/overmind'
  else
    sudo rm '/usr/local/bin/overmind'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_frp:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/frpc" '/usr/local/bin/frpc'
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/frps" '/usr/local/bin/frps'
  else
    sudo rm '/usr/local/bin/frpc' '/usr/local/bin/frps'
  fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_chisel:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/chisel" '/usr/local/bin/chisel'
  else
    sudo rm '/usr/local/bin/chisel'
  fi

  if [[ x"$(echo "${install_got:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/got" '/usr/local/bin/got'
  else
    sudo rm '/usr/local/bin/got'
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
  curl "https://github.com/ogham/dog/releases/download/${dog_latest_tag_name}/dog-${dog_latest_tag_name}-x86_64-unknown-linux-gnu.zip" | bsdtar -xf- -P -C /usr/local
  curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/dog" '/usr/local/bin/dog'

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
    dirs -c
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

  # curl_to_dest "https://github.com/IceCodeNew/haproxy_static/releases/latest/download/haproxy" '/usr/local/sbin/haproxy'
  tmp_dir=$(mktemp -d)
  pushd "$tmp_dir" || exit 1
  download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/IceCodeNew/haproxy_static/releases/latest' |
      grep 'browser_download_url' | cut -d'"' -f4 | grep -E '[0-9]\/haproxy_.+?amd64.deb$')"
  [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
    sed -E 's!github.com/(.+/download/)!github.com.mirror.icecode.xyz/\1!g')
  curl -o 'haproxy_amd64.deb'  -- "$download_url" &&
    download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/IceCodeNew/haproxy_static/releases/latest' |
      grep 'browser_download_url' | cut -d'"' -f4 | grep -E '[0-9]\/jemalloc_.+?amd64.deb$')"
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
      sed -E 's!github.com/(.+/download/)!github.com.mirror.icecode.xyz/\1!g')
    curl -o 'jemalloc_amd64.deb' -- "$download_url" &&
    sudo dpkg -i 'jemalloc_amd64.deb' && sudo dpkg -i 'haproxy_amd64.deb'
  curl -LROJ 'https://github.com/IceCodeNew/haproxy_static/releases/latest/download/haproxy.service' &&
    sudo /bin/mv -f './haproxy.service' '/etc/systemd/system/haproxy.service' &&
    sudo systemctl daemon-reload
  echo 'systemctl enable --now haproxy'
  popd || exit 1
  /bin/rm -rf "$tmp_dir"
  dirs -c

  tmp_dir=$(mktemp -d)
  pushd "$tmp_dir" || exit 1
  if [[ ! -f /lib/systemd/system/caddy.service ]]; then
    download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/caddyserver/caddy/releases/latest' |
        grep 'browser_download_url' | grep 'linux_amd64.deb' | cut -d'"' -f4)"
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
      sed -E 's!github.com/(.+/download/)!github.com.mirror.icecode.xyz/\1!g')
    curl -o 'caddy_linux_amd64.deb' -- "$download_url" &&
      sudo dpkg -i 'caddy_linux_amd64.deb' && sudo rm 'caddy_linux_amd64.deb'
    if [[ x"$(echo "${donot_need_caddy_autorun:=no}" | cut -c1)" = x'y' ]]; then
      sudo systemctl disable --now caddy
    else
      sudo sed -i -E 's/^:80/:19600/' /etc/caddy/Caddyfile
    fi
  fi

  sudo rm -f '/usr/local/bin/caddy' '/usr/local/bin/xcaddy' &&
    curl -L "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/caddy.zst" |
    unzstd -q --no-progress -o './caddy' && sudo "$(type -P install)" -pvD './caddy' '/usr/bin/caddy'
  popd || exit 1
  /bin/rm -rf "$tmp_dir"
  dirs -c

  if [[ x"$(echo "${install_minify:=no}" | cut -c1)" = x'y' ]]; then
    sudo apt-get update
    sudo apt-get -y install minify
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    if curl "https://github.com/tdewolff/minify/releases/latest/download/minify_linux_amd64.tar.gz" | bsdtar -xf-; then
      sudo "$(type -P install)" -pvD './minify' '/usr/bin/minify'
      sudo "$(type -P install)" -pvDm 644 './bash_completion' '/etc/bash_completion.d/minify'
    fi
    popd || exit 1
    /bin/rm -rf "$tmp_dir"
    dirs -c
    [[ -f /usr/share/caddy/index.html ]] && minify -o /usr/share/caddy/index.html /usr/share/caddy/index.html
  else
    sudo dpkg -P minify
    sudo rm -rf '/usr/bin/minify' '/etc/bash_completion.d/minify'
  fi
  sudo rm -f '/usr/share/caddy/index.html' &&
    sudo mkdir -p '/usr/share/caddy' &&
    sudo "$(type -P curl)" -o '/usr/share/caddy/index.html' -- 'https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@master/usr/share/caddy/index.html'

  ################

  checksec --dir=/usr/local/bin
  checksec --listfile=<(echo -e '/usr/bin/bat\n/usr/bin/fd\n/usr/bin/hexyl\n/usr/bin/caddy\n/usr/bin/minify\n/usr/local/sbin/haproxy')

  git config --global --unset url.https://hub.fastgit.org.insteadof
  git config --global --list
  exit 0
}

self_update
