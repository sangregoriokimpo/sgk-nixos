#!/usr/bin/env bash
set -euo pipefail

cd /etc/nixos

if [[ -z "$(git status --porcelain)" ]]; then
  echo "Nothing to commit — tree is clean."
  exit 0
fi

echo "Changes to commit:"
git status --short

msg="${1:-nixos config update $(date '+%Y-%m-%d %H:%M')}"

git add -A
git commit -m "$msg"
echo "Committed: $msg"
