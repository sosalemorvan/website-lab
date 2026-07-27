# VPS deployment (Docker, pull-based)

This site can run in Docker on your VPS independently of the GitHub Pages
deployment (which keeps working unchanged). Deploys are **pull-based**: the
VPS periodically checks the `production` branch for new commits and updates
itself — no SSH keys or secrets are ever given to GitHub Actions.

## One-time VPS setup

1. Install Docker Engine + the Compose plugin:
   ```bash
   curl -fsSL https://get.docker.com | sh
   sudo usermod -aG docker "$USER"   # log out/in after this
   ```

2. Clone the repo on the `production` branch to a stable path, e.g.
   `/opt/website-lab`:
   ```bash
   sudo mkdir -p /opt/website-lab
   sudo chown "$USER":"$USER" /opt/website-lab
   git clone -b production https://github.com/LilkongW/website-lab.git /opt/website-lab
   cd /opt/website-lab
   ```

3. Pick a free host port and edit it into `compose.yaml`
   (`ports: "8082:3000"` by default). Check what's free with:
   ```bash
   ss -ltnp
   ```

4. First deploy, run manually:
   ```bash
   chmod +x deploy.sh
   ./deploy.sh --force
   docker compose ps
   curl http://localhost:8082/
   ```

5. Install the polling timer so future pushes to `production` get picked up
   automatically:
   ```bash
   sudo cp deploy/website-lab-deploy.service /etc/systemd/system/
   sudo cp deploy/website-lab-deploy.timer /etc/systemd/system/
   # edit WorkingDirectory/ExecStart in the .service file if you cloned
   # somewhere other than /opt/website-lab
   sudo systemctl daemon-reload
   sudo systemctl enable --now website-lab-deploy.timer
   systemctl list-timers | grep website-lab
   ```
   (A plain cron entry works just as well if you'd rather not use systemd:
   `*/5 * * * * /opt/website-lab/deploy.sh >> /opt/website-lab/deploy.log 2>&1`)

## Releasing a change to the VPS

Development happens on `master` (still auto-deploys to GitHub Pages as
before). When you want those changes live on the VPS too:

```bash
git checkout production
git merge master
git push origin production
```

Within one polling interval (default 5 min) the VPS pulls, rebuilds the
Docker image, and restarts the container. To skip the wait, SSH in and run
`./deploy.sh --force` (or just `./deploy.sh`, which no-ops if there's
nothing new) — this is also the manual-update path if the timer is ever
disabled or you don't want automatic polling at all.

## Reverse proxy / domain

See `nginx.conf.example` in this folder. Once the university hands you a
domain and its DNS points at this VPS's IP, drop the config into
`/etc/nginx/sites-available/`, reload nginx, then run `certbot --nginx -d
<domain>` to get HTTPS.
