#!/usr/bin/env bash
# apertureshift.com — box-side deploy step. Runs ON the AWS box as wbic16.
#
# Verifies the staged site against its sha256 manifest, then (re)builds the
# rootless podman nginx container (quadlet + systemd --user) and curls the
# loopback endpoint until the new hub answers. Never touches host nginx,
# the old docroot, or any other tenant.
set -euo pipefail

STAGE="${HOME}/apertureshift-deploy"
SITE="${STAGE}/site"
PORT=3002
IMAGE="docker.io/library/nginx:alpine"

fail() { echo "DEPLOY-REMOTE: $*" >&2; exit 1; }

# --- verify staged bytes -----------------------------------------------------
[ -d "${SITE}" ] || fail "no staged site at ${SITE}"
[ -f "${STAGE}/manifest.sha256" ] || fail "no manifest at ${STAGE}/manifest.sha256"
( cd "${STAGE}" && sha256sum -c manifest.sha256 --quiet ) || fail "manifest verification FAILED"
echo "manifest: all staged files match their sha256"

# rootless container uid mapping: the nginx worker runs as a mapped uid that is
# neither owner nor group, so staged files must be world-readable.
chmod -R a+rX "${SITE}"

# --- preflight: podman ---------------------------------------------------------
if ! command -v podman >/dev/null 2>&1; then
  cat >&2 <<'MSG'
DEPLOY-REMOTE: podman is not installed on this box. Everything else is
staged and verified. One sudo step installs it (Will):

  sudo apt-get update && sudo apt-get install -y podman uidmap

Then re-run:  bash ~/apertureshift-deploy/deploy-remote.sh
MSG
  exit 42
fi
echo "podman: $(podman --version)"
podman info --format 'rootless={{.Host.Security.Rootless}}' 2>/dev/null || true

# --- image ---------------------------------------------------------------------
podman pull "${IMAGE}" >/dev/null
echo "image: ${IMAGE} present"

# --- quadlet unit ---------------------------------------------------------------
mkdir -p "${HOME}/.config/containers/systemd"
install -m 0644 "${STAGE}/apertureshift-web.container" \
  "${HOME}/.config/containers/systemd/apertureshift-web.container"
systemctl --user daemon-reload
systemctl --user enable apertureshift-web.service >/dev/null 2>&1 || true
systemctl --user restart apertureshift-web.service

# --- verify on loopback -----------------------------------------------------------
ok=""
for _ in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:${PORT}/" -o /tmp/as-index.html 2>/dev/null; then ok=1; break; fi
  sleep 1
done
if [ -z "${ok}" ]; then
  systemctl --user --no-pager status apertureshift-web.service | head -20 >&2 || true
  fail "container did not answer on 127.0.0.1:${PORT}"
fi
grep -q "Roads to the Future" /tmp/as-index.html || fail "hub marker missing from served /"
grep -q "Road Card" /tmp/as-index.html || fail "XP Road Card missing from served /"
code=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${PORT}/word-home.html")
[ "${code}" = "200" ] || fail "word-home.html returned ${code}"
served_sha=$(sha256sum /tmp/as-index.html | awk '{print $1}')
staged_sha=$(sha256sum "${SITE}/index.html" | awk '{print $1}')
[ "${served_sha}" = "${staged_sha}" ] || fail "served index sha ${served_sha} != staged ${staged_sha}"
echo "CONTAINER_OK port=${PORT} index_sha256=${served_sha}"

# --- cutover hint -------------------------------------------------------------------
if ! grep -q "127.0.0.1:${PORT}" /etc/nginx/sites-enabled/apertureshift.com 2>/dev/null; then
  cat <<MSG

Container is live on loopback but the public vhost still serves the old
docroot. One-time cutover (Will, sudo):

  sudo cp ${STAGE}/apertureshift.com.vhost /etc/nginx/sites-enabled/apertureshift.com && sudo nginx -t && sudo systemctl reload nginx

Rollback (restores the old docroot serving):

  sudo cp ${STAGE}/apertureshift.com.vhost.orig /etc/nginx/sites-enabled/apertureshift.com && sudo nginx -t && sudo systemctl reload nginx
MSG
fi
