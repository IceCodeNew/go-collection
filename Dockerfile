FROM alpine:edge AS base
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
ARG checksec_latest_commit_hash='f3e56af80f7b24ebfdde5679b4a862d739636b11'
ARG bashrc_latest_commit_hash='dffed49d1d1472f1b22b3736a5c191d74213efaa'
RUN apk update; apk --no-progress --no-cache add \
    apk-tools autoconf automake bash binutils build-base ca-certificates coreutils curl dos2unix dpkg gettext-tiny-dev git go grep libarchive-tools libedit-dev libedit-static linux-headers lld musl-dev musl-libintl musl-utils ncurses ncurses-dev ncurses-static openssl perl pkgconf util-linux; \
    apk --no-progress --no-cache upgrade; \
    rm -rf /var/cache/apk/*; \
    update-alternatives --install /usr/local/bin/ld ld /usr/bin/lld 100; \
    update-alternatives --auto ld; \
    curl -sSL4q --retry 5 --retry-delay 10 --retry-max-time 60 -o '/usr/bin/checksec' "https://raw.githubusercontent.com/slimm609/checksec.sh/${checksec_latest_commit_hash}/checksec"; \
    chmod +x '/usr/bin/checksec'; \
    curl -sSL4q --retry 5 --retry-delay 10 --retry-max-time 60 -o '/root/.bashrc' "https://raw.githubusercontent.com/IceCodeNew/myrc/${bashrc_latest_commit_hash}/.bashrc"; \
    # go env -w GOPROXY=https://goproxy.cn,direct; \
    go env -w GOFLAGS="$GOFLAGS -buildmode=pie"; \
    go env -w CGO_CFLAGS="$CGO_CFLAGS -O2 -D_FORTIFY_SOURCE=2 -pipe -fexceptions -fstack-clash-protection -fstack-protector-strong -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all"; \
    go env -w CGO_CXXFLAGS="$CGO_CXXFLAGS -O2 -D_FORTIFY_SOURCE=2 -pipe -fexceptions -fstack-clash-protection -fstack-protector-strong -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all"; \
    go env -w CGO_LDFLAGS="$CGO_LDFLAGS -fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie"

FROM base AS github-release
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN source "/root/.bashrc" \
    && go get -ldflags='-linkmode=external -extldflags "-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie"' -u -v github.com/github-release/github-release \
    && strip "/root/go/bin"/* \
    && rm -r "/root/.cache/go-build" "/root/go/pkg" "/root/go/src"

FROM base AS got
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN source "/root/.bashrc" \
    && go get -ldflags='-linkmode=external -extldflags "-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie"' -u -v github.com/melbahja/got/cmd/got \
    && strip "/root/go/bin"/* \
    && rm -r "/root/.cache/go-build" "/root/go/pkg" "/root/go/src"

FROM base AS shfmt
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN source "/root/.bashrc" \
    && GO111MODULE=on go get -ldflags='-linkmode=external -extldflags "-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie"' -v mvdan.cc/sh/v3/cmd/shfmt \
    && strip "/root/go/bin"/* \
    && rm -r "/root/.cache/go-build" "/root/go/pkg" "/root/go/src"

FROM base AS croc
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN source "/root/.bashrc" \
    && GO111MODULE=on go get -ldflags='-linkmode=external -extldflags "-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie"' -v github.com/schollz/croc/v8 \
    && strip "/root/go/bin"/* \
    && rm -r "/root/.cache/go-build" "/root/go/pkg" "/root/go/src"

FROM base AS go-shadowsocks2
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN source "/root/.bashrc" \
    && go get -ldflags='-linkmode=external -extldflags "-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie"' -u -v github.com/shadowsocks/go-shadowsocks2 \
    && strip "/root/go/bin"/* \
    && rm -r "/root/.cache/go-build" "/root/go/pkg" "/root/go/src"

FROM base AS nali
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN source "/root/.bashrc" \
    && go get -ldflags='-linkmode=external -extldflags "-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie"' -u -v github.com/zu1k/nali \
    && strip "/root/go/bin"/* \
    && rm -r "/root/.cache/go-build" "/root/go/pkg" "/root/go/src"

FROM base AS caddy
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN source "/root/.bashrc" \
    && go get -ldflags='-linkmode=external -extldflags "-fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie"' -u -v github.com/caddyserver/xcaddy/cmd/xcaddy \
    && "/root/go/bin/xcaddy" build --output "/root/go/bin/caddy-maxmind-geolocation" \
    --with github.com/porech/caddy-maxmind-geolocation \
    && strip "/root/go/bin"/* \
    && rm -r "/root/.cache/go-build" "/root/go/pkg" "/root/go/src"

FROM alpine:edge AS collection
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
ARG TZ='Asia/Taipei'
ENV DEFAULT_TZ ${TZ}
COPY --from=github-release /root/go/bin/github-release /root/go/bin/github-release
COPY --from=got /root/go/bin/got /root/go/bin/got
COPY --from=shfmt /root/go/bin/shfmt /root/go/bin/shfmt
COPY --from=croc /root/go/bin/croc /root/go/bin/croc
COPY --from=go-shadowsocks2 /root/go/bin/go-shadowsocks2 /root/go/bin/go-shadowsocks2
COPY --from=nali /root/go/bin/nali /root/go/bin/nali
COPY --from=caddy /root/go/bin/caddy-maxmind-geolocation /root/go/bin/caddy-maxmind-geolocation
RUN apk update; apk --no-progress --no-cache add \
    bash tzdata; \
    apk --no-progress --no-cache upgrade; \
    rm -rf /var/cache/apk/*; \
    cp -f /usr/share/zoneinfo/${DEFAULT_TZ} /etc/localtime
