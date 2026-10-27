# card-platform — progress

Plan: `overview.md` (§3 decisions D1–D14, §4 phases). Per-project notes: `game_server_implementation.md`,
`web_implementation.md`, `client_implementation.md`, `infra_sync_implementation.md`.

| Step | Status |
|---|---|
| Maps of dcm-game-server / dcm-web / dcm-client / dcm-docker (read-only, 2026-10-27) | ✅ |
| Plan written | ✅ 2026-10-27 |
| D1–D16 answered by Fatih (2026-10-27): one `card-manager`, client repo per game, D16 without a column; **D2 revised the same day: backend mono repo `card/card-backend` (web, game-server, docker, manager, twin), only the Unity client separate**; sharing-hygiene D2 ✅ (root `HttpShared/` deleted) | ✅ |
| P1a server seams (S1–S8; S9 deferred to P1d) | ✅ 2026-10-27 — tests 443/3 known/446; local stack brought up (crossle-infra restarted, game server + web rebuilt from source): **`run-smoke.sh` ✅ exit 0** (3 games, rewards/stats/xp/log all through `GameEndReporter`, lobby metrics 101/102); **`game-conn-ramp` bench ✅** (`bench-results/20261027T080819_game-conn-ramp`: 600 bots, 0 errors, game.login p99 10 ms vs 17 ms on 2026-10-15, ping p99 1 ms); Crossle client Play-Mode login 🔲 (needs Unity) |
| P1b web: GameMembership module + 0068, `UserCoreData.GameId`, Stats extension seam, contracts complete + generator direct-to-target (H2) | ✅ 2026-10-27 — web tests 268/0/1 skipped; live set/get/aggregate verified; both CCG checkouts regenerated and identical |
| P1d sync tooling (`general-manager/docs/twin/`: script + 3 manifests + README; S9 upstream) | ✅ 2026-10-27 — scratch dry run: web twin builds, game-server twin builds + tests 125/3 known with `GameModules/Stub`, client twin synced; `--check` ×3 green; details `infra_sync_implementation.md` §1. S10 (legacy NUnit fixtures inside the server binary) left for the owner |
| CCG split + SharedData, pass 2 (2026-10-27, Fatih: "no name-based classification, folderize upstream too, change the namespaces") | ✅ — owner trees folderized (`Contracts/{Request,Response,Data}`, generator `GeneratorShared/{Request,Response,Data}`); three export scripts = plain mirrors; every shared namespace renamed to its export path (`HttpShared.<F>.<Sub>`, `SocketShared.<Area>.<Sub>`, `GeneratorShared.<Sub>`, `*.Core`); ~700 consumer files rewritten by script (`scratchpad/ns_migration{,2,3}.py`), 6 alias disambiguations by hand. Gates: web 268/0/1, server 444/3 known, generator 87/1 (LAN MySQL test), Unity 0 errors, `--check` ×3 up to date, `run-smoke.sh` against the restarted stack ✅ (`bench-results/20261027T144257_smoke`) |
| P1c client AppCore extraction (release window) | 🔲 |
| P2 `card/card-backend` mono repo + `card/batak-client` via `--init` (after the P1a/P1b commits), ports, manager | 🔲 |
| P4 re-sync after Crossle 1.0.9 | 🔲 |
| P3 Batak MVP | 🔲 |

Nothing committed (hard rule).
