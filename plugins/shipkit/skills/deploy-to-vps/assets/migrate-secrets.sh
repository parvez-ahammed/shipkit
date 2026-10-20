#!/usr/bin/env bash
# Move backend secrets that live only in a PaaS secret store into GitHub Secrets,
# so the VPS pipeline (single source of truth = GitHub) can render them.
# Bash equivalent of migrate-secrets.ps1 (macOS / Linux / Git Bash).
#
# Input is a dotenv-style export of the old host's config (KEY=VALUE per line), e.g.
#   heroku config -s -a my-app > old.env
#   railway variables --kv > old.env
#   (Render / Fly / Azure: copy values from the dashboard or CLI into old.env)
# Run it in YOUR OWN session - an automated safety layer will (correctly) block an
# assistant from reading production secret VALUES, so you run it. Delete old.env after.
#
#   bash migrate-secrets.sh old.env OWNER/REPO
#
# Requires gh logged in with access to the repo.
set -euo pipefail

SRC="${1:?usage: bash migrate-secrets.sh <dotenv-file> <OWNER/REPO>}"
REPO="${2:?usage: bash migrate-secrets.sh <dotenv-file> <OWNER/REPO>}"

# source-key -> GitHub-secret-name. Keys not listed are skipped.
# (A case statement, not an associative array, so it runs on macOS's bash 3.2.)
map_key() {
  case "$1" in
    DATABASE_URL)         echo DB_CONNECTION_STRING ;;
    JWT_SECRET)           echo JWT_SECRET ;;
    GOOGLE_CLIENT_SECRET) echo GOOGLE_CLIENT_SECRET ;;
    # ...add the rest...
    *) echo "" ;;
  esac
}

while IFS= read -r line || [ -n "$line" ]; do
  line="${line%$'\r'}"
  case "$line" in ''|'#'*) continue ;; esac
  key="${line%%=*}"; val="${line#*=}"
  key="${key#export }"; key="${key// /}"
  # strip one layer of matching surrounding quotes
  if [[ "$val" == \"*\" || "$val" == \'*\' ]]; then val="${val:1:${#val}-2}"; fi
  dst="$(map_key "$key")"
  [ -n "$dst" ] || continue
  if [ -z "$val" ]; then echo "SKIP $dst (source '$key' empty)"; continue; fi
  printf '%s' "$val" | gh secret set "$dst" -R "$REPO"
  echo "set $dst"
done < "$SRC"

echo; echo "GitHub secrets now:"; gh secret list -R "$REPO"
