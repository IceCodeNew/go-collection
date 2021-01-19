FROM quay.io/icecodenew/go-collection:build_base AS github-release
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/github-release/github-release/releases/latest
ARG github_release_latest_tag_name='v0.9.0'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie'" -u -v github.com/github-release/github-release \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/root/go/pkg" "/root/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS got
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/melbahja/got/releases/latest
ARG got_latest_tag_name='v0.5.0'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie'" -u -v github.com/melbahja/got/cmd/got \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/root/go/pkg" "/root/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS duf
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/muesli/duf/commits?per_page=1&path=go.mod
ARG duf_latest_commit_hash='02161643e0fb8530aa13bfbcfefad79bd8ffdf3c'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie'" -u -v github.com/muesli/duf \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/root/go/pkg" "/root/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS shfmt
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/mvdan/sh/commits?per_page=1&path=go.mod
ARG shfmt_latest_commit_hash='c5ff78f0d68e4067c7218775c2ff4cef6a1d23fc'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && GO111MODULE=on go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie'" -v mvdan.cc/sh/v3/cmd/shfmt \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/root/go/pkg" "/root/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS croc
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/schollz/croc/commits?per_page=1&path=go.mod
ARG croc_latest_commit_hash='0bafce5efe88bbf39f6ec05cb27ae7242478f43b'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && GO111MODULE=on go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie'" -v github.com/schollz/croc/v8 \
    && strip "/go/bin"/*
