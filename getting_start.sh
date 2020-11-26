#!/bin/bash

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
  cd "$@" || exit 1
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
      find . -maxdepth 1 -type f -print0 | xargs -0 -i -r -s 2000 sudo "$(type -P install)" -pvD "{}" "$2"
    fi
    popd || exit 1
    /bin/rm -rf "$tmp_dir"
    dirs -c
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
    grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'amd64.deb$')"
sudo dpkg -i 'ripgrep_amd64.deb' && apt-mark hold ripgrep
popd || exit 1
/bin/rm -rf "$tmp_dir"
dirs -c

tmp_dir=$(mktemp -d)
pushd "$tmp_dir" || exit 1
curl -o 'bat-musl_amd64.deb' \
  "$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/sharkdp/bat/releases/latest' |
    grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'musl.+amd64.deb$')"
sudo dpkg -i 'bat-musl_amd64.deb'
popd || exit 1
/bin/rm -rf "$tmp_dir"
dirs -c
curl_to_dest "https://github.com/IceCodeNew/rust-collection/releases/latest/download/bat" '/usr/bin/bat'

tmp_dir=$(mktemp -d)
pushd "$tmp_dir" || exit 1
curl -o 'fd-musl_amd64.deb' \
  "$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/sharkdp/fd/releases/latest' |
    grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'musl.+amd64.deb$')"
sudo dpkg -i 'fd-musl_amd64.deb'
popd || exit 1
/bin/rm -rf "$tmp_dir"
dirs -c
curl_to_dest "https://github.com/IceCodeNew/rust-collection/releases/latest/download/fd" '/usr/bin/fd'

tmp_dir=$(mktemp -d)
pushd "$tmp_dir" || exit 1
curl -o 'hexyl-musl_amd64.deb' \
  "$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/sharkdp/hexyl/releases/latest' |
    grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'musl.+amd64.deb$')"
sudo dpkg -i 'hexyl-musl_amd64.deb'
popd || exit 1
/bin/rm -rf "$tmp_dir"
dirs -c
curl_to_dest "https://github.com/IceCodeNew/rust-collection/releases/latest/download/hexyl" '/usr/bin/hexyl'

# tmp_dir=$(mktemp -d)
# pushd "$tmp_dir" || exit 1
# curl -o 'diskus-musl_amd64.deb' \
#   "$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
#     'https://api.github.com/repos/sharkdp/diskus/releases/latest' |
#     grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'musl.+amd64.deb$')"
# sudo dpkg -i 'diskus-musl_amd64.deb'
# popd || exit 1
# /bin/rm -rf "$tmp_dir"
# dirs -c
# curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/diskus" '/usr/bin/diskus'

# shellcheck disable=SC2154
if [[ x"${need_hugo_extended:0:1}" = x'y' ]] && date +%u | grep -qF '7'; then
  tmp_dir=$(mktemp -d)
  pushd "$tmp_dir" || exit 1
  curl -o 'hugo_extended_Linux-64bit.deb' \
    "$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/gohugoio/hugo/releases/latest' |
      grep 'browser_download_url' | cut -d'"' -f4 | grep -iE 'extended.+linux-64bit.deb$')"
  sudo dpkg -i 'hugo_extended_Linux-64bit.deb'
  popd || exit 1
  /bin/rm -rf "$tmp_dir"
  dirs -c
fi

################

curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/croc" '/usr/local/bin/croc'
curl_to_dest 'https://raw.githubusercontent.com/schollz/croc/master/src/install/bash_autocomplete' '/etc/bash_completion.d/croc' &&
  sudo chmod -x '/etc/bash_completion.d/croc'

curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/shfmt" '/usr/local/bin/shfmt'

curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/github-release" '/usr/local/bin/github-release'

curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/mos-chinadns" '/usr/local/bin/mos-chinadns'

curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/go-shadowsocks2" '/usr/local/bin/go-shadowsocks2'

curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/chisel" '/usr/local/bin/chisel'

curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/got" '/usr/local/bin/got'

curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/duf" '/usr/local/bin/duf'

curl_to_dest "https://github.com/IceCodeNew/rust-collection/releases/latest/download/fnm" '/usr/local/bin/fnm'

curl_to_dest "https://github.com/IceCodeNew/rust-collection/releases/latest/download/b3sum" '/usr/local/bin/b3sum'

curl_to_dest "https://github.com/IceCodeNew/v2ray-plugin/releases/latest/download/v2ray-plugin_linux_amd64" '/usr/local/bin/v2ray-plugin'

curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/nali" '/usr/local/bin/nali'

[[ -n "$(type -P apk)" ]] && curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/apk-file" '/usr/local/bin/apk-file'

curl_to_dest "https://github.com/IceCodeNew/rust-collection/releases/latest/download/boringtun" '/usr/local/bin/boringtun'

################

# curl_to_dest "https://github.com/IceCodeNew/haproxy_static/releases/latest/download/haproxy" '/usr/local/sbin/haproxy'
tmp_dir=$(mktemp -d)
pushd "$tmp_dir" || exit 1
curl -o 'haproxy_amd64.deb' \
  "$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/IceCodeNew/haproxy_static/releases/latest' |
    grep 'browser_download_url' | cut -d'"' -f4 | grep -E '[0-9]\/haproxy_.+?amd64.deb$')"
curl -o 'jemalloc_amd64.deb' \
  "$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/IceCodeNew/haproxy_static/releases/latest' |
    grep 'browser_download_url' | cut -d'"' -f4 | grep -E '[0-9]\/jemalloc_.+?amd64.deb$')"
sudo dpkg -i 'jemalloc_amd64.deb' && sudo dpkg -i 'haproxy_amd64.deb'
popd || exit 1
/bin/rm -rf "$tmp_dir"
dirs -c

if ! [[ -f /usr/bin/caddy ]] || date +%u | grep -qF '6'; then
  tmp_dir=$(mktemp -d)
  pushd "$tmp_dir" || exit 1
  curl -o 'caddy_linux_amd64.deb' \
    "$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/caddyserver/caddy/releases/latest' |
      grep 'browser_download_url' | grep 'linux_amd64.deb' | cut -d'"' -f4)"
  sudo dpkg -i 'caddy_linux_amd64.deb' && rm 'caddy_linux_amd64.deb'
  popd || exit 1
  /bin/rm -rf "$tmp_dir"
  dirs -c
  # shellcheck disable=SC2154
  if [[ x"${donot_need_caddy_autorun:0:1}" = x'y' ]]; then
    sudo systemctl disable --now caddy
  else
    sudo sed -i -E 's/^:80/:19600/' /etc/caddy/Caddyfile
  fi
  sudo rm '/usr/local/bin/caddy' '/usr/local/bin/xcaddy' '/usr/local/bin/caddy-maxmind-geolocation'
  curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/latest/download/caddy-maxmind-geolocation" '/usr/bin/caddy'
fi

sudo apt-get update
sudo apt-get -y install minify
tmp_dir=$(mktemp -d)
pushd "$tmp_dir" || exit 1
curl "https://github.com/tdewolff/minify/releases/latest/download/minify_linux_amd64.tar.gz" | bsdtar -xf-
sudo "$(type -P install)" -pvD './minify' '/usr/bin/minify'
sudo "$(type -P install)" -pvDm 644 './bash_completion' '/etc/bash_completion.d/minify'
popd || exit 1
/bin/rm -rf "$tmp_dir"
dirs -c
[[ -f /usr/share/caddy/index.html ]] && minify -o /usr/share/caddy/index.html /usr/share/caddy/index.html

################

checksec --dir=/usr/local/bin
checksec --listfile=<(echo -e '/usr/bin/bat\n/usr/bin/fd\n/usr/bin/hexyl\n/usr/bin/caddy\n/usr/bin/minify')
