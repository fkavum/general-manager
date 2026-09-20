# Port Registry — single source of truth

Scheme: every port is `2` + `NN` (two-digit app number) + `RR` (two-digit role offset) → `2NNRR`.
Range 20000–29999. App 00 is shared infrastructure. Decode at a glance: **20221** = app 02 (Hunter), role 21 (PWA dev server).

Rules
- This file is authoritative. Compose files read `${VAR:-<registry value>}`; the default must equal this table.
- Our own services (.NET, Java, Node) bind the registry port **inside** the container too — host port == container port.
- Third-party images (MySQL 3306, Redis 6379, Mongo 27017, nginx 80/8080) keep their native port inside; the registry port is only the host publish. In-network traffic uses `container-name:native-port`.
- Legacy public ports that shipped clients depend on are kept as **additional** host publishes until retired (see DCM game server).
- A role offset means the same thing in every app. Metrics of the service at offset `0x` live at `3x`.

## Role offsets

| Offset | Group | Meaning |
|---|---|---|
| 00 | backend | web / REST API |
| 01 | backend | game server TCP |
| 02 | backend | game server WebSocket |
| 03 | backend | generator / worker / secondary API |
| 04 | backend | admin API |
| 05–09 | backend | spare |
| 10 | infra | SQL (MySQL / Postgres) |
| 11 | infra | Redis |
| 12 | infra | other DB (Mongo, …) |
| 13 | infra | object storage (S3 / RustFS) |
| 14–19 | infra | spare |
| 20 | client | main client (WebGL host, static site) |
| 21 | client | PWA dev server / PWA container |
| 22 | client | admin SPA |
| 23–29 | client | spare |
| 30–39 | observability | metrics of backend at `0x` → `3x` (web 30, game 31, generator 33, admin 34). Common block: 30 Prometheus, 31 Grafana, 32 nginx-exporter, 33 mysql-exporter, 34 cadvisor, 35 nginx status vhost |
| 40–99 | — | spare |

## App numbers

| NN | App | Block | Manager |
|---|---|---|---|
| 00 | Common (shared infra, edge, monitoring) | 20000–20099 | `general-manager/`, `dcm-docker/common-infra`, `dcm-docker/Grafana`, `dcm-docker/traefik` |
| 01 | DCM / Crossle (**production**) | 20100–20199 | `dcm-manager/introduction.md` |
| 02 | Hunter | 20200–20299 | `testapp/hunter-manager/introduction.md` |
| 03 | Flash | 20300–20399 | `flash/flash-manager/introduction.md` |
| 04 | Tapit | 20400–20499 | `tapit/tapit-manager/introduction.md` |
| 05 | Racer | 20500–20599 | `racer/racer-manager/introduction.md` |
| 06–99 | free | | |

## Allocations

| App | Service | Port | Notes |
|---|---|---|---|
| Common | Traefik (edge) | 80 / 443 | standard, unchanged |
| Common | Traefik dashboard (standalone stack) | 20005 | was 8080 |
| Common | dcx-mysql-container (shared MySQL 8) | 20010 → 3306 | was 3309. Used by hunter, flash, tapit, dcm-admin |
| Common | RustFS / S3 | 20013 | reserved; currently reached via Traefik hostname, no compose in our repos |
| Common | Prometheus | 20030 | was 9090 |
| Common | Grafana | 20031 → 3000 | was 2999 |
| Common | nginx-exporter | 20032 | was 9113 |
| Common | mysql-exporter | 20033 | was 9104 |
| Common | cadvisor | 20034 → 8080 | was 8085 |
| Common | nginx `/nginx_status` vhost (Ubuntu host nginx) | 20035 | was 8080 |
| DCM | dcm-web (API) | 20100 | was 2325 |
| DCM | game server TCP | 20101 | was 2323 inside / 2303 public. **Legacy 2303→20101 also published** until old clients retire |
| DCM | game server WebSocket `/ws` | 20102 | was 2326 inside / 2306 public. **Legacy 2306→20102 also published** |
| DCM | CrossGenerator API | 20103 | was 3310 |
| DCM | dcm-admin backend (Spring) | 20104 | was 8080 |
| DCM | dcm-mysql-container (game MySQL) | 20110 → 3306 | was 3308 |
| DCM | dcm-redis-container | 20111 → 6379 | was 6379. In-network alias `redis:6379` unchanged |
| DCM | play-crossle WebGL host | 20120 → 80 | Traefik-only in prod; local test mapping |
| DCM | dcm-admin frontend (SPA) | 20122 → 8080 | was 8081 (nginx-unprivileged inside) |
| DCM | game server Prometheus metrics | 20131 | was 9201 hardcoded; now config-driven |
| Hunter | hunter-web (API + SignalR) | 20200 | was 5103 → 8080 |
| Hunter | off-mirror API | 20201 | was 5199 → 8080 (parked) |
| Hunter | off-mirror Mongo | 20212 → 27017 | was 27027 (parked) |
| Hunter | PWA dev server / PWA container | 20221 | was 8090 |
| Flash | flash-web (API) | 20300 | was 5210 docker / 5276 local |
| Flash | PWA dev server / PWA container | 20321 | was 8091 |
| Tapit | tapit-web (API) | 20400 | was 5062 |
| Tapit | PWA dev server / PWA container | 20421 | was 8090 (collided with Hunter) |
| Racer | racer-web (API) | 20500 | was 5089. Uses the shared MySQL (20010); racer has no DB container of its own since 2026-09-11 |
| Racer | Unity client → API | 20500 | serialized default in Boot scene |

## Retired / legacy numbers (do not reuse for anything else)

| Port | Was | Status |
|---|---|---|
| 2303 / 2306 | DCM public game TCP / WS | **still published** as legacy aliases of 20101 / 20102; baked into shipped Unity builds and advertised by dcm-web prod config. Retire when old builds are gone. |
| 2305, 2311, 2327 | old dcm-web, old service, Mac-mini MySQL | dead, only in stale base configs |
| 2323 / 2326 / 2325 / 3310 / 3308 / 9201 | DCM internals | replaced |
| 3309 | shared MySQL | replaced by 20010 |
| 20510 | racer's own MySQL | **withdrawn** 2026-09-11 — racer moved to the shared 20010; do not reuse |
| 5062 / 5089 / 5103 / 5199 / 5210 / 5276 | app APIs | replaced |
| 8080 / 8081 / 8085 / 8090 / 8091 | admin, cadvisor, PWAs | replaced |

## Deploy checklist when a port moves

1. Compose `ports:` default and the service's bind (`ASPNETCORE_URLS` / `Urls` / `server.port`).
2. Every consumer: other services' `*_docker.json` (`container-name:port`), local `appsettings.local`, client configs, CORS allowlists, tests.
3. Dokploy / Traefik **target container port** (set in Dokploy UI, not in repo) for every web service that changed.
4. Ubuntu host nginx (`bash-scripts/apps/dcm_ubuntu/nginx`) upstreams.
5. Prometheus scrape targets (`dcm-docker/Grafana/prometheus.yml`).
6. This file, then the app's manager `introduction.md`.
