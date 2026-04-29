# Unturned Git

Pterodactyl egg for Unturned dedicated servers that pulls per-server config and plugins from a Git repository on startup.

Fork of [RestoreMonarchyPlugins/UnturnedGit](https://github.com/RestoreMonarchyPlugins/UnturnedGit). Image is published to GHCR instead of Docker Hub.

## Setup

1. Import `egg-unturned-git.json` into Pterodactyl.
2. Create a server, set `REPOSITORY_ENABLED=1`, fill in the variables below, start it.

## Variables

| Variable | Default | Notes |
|---|---|---|
| `REPOSITORY_ENABLED` | `0` | Set to `1` to enable Git sync |
| `REPOSITORY_URL` | — | Repo URL without scheme, e.g. `github.com/you/yourrepo.git` (a leading `https://` is stripped if present) |
| `REPOSITORY_BRANCH` | `master` | Branch to pull |
| `REPOSITORY_DIR` | — | Subdirectory inside the repo to use as the server root. One repo can host many servers, one per directory |
| `REPOSITORY_ACCESS_TOKEN` | — | Required for private repos. Sent as an HTTP header, not embedded in the clone URL |

The repo is cached at `tmp/repo` and updated incrementally (`fetch` + `reset --hard`) on subsequent restarts.

## Per-server cleanup

Place an `egg-config.json` in your `REPOSITORY_DIR` (or repo root) listing paths to wipe before each sync:

```json
{
  "Delete": [
    "Servers/unturned/Rocket/Plugins",
    "Servers/unturned/Rocket/Libraries"
  ]
}
```

This avoids stale files lingering after they're removed from the repo.

## Image

Pulls `ghcr.io/zombie-zonee/unturnedgit:latest`, built from `docker/Dockerfile` by the `Build and publish Docker image` workflow.
