FROM quay.io/icecodenew/go-collection:build_base AS github-release
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/github-release/github-release/releases/latest
ARG github_release_latest_tag_name=v0.10.0
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -u -v github.com/github-release/github-release \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS nfpm
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/goreleaser/nfpm/commits?per_page=1
ARG nfpm_latest_commit_hash=36a847b2f85bb74b68ffd7997d27678160838ef6
WORKDIR '/go/src/nfpm'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GO111MODULE=on \
    && git_clone 'https://github.com/goreleaser/nfpm.git' '/go/src/nfpm' \
    && go mod download \
    && go build -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -o /go/bin/nfpm -v cmd/nfpm/main.go \
    && strip "/go/bin"/* \
    && /go/bin/nfpm --version \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS mmp-go
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/Qv2ray/mmp-go/commits?per_page=1
ARG mmp_go_latest_commit_hash=427f95274f185a0d906e06d1d2bafecb653d5475
WORKDIR '/go/src/mmp-go'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GO111MODULE=on \
    && git_clone 'https://github.com/Qv2ray/mmp-go.git' '/go/src/mmp-go' \
    && go build -trimpath -ldflags="-linkmode=external -X 'github.com/Qv2ray/mmp-go/config.Version=$(git describe --tags --long --always)' -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -o /go/bin/mmp-go -v . \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS caddy
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/caddyserver/caddy/commits?per_page=1
ARG CADDY_VERSION=124ba1ba714220322c65625012c564f89b75bfc9
# https://api.github.com/repos/caddy-dns/cloudflare/commits?per_page=1
ARG caddydns_cloudflare_latest_commit_hash=91cf700356a1cd0127bcc4e784dd50ed85794af5
# https://api.github.com/repos/caddyserver/jsonc-adapter/commits?per_page=1
ARG caddy_jsoncadapter_latest_commit_hash=825ee096306c2af9a28858f0db87fb982795cbea
# https://api.github.com/repos/caddyserver/nginx-adapter/commits?per_page=1
ARG caddy_nginxadapter_latest_commit_hash=50635ac4cf58f1a0f7d6f8a8ae059c3681fc4088
# https://api.github.com/repos/porech/caddy-maxmind-geolocation/commits?per_page=1
ARG caddy_geoip_latest_commit_hash=088c2173a3676a4956b220af619fa1c586ac7be6
# https://api.github.com/repos/mastercactapus/caddy2-proxyprotocol/commits?per_page=1
ARG caddy_proxyprotocol_latest_commit_hash=27e19628361b50aa252290d3982d2354dc6f93e5
# https://api.github.com/repos/mholt/caddy-l4/commits?per_page=1
ARG caddy_l4_latest_commit_hash=3cfcafe708834b071dae82a5f75224e55baef230
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -u -v github.com/caddyserver/xcaddy/cmd/xcaddy \
    && "/go/bin/xcaddy" build --output "/go/bin/caddy-with-geoip-proxyproto-and-l4" \
    --with github.com/caddy-dns/cloudflare@master \
    --with github.com/caddyserver/jsonc-adapter@master \
    --with github.com/caddyserver/nginx-adapter@master \
    --with github.com/porech/caddy-maxmind-geolocation@master \
    --with github.com/mastercactapus/caddy2-proxyprotocol@master \
    --with github.com/mholt/caddy-l4@master \
    && strip "/go/bin"/*
RUN GOOS=windows GOARCH=amd64 "/go/bin/xcaddy" build --output "/go/bin/caddy-with-geoip-proxyproto-and-l4.exe" \
    --with github.com/caddy-dns/cloudflare@master \
    --with github.com/caddyserver/jsonc-adapter@master \
    --with github.com/caddyserver/nginx-adapter@master \
    --with github.com/porech/caddy-maxmind-geolocation@master \
    --with github.com/mastercactapus/caddy2-proxyprotocol@master \
    --with github.com/mholt/caddy-l4@master \
    && rm -rf "/go/bin/xcaddy" "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS age
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/FiloSottile/age/commits?per_page=1
ARG age_latest_commit_hash=e08055f4e519032f67c9a6740d8e97ed53749c6d
WORKDIR '/go/src/age'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && git_clone 'https://github.com/FiloSottile/age.git' '/go/src/age' \
    && go build -trimpath -ldflags="-linkmode=external -X 'main.Version=$(git describe --tags --long --always) ($(go version))' -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -o /go/bin/ -v ./cmd/... \
    && strip "/go/bin"/* \
    && mv "/go/bin/age" "/go/bin/age-keygen" ./ \
    && bsdtar --no-xattrs -a -cf /go/bin/age-linux-amd64.tar.gz ./age ./age-keygen
RUN GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="-s -w -X 'main.Version=$(git describe --tags --long --always) ($(go version))' -buildid=" -o /go/bin/ -v ./cmd/... \
    && mv "/go/bin/age.exe" "/go/bin/age-keygen.exe" ./ \
    && bsdtar --no-xattrs -a -cf /go/bin/age-windows-amd64.zip ./age.exe ./age-keygen.exe \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS mtg
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/9seconds/mtg/commits?per_page=1
ARG mtg_latest_commit_hash=889ab6c227818e92383a286b0dafc95ccb603a85
WORKDIR '/go/src/mtg'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GO111MODULE=on \
    # && git_clone 'https://github.com/9seconds/mtg.git' --branch 'stable' '/go/src/mtg' \
    && git_clone 'https://github.com/9seconds/mtg.git' '/go/src/mtg' \
    && go build -trimpath -ldflags="-linkmode=external -X 'main.version=$(git describe --tags --long --always) ($(go version)) [$(date -Ru)]' -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -o /go/bin/mtg -v . \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS got
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/melbahja/got/releases/latest
ARG got_latest_tag_name=v0.5.0
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -u -v github.com/melbahja/got/cmd/got \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS shfmt
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/mvdan/sh/commits?per_page=1&path=go.mod
ARG shfmt_latest_commit_hash=e25bb494d7752cb31f7a41dc1369bf84048e3e49
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GO111MODULE=on \
    && go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -v mvdan.cc/sh/v3/cmd/shfmt \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS croc
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/schollz/croc/commits?per_page=1
ARG croc_latest_commit_hash=d922808fd8bfc97571bdc4ddd6d115d979bc9ba7
WORKDIR '/go/src/croc'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GO111MODULE=on \
    && git_clone 'https://github.com/schollz/croc.git' '/go/src/croc' \
    && go build -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -o /go/bin/croc -v . \
    && strip "/go/bin"/*
RUN GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="-s -w -buildid=" -o /go/bin/croc.exe -v . \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS mosdns
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/IrineSistiana/mosdns/commits?per_page=1
ARG mosdns_latest_commit_hash=da960f396224cc3476d7e1b757a007e4f6cc3a94
WORKDIR '/go/src/mosdns'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && git_clone 'https://github.com/IrineSistiana/mosdns.git' '/go/src/mosdns' \
    && go build -trimpath -ldflags="-linkmode=external -X main.version=$(git describe --tags --long --always) -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -o /go/bin/mosdns -v . \
    && strip "/go/bin"/*
RUN GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="-s -w -X main.version=$(git describe --tags --long --always) -buildid=" -o /go/bin/mosdns.exe -v . \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS go-shadowsocks2
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/shadowsocks/go-shadowsocks2/commits?per_page=1
ARG go_ss2_latest_commit_hash=acdbac05f5a55fd360edb1978c6a23c4988313a6
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -u -v github.com/shadowsocks/go-shadowsocks2 \
    && strip "/go/bin"/*
RUN GOOS=windows GOARCH=amd64 go get -trimpath -ldflags="-s -w -buildid=" -u -v github.com/shadowsocks/go-shadowsocks2 \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS frp
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/fatedier/frp/commits?per_page=1
ARG frp_latest_commit_hash=2a68c1152f4d20b07f112cdcd4ee84151a859a1f
WORKDIR '/go/src/frp'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GO111MODULE=on \
    && git_clone 'https://github.com/fatedier/frp.git' '/go/src/frp' \
    && go build -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -o /go/bin/frpc -v ./cmd/frpc \
    && go build -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -o /go/bin/frps -v ./cmd/frps \
    && strip "/go/bin"/*
RUN GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="-s -w -buildid=" -o /go/bin/frpc.exe -v ./cmd/frpc \
    && GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="-s -w -buildid=" -o /go/bin/frps.exe -v ./cmd/frps \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS nali
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/zu1k/nali/commits?per_page=1&path=go.mod
ARG nali_latest_commit_hash=10b36ef0701af9c1e85902ad681ac237019bc2f8
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -u -v github.com/zu1k/nali \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS dnslookup
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/ameshkov/dnslookup/commits?per_page=1
ARG dnslookup_latest_commit_hash=b0feb9b2afa3fed00bd19fd2d21935b4d666d75d
WORKDIR '/go/src/dnslookup'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GO111MODULE=on \
    && git_clone 'https://github.com/ameshkov/dnslookup.git' '/go/src/dnslookup' \
    && go build -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -o /go/bin/dnslookup -v . \
    && strip "/go/bin"/*
RUN GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="-s -w -buildid=" -o /go/bin/dnslookup.exe -v . \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS wgcf
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/ViRb3/wgcf/commits?per_page=1
ARG wgcf_latest_commit_hash=0c454559694de66e4e1e98ac3bc0b4885b6f73d3
WORKDIR '/go/src/wgcf'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && git_clone 'https://github.com/ViRb3/wgcf.git' '/go/src/wgcf' \
    && go build -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -o /go/bin/wgcf -v . \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS dive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/wagoodman/dive/commits?per_page=1
ARG dive_latest_tag_name=v0.10.0
ARG dive_latest_commit_hash=c7d121b3d72aeaded26d5731819afaf49b686df6
WORKDIR '/go/src/dive'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && git_clone 'https://github.com/wagoodman/dive.git' '/go/src/dive' \
    && go build -trimpath -ldflags="-linkmode=external -X main.version=${dive_latest_tag_name} -X 'main.commit=${dive_latest_commit_hash} -X main.buildTime=$(date -u --rfc-3339=seconds)' -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -o /go/bin/dive -v . \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS duf
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/muesli/duf/commits?per_page=1&path=go.mod
ARG duf_latest_commit_hash=c170db441864787fa6ea7a1f87487a8a74c39f4c
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -u -v github.com/muesli/duf \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS wuzz
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/asciimoo/wuzz/commits?per_page=1
ARG wuzz_latest_commit_hash=66176b6ef86c4879975d4075d784135d56ee3e82
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -u -v github.com/asciimoo/wuzz \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS httpstat
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/davecheney/httpstat/commits?per_page=1
ARG httpstat_latest_commit_hash=6fb037431c4fad2f5d0d173e931d48e78a495911
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -u -v github.com/davecheney/httpstat \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS chisel
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/jpillora/chisel/commits?per_page=1
ARG chisel_latest_commit_hash=60d62c6f20e93f4932703d2fccfec86af5e4161c
WORKDIR '/go/src/chisel'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && git_clone 'https://github.com/jpillora/chisel.git' '/go/src/chisel' \
    && go build -trimpath -ldflags="-linkmode=external -X github.com/jpillora/chisel/share.BuildVersion=$(git describe --tags --long --always) -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -o /go/bin/chisel -v . \
    && strip "/go/bin"/*
RUN GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="-s -w -X github.com/jpillora/chisel/share.BuildVersion=$(git describe --tags --long --always) -buildid=" -o /go/bin/chisel.exe -v . \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS cloudflarespeedtest
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/XIU2/CloudflareSpeedTest/commits?per_page=1
ARG cloudflarespeedtest_latest_commit_hash=9bab2944b14109487edbcb5849a00b224aeee87a
WORKDIR '/go/src/CloudflareSpeedTest'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && git_clone 'https://github.com/XIU2/CloudflareSpeedTest.git' '/go/src/CloudflareSpeedTest' \
    && go build -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -o /go/bin/CloudflareST -v . \
    && strip "/go/bin"/*
RUN GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="-s -w -buildid=" -o /go/bin/CloudflareST.exe -v . \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS netflix-verify
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/sjlleo/netflix-verify/commits?per_page=1
ARG netflix_verify_latest_commit_hash=d4ce663a1e06ccc18427cea268c03b587a1a6636
WORKDIR '/go/src/netflix-verify'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && git_clone 'https://github.com/sjlleo/netflix-verify.git' '/go/src/netflix-verify' \
    && go mod init \
    && go mod tidy \
    && go build -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -o /go/bin/nf -v . \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS piknik
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/jedisct1/piknik/commits?per_page=1
ARG piknik_latest_commit_hash=d6b7f77256f52cdc37941736f9de9c15c2248a10
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -u -v github.com/jedisct1/piknik \
    && strip "/go/bin"/*
RUN GOOS=windows GOARCH=amd64 go get -trimpath -ldflags="-s -w -buildid=" -u -v github.com/jedisct1/piknik \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS apk-file
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/genuinetools/apk-file/releases/latest
ARG apk_file_latest_tag_name=v0.3.6
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie' -buildid=" -u -v github.com/genuinetools/apk-file \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/alpine:latest AS collection
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
# date +%s
# ARG cachebust='1603527789'
ARG TZ='Asia/Taipei'
ENV DEFAULT_TZ ${TZ}
COPY --from=github-release /go/bin /go/bin/
COPY --from=nfpm /go/bin /go/bin/
COPY --from=mmp-go /go/bin /go/bin/
COPY --from=caddy /go/bin /go/bin/
COPY --from=age /go/bin /go/bin/
COPY --from=mtg /go/bin /go/bin/
COPY --from=got /go/bin /go/bin/
COPY --from=shfmt /go/bin /go/bin/
COPY --from=croc /go/bin /go/bin/
COPY --from=mosdns /go/bin /go/bin/
COPY --from=go-shadowsocks2 /go/bin /go/bin/
COPY --from=frp /go/bin /go/bin/
COPY --from=nali /go/bin /go/bin/
COPY --from=dnslookup /go/bin /go/bin/
COPY --from=wgcf /go/bin /go/bin/
COPY --from=dive /go/bin /go/bin/
COPY --from=duf /go/bin /go/bin/
COPY --from=wuzz /go/bin /go/bin/
COPY --from=httpstat /go/bin /go/bin/
COPY --from=chisel /go/bin /go/bin/
COPY --from=cloudflarespeedtest /go/bin /go/bin/
COPY --from=netflix-verify /go/bin /go/bin/
COPY --from=piknik /go/bin /go/bin/
COPY --from=apk-file /go/bin /go/bin/
RUN apk update; apk --no-progress --no-cache add \
    bash tzdata; \
    apk --no-progress --no-cache upgrade; \
    rm -rf /var/cache/apk/*; \
    cp -f /usr/share/zoneinfo/${DEFAULT_TZ} /etc/localtime; \
    mv /go/bin/windows_amd64/* /go/bin/
