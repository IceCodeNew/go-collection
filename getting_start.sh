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
    (
      tmp_dir=$(mktemp -d)
      cd "$tmp_dir" || exit 1
      if $(type -P curl) -LROJq --retry 5 --retry-delay 10 --retry-max-time 60 "$1"; then
        find . -maxdepth 1 -type f -print0 | xargs -0 -i -r -s 2000 "$(type -P install)" -pvDm 644 "{}" "$2"
      fi
      /bin/rm -rf "$tmp_dir"
    )
  fi
}

################

sudo mkdir -p /usr/local/bin
go_collection_tag_name=$(curl -sSL -H "Accept: application/vnd.github.v3+json" \
  'https://api.github.com/repos/icecodenew/go-collection/releases/latest' |
  grep 'tag_name' | cut -d\" -f4)
sudo rm '/usr/local/bin/croc'
curl "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/croc" -o '/usr/local/bin/croc' &&
  sudo chmod +x '/usr/local/bin/croc'
sudo rm '/etc/bash_completion.d/croc'
curl -sS 'https://github.com/schollz/croc/raw/master/src/install/bash_autocomplete' -o '/etc/bash_completion.d/croc'

sudo rm '/usr/local/bin/shfmt'
curl "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/shfmt" -o '/usr/local/bin/shfmt' &&
  sudo chmod +x '/usr/local/bin/shfmt'

sudo rm '/usr/local/bin/github-release'
curl "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/github-release" -o '/usr/local/bin/github-release' &&
  sudo chmod +x '/usr/local/bin/github-release'

sudo rm '/usr/local/bin/go-shadowsocks2'
curl "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/go-shadowsocks2" -o '/usr/local/bin/go-shadowsocks2' &&
  sudo chmod +x '/usr/local/bin/go-shadowsocks2'

sudo rm '/usr/local/bin/nali'
curl "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/nali" -o '/usr/local/bin/nali' &&
  sudo chmod +x '/usr/local/bin/nali'

curl -o 'caddy_linux_amd64.deb' \
  "$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
    'https://api.github.com/repos/caddyserver/caddy/releases/latest' |
    grep 'browser_download_url' | grep 'linux_amd64.deb' | cut -d\" -f4)"
sudo gdebi -n 'caddy_linux_amd64.deb' && rm 'caddy_linux_amd64.deb'
sudo systemctl disable --now caddy
sudo rm '/usr/bin/caddy' '/usr/local/bin/caddy' '/usr/local/bin/xcaddy' '/usr/local/bin/caddy-maxmind-geolocation'
curl "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/caddy-maxmind-geolocation" -o '/usr/bin/caddy' &&
  sudo chmod +x '/usr/bin/caddy'

sudo apt-get update
sudo apt-get -y install minify
(
  tmp_dir=$(mktemp -d)
  cd "$tmp_dir" || exit 1
  curl \
    "$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
      'https://api.github.com/repos/tdewolff/minify/releases/latest' |
      grep 'browser_download_url' | grep 'linux_amd64.tar.gz' | cut -d\" -f4)" |
    bsdtar -xf-
  /bin/mv -f './minify' '/usr/bin/minify'
  /bin/mv -f './bash_completion' '/etc/bash_completion.d/minify'
  /bin/rm -rf "$tmp_dir"
)
checksec --dir=/usr/local/bin
checksec --file=/usr/bin/caddy
checksec --file=/usr/bin/minify
