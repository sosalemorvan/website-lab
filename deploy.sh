#!/usr/bin/env bash
# Pull-based deploy script, meant to run ON THE VPS (via cron/systemd timer,
# or manually). Polls the `production` branch for new commits and, if found
# (or if --force is passed), rebuilds and restarts the Docker container.
#
# Usage:
#   ./deploy.sh            # deploy only if origin/production has new commits
#   ./deploy.sh --force    # rebuild and restart regardless

set -euo pipefail

BRANCH="production"
LOG_FILE="deploy.log"
FORCE=0

if [[ "${1:-}" == "--force" ]]; then
  FORCE=1
fi

cd "$(dirname "$0")"

log() {
  echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*" | tee -a "$LOG_FILE"
}

git fetch origin "$BRANCH" --quiet

LOCAL_HEAD="$(git rev-parse HEAD)"
REMOTE_HEAD="$(git rev-parse "origin/$BRANCH")"

if [[ "$LOCAL_HEAD" == "$REMOTE_HEAD" && "$FORCE" -eq 0 ]]; then
  exit 0
fi

log "Deploying $BRANCH: $LOCAL_HEAD -> $REMOTE_HEAD (force=$FORCE)"

git reset --hard "origin/$BRANCH"

if docker compose up -d --build; then
  log "Deploy succeeded at commit $(git rev-parse HEAD)"
else
  log "Deploy FAILED at commit $(git rev-parse HEAD)"
  exit 1
fi
