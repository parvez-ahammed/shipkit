#!/usr/bin/env bash
# Copy every skill in plugins/shipkit/skills into the Claude Code personal skills dir
# so they go live without the plugin. Same as sync-skills.ps1, for macOS / Linux / Git Bash.
#
#   bash sync-skills.sh                 # sync all into ~/.claude/skills
#   bash sync-skills.sh --dry-run       # preview only
#   bash sync-skills.sh /other/dest     # custom destination
set -euo pipefail

dry=0
dest="$HOME/.claude/skills"
for arg in "$@"; do
  case "$arg" in
    -n|--dry-run) dry=1 ;;
    *) dest="$arg" ;;
  esac
done

src="$(cd "$(dirname "$0")" && pwd)/plugins/shipkit/skills"
[ -d "$src" ] || { echo "No skills directory found at $src" >&2; exit 1; }
[ "$dry" -eq 1 ] || mkdir -p "$dest"

count=0
for dir in "$src"/*/; do
  name="$(basename "$dir")"
  target="$dest/$name"
  if [ "$dry" -eq 1 ]; then
    echo "would sync $name -> $target"
  else
    rm -rf "$target"
    # node_modules and packaging output are build artifacts, not skill content.
    mkdir -p "$target"
    (cd "$dir" && tar --exclude=node_modules --exclude='*.zip' --exclude='*.rar' -cf - .) | (cd "$target" && tar -xf -)
    echo "synced $name -> $target"
  fi
  count=$((count + 1))
done
echo
echo "$count skill(s) processed. Start a new Claude Code session to pick them up."
