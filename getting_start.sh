#!/bin/bash

sudo mkdir -p /usr/local/bin
go_collection_tag_name=$(curl -sSL -H "Accept: application/vnd.github.v3+json" \
  'https://api.github.com/repos/icecodenew/go-collection/releases/latest' |
  grep 'tag_name' | cut -d\" -f4)
sudo rm '/usr/local/bin/croc';
curl -LR4q "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/croc" > \
  '/usr/local/bin/croc' && sudo chmod +x '/usr/local/bin/croc'
curl -sSLR4q 'https://github.com/schollz/croc/raw/master/src/install/bash_autocomplete' > '/etc/bash_completion.d/croc'
sudo rm '/usr/local/bin/shfmt';
curl -LR4q "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/shfmt" > \
  '/usr/local/bin/shfmt' && sudo chmod +x '/usr/local/bin/shfmt'

sudo rm '/usr/local/bin/github-release';
curl -LR4q "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/github-release" > \
  '/usr/local/bin/github-release' && sudo chmod +x '/usr/local/bin/github-release'
sudo rm '/usr/local/bin/go-shadowsocks2';
curl -LR4q "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/go-shadowsocks2" > \
  '/usr/local/bin/go-shadowsocks2' && sudo chmod +x '/usr/local/bin/go-shadowsocks2'
sudo rm '/usr/local/bin/xcaddy';
curl -LR4q "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/xcaddy" > \
  '/usr/local/bin/xcaddy' && sudo chmod +x '/usr/local/bin/xcaddy'
sudo rm '/usr/local/bin/nali';
curl -LR4q "https://github.com/IceCodeNew/go-collection/releases/download/${go_collection_tag_name}/nali" > \
  '/usr/local/bin/nali' && sudo chmod +x '/usr/local/bin/nali'
# checksec --dir=/usr/local/bin
