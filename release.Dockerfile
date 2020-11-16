# syntax = docker/dockerfile:1.0-experimental
FROM quay.io/icecodenew/go-collection:latest AS go_upload
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /root/go/bin
# import secret:
RUN --mount=type=secret,id=GIT_AUTH_TOKEN,dst=/tmp/secret_token export GITHUB_TOKEN="$(cat /tmp/secret_token)" \
    && export tag_name="$(TZ=':Asia/Taipei' date +%F-%H-%M-%S)" \
    && "/root/go/bin/github-release" release \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "$tag_name"; \
    "/root/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "croc" \
    --file "/root/go/bin/croc"; \
    "/root/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "github-release" \
    --file "/root/go/bin/github-release"; \
    "/root/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "go-shadowsocks2" \
    --file "/root/go/bin/go-shadowsocks2"; \
    "/root/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "got" \
    --file "/root/go/bin/got"; \
    "/root/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "duf" \
    --file "/root/go/bin/duf"; \
    "/root/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "nali" \
    --file "/root/go/bin/nali"; \
    "/root/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "shfmt" \
    --file "/root/go/bin/shfmt"; \
    "/root/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "apk-file" \
    --file "/root/go/bin/apk-file"; \
    "/root/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "caddy-maxmind-geolocation" \
    --file "/root/go/bin/caddy-maxmind-geolocation"
