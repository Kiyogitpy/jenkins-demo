#!/usr/bin/env bash
# Backs up the jenkins_home volume to backups/, or restores one: scripts/backup.sh restore backups/<file>.tgz
set -euo pipefail
cd "$(dirname "$0")/.."
export MSYS_NO_PATHCONV=1  # Keeps Git Bash from rewriting the container paths below.
volume=jenkins-demo_jenkins_home
mkdir -p backups

if [ "${1:-}" = restore ]; then
    file=${2:?usage: scripts/backup.sh restore backups/<file>.tgz}
    docker compose stop jenkins
    docker run --rm -v "$volume:/data" -v "$PWD/backups:/backup" alpine \
        sh -c "rm -rf /data/* /data/.[!.]* && tar xzf /backup/$(basename "$file") -C /data"
    docker compose start jenkins
    echo "restored $file"
else
    file="jenkins_home-$(date +%Y%m%d-%H%M%S).tgz"
    # Left out because they are rebuilt: plugins and war come from the image, workspaces and caches from builds.
    docker run --rm -v "$volume:/data:ro" -v "$PWD/backups:/backup" alpine \
        tar czf "/backup/$file" -C /data --exclude=./plugins --exclude=./war --exclude=./workspace --exclude=./caches .
    echo "backups/$file"
fi
