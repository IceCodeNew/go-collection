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
    --name "github-release" \
    --file "/go/bin/github-release"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "mos-chinadns" \
    --file "/go/bin/mos-chinadns"; \
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
    --name "chisel" \
    --file "/go/bin/chisel"; \
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
    --name "shfmt" \
    --file "/go/bin/shfmt"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "apk-file" \
    --file "/go/bin/apk-file"; \
    "/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$tag_name" \
    --name "caddy-maxmind-geolocation" \
    --file "/go/bin/caddy-maxmind-geolocation"
