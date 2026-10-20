#!/usr/bin/env bash
# Baseline VPS hardening for Ubuntu. Run as root (or with sudo) on a FRESH box,
# BEFORE exposing services. Read it first; it changes SSH. DO NOT close your current
# SSH session until you've confirmed a NEW session works on the new port.
#
#   sudo SSH_PORT=49222 DEPLOY_USER=deploy bash harden.sh
#
# Edit the vars or pass them as env. Re-run is mostly idempotent.
set -euo pipefail

SSH_PORT="${SSH_PORT:-49222}"
DEPLOY_USER="${DEPLOY_USER:-deploy}"

echo ">>> 1. non-root sudo user: ${DEPLOY_USER}"
if ! id "$DEPLOY_USER" &>/dev/null; then
  adduser --disabled-password --gecos "" "$DEPLOY_USER"
  usermod -aG sudo "$DEPLOY_USER"
fi
# Copy the keys you logged in with, so key auth works for the new user. Prefer the
# sudo caller's keys: on many cloud images (AWS, some Ubuntu builds) root's
# authorized_keys carries a command="echo Please login as ubuntu" prefix that would
# lock the new user out. Lines are appended, never overwritten, so re-running does
# not wipe a CI deploy key added later.
SRC_KEYS=/root/.ssh/authorized_keys
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != root ] && [ -f "/home/$SUDO_USER/.ssh/authorized_keys" ]; then
  SRC_KEYS="/home/$SUDO_USER/.ssh/authorized_keys"
fi
if [ -f "$SRC_KEYS" ]; then
  DST_KEYS="/home/$DEPLOY_USER/.ssh/authorized_keys"
  install -d -m 700 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "/home/$DEPLOY_USER/.ssh"
  touch "$DST_KEYS"
  while IFS= read -r key || [ -n "$key" ]; do
    case "$key" in ''|'#'*) continue ;; esac
    case "$key" in *'command="'*) echo "WARN: skipping restricted key (command=...) from $SRC_KEYS"; continue ;; esac
    grep -qxF "$key" "$DST_KEYS" || printf '%s\n' "$key" >> "$DST_KEYS"
  done < "$SRC_KEYS"
  chown "$DEPLOY_USER:$DEPLOY_USER" "$DST_KEYS"; chmod 600 "$DST_KEYS"
  [ -s "$DST_KEYS" ] || { echo "ERROR: no usable key copied to $DST_KEYS; add one before continuing"; exit 1; }
else
  echo "ERROR: no authorized_keys found; add your public key for $DEPLOY_USER first"; exit 1
fi

echo ">>> 2. sshd: key-only, no root, custom port ${SSH_PORT}"
install -d /etc/ssh/sshd_config.d
# sshd keeps the FIRST value it reads for each keyword, and drop-ins load in lexical
# order. Ubuntu cloud images ship 50-cloud-init.conf with PasswordAuthentication yes,
# so a 99-* file would silently lose. 00- sorts first and wins.
rm -f /etc/ssh/sshd_config.d/99-hardening.conf   # name used by older versions of this script
cat > /etc/ssh/sshd_config.d/00-hardening.conf <<EOF
Port ${SSH_PORT}
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
EOF
# Ubuntu 22.10+ socket activation: point the socket at the new port too.
if systemctl list-unit-files | grep -q '^ssh.socket'; then
  mkdir -p /etc/systemd/system/ssh.socket.d
  printf '[Socket]\nListenStream=\nListenStream=%s\n' "$SSH_PORT" > /etc/systemd/system/ssh.socket.d/port.conf
  systemctl daemon-reload
fi

echo ">>> 3. firewall (UFW): default-deny, allow SSH+web"
apt-get update -qq && apt-get install -y -qq ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow "${SSH_PORT}/tcp"
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo ">>> 4. fail2ban"
apt-get install -y -qq fail2ban
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
backend  = systemd
[sshd]
enabled = true
port    = ${SSH_PORT}
EOF
systemctl enable --now fail2ban

echo ">>> 5. unattended security updates (+ rsync for the CI deploy)"
apt-get install -y -qq unattended-upgrades rsync
echo 'APT::Periodic::Unattended-Upgrade "1";' > /etc/apt/apt.conf.d/20auto-upgrades

# Restart ssh LAST, after the firewall already allows the new port.
# Validate the config first: a syntax error here would leave sshd unable to start.
mkdir -p /run/sshd   # sshd -t needs it; absent on socket-activated boxes before first login
sshd -t || { echo "sshd -t failed; NOT restarting ssh. Fix /etc/ssh/sshd_config.d/00-hardening.conf"; exit 1; }
echo ">>> restarting ssh on port ${SSH_PORT}"
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true
systemctl restart ssh.socket 2>/dev/null || true

cat <<EOF

DONE. Now, BEFORE closing this session, open a NEW terminal and confirm:
    ssh -p ${SSH_PORT} ${DEPLOY_USER}@<this-host>
Then update CI: set GitHub variable VPS_SSH_PORT=${SSH_PORT}, VPS_USER=${DEPLOY_USER}.

${DEPLOY_USER} has no password (SSH is key-only), so sudo will refuse it until you set one:
    passwd ${DEPLOY_USER}
Use 'ssh -t' for any remote command that runs sudo, so it can prompt.

OPTIONAL (when behind Cloudflare proxy) - lock the origin to Cloudflare IPs.
WARNING: ports PUBLISHED BY DOCKER (Caddy's 80/443) bypass plain 'ufw allow/deny'
rules, because Docker writes its own iptables rules ahead of UFW's. Filter them with
'ufw route' rules after installing ufw-docker (github.com/chaifeng/ufw-docker), or use
a Cloudflare Tunnel so no web port is open at all. See references/vps-hardening.md 5.
    ufw-docker install && systemctl restart ufw
    for ip in \$(curl -s https://www.cloudflare.com/ips-v4) \$(curl -s https://www.cloudflare.com/ips-v6); do ufw route allow proto tcp from \$ip to any port 443; ufw route allow proto tcp from \$ip to any port 80; done
And restrict SSH to your IP if static:
    ufw allow from <YOUR_IP> to any port ${SSH_PORT} proto tcp && ufw delete allow ${SSH_PORT}/tcp
EOF
