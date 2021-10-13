#!/usr/bin/env bash
# shellcheck disable=SC2268
#
# --- Script Version ---
# Name    : void_getting_start.sh
# Version : ded0d1b (1 commit after this ref)
# Author  : IceCodeNew
# Date    : March 2021
# Download: https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@master/void_getting_start.sh
readonly local_script_version='ded0d1b'

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
    'https://api.github.com/repos/IceCodeNew/go-collection/commits?per_page=2&path=void_getting_start.sh' |
      jq .[1] | grep -Fm1 'sha' | cut -d'"' -f4 | head -c7)"
  readonly remote_script_version
  # Should any error occured during quering `api.github.com`, do not execute this script.
  [[ x"${geoip_is_cn:0:1}" = x'y' ]] &&
    sed -i -E -e 's!(https://github.com/.+/download/)!https://gh.api.99988866.xyz/\1!g' "$HOME/void_getting_start.sh" &&
    git config --global url."https://hub.fastgit.org".insteadOf https://github.com
  [[ x"$local_script_version" = x"$remote_script_version" ]] &&
    install_binaries
  sleep $(( ( RANDOM % 10 ) + 1 ))s && curl -i "https://purge.jsdelivr.net/gh/IceCodeNew/go-collection@master/void_getting_start.sh"
  if [[ x"${geoip_is_cn:0:1}" = x'y' ]]; then
    curl -o "$HOME/void_getting_start.sh.tmp" -- 'https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@master/void_getting_start.sh'
    sed -i -E -e 's!(https://github.com/.+/download/)!https://gh.api.99988866.xyz/\1!g' "$HOME/void_getting_start.sh.tmp"
  else
    curl -o "$HOME/void_getting_start.sh.tmp" -- 'https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@master/void_getting_start.sh'
  fi
  dos2unix "$HOME/void_getting_start.sh.tmp" && mv -f "$HOME/void_getting_start.sh.tmp" "$HOME/void_getting_start.sh" &&
  echo 'Upgrade successful!' && exit 1
}

