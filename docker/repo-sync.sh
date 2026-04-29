#!/bin/bash
set -euo pipefail
sleep 1

cd /home/container

REPO_CACHE="tmp/repo"
GREEN='\033[0;32m'
NC='\033[0m'
log() { echo -e "${GREEN}$*${NC}"; }

if [ -z "${REPOSITORY_URL:-}" ]; then
    log "REPOSITORY_URL is not set, skipping repository sync"
    exit 0
fi

: "${REPOSITORY_BRANCH:=master}"
: "${REPOSITORY_DIR:=}"
: "${REPOSITORY_ACCESS_TOKEN:=}"
: "${INSTALL_DIR:=Servers/unturned}"

# Normalize: accept REPOSITORY_URL with or without scheme.
REPOSITORY_URL="${REPOSITORY_URL#https://}"
REPOSITORY_URL="${REPOSITORY_URL#http://}"
CLONE_URL="https://${REPOSITORY_URL}"

# Pass the access token via an HTTP header rather than embedding it in the
# clone URL. This keeps the token out of process listings, error output,
# and the persisted git remote config.
GIT_AUTH_ARGS=()
if [ -n "${REPOSITORY_ACCESS_TOKEN}" ]; then
    AUTH_TOKEN="$(printf 'x-access-token:%s' "${REPOSITORY_ACCESS_TOKEN}" | base64 -w0)"
    GIT_AUTH_ARGS=(-c "http.extraheader=Authorization: Basic ${AUTH_TOKEN}")
else
    log "REPOSITORY_ACCESS_TOKEN is not set, syncing without authentication"
fi

log "Starting repository sync (${REPOSITORY_URL}, branch: ${REPOSITORY_BRANCH})"

# Reuse the cached clone when the configured URL still matches; otherwise
# wipe and clone fresh. This avoids re-downloading the full repo on every
# server restart.
NEEDS_CLONE=1
if [ -d "${REPO_CACHE}/.git" ]; then
    EXISTING_URL="$(git -C "${REPO_CACHE}" config --get remote.origin.url 2>/dev/null || echo "")"
    if [ "${EXISTING_URL}" = "${CLONE_URL}" ]; then
        NEEDS_CLONE=0
    else
        log "Cached repository origin (${EXISTING_URL}) differs from configured URL, recloning"
        rm -rf "${REPO_CACHE}"
    fi
fi

if [ "${NEEDS_CLONE}" = "1" ]; then
    log "Cloning ${REPOSITORY_URL} into ${REPO_CACHE}"
    rm -rf "${REPO_CACHE}"
    git "${GIT_AUTH_ARGS[@]}" clone --depth 1 -b "${REPOSITORY_BRANCH}" "${CLONE_URL}" "${REPO_CACHE}"
else
    log "Updating cached repository at ${REPO_CACHE}"
    git "${GIT_AUTH_ARGS[@]}" -C "${REPO_CACHE}" fetch --depth 1 origin "${REPOSITORY_BRANCH}"
    git -C "${REPO_CACHE}" reset --hard FETCH_HEAD
    git -C "${REPO_CACHE}" clean -fdx
fi

SRC="${REPO_CACHE}${REPOSITORY_DIR:+/${REPOSITORY_DIR}}"
CONFIG_PATH="${SRC}/egg-config.json"

if [ -f "${CONFIG_PATH}" ]; then
    log "Applying delete rules from ${CONFIG_PATH}"
    while IFS= read -r DELETE_PATH; do
        [ -z "${DELETE_PATH}" ] && continue
        if [ -d "${DELETE_PATH}" ]; then
            log "Deleting ${DELETE_PATH}"
            rm -rf "${DELETE_PATH}"
        else
            log "${DELETE_PATH} does not exist, skipping deletion"
        fi
    done < <(jq -r '.Delete[]?' "${CONFIG_PATH}")
else
    log "No egg-config.json at ${CONFIG_PATH}, skipping delete step"
fi

mkdir -p "${INSTALL_DIR}"

# cp -rT merges SRC's contents into INSTALL_DIR (no nested copy of SRC) and,
# unlike `cp -r SRC/*`, includes dotfiles.
log "Copying ${SRC}/ to ${INSTALL_DIR}/"
cp -rT "${SRC}" "${INSTALL_DIR}"

# When syncing from the repo root (REPOSITORY_DIR empty), the .git folder
# lands inside INSTALL_DIR. Strip it so the running server doesn't ship
# git metadata.
rm -rf "${INSTALL_DIR}/.git"

log "Repository sync completed"
