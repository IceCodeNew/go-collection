#!/bin/bash

sudo mkdir -p /usr/local/bin
go_collection_tag_name=$(curl -sSL -H "Accept: application/vnd.github.v3+json" \
  'https://api.github.com/repos/icecodenew/go-collection/releases/latest' |
  grep 'tag_name' | cut -d\" -f4)
sudo rm '/usr/local/bin/croc';
curl -LR4q "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/croc" -o '/usr/local/bin/croc' && \
sudo chmod +x '/usr/local/bin/croc'
sudo rm '/etc/bash_completion.d/croc';
curl -sSLR4q 'https://github.com/schollz/croc/raw/master/src/install/bash_autocomplete' -o '/etc/bash_completion.d/croc'

sudo rm '/usr/local/bin/shfmt';
curl -LR4q "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/shfmt" -o '/usr/local/bin/shfmt' && \
sudo chmod +x '/usr/local/bin/shfmt'

sudo rm '/usr/local/bin/github-release';
curl -LR4q "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/github-release" -o '/usr/local/bin/github-release' && \
sudo chmod +x '/usr/local/bin/github-release'

sudo rm '/usr/local/bin/go-shadowsocks2';
curl -LR4q "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/go-shadowsocks2" -o '/usr/local/bin/go-shadowsocks2' && \
sudo chmod +x '/usr/local/bin/go-shadowsocks2'

sudo rm '/usr/local/bin/nali';
curl -LR4q "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/nali" -o '/usr/local/bin/nali' && \
sudo chmod +x '/usr/local/bin/nali'

curl -LR4q -o 'caddy_linux_amd64.deb' \
"$(curl -sSL -H 'Accept: application/vnd.github.v3+json' \
       'https://api.github.com/repos/caddyserver/caddy/releases/latest' |
       grep 'browser_download_url' | grep 'linux_amd64.deb' | cut -d\" -f4)"
sudo gdebi -n 'caddy_linux_amd64.deb' && rm 'caddy_linux_amd64.deb'
sudo systemctl disable --now caddy
sudo rm '/usr/bin/caddy' '/usr/local/bin/caddy' '/usr/local/bin/xcaddy' '/usr/local/bin/caddy-maxmind-geolocation';
curl -LR4q "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/caddy-maxmind-geolocation" -o '/usr/bin/caddy' && \
sudo chmod +x '/usr/bin/caddy'

sudo apt-get update
sudo apt-get -y install minify
(
tmp_dir=$(mktemp -d)
cd "$tmp_dir" || exit 1
curl -LR4q \
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