install_binaries() {
  sudo mkdir -p /usr/local/bin /usr/local/sbin

  ########

  tmp_dir=$(mktemp -d) && pushd "$tmp_dir" || exit 1
  download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/aristocratos/btop/releases/latest' |
      grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'linux-x86_64.tbz$')" && \
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" |
      sed -E 's!(https://github.com/.+/download/)!https://gh.api.99988866.xyz/\1!g')
  curl -- "$download_url" | bsdtar -xf- && \
    sudo make install PREFIX=/usr && \
    sudo make setuid PREFIX=/usr && \
    sudo strip /usr/bin/btop && \
  popd || exit 1
  /bin/rm -rf "$tmp_dir"
  dirs -c

  ########

  curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/croc" '/usr/local/bin/croc'
  curl_to_dest 'https://cdn.jsdelivr.net/gh/schollz/croc@master/src/install/bash_autocomplete' '/usr/share/bash-completion/completions/croc' &&
    sudo chmod -x '/usr/share/bash-completion/completions/croc'

  if [[ x"$(echo "${install_shfmt:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/shfmt" '/usr/local/bin/shfmt'
  else
    sudo rm '/usr/local/bin/shfmt'
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
    [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" | sed -E 's!(https://github.com/.+/download/)!https://gh.api.99988866.xyz/\1!g')
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

  # # shellcheck disable=SC2154
  # if [[ x"$(echo "${install_rsign:=yes}" | cut -c1)" = x'y' ]]; then
  #   curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/rsign" '/usr/local/bin/rsign'
  # else
  #   sudo rm '/usr/local/bin/rsign'
  # fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_b3sum:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/rust-collection@latest-release/assets/b3sum" '/usr/local/bin/b3sum'
  else
    sudo rm '/usr/local/bin/b3sum'
  fi

  # # shellcheck disable=SC2154
  # if [[ x"$(echo "${install_nali:=yes}" | cut -c1)" = x'y' ]]; then
  #   curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/nali" '/usr/local/bin/nali'
  # else
  #   sudo rm '/usr/local/bin/nali'
  # fi

  # # shellcheck disable=SC2154
  # if [[ x"$(echo "${install_age:=yes}" | cut -c1)" = x'y' ]]; then
  #   tmp_dir=$(mktemp -d)
  #   pushd "$tmp_dir" || exit 1
  #   if curl "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/age-linux-amd64.tar.gz" | bsdtar -xf-; then
  #     sudo "$(type -P install)" -pvD './age' '/usr/local/bin/age'
  #     sudo "$(type -P install)" -pvD './age-keygen' '/usr/local/bin/age-keygen'
  #   fi
  #   popd || exit 1
  #   /bin/rm -rf "$tmp_dir"
  # else
  #   sudo rm '/usr/local/bin/age' '/usr/local/bin/age-keygen'
  # fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_mtg:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/mtg" '/usr/local/bin/mtg'
  else
    sudo rm '/usr/local/bin/mtg'
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

  # # shellcheck disable=SC2154
  # if [[ x"$(echo "${install_cloudflarest:=yes}" | cut -c1)" = x'y' ]]; then
  #   curl_to_dest "https://cdn.jsdelivr.net/gh/IceCodeNew/go-collection@latest-release/assets/CloudflareST" '/usr/local/bin/CloudflareST'
  # else
  #   sudo rm '/usr/local/bin/CloudflareST'
  # fi

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

  tmp_dir=$(mktemp -d)
  pushd "$tmp_dir" || exit 1
  download_url="https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip"
  [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" | sed -E 's!(https://github.com/.+/download/)!https://gh.api.99988866.xyz/\1!g')
  curl "$download_url" | bsdtar -xf- &&
    sudo "$(type -P install)" -pvD './v2ctl' '/usr/bin/v2ctl' &&
    sudo "$(type -P install)" -pvD './v2ray' '/usr/bin/v2ray' &&
    sudo setcap 'CAP_NET_ADMIN=+ep CAP_NET_BIND_SERVICE=+ep' '/usr/bin/v2ray' &&
    sudo "$(type -P install)" -pvD -o nobody -g nogroup -m 644 './geoip-only-cn-private.dat' '/usr/local/share/v2ray/geoip.dat'
  popd || exit 1
  /bin/rm -rf "$tmp_dir"

  if ! [[ -f /etc/sv/v2ray/run ]]; then
    sudo rm -rf /etc/sv/v2ray && sudo mkdir -p /etc/sv/v2ray && sudo mkdir -p /var/log/v2ray &&
    cat > /etc/sv/v2ray/run << 'END_TEXT'
#!/bin/sh
ulimit -n ${MAX_OPEN_FILES:-65535}

# exec chpst -u nobody:nogroup v2ray -config /usr/local/etc/v2ray/config.json
exec chpst -u nobody:nogroup v2ray -confdir /usr/local/etc/v2ray/conf.d
END_TEXT

    chmod +x /etc/sv/v2ray/run &&
    ln -s /etc/sv/v2ray /var/service/;
  fi

  ################

  sudo xbps-install -Su &&
  sudo xbps-install -Su &&
  sudo xbps-install -y haproxy &&
  ln -s /etc/sv/haproxy /var/service/;
  curl_to_dest "https://github.com/IceCodeNew/haproxy_static/releases/latest/download/haproxy" '/usr/local/sbin/haproxy' &&
      sudo rm -f /usr/bin/haproxy &&
      sudo ln -s /usr/local/sbin/haproxy /usr/bin/

  sudo xbps-install -Su &&
  sudo xbps-install -Su &&
  sudo xbps-install -y caddy &&
  ln -s /etc/sv/caddy /var/service/;
  if [[ x"$(echo "${donot_need_caddy_autorun:=no}" | cut -c1)" = x'y' ]]; then
    sudo touch /etc/sv/caddy/down
  else
    sudo sed -i -E 's/^:80/:19600/' /etc/caddy/Caddyfile
  fi
  sudo rm '/usr/local/bin/caddy' '/usr/local/bin/xcaddy'
  curl_to_dest "https://github.com/IceCodeNew/go-collection/raw/latest-release/assets/caddy" '/usr/local/sbin/caddy' &&
    sudo rm -f /usr/bin/caddy &&
    sudo ln -s /usr/local/sbin/caddy /usr/bin/

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

  git config --global --unset url.https://hub.fastgit.org.insteadof
  git config --global --list
  exit 0
}

self_update
