FROM quay.io/icecodenew/go-collection:build_base AS github-release
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/github-release/github-release/releases/latest
ARG github_release_latest_tag_name=v0.10.0
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GOAMD64=v2 \
    && go install -trimpath -ldflags="-s -w -buildid=" -buildmode=pie -v github.com/github-release/github-release@latest \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS go-mmproxy
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/path-network/go-mmproxy/commits?per_page=1
ARG go-mmproxy_latest_commit_hash='7197f99c984ec67018cc1ee4dfaacbd47a8e5c8c'
WORKDIR '/go/src/go-mmproxy'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GO111MODULE=on \
    && go env -w GOAMD64=v2 \
    && git_clone 'https://github.com/path-network/go-mmproxy.git' '/go/src/go-mmproxy' \
    && go mod download \
    && go build -trimpath -ldflags="-s -w -buildid=" -buildmode=pie -o /go/bin/go-mmproxy -v . \
    && strip "/go/bin"/* \
    && /go/bin/go-mmproxy --version \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS nfpm
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/goreleaser/nfpm/commits?per_page=1
ARG nfpm_latest_commit_hash=b207f76f23e542ce74de42a66c4b81bc3a774d5a
WORKDIR '/go/src/nfpm'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GO111MODULE=on \
    && go env -w GOAMD64=v2 \
    && git_clone 'https://github.com/goreleaser/nfpm.git' '/go/src/nfpm' \
    && go mod download \
    && go build -trimpath -ldflags="-s -w -buildid=" -buildmode=pie -o /go/bin/nfpm -v cmd/nfpm/main.go \
    && strip "/go/bin"/* \
    && /go/bin/nfpm --version \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS mmp-go
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/Qv2ray/mmp-go/commits?per_page=1
ARG mmp_go_latest_commit_hash=4937afb470f3a2aae2dccf403ccd2ca6cac6bd99
WORKDIR '/go/src/mmp-go'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GO111MODULE=on \
    && go env -w GOAMD64=v2 \
    && git_clone 'https://github.com/Qv2ray/mmp-go.git' '/go/src/mmp-go' \
    && go build -trimpath -ldflags="-X 'github.com/Qv2ray/mmp-go/config.Version=$(git describe --tags --long --always)' -s -w -buildid=" -buildmode=pie -o /go/bin/mmp-go -v . \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS caddy
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
# https://api.github.com/repos/caddyserver/caddy/commits?per_page=1
ARG CADDY_VERSION=eaaa2e5872ef9e845a50c6aade36676c0ecfe2e2
# https://api.github.com/repos/caddy-dns/cloudflare/commits?per_page=1
ARG caddydns_cloudflare_latest_commit_hash=89f16b99c18ef49c8bb470a82f895bce01cbaece
# https://api.github.com/repos/caddyserver/jsonc-adapter/commits?per_page=1
ARG caddy_jsoncadapter_latest_commit_hash=825ee096306c2af9a28858f0db87fb982795cbea
# https://api.github.com/repos/mholt/caddy-l4/commits?per_page=1
ARG caddy_l4_latest_commit_hash=16b3b200e1828ec0ad7cfdf88bf67b3a0c80cda0
RUN apk --no-progress --no-cache add \
    binutils \
    && go env -w GOFLAGS="$GOFLAGS -buildmode=pie" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GOAMD64=v2 \
    && go env -w GO111MODULE='on' \
    && go install -trimpath -v github.com/caddyserver/xcaddy/cmd/xcaddy@latest \
    && /go/bin/xcaddy build \
    --output "/go/bin/caddy-with-cfdns-l4" \
    --with github.com/caddy-dns/cloudflare@master \
    --with github.com/caddyserver/jsonc-adapter=github.com/IceCodeNew/jsonc-adapter@v0.0.0-20240223101055-68e1734195e4 \
    --with github.com/mholt/caddy-l4@master \
    && strip "/go/bin"/* \
### Build for windows
    && GOOS=windows GOARCH=amd64 /go/bin/xcaddy build \
    --output "/go/bin/caddy-with-cfdns-l4.exe" \
    --with github.com/caddy-dns/cloudflare@master \
    --with github.com/caddyserver/jsonc-adapter=github.com/IceCodeNew/jsonc-adapter@v0.0.0-20240223101055-68e1734195e4 \
    --with github.com/mholt/caddy-l4@master \
    && rm -rf "/go/bin/xcaddy" "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS age
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/FiloSottile/age/commits?per_page=1
ARG age_latest_commit_hash=176e245b3cb3ada322c21eef0bce166dc5a5e4c7
WORKDIR '/go/src/age'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GOAMD64=v2 \
    && git_clone 'https://github.com/FiloSottile/age.git' '/go/src/age' \
    && go build -trimpath -ldflags="-X 'main.Version=$(git describe --tags --long --always) ($(go version))' -s -w -buildid=" -buildmode=pie -o /go/bin/ -v ./cmd/... \
    && strip "/go/bin"/* \
    && mv "/go/bin/age" "/go/bin/age-keygen" ./ \
    && bsdtar --no-xattrs -a -cf /go/bin/age-linux-amd64.tar.gz ./age ./age-keygen
RUN GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="-X 'main.Version=$(git describe --tags --long --always) ($(go version))' -s -w -buildid=" -buildmode=pie -o /go/bin/ -v ./cmd/... \
    && mv "/go/bin/age.exe" "/go/bin/age-keygen.exe" ./ \
    && bsdtar --no-xattrs -a -cf /go/bin/age-windows-amd64.zip ./age.exe ./age-keygen.exe \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS mtg
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/9seconds/mtg/commits?per_page=1
ARG mtg_latest_commit_hash=e68d0c7da53b266019d33644b902e8872c84fe32
WORKDIR '/go/src/mtg'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GO111MODULE=on \
    && go env -w GOAMD64=v2 \
    # && git_clone 'https://github.com/9seconds/mtg.git' --branch 'stable' '/go/src/mtg' \
    && git_clone 'https://github.com/9seconds/mtg.git' '/go/src/mtg' \
    && go build -trimpath -ldflags="-X 'main.version=$(git describe --tags --long --always) ($(go version)) [$(date -Ru)]' -s -w -buildid=" -buildmode=pie -o /go/bin/mtg -v . \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS pget
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/Code-Hex/pget/releases/latest
ARG pget_latest_tag_name=v0.2.1
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GOAMD64=v2 \
    && go install -trimpath -ldflags="-s -w -buildid=" -buildmode=pie -v github.com/Code-Hex/pget/cmd/pget@latest \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS shfmt
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/mvdan/sh/commits?per_page=1&path=go.mod
ARG shfmt_latest_commit_hash=fa9120ac5107891dcd1a57443a3ff7e6d07c400c
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GO111MODULE=on \
    && go env -w GOAMD64=v2 \
    && go install -trimpath -ldflags="-s -w -buildid=" -buildmode=pie -v mvdan.cc/sh/v3/cmd/shfmt@latest \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS croc
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/schollz/croc/commits?per_page=1
ARG croc_latest_commit_hash=30684fb383678edb81769b1df57dc9ca053b1206
WORKDIR '/go/src/croc'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GO111MODULE=on \
    && go env -w GOAMD64=v2 \
    && git_clone 'https://github.com/schollz/croc.git' '/go/src/croc' \
    && go build -trimpath -ldflags="-s -w -buildid=" -buildmode=pie -o /go/bin/croc -v . \
    && strip "/go/bin"/*
RUN GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="-s -w -buildid=" -buildmode=pie -o /go/bin/croc.exe -v . \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS shadowsocks-go
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/database64128/shadowsocks-go/commits?per_page=1
ARG shadowsocks_go_latest_commit_hash=e1fe9ea737409e4d71efaa65e3caefa42a8fc188
WORKDIR '/go/src/shadowsocks-go'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GOAMD64=v2 \
    && git_clone 'https://github.com/database64128/shadowsocks-go.git' '/go/src/shadowsocks-go' \
    && go build -trimpath -ldflags="-s -w -buildid=" -buildmode=pie -o /go/bin/ -v ./cmd/shadowsocks-go \
    && strip "/go/bin"/*
RUN GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="-s -w -buildid=" -buildmode=pie -o /go/bin/ -v ./cmd/shadowsocks-go \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS nali
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/zu1k/nali/commits?per_page=1&path=go.mod
ARG nali_latest_commit_hash=559ba291a7fabd796f79e0476b8759be9754be63
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GOAMD64=v2 \
    && go install -trimpath -ldflags="-s -w -buildid=" -buildmode=pie -v github.com/zu1k/nali@latest \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS wgcf
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/ViRb3/wgcf/commits?per_page=1
ARG wgcf_latest_commit_hash=a7d2983c54d8330dfd3d976f757e6c8b017e0712
WORKDIR '/go/src/wgcf'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GOAMD64=v2 \
    && git_clone 'https://github.com/ViRb3/wgcf.git' '/go/src/wgcf' \
    && go build -trimpath -ldflags="-s -w -buildid=" -buildmode=pie -o /go/bin/wgcf -v . \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS dive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/wagoodman/dive/commits?per_page=1
ARG dive_latest_tag_name=v0.12.0
ARG dive_latest_commit_hash=925cdd86482edec42185794620a1e616b79bbee5
WORKDIR '/go/src/dive'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GOAMD64=v2 \
    && git_clone 'https://github.com/wagoodman/dive.git' '/go/src/dive' \
    && go build -trimpath -ldflags="-X 'main.version=${dive_latest_tag_name}' -X 'main.commit=${dive_latest_commit_hash}' -X 'main.buildTime=$(date -u --rfc-3339=seconds)' -s -w -buildid=" -buildmode=pie -o /go/bin/dive -v . \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS duf
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/muesli/duf/commits?per_page=1&path=go.mod
ARG duf_latest_commit_hash=22abf3127a094c7710ac9c9fcffa3dadf22197f9
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GOAMD64=v2 \
    && go install -trimpath -ldflags="-s -w -buildid=" -buildmode=pie -v github.com/muesli/duf@latest \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS wuzz
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/asciimoo/wuzz/commits?per_page=1
ARG wuzz_latest_commit_hash=66176b6ef86c4879975d4075d784135d56ee3e82
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GOAMD64=v2 \
    && go install -trimpath -ldflags="-s -w -buildid=" -buildmode=pie -v github.com/asciimoo/wuzz@latest \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS httpstat
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/davecheney/httpstat/commits?per_page=1
ARG httpstat_latest_commit_hash=930bf5a8fc7df0a18f6f156f4b235fbeac769675
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GOAMD64=v2 \
    && go install -trimpath -ldflags="-s -w -buildid=" -buildmode=pie -v github.com/davecheney/httpstat@latest \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

# FROM quay.io/icecodenew/go-collection:build_base AS chisel
# SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# # https://api.github.com/repos/jpillora/chisel/commits?per_page=1
# ARG chisel_latest_commit_hash='20921074b5827147b1a24d4ef4f5cba174856430'
# WORKDIR '/go/src/chisel'
# RUN source "/root/.bashrc" \
#     && go env -w CGO_ENABLED=0 \
#     && go env -w GOAMD64=v2 \
#     && git_clone 'https://github.com/jpillora/chisel.git' '/go/src/chisel' \
#     && go build -trimpath -ldflags="-X 'github.com/jpillora/chisel/share.BuildVersion=$(git describe --tags --long --always)' -s -w -buildid=" -buildmode=pie -o /go/bin/chisel -v . \
#     && strip "/go/bin"/*
# RUN GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="-s -w -X 'github.com/jpillora/chisel/share.BuildVersion=$(git describe --tags --long --always)' -buildid=" -buildmode=pie -o /go/bin/chisel.exe -v . \
#     && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS cloudflarespeedtest
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/XIU2/CloudflareSpeedTest/commits?per_page=1
ARG cloudflarespeedtest_latest_commit_hash=66c0923bf7d8db8ccbefb93c72cd2ea7930d97a1
WORKDIR '/go/src/CloudflareSpeedTest'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GOAMD64=v2 \
    && git_clone 'https://github.com/XIU2/CloudflareSpeedTest.git' '/go/src/CloudflareSpeedTest' \
    && go build -trimpath -ldflags="-s -w -buildid=" -buildmode=pie -o /go/bin/CloudflareST -v . \
    && strip "/go/bin"/*
RUN GOOS=windows GOARCH=amd64 go build -trimpath -ldflags="-s -w -buildid=" -buildmode=pie -o /go/bin/CloudflareST.exe -v . \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS netflix-verify
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/sjlleo/netflix-verify/commits?per_page=1
ARG netflix_verify_latest_commit_hash=5823408c49c46f3a9ff5235750daa8c2134af835
WORKDIR '/go/src/netflix-verify'
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GOAMD64=v2 \
    && git_clone 'https://github.com/sjlleo/netflix-verify.git' '/go/src/netflix-verify' \
    && go mod init \
    && go mod tidy \
    && go build -trimpath -ldflags="-s -w -buildid=" -buildmode=pie -o /go/bin/nf -v . \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS piknik
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/jedisct1/piknik/commits?per_page=1
ARG piknik_latest_commit_hash=b5871a8628622a64c28852715fae1c9ced93355a
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GOAMD64=v2 \
    && go install -trimpath -ldflags="-s -w -buildid=" -buildmode=pie -v github.com/jedisct1/piknik@latest \
    && strip "/go/bin"/*
RUN GOOS=windows GOARCH=amd64 go install -trimpath -ldflags="-s -w -buildid=" -buildmode=pie -v github.com/jedisct1/piknik@latest \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM quay.io/icecodenew/go-collection:build_base AS apk-file
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# https://api.github.com/repos/genuinetools/apk-file/releases/latest
ARG apk_file_latest_tag_name=v0.3.6
RUN source "/root/.bashrc" \
    && go env -w CGO_ENABLED=0 \
    && go env -w GOAMD64=v2 \
    && go install -trimpath -ldflags="-s -w -buildid=" -buildmode=pie -v github.com/genuinetools/apk-file@latest \
    && strip "/go/bin"/* \
    && rm -rf "/root/.cache/go-build" "/go/pkg" "/go/src" || exit 0

FROM scratch AS assets
COPY --from=github-release /go/bin /go/bin/
COPY --from=go-mmproxy /go/bin /go/bin/
COPY --from=nfpm /go/bin /go/bin/
COPY --from=mmp-go /go/bin /go/bin/
COPY --from=caddy /go/bin /go/bin/
COPY --from=age /go/bin /go/bin/
COPY --from=mtg /go/bin /go/bin/
COPY --from=pget /go/bin /go/bin/
COPY --from=shfmt /go/bin /go/bin/
COPY --from=croc /go/bin /go/bin/
COPY --from=shadowsocks-go /go/bin /go/bin/
COPY --from=nali /go/bin /go/bin/
COPY --from=wgcf /go/bin /go/bin/
COPY --from=dive /go/bin /go/bin/
COPY --from=duf /go/bin /go/bin/
COPY --from=wuzz /go/bin /go/bin/
COPY --from=httpstat /go/bin /go/bin/
# COPY --from=chisel /go/bin /go/bin/
COPY --from=cloudflarespeedtest /go/bin /go/bin/
COPY --from=netflix-verify /go/bin /go/bin/
COPY --from=piknik /go/bin /go/bin/
COPY --from=apk-file /go/bin /go/bin/

FROM quay.io/icecodenew/alpine:latest AS collection
COPY --from=assets /go/bin/* /go/bin/windows_amd64/* /go/bin/
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
# date +%s
# ARG cachebust='1603527789'
ARG TZ='Asia/Taipei'
ENV DEFAULT_TZ ${TZ}
RUN apk update; apk --no-progress --no-cache add \
    bash tzdata; \
    apk --no-progress --no-cache upgrade; \
    rm -rf /var/cache/apk/*; \
    cp -f /usr/share/zoneinfo/${DEFAULT_TZ} /etc/localtime
