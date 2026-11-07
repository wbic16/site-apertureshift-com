# Deploying apertureshift.com (Roads to the Future)

Modernized deployment shape, replacing hand-edited docroots:

- **Source of truth:** `wbic16/site-apertureshift-com@exo`. The site files
  live at the repo root; this `deploy/` folder is the deploy tooling.
- **On the box** (44.248.235.76, user `wbic16`): a **rootless podman**
  container `apertureshift-web` (nginx:alpine) serves
  `~/apertureshift-deploy/site/` on `127.0.0.1:3002`, managed by a
  systemd **--user** quadlet unit. Linger is already enabled for wbic16,
  and wbic16 already has subuid/subgid ranges, so the container survives
  logouts and reboots.
- **Host nginx** keeps TLS (existing Let's Encrypt cert) and proxies
  apertureshift.com to the loopback port once the cutover vhost is in.
  The old docroot `/sites/web/apertureshift.com` is never modified: the
  port-80 ACME challenge still roots there, and it is the rollback.
- **Web root** = publish tree minus `AGENTS.md` (repo working notes; the
  old docroot exposed no repo files either). All other repo-root files,
  including `version.json`, the docs, and the LICENSE, are served.

## Routine deploy (no sudo)

    ./deploy.sh                    # from the Muse VM (nested hop via aletheia-core)
    DEPLOY_HOP=direct ./deploy.sh  # from aletheia-core itself

It verifies the local publish tree against the repo tree (fresh HEAD),
stages to the box, verifies a sha256 manifest on the box, rebuilds the
container, and curls the loopback endpoint for the new hub.

## One-time steps (Will, sudo - the only sudo in the system)

1. Install podman (once, ever):

       sudo apt-get update && sudo apt-get install -y podman uidmap

2. Cutover, after `deploy.sh` reports `CONTAINER_OK`:

       sudo cp /home/wbic16/apertureshift-deploy/apertureshift.com.vhost /etc/nginx/sites-enabled/apertureshift.com && sudo nginx -t && sudo systemctl reload nginx

## Rollback (Will, sudo)

    sudo cp /home/wbic16/apertureshift-deploy/apertureshift.com.vhost.orig /etc/nginx/sites-enabled/apertureshift.com && sudo nginx -t && sudo systemctl reload nginx

This restores the old docroot serving exactly as before; the container
can keep running harmlessly on its loopback port.
