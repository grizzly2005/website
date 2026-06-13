# Site update - 2026-06-13

## Context

The portfolio previously presented HYDRA as an always-on public VPS honeypot.
That instance is currently paused/expired, so the site should not imply live
collection, live sessions, or 24/7 infrastructure monitoring.

The maintained angle is now PDX:

- Burp Suite extension
- local Python bridge
- `.pdx` delta format
- DataRouter
- defensive/offensive replay and training-data workflows

## What changed

- The featured project copy now positions HYDRA as an archived research run.
- PDX/Burp is presented as the active, local-first workflow.
- The portfolio no longer fetches a temporary Cloudflare Tunnel for live stats.
- `/api/stats` returns a stable project status instead of proxying a dead VPS.
- The footer no longer claims 24/7 infrastructure monitoring.
- Cloudflare middleware blocks old public backup/bait paths:
  - `/.git` and `/.git/*`
  - `/.wrangler` and `/.wrangler/*`
  - `/admin` and `/admin/*`
  - `/backup` and `/backup/*`
  - `*.bak-theme`
  - `/.env`
- The old client-side admin credential demo was retired.
- Old `*.bak-theme` static backups were removed from the deployable tree.

## Why

This keeps the portfolio honest and easier to maintain:

- no dependency on a paid VPS subscription;
- no broken live metrics;
- no public secret-looking bait files;
- no client-side admin password surface;
- clearer story for recruiters or collaborators;
- better emphasis on the tool that can still be used locally during pentests.

## Current deployment

The site is hosted on Cloudflare Pages and should deploy from GitHub. No
Cloudflare dashboard change is required for this update unless the Pages project
is not connected to the expected repository.

Expected repo targets seen locally:

- `deploy`: `github.com/grizzly2005/website.git`
- `origin`: `github.com/groupe-massetti/portfolio-prod.git`

Active project repo linked from the portfolio:

- HYDRA/PDX: `github.com/grizzly2005/hydra-pdx.git`

## Next idea

Instead of "a bot that collects things from a honeypot", present the project as:

> PDX Evidence Pipeline: a local workbench that turns Burp traffic into
> structured security deltas, replay traces, MITRE-mapped notes, and clean
> training examples.

This is more durable than a live honeypot because it works during normal web
security work and does not require maintaining exposed infrastructure.

## If HYDRA is relaunched later

Do not re-enable live metrics directly against a temporary tunnel. Prefer:

1. a stable API endpoint;
2. a small sanitized status payload;
3. no raw session data on the portfolio;
4. no real or realistic secrets in static files;
5. a clear "live" vs "archived" label in the UI.
