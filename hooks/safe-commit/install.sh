#!/usr/bin/env bash
# Install the safe-commit commit-msg hook into a target git repo (macOS / Linux / Git Bash).
#   bash install.sh [/path/to/repo]      # defaults to current dir
set -euo pipefail
repo="${1:-.}"
# Ask git for the hooks dir: handles worktrees (.git is a file) and core.hooksPath.
hooks_dir="$(git -C "$repo" rev-parse --path-format=absolute --git-path hooks)"   || { echo "$repo is not a git repo" >&2; exit 1; }
src="$(cd "$(dirname "$0")" && pwd)/commit-msg"
dest="$hooks_dir/commit-msg"
mkdir -p "$hooks_dir"
if [ -e "$dest" ]; then cp "$dest" "$dest.bak"; echo "backed up existing hook -> commit-msg.bak"; fi
cp "$src" "$dest"
chmod +x "$dest"
echo "installed safe-commit commit-msg -> $dest"
