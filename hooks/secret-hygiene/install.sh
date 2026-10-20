#!/usr/bin/env bash
# Install the secret-hygiene pre-commit hook into a target git repo (macOS / Linux / Git Bash).
#   bash install.sh [/path/to/repo]      # defaults to current dir
set -euo pipefail
repo="${1:-.}"
# Ask git for the hooks dir: handles worktrees (.git is a file) and core.hooksPath.
hooks_dir="$(git -C "$repo" rev-parse --path-format=absolute --git-path hooks)"   || { echo "$repo is not a git repo" >&2; exit 1; }
src="$(cd "$(dirname "$0")" && pwd)/pre-commit"
dest="$hooks_dir/pre-commit"
mkdir -p "$hooks_dir"
if [ -e "$dest" ]; then cp "$dest" "$dest.bak"; echo "backed up existing hook -> pre-commit.bak"; fi
cp "$src" "$dest"
chmod +x "$dest"
echo "installed secret-hygiene pre-commit -> $dest"
