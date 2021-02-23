#!/usr/bin/env bash

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
geo_country="$(curl 'https://api.myip.la/en?json' | jq . | grep country_code | cut -d'"' -f4)"
[[ x"$geo_country" = x'CN' ]] && curl_path="$(type -P curl) --retry-connrefused"
curl() {
  $curl_path -LRq --retry 5 --retry-delay 10 --retry-max-time 60 "$@"
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
    $(type -P git) clone -j "$(nproc)" --no-tags --shallow-submodules --recurse-submodules --depth 1 --single-branch "$@"
  else
    $(type -P git) -c "$GIT_PROXY" clone -j "$(nproc)" --no-tags --shallow-submodules --recurse-submodules --depth 1 --single-branch "$@"
  fi
}

################

# sudo mkdir -p /usr/local/bin /usr/local/sbin
sudo mkdir -p /usr/local/bin

tmp_dir=$(mktemp -d)
pushd "$tmp_dir" || exit 1
curl -o 'ripgrep_amd64.deb' \
  "$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/BurntSushi/ripgrep/releases/latest' |
    grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'amd64.deb$')" \
&& sudo dpkg -i 'ripgrep_amd64.deb' && apt-mark hold ripgrep
popd || exit 1
/bin/rm -rf "$tmp_dir"
dirs -c
curl_to_dest "https://github.com/IceCodeNew/rust-collection/releases/latest/download/ripgrep" '/usr/bin/rg'

tmp_dir=$(mktemp -d)
pushd "$tmp_dir" || exit 1
curl -o 'bat-musl_amd64.deb' \
  "$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/sharkdp/bat/releases/latest' |
    grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'musl.+amd64.deb$')" \
&& sudo dpkg -i 'bat-musl_amd64.deb'
git_clone https://github.com/eth-p/bat-extras.git \
&& cd bat-extras \
&& chmod +x build.sh \
&& ./build.sh --install --no-manuals
popd || exit 1
/bin/rm -rf "$tmp_dir"
dirs -c
curl_to_dest "https://github.com/IceCodeNew/rust-collection/releases/latest/download/bat" '/usr/bin/bat'

tmp_dir=$(mktemp -d)
pushd "$tmp_dir" || exit 1
curl -o 'fd-musl_amd64.deb' \
  "$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/sharkdp/fd/releases/latest' |
    grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'musl.+amd64.deb$')" \
&& sudo dpkg -i 'fd-musl_amd64.deb'
popd || exit 1
/bin/rm -rf "$tmp_dir"
dirs -c
curl_to_dest "https://github.com/IceCodeNew/rust-collection/releases/latest/download/fd" '/usr/bin/fd'

tmp_dir=$(mktemp -d)
pushd "$tmp_dir" || exit 1
curl -o 'hexyl-musl_amd64.deb' \
  "$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/sharkdp/hexyl/releases/latest' |
    grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'musl.+amd64.deb$')" \
&& sudo dpkg -i 'hexyl-musl_amd64.deb'
popd || exit 1
/bin/rm -rf "$tmp_dir"
dirs -c
curl_to_dest "https://github.com/IceCodeNew/rust-collection/releases/latest/download/hexyl" '/usr/bin/hexyl'

# shellcheck disable=SC2154
if [[ x"${install_hugo_extended:0:1}" = x'y' ]] && date +%u | grep -qF '7'; then
  tmp_dir=$(mktemp -d)
  pushd "$tmp_dir" || exit 1
  curl -o 'hugo_extended_Linux-64bit.deb' \
    "$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/gohugoio/hugo/releases/latest' |
      grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'extended.+linux-64bit.deb$')" \
  && sudo dpkg -i 'hugo_extended_Linux-64bit.deb'
  popd || exit 1
  /bin/rm -rf "$tmp_dir"
  dirs -c
fi

################

curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/croc" '/usr/local/bin/croc'
curl_to_dest 'https://raw.githubusercontent.com/schollz/croc/master/src/install/bash_autocomplete' '/etc/bash_completion.d/croc' \
  && sudo chmod -x '/etc/bash_completion.d/croc'

curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/shfmt" '/usr/local/bin/shfmt'

# shellcheck disable=SC2154
if [[ x"$(echo "${install_github_release:=no}" | cut -c1)" = x'y' ]]; then
  curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/github-release" '/usr/local/bin/github-release'
else
  rm '/usr/local/bin/github-release'
fi

# shellcheck disable=SC2154
if [[ x"$(echo "${install_nfpm:=no}" | cut -c1)" = x'y' ]]; then
  curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/nfpm" '/usr/local/bin/nfpm'
else
  rm '/usr/local/bin/nfpm'
fi

# shellcheck disable=SC2154
if [[ x"$(echo "${install_mosdns:=no}" | cut -c1)" = x'y' ]]; then
  curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/mosdns" '/usr/local/bin/mosdns'
else
  rm '/usr/local/bin/mosdns'
fi

# shellcheck disable=SC2154
if [[ x"$(echo "${install_shadowsocks:=yes}" | cut -c1)" = x'y' ]]; then
  curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/go-shadowsocks2" '/usr/local/bin/go-shadowsocks2'
  curl_to_dest "https://github.com/IceCodeNew/v2ray-plugin/releases/latest/download/v2ray-plugin_linux_amd64" '/usr/local/bin/v2ray-plugin'

  tmp_dir=$(mktemp -d)
  pushd "$tmp_dir" || exit 1
  if grep -qw avx2 /proc/cpuinfo && grep -qw fma /proc/cpuinfo; then
    export ss_rust_file_name='ss-rust-linux-gnu-x64.tar.xz';
  else
    export ss_rust_file_name='4limit-mem-server-only-ss-rust-linux-gnu-x64.tar.gz';
  fi;
  if curl "https://github.com/IceCodeNew/rust-collection/releases/latest/download/${ss_rust_file_name}" | bsdtar -xf-; then
    [[ x"$ss_rust_file_name" = x'ss-rust-linux-gnu-x64.tar.xz' ]] && \
    sudo "$(type -P install)" -pvD './sslocal' '/usr/local/bin/sslocal' && \
    sudo "$(type -P install)" -pvD './ssurl' '/usr/local/bin/ssurl';
    sudo "$(type -P install)" -pvD './ssmanager' '/usr/local/bin/ssmanager'
    sudo "$(type -P install)" -pvD './ssserver' '/usr/local/bin/ssserver';
  fi;
  popd || exit 1
  /bin/rm -rf "$tmp_dir"
  dirs -c
else
  rm '/usr/local/bin/go-shadowsocks2' '/usr/local/bin/sslocal' '/usr/local/bin/ssmanager' '/usr/local/bin/ssserver' '/usr/local/bin/ssurl'
fi

# shellcheck disable=SC2154
if [[ x"$(echo "${install_frp:=no}" | cut -c1)" = x'y' ]]; then
  curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/frpc" '/usr/local/bin/frpc'
  curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/frps" '/usr/local/bin/frps'
else
  rm '/usr/local/bin/frpc' '/usr/local/bin/frps'
fi

# shellcheck disable=SC2154
if [[ x"$(echo "${install_chisel:=no}" | cut -c1)" = x'y' ]]; then
  curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/chisel" '/usr/local/bin/chisel'
else
  rm '/usr/local/bin/chisel'
fi

curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/got" '/usr/local/bin/got'

curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/duf" '/usr/local/bin/duf'

curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/dnslookup" '/usr/local/bin/dnslookup'

dog_latest_tag_name="$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/ogham/dog/tags?per_page=100' |
      grep 'name' | cut -d'"' -f4 | grep -vE 'alpha|beta|rc|test|week|pre' |
      sort -rV | head -1)"
