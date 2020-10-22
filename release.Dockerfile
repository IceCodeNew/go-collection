FROM quay.io/icecodenew/go-collection:latest AS go_upload
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# ARG GITHUB_TOKEN
WORKDIR "$HOME/go/bin"
RUN "$HOME/go/bin/github-release" release \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$(TZ=':Asia/Taipei' date -I)" \
    --name "$(TZ=':Asia/Taipei' date -I)"; \
    "$HOME/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$(TZ=':Asia/Taipei' date -I)" \
    --name "croc" \
    --file "$HOME/go/bin/croc"; \
    "$HOME/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$(TZ=':Asia/Taipei' date -I)" \
    --name "github-release" \
    --file "$HOME/go/bin/github-release"; \
    "$HOME/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$(TZ=':Asia/Taipei' date -I)" \
    --name "go-shadowsocks2" \
    --file "$HOME/go/bin/go-shadowsocks2"; \
    "$HOME/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$(TZ=':Asia/Taipei' date -I)" \
    --name "got" \
    --file "$HOME/go/bin/got"; \
    "$HOME/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$(TZ=':Asia/Taipei' date -I)" \
    --name "nali" \
    --file "$HOME/go/bin/nali"; \
    "$HOME/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$(TZ=':Asia/Taipei' date -I)" \
    --name "shfmt" \
    --file "$HOME/go/bin/shfmt"; \
    "$HOME/go/bin/github-release" upload \
    --user IceCodeNew \
    --repo go-collection \
    --tag "$(TZ=':Asia/Taipei' date -I)" \
    --name "caddy-maxmind-geolocation" \
    --file "$HOME/go/bin/caddy-maxmind-geolocation";
