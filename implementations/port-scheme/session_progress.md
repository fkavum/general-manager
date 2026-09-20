# Port scheme migration — progress

Decided 2026-09-11: `2NNRR` scheme, 100 ports per app, role offsets in `../../PORTS.md`.

| Step | Status |
|---|---|
| Registry + general-manager written | ✅ 2026-09-11 |
| Common infra: dcx-mysql 3309→20010, Grafana stack 2003x, traefik dashboard 20005, host nginx status 20035, prometheus targets (game 20131, web 20100, mysql-exporter → 20110) | ✅ repo edits done, `docker compose config` OK |
| Hunter: 20200 / 20201 / 20212 / 20221, MySQL 20010 | ✅ build OK |
| Flash: 20300 / 20321, MySQL 20010 | ✅ build OK |
| Tapit: 20400 / 20421, CORS + smoke test updated, MySQL 20010 | ✅ `dotnet test` 20/20 |
| Racer: 20500, Unity Boot scene + bootstrapper defaults (own MySQL 20510 later withdrawn, see below) | ✅ build OK |
| DCM: 20100–20131 across web/game/generator/admin/client-local/compose/host nginx; metrics config-driven (`AppConfig.Metrics.Port`); 2303/2306 kept as legacy publishes → 20101/20102 | ✅ 3 solutions build, 9 composes render |
| dcm-docker committed (`203f3dc new ports added`, by owner) — other repos uncommitted | ℹ️ |
| **Manual, not done:** Dokploy target container ports: dcm-web 2325→20100, generator 3310→20103, dcm-admin api 8080→20104, hunter-web 8080→20200, flash-web 5210→20300, tapit-web 5062→20400 | 🔲 |
| **Manual:** VPS redeploy order — common-infra → crossle-infra → game server → dcm-web → generator → dcm-admin → Grafana; reload host nginx (`game-server.conf`, `crossle-dcxstudios.conf`, `dcm-web.conf`, `metrics.conf`) | 🔲 |
| **Manual:** verify `:20100/health`, `:20103`, `:20131/metrics`, TCP 2303 + 20101, WS 2306 + 20102, Prometheus targets up | 🔲 |
| **Later flip:** dcm-web `prod/dev/stage_docker` GameServer 2303/2306 → 20101/20102, then client `AppConfig_prod/dev.json`, then drop `2303:20101` / `2306:20102` publishes | 🔲 |
| Rebuild Flutter PWAs (hunter, flash, tapit) — API_BASE_URL compiled in | 🔲 |
| **Racer follow-up 2026-09-11:** dropped its own MySQL (`Docker/Infra` removed) → shared `dcx-mysql-container` (20010 host / 3306 in-network); added the `--env=` config pattern (`appsettings.local/docker.json`) like dcm-web/flash/tapit/hunter; added migration `0000_create_database.sql`; Unity client moved to `Assets/Resources/AppConfig*.json` + `EnvironmentInfo`/`AppModel` like dcm-client | ✅ verified: app boots, migration ran on the shared instance, `/health/deep` MySQL check Healthy, Unity assembly compiles |
| Known leftovers: `WebSocketSecure:false` everywhere (prod WebGL over HTTPS blocked, separate task); Grafana compose mounts `./my.cnf` but file is `./.my.cnf`; racer-web has no `appsettings.Docker.json` (container still targets localhost MySQL) | ℹ️ |