curl "https://github.com/ogham/dog/releases/download/${dog_latest_tag_name}/dog-${dog_latest_tag_name}-x86_64-unknown-linux-gnu.zip" | bsdtar -xf- -P -C /usr/local
curl_to_dest "https://github.com/IceCodeNew/rust-collection/releases/latest/download/dog" '/usr/local/bin/dog'

# shellcheck disable=SC2154
if [[ x"$(echo "${install_websocat:=no}" | cut -c1)" = x'y' ]]; then
  curl_to_dest "https://github.com/IceCodeNew/rust-collection/releases/latest/download/websocat" '/usr/local/bin/websocat'
else
  rm '/usr/local/bin/websocat'
fi

# shellcheck disable=SC2154
if [[ x"$(echo "${install_just:=no}" | cut -c1)" = x'y' ]]; then
  curl_to_dest "https://github.com/IceCodeNew/rust-collection/releases/latest/download/just" '/usr/local/bin/just'
else
  rm '/usr/local/bin/just'
fi

# shellcheck disable=SC2154
if [[ x"$(echo "${install_desed:=no}" | cut -c1)" = x'y' ]]; then
  curl_to_dest "https://github.com/IceCodeNew/rust-collection/releases/latest/download/desed" '/usr/local/bin/desed'
else
  rm '/usr/local/bin/desed'
fi

# shellcheck disable=SC2154
if [[ x"$(echo "${install_fnm:=yes}" | cut -c1)" = x'y' ]]; then
  curl_to_dest "https://github.com/IceCodeNew/rust-collection/releases/latest/download/fnm" '/usr/local/bin/fnm'
else
  rm '/usr/local/bin/fnm'
fi

# shellcheck disable=SC2154
if [[ x"$(echo "${install_rsign:=yes}" | cut -c1)" = x'y' ]]; then
  curl_to_dest "https://github.com/IceCodeNew/rust-collection/releases/latest/download/rsign" '/usr/local/bin/rsign'
else
  rm '/usr/local/bin/rsign'
fi

# shellcheck disable=SC2154
if [[ x"$(echo "${install_b3sum:=yes}" | cut -c1)" = x'y' ]]; then
  curl_to_dest "https://github.com/IceCodeNew/rust-collection/releases/latest/download/b3sum" '/usr/local/bin/b3sum'
else
  rm '/usr/local/bin/b3sum'
fi

# shellcheck disable=SC2154
if [[ x"$(echo "${install_nali:=yes}" | cut -c1)" = x'y' ]]; then
  curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/nali" '/usr/local/bin/nali'
else
  rm '/usr/local/bin/nali'
fi

[[ -n "$(type -P apk)" ]] && curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/apk-file" '/usr/local/bin/apk-file'

# shellcheck disable=SC2154
if [[ x"$(echo "${install_mtg:=no}" | cut -c1)" = x'y' ]]; then
  curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/mtg" '/usr/local/bin/mtg'
else
  rm '/usr/local/bin/mtg'
fi

# shellcheck disable=SC2154
if [[ x"$(echo "${install_wuzz:=no}" | cut -c1)" = x'y' ]]; then
  curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/wuzz" '/usr/local/bin/wuzz'
else
  rm '/usr/local/bin/wuzz'
fi

# shellcheck disable=SC2154
if [[ x"$(echo "${install_httpstat:=no}" | cut -c1)" = x'y' ]]; then
  curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/httpstat" '/usr/local/bin/httpstat'
else
  rm '/usr/local/bin/httpstat'
fi

# shellcheck disable=SC2154
if [[ x"$(echo "${install_wgcf:=no}" | cut -c1)" = x'y' ]]; then
  curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/wgcf" '/usr/local/bin/wgcf'
else
  rm '/usr/local/bin/wgcf'
fi

# shellcheck disable=SC2154
if [[ x"$(echo "${install_mmp_go:=no}" | cut -c1)" = x'y' ]]; then
  curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/mmp-go" '/usr/local/bin/mmp-go'
