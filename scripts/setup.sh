#!/usr/bin/env bash
# Creates .env and the agent SSH key. Safe to re-run: existing values are kept.
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p secrets
[ -f secrets/agent_key ] || ssh-keygen -q -t rsa -b 4096 -m PEM -N '' -C jenkins-agent -f secrets/agent_key
[ -f .env ] || cp .env.example .env

fill() {  # Sets NAME only when it is still empty in .env.
    sed -i "s|^$1=\$|$1=$2|" .env
}
fill JENKINS_ADMIN_PASSWORD "$(openssl rand -hex 12)"
fill JENKINS_VIEWER_PASSWORD "$(openssl rand -hex 12)"
fill GITHUB_WEBHOOK_SECRET "$(openssl rand -hex 20)"
fill JENKINS_AGENT_SSH_PUBKEY "$(cat secrets/agent_key.pub)"

missing=$(grep -E '^(DOCKERHUB_USER|DOCKERHUB_TOKEN|GITHUB_TOKEN|NGROK_AUTHTOKEN|NGROK_DOMAIN)=$' .env | cut -d= -f1 || true)
if [ -n "$missing" ]; then
    echo "Fill these in .env:"; echo "$missing"
fi
