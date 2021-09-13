#!/usr/bin/env bash
# shellcheck disable=SC2268
#
# --- Script Version ---
# Name    : void_getting_start.sh
# Version : 02b77f4 (1 commit after this ref)
# Author  : IceCodeNew
# Date    : March 2021
# Download: https://raw.githubusercontent.com/IceCodeNew/go-collection/master/void_getting_start.sh
readonly local_script_version='02b77f4'

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
    sed -i -E -e 's!raw.githubusercontent.com!raw.githubusercontents.com!g' -e 's!(https://github.com/.+/download/)!https://gh.api.99988866.xyz/\1!g' "$HOME/void_getting_start.sh" &&
    git config --global url."https://hub.fastgit.org".insteadOf https://github.com
  [[ x"$local_script_version" = x"$remote_script_version" ]] &&
    install_binaries
  if [[ x"${geoip_is_cn:0:1}" = x'y' ]]; then
    curl -o "$HOME/void_getting_start.sh.tmp" -- 'https://raw.githubusercontents.com/IceCodeNew/go-collection/master/void_getting_start.sh'
    sed -i -E -e 's!raw.githubusercontent.com!raw.githubusercontents.com!g' -e 's!(https://github.com/.+/download/)!https://gh.api.99988866.xyz/\1!g' "$HOME/void_getting_start.sh.tmp"
  else
    curl -o "$HOME/void_getting_start.sh.tmp" -- 'https://raw.githubusercontent.com/IceCodeNew/go-collection/master/void_getting_start.sh'
  fi
  dos2unix "$HOME/void_getting_start.sh.tmp" && mv -f "$HOME/void_getting_start.sh.tmp" "$HOME/void_getting_start.sh" &&
  echo 'Upgrade successful!' && exit 1
}