else
  rm '/usr/local/bin/mmp-go'
fi

# shellcheck disable=SC2154
if [[ x"$(echo "${install_cloudflarest:=yes}" | cut -c1)" = x'y' ]]; then
  curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/CloudflareST" '/usr/local/bin/CloudflareST'
else
  rm '/usr/local/bin/CloudflareST'
fi

# shellcheck disable=SC2154
if [[ x"$(echo "${install_piknik:=no}" | cut -c1)" = x'y' ]]; then
  curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/piknik" '/usr/local/bin/piknik'
else
  rm '/usr/local/bin/piknik'
fi

# shellcheck disable=SC2154
if [[ x"$(echo "${install_boringtun:=no}" | cut -c1)" = x'y' ]]; then
  curl_to_dest "https://github.com/IceCodeNew/rust-collection/releases/latest/download/boringtun-linux-musl-x64" '/usr/local/bin/boringtun'
else
  rm '/usr/local/bin/boringtun'
fi

# shellcheck disable=SC2154
if [[ x"$(echo "${install_cfnts:=no}" | cut -c1)" = x'y' ]]; then
  curl_to_dest "https://github.com/IceCodeNew/rust-collection/releases/latest/download/cfnts" '/usr/local/bin/cfnts'
else
  rm '/usr/local/bin/cfnts'
fi

################

# curl_to_dest "https://github.com/IceCodeNew/haproxy_static/releases/latest/download/haproxy" '/usr/local/sbin/haproxy'
tmp_dir=$(mktemp -d)
pushd "$tmp_dir" || exit 1
curl -o 'haproxy_amd64.deb' \
  "$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/IceCodeNew/haproxy_static/releases/latest' |
    grep 'browser_download_url' | cut -d'"' -f4 | grep -E '[0-9]\/haproxy_.+?amd64.deb$')" \
&& curl -o 'jemalloc_amd64.deb' \
  "$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/IceCodeNew/haproxy_static/releases/latest' |
    grep 'browser_download_url' | cut -d'"' -f4 | grep -E '[0-9]\/jemalloc_.+?amd64.deb$')" \
&& sudo dpkg -i 'jemalloc_amd64.deb' && sudo dpkg -i 'haproxy_amd64.deb'
curl -LROJ 'https://github.com/IceCodeNew/haproxy_static/releases/latest/download/haproxy.service' &&
sudo /bin/mv -f './haproxy.service' '/etc/systemd/system/haproxy.service' &&
sudo systemctl daemon-reload
echo 'systemctl enable --now haproxy'
popd || exit 1
/bin/rm -rf "$tmp_dir"
dirs -c

if ! [[ -f /usr/bin/caddy ]] || date +%u | grep -qF '6'; then
  tmp_dir=$(mktemp -d)
  pushd "$tmp_dir" || exit 1
  curl -o 'caddy_linux_amd64.deb' \
    "$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/caddyserver/caddy/releases/latest' |
      grep 'browser_download_url' | grep 'linux_amd64.deb' | cut -d'"' -f4)" \
  && sudo dpkg -i 'caddy_linux_amd64.deb' && rm 'caddy_linux_amd64.deb'
  popd || exit 1
  /bin/rm -rf "$tmp_dir"
  dirs -c
  # shellcheck disable=SC2154
  if [[ x"${donot_need_caddy_autorun:0:1}" = x'y' ]]; then
    sudo systemctl disable --now caddy
  else
    sudo sed -i -E 's/^:80/:19600/' /etc/caddy/Caddyfile
  fi
  sudo rm '/usr/local/bin/caddy' '/usr/local/bin/xcaddy'
  curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/caddy" '/usr/bin/caddy'

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
fi

################

checksec --dir=/usr/local/bin
checksec --listfile=<(echo -e '/usr/bin/bat\n/usr/bin/fd\n/usr/bin/hexyl\n/usr/bin/caddy\n/usr/bin/minify\n/usr/local/sbin/haproxy')
