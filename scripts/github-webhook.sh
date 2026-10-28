#!/usr/bin/env bash
# Points a GitHub webhook at Jenkins through the ngrok domain in .env. Needs gh with admin rights on the repo.
set -euo pipefail
cd "$(dirname "$0")/.."
repo=Kiyogitpy/jenkins-demo
domain=$(grep '^NGROK_DOMAIN=' .env | cut -d= -f2-)
secret=$(grep '^GITHUB_WEBHOOK_SECRET=' .env | cut -d= -f2-)
url="https://$domain/github-webhook/"

id=$(gh api "repos/$repo/hooks" --jq ".[] | select(.config.url == \"$url\") | .id")
args=(-F active=true -f 'events[]=push' -f 'events[]=pull_request'
      -f "config[url]=$url" -f config[content_type]=json -f "config[secret]=$secret")
if [ -n "$id" ]; then
    gh api -X PATCH "repos/$repo/hooks/$id" "${args[@]}" --jq '"updated hook \(.id)"'
else
    gh api "repos/$repo/hooks" -f name=web "${args[@]}" --jq '"created hook \(.id)"'
fi
