FROM quay.io/icecodenew/golang:alpine AS base
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
# https://api.github.com/repos/slimm609/checksec.sh/releases/latest
ARG checksec_latest_tag_name=2.4.0
# https://api.github.com/repos/IceCodeNew/myrc/commits?per_page=1&path=.bashrc
ARG bashrc_latest_commit_hash=6f332268abdbb7ef6c264a84691127778e3c6ef2
# https://api.github.com/repos/rui314/mold/releases/latest
ARG mold_latest_tag_name='v1.0.3'
# https://api.github.com/repos/golang/go/tags?per_page=100&page=2
ARG golang_latest_tag_name=go1.15.4
ARG build_base_date='2020-12-03'
    # echo 'http://dl-cdn.alpinelinux.org/alpine/edge/main' > /etc/apk/repositories; \
    # echo 'http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories; \
RUN apk update; apk --no-progress --no-cache add \
    apk-tools autoconf automake bash binutils build-base ca-certificates coreutils curl dos2unix dpkg file gettext-tiny-dev git grep libarchive-tools libedit-dev libedit-static linux-headers lld musl musl-dev musl-libintl musl-utils ncurses ncurses-dev ncurses-static openssl perl pkgconf util-linux; \
    apk --no-progress --no-cache upgrade; \
    apk --no-progress --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ add \
    mold; \
    rm -rf /var/cache/apk/*; \
    update-alternatives --install /usr/local/bin/ld ld /usr/bin/ld.lld 100; \
    update-alternatives --auto ld; \
    curl -sSL4q --retry 5 --retry-delay 10 --retry-max-time 60 -o '/usr/bin/checksec' "https://raw.githubusercontent.com/slimm609/checksec.sh/${checksec_latest_tag_name}/checksec"; \
    chmod +x '/usr/bin/checksec'; \
    curl -sSL4q --retry 5 --retry-delay 10 --retry-max-time 60 -o '/root/.bashrc' "https://raw.githubusercontent.com/IceCodeNew/myrc/${bashrc_latest_commit_hash}/.bashrc"; \
    # go env -w GOPROXY=https://goproxy.cn,direct; \
    go env -w GOFLAGS="$GOFLAGS -buildmode=pie"; \
    go env -w CGO_CFLAGS="$CGO_CFLAGS -O2 -D_FORTIFY_SOURCE=2 -pipe -fexceptions -fstack-clash-protection -fstack-protector-strong -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all"; \
    go env -w CGO_CXXFLAGS="$CGO_CXXFLAGS -O2 -D_FORTIFY_SOURCE=2 -pipe -fexceptions -fstack-clash-protection -fstack-protector-strong -g -grecord-gcc-switches -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all"; \
    go env -w CGO_LDFLAGS="$CGO_LDFLAGS -fuse-ld=lld -Wl,-z,noexecstack,-z,relro,-z,now,-z,defs -Wl,--icf=all -static-pie"; \
    go env
