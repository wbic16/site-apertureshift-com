#!/usr/bin/env bash
# apertureshift.com - operator-side deploy for Roads to the Future.
#
# 1. Verifies the local publish tree against the live repo tree of
#    wbic16/site-apertureshift-com@exo (fresh HEAD read at run time).
# 2. Stages the web files + box tooling to the AWS box via aletheia-core
#    (the proven nested hop), into ~/apertureshift-deploy/ on the box.
# 3. Runs the box-side deploy-remote.sh, which rebuilds the rootless
#    podman nginx container and verifies the loopback endpoint.
#
# The public cutover (host nginx vhost swap) is a separate one-time sudo
# step for Will - see README.md. This script never touches /etc/nginx,
# the old docroot, DNS, or any other tenant.
#
# Usage:
#   ./deploy.sh                     # from the Muse VM (nested hop)
#   DEPLOY_HOP=direct ./deploy.sh   # when already running ON aletheia-core
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "${HERE}")"
PUBLISH="${ROOT}/publish"
REPO="wbic16/site-apertureshift-com"
BOX="wbic16@44.248.235.76"
ACORE="wbic16@100.88.154.1"
SSH_VM=(ssh -i "${HOME}/.ssh/id_ed25519" -o IdentitiesOnly=yes
        -o "ProxyCommand=nc -X connect -x hatch-egress-proxy:3130 %h %p")

if [ "${DEPLOY_HOP:-nested}" = "direct" ]; then
  acore_sh() { bash -s; }
  acore_put() { cat > "$1"; }
  box_sh() { ssh -o BatchMode=yes "${BOX}" 'bash -s'; }
else
  acore_sh() { "${SSH_VM[@]}" "${ACORE}" 'bash -s'; }
  acore_put() { "${SSH_VM[@]}" "${ACORE}" "cat > $1"; }
  box_sh() { "${SSH_VM[@]}" "${ACORE}" "ssh -o BatchMode=yes ${BOX} 'bash -s'"; }
fi

# --- 1. verify local publish tree against the repo tree -----------------------
if [ -f "${ROOT}/ghget.py" ]; then
  echo "== verifying publish tree against ${REPO}@exo (fresh HEAD) =="
  TMPD="$(mktemp -d)"
  python3 "${ROOT}/ghget.py" "/repos/${REPO}/git/ref/heads/exo" "${TMPD}/ref.json" >/dev/null
  HEAD_SHA="$(python3 -c "import json;print(json.load(open('${TMPD}/ref.json'))['object']['sha'])")"
  python3 "${ROOT}/ghget.py" "/repos/${REPO}/git/commits/${HEAD_SHA}" "${TMPD}/commit.json" >/dev/null
  TREE_SHA="$(python3 -c "import json;print(json.load(open('${TMPD}/commit.json'))['tree']['sha'])")"
  python3 "${ROOT}/ghget.py" "/repos/${REPO}/git/trees/${TREE_SHA}" "${TMPD}/tree.json" >/dev/null
  python3 - "${TMPD}/tree.json" "${PUBLISH}" <<'PY'
import json, hashlib, os, sys
tree = json.load(open(sys.argv[1])); pub = sys.argv[2]
remote = {e["path"]: e["sha"] for e in tree["tree"] if e["type"] == "blob"}
bad = []
for name in sorted(os.listdir(pub)):
    p = os.path.join(pub, name)
    if not os.path.isfile(p): continue
    data = open(p, "rb").read()
    blob = hashlib.sha1(b"blob %d\0" % len(data) + data).hexdigest()
    if remote.get(name) != blob: bad.append(name)
if bad:
    print("MISMATCH vs repo tree:", bad); sys.exit(1)
print(f"publish tree verified: {len(remote)} repo blobs, all local files match")
PY
  rm -rf "${TMPD}"
else
  echo "WARNING: ghget.py not found - skipping repo verification (box manifest still verified)" >&2
fi

# --- 2. build the staging bundle ------------------------------------------------
# Web root = the publish tree minus AGENTS.md (repo-working notes; they were
# never web content - the old docroot exposed no repo files either).
echo "== building staging bundle =="
STAGE="${HERE}/.stage"
rm -rf "${STAGE}"; mkdir -p "${STAGE}/site"
for f in "${PUBLISH}"/*; do
  [ -f "${f}" ] || continue
  [ "$(basename "${f}")" = "AGENTS.md" ] && continue
  cp "${f}" "${STAGE}/site/"
done
cp "${HERE}/deploy-remote.sh" "${HERE}/apertureshift-web.container" \
   "${HERE}/apertureshift.com.vhost" "${STAGE}/"
( cd "${STAGE}" && find site -type f | sort | xargs sha256sum > manifest.sha256 )
echo "staged $(find "${STAGE}/site" -type f | wc -l) web files + tooling"

# --- 3. ship to the box via aletheia-core ----------------------------------------
echo "== shipping to the box via aletheia-core =="
tar czf - -C "${STAGE}" . | acore_put /tmp/as-stage.tgz
acore_sh <<'EOF'
set -e
scp -q -o BatchMode=yes /tmp/as-stage.tgz wbic16@44.248.235.76:/tmp/as-stage.tgz
ssh -o BatchMode=yes wbic16@44.248.235.76 'bash -s' <<'BOXEOF'
set -e
mkdir -p ~/apertureshift-deploy
tar xzf /tmp/as-stage.tgz -C ~/apertureshift-deploy
# rootless container uid mapping: the nginx worker runs as a mapped uid that is
# neither owner nor group, so staged files must be world-readable.
chmod -R a+rX ~/apertureshift-deploy/site
# one-time backup of the live vhost (rollback source); never overwritten later
if [ ! -f ~/apertureshift-deploy/apertureshift.com.vhost.orig ]; then
  cp /etc/nginx/sites-enabled/apertureshift.com ~/apertureshift-deploy/apertureshift.com.vhost.orig
fi
ls ~/apertureshift-deploy
BOXEOF
EOF

# --- 4. box-side deploy --------------------------------------------------------------
echo "== running box-side deploy =="
set +e
box_sh <<'EOF'
bash ~/apertureshift-deploy/deploy-remote.sh
EOF
RC=$?
set -e
if [ "${RC}" = "42" ]; then
  echo "== box-side deploy paused: podman install (Will, sudo) is the one missing step - see README.md =="
elif [ "${RC}" != "0" ]; then
  echo "== box-side deploy FAILED (rc=${RC}) - old site untouched ==" >&2
  exit "${RC}"
fi

# --- 5. public state (informational; cutover is Will's sudo step) ---------------------
echo "== public state of https://apertureshift.com =="
acore_sh <<'EOF'
body=$(curl -fsS https://apertureshift.com/ 2>/dev/null || echo "")
if echo "${body}" | grep -q "Roads to the Future"; then
  echo "LIVE: the new hub is serving publicly."
else
  echo "NOT YET LIVE: the old page still serves (expected until Will runs the vhost cutover)."
fi
EOF
rm -rf "${STAGE}"
