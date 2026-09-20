# General Manager — cross-app conventions

This folder holds decisions that span more than one app. Per-app knowledge stays in each app's own manager
(`dcm-manager`, `testapp/hunter-manager`, `flash/flash-manager`, `tapit/tapit-manager`, `racer/racer-manager`).
All paths are relative to `/Users/fkavum/Documents/project/`.

## Apps

| NN | App | Status | Code | Manager |
|---|---|---|---|---|
| 00 | Common infra | running on VPS | `dcm-docker/common-infra` (shared MySQL `dcx-mysql-container`, `dcx-network`), `dcm-docker/Grafana`, `dcm-docker/traefik`, `bash-scripts/` (host nginx, deploy scripts) | this folder |
| 01 | DCM / Crossle | **production** | `dcm-web`, `dcm-game-server`, `dcm-generator`, `dcm-client` (Unity), `dcm-admin`, `dcm-docker/crossle*`, `dcxstudios-website` | `dcm-manager/introduction.md` |
| 02 | Hunter | pre-MVP | `testapp/hunter-web`, `testapp/client` (Flutter PWA), `testapp/off-mirror` (parked) | `testapp/hunter-manager/introduction.md` |
| 03 | Flash | deployed API, PWA not yet | `flash/flash-web`, `flash/client` (Flutter PWA) | `flash/flash-manager/introduction.md` |
| 04 | Tapit | not deployed | `tapit/tapit-web`, `tapit/tapit-client` (Flutter PWA) | `tapit/tapit-manager/introduction.md` |
| 05 | Racer | local only | `racer-web`, `racer` (Unity) | `racer/racer-manager/introduction.md` |

## Ports

See **[PORTS.md](PORTS.md)** — the only authoritative list. Summary of the scheme:

- Port = `2NNRR`: `NN` app number, `RR` role offset. Range 20000–29999, 100 ports per app.
- Role offsets are identical across apps: `00` web API, `01` game TCP, `02` game WS, `03` generator, `04` admin API,
  `10` SQL, `11` Redis, `12` other DB, `13` object storage, `20` main client, `21` PWA, `22` admin SPA, `3x` metrics of backend `0x`.
- Our own services bind the registry port inside the container (host port == container port).
  Third-party images keep native ports inside (MySQL 3306, Redis 6379, Mongo 27017, nginx 80); only the host publish uses the registry number.
- Compose files use env with the registry value as default, e.g. `"${DCM_WEB_PORT:-20100}:20100"`.
- Legacy public ports are kept as extra publishes while shipped clients depend on them (DCM 2303 / 2306).

Adding a service: pick the role offset, write it in `PORTS.md` first, then wire compose → bind → consumers → Dokploy target → Prometheus → docs (checklist at the bottom of `PORTS.md`).

Adding an app: take the next free `NN`, add a row to the app table above and to `PORTS.md`.

## Shared infrastructure facts

- `dcx-mysql-container` (host 20010 → 3306, network `dcx-network`) is the one shared MySQL; each app creates its own database in its migration 0000. It is **not** the Crossle game DB (`dcm-mysql-container`, host 20110, network `dcm-network`).
- Public HTTPS for every web service goes through Dokploy's Traefik on `dokploy-network`. Dokploy stores the **target container port** in its UI; it is not in any repo, so a port move needs a manual Dokploy edit.
- The Ubuntu host nginx (`bash-scripts/apps/dcm_ubuntu/nginx`) still fronts Crossle: TCP stream `2303 → 20101`, HTTP vhosts → `20100`.
- Prometheus config lives in `dcm-docker/Grafana/prometheus.yml`; every metrics port change goes there too.

## How we work with AI

Same convention as the app managers: multi-project features get a folder `general-manager/implementations/{feature}/`
with per-project notes and a `session_progress.md`. Move to `implementation-done/` when finished.
Current: `implementations/port-scheme/` — the migration to the `2NNRR` scheme.
