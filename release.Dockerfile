# syntax = docker/dockerfile:1.0-experimental
FROM quay.io/icecodenew/go-collection:latest AS go_upload
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /go/bin
# import secret:
RUN --mount=type=secret,id=GIT_AUTH_TOKEN,dst=/tmp/secret_token export GITHUB_TOKEN="$(cat /tmp/secret_token)" \
    && export tag_name="$(TZ=':Asia/Taipei' date +%F-%H-%M-%S)" \
    && "/go/bin/github-release" release \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "$tag_name"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "croc" \
    --file "/go/bin/croc"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "croc.exe" \
    --file "/go/bin/croc.exe"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "github-release" \
    --file "/go/bin/github-release"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "nfpm" \
    --file "/go/bin/nfpm"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "caddy" \
    --file "/go/bin/caddy-with-geoip-proxyproto-and-l4"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "mtg" \
    --file "/go/bin/mtg"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "mosdns" \
    --file "/go/bin/mosdns"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "mosdns.exe" \
    --file "/go/bin/mosdns.exe"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "go-shadowsocks2" \
    --file "/go/bin/go-shadowsocks2"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "go-shadowsocks2.exe" \
    --file "/go/bin/go-shadowsocks2.exe"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "frpc" \
    --file "/go/bin/frpc"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "frpc.exe" \
    --file "/go/bin/frpc.exe"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "frps" \
    --file "/go/bin/frps"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "frps.exe" \
    --file "/go/bin/frps.exe"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "chisel" \
    --file "/go/bin/chisel"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "chisel.exe" \
    --file "/go/bin/chisel.exe"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "got" \
    --file "/go/bin/got"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "duf" \
    --file "/go/bin/duf"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "nali" \
    --file "/go/bin/nali"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "dnslookup" \
    --file "/go/bin/dnslookup"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "dnslookup.exe" \
    --file "/go/bin/dnslookup.exe"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "shfmt" \
    --file "/go/bin/shfmt"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "wuzz" \
    --file "/go/bin/wuzz"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "httpstat" \
    --file "/go/bin/httpstat"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "wgcf" \
    --file "/go/bin/wgcf"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "mmp-go" \
    --file "/go/bin/mmp-go"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "CloudflareST" \
    --file "/go/bin/CloudflareST"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "CloudflareST.exe" \
    --file "/go/bin/CloudflareST.exe"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "piknik" \
    --file "/go/bin/piknik"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "piknik.exe" \
    --file "/go/bin/piknik.exe"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "apk-file" \
    --file "/go/bin/apk-file"