RUN GO111MODULE=on GOOS=windows GOARCH=amd64 go get -trimpath -v github.com/schollz/croc/v8 \
    && rm -rf "/root/.cache/go-build" "/root/go/pkg" "/root/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS mosdns
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/IrineSistiana/mosdns/commits?per_page=1
ARG mosdns_latest_commit_hash='5ee263d0b686404c93016351076851861a854eb4'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && git_clone 'https://github.com/IrineSistiana/mosdns.git' '/go/src/mosdns' \
    && cd /go/src/mosdns || exit 1 \
    && go build -trimpath -ldflags="-linkmode=external -X main.version=$(git describe --tags --long --always) -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie'" -o /go/bin/mosdns -v . \
    && strip "/go/bin"/*
WORKDIR /go/src/mosdns
RUN GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="-X main.version=$(git describe --tags --long --always)" -o /go/bin/mosdns.exe -v . \
    && rm -rf "/root/.cache/go-build" "/root/go/pkg" "/root/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS go-shadowsocks2
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/shadowsocks/go-shadowsocks2/commits?per_page=1
ARG go_ss2_latest_commit_hash='75d43273f5a50373be2a70e91372a3a6afc53a54'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie'" -u -v github.com/shadowsocks/go-shadowsocks2 \
    && strip "/go/bin"/*
RUN GOOS=windows GOARCH=amd64 go get -trimpath -u -v github.com/shadowsocks/go-shadowsocks2 \
    && rm -rf "/root/.cache/go-build" "/root/go/pkg" "/root/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS frp
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/fatedier/frp/commits?per_page=1
ARG frp_latest_commit_hash='72595b2da84f7eaceac735dbe8fd45ff9668d92c'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GO111MODULE=on \
    && git_clone 'https://github.com/fatedier/frp.git' '/go/src/frp' \
    && cd /go/src/frp || exit 1 \
    && go build -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie'" -o /go/bin/frpc -v ./cmd/frpc \
    && go build -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie'" -o /go/bin/frps -v ./cmd/frps \
    && strip "/go/bin"/*
WORKDIR /go/src/frp
RUN GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o /go/bin/frpc.exe -v ./cmd/frpc \
    && GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o /go/bin/frps.exe -v ./cmd/frps \
    && rm -rf "/root/.cache/go-build" "/root/go/pkg" "/root/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS chisel
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/jpillora/chisel/commits?per_page=1
ARG chisel_latest_commit_hash='20921074b5827147b1a24d4ef4f5cba174856430'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && git_clone 'https://github.com/jpillora/chisel.git' '/go/src/chisel' \
    && cd /go/src/chisel || exit 1 \
    && go build -trimpath -ldflags="-linkmode=external -X github.com/jpillora/chisel/share.BuildVersion=$(git describe --tags --long --always) -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie'" -o /go/bin/chisel -v . \
    && strip "/go/bin"/*
WORKDIR /go/src/chisel
RUN GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="-X github.com/jpillora/chisel/share.BuildVersion=$(git describe --tags --long --always)" -o /go/bin/chisel.exe -v . \
    && rm -rf "/root/.cache/go-build" "/root/go/pkg" "/root/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS nali
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/zu1k/nali/commits?per_page=1&path=go.mod
ARG nali_latest_commit_hash='9b0aa92bd4a677a9e61f27be5e1cce30b8040fc9'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie'" -u -v github.com/zu1k/nali \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/root/go/pkg" "/root/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS apk-file
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/genuinetools/apk-file/releases/latest
ARG apk_file_latest_tag_name='v0.3.6'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie'" -u -v github.com/genuinetools/apk-file \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/root/go/pkg" "/root/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS caddy
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/caddyserver/caddy/commits?per_page=1
ARG caddy_latest_commit_hash='b6e96d6f4a55f96ccbb69f112822f0a923942246'
# https://api.github.com/repos/porech/caddy-maxmind-geolocation/commits?per_page=1
ARG caddy_geoip_latest_commit_hash='d500cc3ca64b734da42e0f0446003f437c915ac8'
# https://api.github.com/repos/mholt/caddy-l4/commits?per_page=1
ARG caddy_l4_latest_commit_hash='bf3444c4665a1d7e0df58c2f4e9fbafc2aa1ed29'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie'" -u -v github.com/caddyserver/xcaddy/cmd/xcaddy \
    && "/go/bin/xcaddy" build --output "/go/bin/caddy-with-geoip-and-l4" \
    --with github.com/porech/caddy-maxmind-geolocation \
    --with github.com/mholt/caddy-l4 \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/root/go/pkg" "/root/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS wuzz
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/asciimoo/wuzz/commits?per_page=1
ARG wuzz_latest_commit_hash='0935ebdf55d223abbf0fd10cb8f0f9c0a323ccb7'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie'" -u -v github.com/asciimoo/wuzz \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/root/go/pkg" "/root/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS httpstat
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/davecheney/httpstat/commits?per_page=1
ARG httpstat_latest_commit_hash='48531c3e2d3e4cd51f04c33002898d81d61e0c93'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie'" -u -v github.com/davecheney/httpstat \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/root/go/pkg" "/root/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS piknik
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/jedisct1/piknik/commits?per_page=1
ARG piknik_latest_commit_hash='00ee34cd9fe6c6c3fca2ba954c93e2a3b129f45c'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go get -trimpath -ldflags="-linkmode=external -extldflags '-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie'" -u -v github.com/jedisct1/piknik \
    && strip "/go/bin"/*
RUN GOOS=windows GOARCH=amd64 go get -trimpath -u -v github.com/jedisct1/piknik \
    && rm -rf "/root/.cache/go-build" "/root/go/pkg" "/root/go/src" || exit 0

FROM quay.io/icecodenew/alpine:edge AS collection
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
# date +%s
# ARG cachebust='1603527789'
ARG TZ='Asia/Taipei'
ENV DEFAULT_TZ ${TZ}
COPY --from=github-release /go/bin /go/bin/
COPY --from=got /go/bin /go/bin/
COPY --from=duf /go/bin /go/bin/
COPY --from=shfmt /go/bin /go/bin/
COPY --from=croc /go/bin /go/bin/
COPY --from=mosdns /go/bin /go/bin/
COPY --from=go-shadowsocks2 /go/bin /go/bin/
COPY --from=frp /go/bin /go/bin/
COPY --from=chisel /go/bin /go/bin/
COPY --from=nali /go/bin /go/bin/
COPY --from=apk-file /go/bin /go/bin/
COPY --from=caddy /go/bin /go/bin/
COPY --from=wuzz /go/bin /go/bin/
COPY --from=httpstat /go/bin /go/bin/
COPY --from=piknik /go/bin /go/bin/
RUN apk update; apk --no-progress --no-cache add \
    bash tzdata; \
    apk --no-progress --no-cache upgrade; \
    rm -rf /var/cache/apk/*; \
    cp -f /usr/share/zoneinfo/${DEFAULT_TZ} /etc/localtime; \
    mv /go/bin/windows_amd64/* /go/bin/
