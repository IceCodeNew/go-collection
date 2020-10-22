# syntax = docker/dockerfile:1.0-experimental
FROM quay.io/icecodenew/go-collection:latest AS go_upload
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR "/root/go/bin"
# import secret:
RUN --mount=type=secret,id=GIT_AUTH_TOKEN,dst=/root/go/bin/secret_token export GITHUB_TOKEN="$(cat /root/go/bin/secret_token)" \
    && "/root/go/bin/github-release" release \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$(TZ=':Asia/Taipei' date -I)" \
    --name "$(TZ=':Asia/Taipei' date -I)"; \
    "/root/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$(TZ=':Asia/Taipei' date -I)" \
    --name "croc" \
    --file "/root/go/bin/croc"; \
    "/root/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$(TZ=':Asia/Taipei' date -I)" \
    --name "github-release" \
    --file "/root/go/bin/github-release"; \
    "/root/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$(TZ=':Asia/Taipei' date -I)" \
    --name "go-shadowsocks2" \
    --file "/root/go/bin/go-shadowsocks2"; \
    "/root/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$(TZ=':Asia/Taipei' date -I)" \
    --name "got" \
    --file "/root/go/bin/got"; \
    "/root/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$(TZ=':Asia/Taipei' date -I)" \
    --name "nali" \
    --file "/root/go/bin/nali"; \
    "/root/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$(TZ=':Asia/Taipei' date -I)" \
    --name "shfmt" \
    --file "/root/go/bin/shfmt"; \
    "/root/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$(TZ=':Asia/Taipei' date -I)" \
    --name "caddy-maxmind-geolocation" \
    --file "/root/go/bin/caddy-maxmind-geolocation";
