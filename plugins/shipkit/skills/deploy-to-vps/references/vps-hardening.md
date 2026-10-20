# VPS hardening - baseline against brute-force and origin exposure

Do this on a **fresh box, before exposing services**. A new VPS with password SSH on
port 22 starts getting brute-forced within minutes. The goal: key-only auth, a moving
target (non-standard port), automated banning (fail2ban), a default-deny firewall,
and - when behind a CDN - locking the origin so the real IP can't be reached directly.

`assets/harden.sh` automates most of this; run it interactively the first time and
read what it does. Key principle: **don't lock yourself out** - keep your current SSH
session open and test a new session on the new port/key before closing the old one.

## Contents

- 1. Non-root user + key-only SSH
- 2. Rotate the SSH port (move the target)
- 3. fail2ban (auto-ban repeat offenders)
- 4. Firewall (default-deny)
- 5. Lock the origin to your CDN (when proxied)
- 6. Unattended security updates + misc

## 1. Non-root user + key-only SSH

```bash
# as root on a fresh box
adduser deploy && usermod -aG sudo deploy
mkdir -p /home/deploy/.ssh && cp ~/.ssh/authorized_keys /home/deploy/.ssh/
chown -R deploy:deploy /home/deploy/.ssh && chmod 700 /home/deploy/.ssh
```

In a drop-in such as `/etc/ssh/sshd_config.d/00-hardening.conf` (sshd keeps the
FIRST value it reads, and Ubuntu cloud images ship `50-cloud-init.conf` with
`PasswordAuthentication yes`, so name yours to sort first; verify with
`sudo sshd -T | grep -i passwordauthentication`):

```
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
```

## 2. Rotate the SSH port (move the target)

Most brute-force bots only hit port 22. Moving it cuts the noise dramatically. Pick a
high port (e.g. 49222). In the sshd config:

```
Port 49222
```

Then **open the new port in the firewall and Ubuntu's socket FIRST**, restart ssh, and
**test a new session on the new port before closing your current one**:

```bash
sudo ss -tlnp | grep ssh        # confirm it's listening on the new port
# from your laptop, in a NEW terminal:  ssh -p 49222 deploy@VM
```

Ubuntu 22.10+ uses socket activation: `sudo systemctl edit ssh.socket` and set
`ListenStream=` to the new port (blank line first to clear), or disable the socket and
use the service. The CI deploy must use this port too - store it as the GitHub
variable `VPS_SSH_PORT` and pass `-p` / `ssh -p` everywhere.

Note: port rotation is **obscurity, not security** - it reduces log noise and
opportunistic bots, but is not a substitute for key-only auth + fail2ban + firewall.

## 3. fail2ban (auto-ban repeat offenders)

```bash
sudo apt-get update && sudo apt-get install -y fail2ban
sudo tee /etc/fail2ban/jail.local >/dev/null <<'EOF'
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
backend  = systemd

[sshd]
enabled  = true
# match your SSH port (keep comments on their own line in fail2ban configs)
port     = 49222
EOF
sudo systemctl enable --now fail2ban
sudo fail2ban-client status sshd
```

If SSH is on a custom port, fail2ban must know it (the `port` line above), or it
watches the wrong port and bans nothing.

## 4. Firewall (default-deny)

UFW is simplest. Allow only the SSH port + web:

```bash
sudo apt-get install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 49222/tcp       # SSH (your custom port) - add BEFORE enabling!
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status verbose
```

Forgetting to allow the SSH port before `ufw enable` locks you out. If you do, most
providers offer a web console/VNC to recover.

## 5. Lock the origin to your CDN (when proxied)

Proxying through Cloudflare hides your IP from *web visitors*, but the box is still
directly reachable at its IP, and SSH is never proxied. Anyone who finds the IP (old
DNS history, email headers, scanning) can bypass the CDN and hit the origin or brute
SSH. To actually hide/protect the origin:

- **Docker bypasses UFW for published ports.** In this architecture 80/443 are
  published by the Caddy *container*, and Docker inserts its own iptables rules
  (nat PREROUTING + FORWARD) that are evaluated before UFW's INPUT rules. So plain
  `ufw allow from <range> to any port 443` / `ufw delete allow 443/tcp` does **not**
  restrict the container: the port stays open to the world. Verify from an outside
  host with `curl -skI https://<VPS_IP>/`. Pick one fix:
  - **ufw-docker** (keeps UFW as the one firewall): install
    [chaifeng/ufw-docker](https://github.com/chaifeng/ufw-docker), run
    `sudo ufw-docker install && sudo systemctl restart ufw`, then allow the CDN with
    **`ufw route`** rules (they apply to forwarded/container traffic):
    ```bash
    for ip in $(curl -s https://www.cloudflare.com/ips-v4) $(curl -s https://www.cloudflare.com/ips-v6); do
      sudo ufw route allow proto tcp from $ip to any port 443
      sudo ufw route allow proto tcp from $ip to any port 80
    done
    sudo ufw status numbered
    ```
  - **Cloudflare Tunnel** (`cloudflared` as a compose service): the origin makes an
    outbound connection to Cloudflare, so you publish no web port at all and the
    lockdown problem disappears.
  - **`DOCKER-USER` chain**: hand-written iptables/ipset rules that drop new
    connections to 80/443 unless the source is a Cloudflare range. Most control,
    most to maintain.
- **Host-level services (not in Docker)** - e.g. Caddy installed via apt - do obey
  UFW. For those, restrict 80/443 to Cloudflare's published IP ranges directly:
  ```bash
  # fetch ranges and allow only those to 443 (and 80); deny the rest
  for ip in $(curl -s https://www.cloudflare.com/ips-v4) $(curl -s https://www.cloudflare.com/ips-v6); do
    sudo ufw allow from $ip to any port 443 proto tcp
    sudo ufw allow from $ip to any port 80  proto tcp
  done
  # Remove the open-to-everyone rules from step 4. UFW is first-match, so appending
  # `ufw deny 80/tcp` would never fire: the earlier `allow 80/tcp` already matched.
  sudo ufw delete allow 80/tcp; sudo ufw delete allow 443/tcp
  sudo ufw status numbered    # confirm only Cloudflare ranges remain on 80/443
  ```
  (Re-run when Cloudflare updates ranges, or script it as a cron.)
- **Restrict SSH to your IP/VPN** if it's static: `sudo ufw allow from YOUR_IP to any port 49222 proto tcp` and remove the open SSH rule. If your IP is dynamic, rely on key-only + fail2ban + non-standard port.
- Set Cloudflare SSL/TLS mode to **Full(strict)** and install a **Cloudflare Origin
  Certificate** (or use Caddy DNS-01) so the origin only trusts the CDN.

SSH runs on the host, not in Docker, so the plain `ufw` rules above do apply to it.

This combination means a port scan of the IP finds a closed box, and web traffic must
come through Cloudflare (where you also get WAF/DDoS/rate-limiting).

## 6. Unattended security updates + misc

```bash
sudo apt-get install -y unattended-upgrades && sudo dpkg-reconfigure -plow unattended-upgrades
```

- Disable unused services; keep the box minimal.
- Don't run containers as root where avoidable: add a `USER` line to your Dockerfile
  (the `runtimes.md` examples don't, so add one; distroless `:nonroot` and recent
  `aspnet` images ship a non-root user you can switch to).
- Back up the managed DB on its own schedule (it's external in this architecture).
