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

curl() {
  $(type -P curl) -LRq --retry 5 --retry-delay 10 --retry-max-time 60 "$@"
}
curl_to_dest() {
  if [[ $# -eq 2 ]]; then
    tmp_dir=$(mktemp -d)
    pushd "$tmp_dir" || exit 1
    if $(type -P curl) -LROJq --retry 5 --retry-delay 10 --retry-max-time 60 "$1"; then
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
go_collection_tag_name=$(curl -sSL -H "Accept: application/vnd.github.v3+json" \
  'https://api.github.com/repos/IceCodeNew/go-collection/releases/latest' |
  grep 'tag_name' | cut -d\" -f4)
v2ray_plugin_url=$(curl -sSL -H "Accept: application/vnd.github.v3+json" \
  'https://api.github.com/repos/IceCodeNew/v2ray-plugin/releases/latest' |
  grep 'browser_download_url' | grep -i 'linux_amd64' | cut -d\" -f4)
# haproxy_url=$(curl -sSL -H "Accept: application/vnd.github.v3+json" \
#   'https://api.github.com/repos/IceCodeNew/haproxy_static/releases/latest' |
#   grep 'browser_download_url' | cut -d\" -f4 | grep -iE 'haproxy$')

curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/croc" '/usr/local/bin/croc'
curl_to_dest 'https://raw.githubusercontent.com/schollz/croc/master/src/install/bash_autocomplete' '/etc/bash_completion.d/croc' &&
  sudo chmod -x '/etc/bash_completion.d/croc'

curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/shfmt" '/usr/local/bin/shfmt'

curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/github-release" '/usr/local/bin/github-release'

curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/go-shadowsocks2" '/usr/local/bin/go-shadowsocks2'

curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/got" '/usr/local/bin/got'

curl_to_dest "$v2ray_plugin_url" '/usr/local/bin/v2ray-plugin'

# curl_to_dest "$haproxy_url" '/usr/local/sbin/haproxy'

curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/nali" '/usr/local/bin/nali'

tmp_dir=$(mktemp -d)
pushd "$tmp_dir" || exit 1
curl -o 'caddy_linux_amd64.deb' \
  "$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/caddyserver/caddy/releases/latest' |
    grep 'browser_download_url' | grep 'linux_amd64.deb' | cut -d\" -f4)"
sudo gdebi -n 'caddy_linux_amd64.deb' && rm 'caddy_linux_amd64.deb'
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
curl_to_dest "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/caddy-maxmind-geolocation" '/usr/bin/caddy'

sudo apt-get update
sudo apt-get -y install minify
tmp_dir=$(mktemp -d)
pushd "$tmp_dir" || exit 1
curl \
  "$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/tdewolff/minify/releases/latest' |
    grep 'browser_download_url' | grep 'linux_amd64.tar.gz' | cut -d\" -f4)" |
  bsdtar -xf-
sudo "$(type -P install)" -pvD './minify' '/usr/bin/minify'
sudo "$(type -P install)" -pvDm 644 './bash_completion' '/etc/bash_completion.d/minify'
popd || exit 1
/bin/rm -rf "$tmp_dir"
dirs -c
[[ -f /usr/share/caddy/index.html ]] && minify -o /usr/share/caddy/index.html /usr/share/caddy/index.html


checksec --dir=/usr/local/bin
checksec --file=/usr/bin/caddy
checksec --file=/usr/bin/minify
