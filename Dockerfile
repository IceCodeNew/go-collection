FROM alpine:edge AS base
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN apk update; apk --no-cache add \
    apk-tools autoconf automake bash bash-completion binutils build-base ca-certificates coreutils curl dos2unix dpkg gettext-tiny-dev git go grep libarchive-tools libedit-dev libedit-static linux-headers lld musl-dev musl-libintl musl-utils ncurses ncurses-dev ncurses-static openssl perl pkgconf util-linux; \
    apk --no-cache upgrade; \
    update-alternatives --install /usr/local/bin/ld ld /usr/bin/lld 100; \
    update-alternatives --auto ld; \
    curl -sSL4q --retry 5 --retry-delay 10 --retry-max-time 60 -o '/usr/bin/checksec' 'https://raw.githubusercontent.com/slimm609/checksec.sh/master/checksec'; \
    chmod +x '/usr/bin/checksec'; \
    curl -sSL4q --retry 5 --retry-delay 10 --retry-max-time 60 -o '/root/.bashrc' 'https://raw.githubusercontent.com/IceCodeNew/myrc/main/.bashrc'; \
    mkdir -p "/root/go-collection"

FROM base AS go_get
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN source "/root/.bashrc" \
    && go env -w GOFLAGS="$GOFLAGS -buildmode=pie" \
    && go env -w CGO_CFLAGS="$CGO_CFLAGS -O2 -D_FORTIFY_SOURCE=2 -pipe -fexceptions -fstack-clash-protection -fstack-protector-strong -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all" \
    && go env -w CGO_CXXFLAGS="$CGO_CXXFLAGS -O2 -D_FORTIFY_SOURCE=2 -pipe -fexceptions -fstack-clash-protection -fstack-protector-strong -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all" \
    && go env -w CGO_LDFLAGS="$CGO_LDFLAGS -fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie" \
    # && go env -w GO111MODULE=on \
    # && go env -w GOPROXY=https://goproxy.cn,direct \
    && go get -ldflags='-linkmode=external -extldflags "-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie"' -u -v github.com/github-release/github-release \
    && go get -ldflags='-linkmode=external -extldflags "-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie"' -u -v github.com/shadowsocks/go-shadowsocks2 \
    && go get -ldflags='-linkmode=external -extldflags "-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie"' -u -v github.com/melbahja/got/cmd/got \
    && go get -ldflags='-linkmode=external -extldflags "-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie"' -u -v github.com/caddyserver/xcaddy/cmd/xcaddy \
    && go get -ldflags='-linkmode=external -extldflags "-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie"' -u -v github.com/zu1k/nali \
    && GO111MODULE=on go get -ldflags='-linkmode=external -extldflags "-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie"' -v mvdan.cc/sh/v3/cmd/shfmt \
    && GO111MODULE=on go get -ldflags='-linkmode=external -extldflags "-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie"' -v github.com/schollz/croc/v8 \
    && "/root/go/bin/xcaddy" build --output "/root/go/bin/caddy-maxmind-geolocation" \
    --with github.com/porech/caddy-maxmind-geolocation \
    && strip "/root/go/bin"/* \
    && rm -r "/root/.cache/go-build" "/root/go/pkg" "/root/go/src"