install_binaries() {
  sudo mkdir -p /usr/local/bin /usr/local/sbin

  curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/croc" '/usr/local/bin/croc'
  curl_to_dest 'https://raw.githubusercontent.com/schollz/croc/master/src/install/bash_autocomplete' '/usr/share/bash-completion/completions/croc'

  curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/shfmt" '/usr/local/bin/shfmt'

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_shadowsocks:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/go-shadowsocks2" '/usr/local/bin/go-shadowsocks2'
    curl_to_dest "https://github.com/IceCodeNew/v2ray-plugin/releases/latest/download/v2ray-plugin_linux_amd64" '/usr/local/bin/v2ray-plugin'

    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    if grep -qw avx2 /proc/cpuinfo && grep -qw sha /proc/cpuinfo; then
      export ss_rust_file_name='ss-rust-linux-gnu-x64.tar.xz'
    else
      export ss_rust_file_name='4limit-mem-server-only-ss-rust-linux-gnu-x64.tar.gz'
    fi
    if curl "https://github.com/IceCodeNew/rust-collection/releases/latest/download/${ss_rust_file_name}" | bsdtar -xf-; then
      [[ x"$ss_rust_file_name" = x'ss-rust-linux-gnu-x64.tar.xz' ]] &&
        sudo "$(type -P install)" -pvD './sslocal' '/usr/local/bin/sslocal' &&
        sudo "$(type -P install)" -pvD './ssurl' '/usr/local/bin/ssurl'
      sudo "$(type -P install)" -pvD './ssmanager' '/usr/local/bin/ssmanager'
      sudo "$(type -P install)" -pvD './ssserver' '/usr/local/bin/ssserver'
    fi
    popd || exit 1
    /bin/rm -rf "$tmp_dir"
  else
    sudo rm '/usr/local/bin/go-shadowsocks2' '/usr/local/bin/sslocal' '/usr/local/bin/ssmanager' '/usr/local/bin/ssserver' '/usr/local/bin/ssurl'
  fi

  tmp_dir=$(mktemp -d)
  pushd "$tmp_dir" || exit 1
  download_url="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/klzgrad/naiveproxy/releases/latest' |
      grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'linux-x64.tar.xz$')"
  [[ x"${geoip_is_cn:0:1}" = x'y' ]] && download_url=$(echo "$download_url" | sed -E 's!(https://github.com/.+/download/)!https://gh.api.99988866.xyz/\1!g')
  curl "$download_url" | bsdtar -xf- --strip-components 1
  # Need glibc runtime.
  sudo "$(type -P install)" -pvD './naive' '/usr/local/bin/naive'
  popd || exit 1
  /bin/rm -rf "$tmp_dir"

  dog_latest_tag_name="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/ogham/dog/tags?per_page=100' |
    grep 'name' | cut -d'"' -f4 | grep -vE 'alpha|beta|rc|test|week|pre' |
    sort -rV | head -1)"
  curl "https://github.com/ogham/dog/releases/download/${dog_latest_tag_name}/dog-${dog_latest_tag_name}-x86_64-unknown-linux-gnu.zip" | bsdtar -xf- -P -C /usr/local
  curl_to_dest "https://github.com/IceCodeNew/rust-collection/releases/latest/download/dog" '/usr/local/bin/dog'

  # # shellcheck disable=SC2154
  # if [[ x"$(echo "${install_rsign:=yes}" | cut -c1)" = x'y' ]]; then
  #   curl_to_dest "https://github.com/IceCodeNew/rust-collection/releases/latest/download/rsign" '/usr/local/bin/rsign'
  # else
  #   sudo rm '/usr/local/bin/rsign'
  # fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_b3sum:=yes}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://github.com/IceCodeNew/rust-collection/releases/latest/download/b3sum" '/usr/local/bin/b3sum'
  else
    sudo rm '/usr/local/bin/b3sum'
  fi

  # # shellcheck disable=SC2154
  # if [[ x"$(echo "${install_age:=yes}" | cut -c1)" = x'y' ]]; then
  #   tmp_dir=$(mktemp -d)
  #   pushd "$tmp_dir" || exit 1
  #   if curl "https://github.com/IceCodeNew/go-collection/releases/latest/download/age-linux-amd64.tar.gz" | bsdtar -xf-; then
  #     sudo "$(type -P install)" -pvD './age' '/usr/local/bin/age'
  #     sudo "$(type -P install)" -pvD './age-keygen' '/usr/local/bin/age-keygen'
  #   fi
  #   popd || exit 1
  #   /bin/rm -rf "$tmp_dir"
  # else
  #   sudo rm '/usr/local/bin/age' '/usr/local/bin/age-keygen'
  # fi

  # shellcheck disable=SC2154
  if [[ x"$(echo "${install_overmind:=no}" | cut -c1)" = x'y' ]]; then
    curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/overmind" '/usr/local/bin/overmind'
  else
    sudo rm '/usr/local/bin/overmind'
  fi

  ################

  sudo xbps-install -Su &&
  sudo xbps-install -Su &&
  sudo xbps-install -y haproxy &&
  ln -s /etc/sv/haproxy /var/service/;
  curl_to_dest "https://github.com/IceCodeNew/haproxy_static/releases/latest/download/haproxy" '/usr/local/sbin/haproxy'

  if ! [[ -f /usr/bin/caddy ]] || date +%u | grep -qF '6'; then
    sudo xbps-install -Su &&
    sudo xbps-install -Su &&
    sudo xbps-install -y caddy &&
    ln -s /etc/sv/caddy /var/service/;
    # shellcheck disable=SC2154
    if [[ x"${donot_need_caddy_autorun:0:1}" = x'y' ]]; then
      sudo touch /etc/sv/caddy/down
    else
      sudo sed -i -E 's/^:80/:19600/' /etc/caddy/Caddyfile
    fi
    sudo rm '/usr/local/bin/caddy' '/usr/local/bin/xcaddy'
    curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/caddy" '/usr/local/sbin/caddy'

    # tmp_dir=$(mktemp -d)
    # pushd "$tmp_dir" || exit 1
    # if curl "https://github.com/tdewolff/minify/releases/latest/download/minify_linux_amd64.tar.gz" | bsdtar -xf-; then
    #   sudo "$(type -P install)" -pvD './minify' '/usr/bin/minify'
    #   sudo "$(type -P install)" -pvDm 644 './bash_completion' '/usr/share/bash-completion/completions/minify'
    # fi
    # popd || exit 1
    # /bin/rm -rf "$tmp_dir"
    # [[ -f /usr/share/caddy/index.html ]] && minify -o /usr/share/caddy/index.html /usr/share/caddy/index.html
  fi

  ################

  git config --global --unset url.https://hub.fastgit.org.insteadof
  git config --global --list
  exit 0
}

self_update
