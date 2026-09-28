# Architecture review — progress

Review written 2026-09-27 (`report.md`). This folder tracks which recommendations Fatih accepts and their state.
Move to `implementation-done/` when every accepted item is ✅ or explicitly rejected.

| # | Recommendation (report §) | Decision | Status |
|---|---|---|---|
| 1 | Ship Crossle: `feature/friends` → `dev` now; release in ~1 month after art (owner 2026-09-27); plan `implementations/crossle-release-discipline/` (§3.1) | ✅ agreed, ~1 month | 🔲 |
| 2 | Branch rule in dcm-manager intro: feature branches ≤ 2 weeks, `dev` always stage-deployable, shared changes ride the next release (§3.1) | 🔲 | 🔲 |
| 3 | ~~Scheduled MySQL backup~~ — already daily on the Dokploy server (owner 2026-09-27). Left: document it in dcm-manager intro + one restore drill as the migration rehearsal (§3.2) | ✅ decided | 🔲 |
| 4 | GitHub Actions build+test for dcm-web, hunter-web, flash-web, tapit-web, racer-web (§3.2) | 🔲 | 🔲 |
| 5 | `general-manager/check-all.sh` running every existing gate (§3.2) | 🔲 | 🔲 |
| 6 | Close or park `implementations/port-scheme/` (Dokploy ports, VPS redeploy, `dcm-docker` branch) (§3.2) | 🔲 | 🔲 |
| 7 | Intros ≤ 150 lines; one-line active list; change log to `docs/`; hard rules referenced not copied (§3.3) → plan `implementations/shrinking-intros/` | ✅ owner: do asap | 🔲 |
| 8 | Triage dcm-manager's 23 open folders into active (≤ 3) / parked / ideas (§3.3) | 🔲 | 🔲 |
| 9 | `dcx-flutter-core` path package for the three Flutter clients (§3.4) → `implementation-done/flutter-core/` | ✅ owner: yes, how-to left to the plan | ✅ 2026-09-27 |
| 10 | Unity shared package — deferred until Racer nears release (§3.4) | 🔲 | ⏸ |
| 11 | Sync scripts refuse a dirty dcm-web; `HttpShared` single location (§3.5) | 🔲 | 🔲 |
| 12 | Move web masters from hunter-manager to `general-manager/docs/web/`; delete `dcm-manager/tools` v1; fix README pointers (§3.5) | 🔲 | 🔲 |
| 13 | Local NuGet feed instead of DLLs in `Src/Lib/` — later (§3.5) | 🔲 | ⏸ |
| 14 | Monorepo shape written down as the rule for new apps (§3.6) | 🔲 | 🔲 |
| 15 | racer-web test project with route/EF baselines (§3.5) | 🔲 | 🔲 |

Plans written 2026-09-27 (owner: "create implementation plan for each item"): `crossle-release-discipline/`,
`ci-gates/` (items 4, 5), `shrinking-intros/` (7, 8), `flutter-core/` (9), `sharing-hygiene/` (11, 12, 14, 15),
`unity-core/` (10, parked), `nuget-feed/` (13, parked). Item 6 lives in the existing `port-scheme/`.

Nothing committed (hard rule).
