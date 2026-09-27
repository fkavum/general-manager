# ci-gates — the gates that exist run by themselves

Review §3.2 items 2–3, owner 2026-09-27: agreed. Multi-project: general-manager, dcm-web, hunter-web, flash-web,
tapit-web, racer-web, the three Flutter clients. Paths relative to `/Users/fkavum/Documents/project/`.

## 1. What exists today and only runs when remembered

| Gate | Where | Proves |
|---|---|---|
| `Tools/sync-dcm-features.sh --check` | 4 downstreams | synced modules byte-identical to dcm-web |
| `Tools/list-shared-modules.sh` | dcm-web | no module is hosted AND wired |
| `dotnet build Dcm.sln` (incl. `Main.Hosted`) + `dotnet test` (152/153) | dcm-web | hosted modules still compile; wire contracts |
| `dotnet test` with `Baselines/routes.txt`, `efmodel.txt` | hunter 46, flash 93, tapit 20 attrs | route + EF model snapshots; racer-web has **no** test project |
| `docs/app-icons/icons.sh check` | general-manager | icon pipeline + artwork in sync |
| `bash/lib/test-generate.sh` | general-manager | launcher goldens |
| `check-intros.sh` (after `shrinking-intros/`) | general-manager | intro caps |
| `flutter analyze` / `flutter test` / `flutter build web` | 3 clients | nothing runs them |

No `.github/workflows` anywhere in the portfolio.

## 2. Decision (proposal)

Two layers, both cheap:

**A. Local: `general-manager/check-all.sh`** — one command, one table, exit 1 if any row fails. Runs every gate in
§1 that needs the sibling checkouts (the `--check` scripts need dcm-web next door, which CI does not have). Rule:
run it at the end of every multi-project implementation; the result line goes into that feature's
`session_progress.md`. Options: `--fast` (skips `dotnet test`), `--only <name>`.

**B. GitHub Actions per repo, build + test only.** One workflow file per .NET repo (five), path-filtered in the
monorepos, and one per Flutter client (three). Testcontainers works on `ubuntu-latest` (Docker preinstalled). No
deploy from CI — Dokploy and `bash-scripts` stay the deploy path (owner's webgl decision). Cross-repo checks
(`--check`) stay local in layer A; adding them to CI needs a second checkout of dcm-web with a token — later, if ever.

## 3. Workflow shape (.NET; the same file in every web repo, only `working-directory` differs)

```yaml
name: build-test
on: { push: { paths: ['hunter-web/**'] }, pull_request: { paths: ['hunter-web/**'] } }   # monorepo filter; dcm-web/racer-web: no paths
jobs:
  build-test:
    runs-on: ubuntu-latest
    defaults: { run: { working-directory: hunter-web } }        # dcm-web/racer-web: '.'
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with: { dotnet-version: '8.0.x' }
      - run: dotnet build --configuration Release
      - run: dotnet test --configuration Release --no-build --logger 'trx'
        env: { DOTNET_ROLL_FORWARD: LatestMajor }              # what Src/Docs/README.md says the tests need
```
dcm-web builds `Dcm.sln`, so `Main.Hosted` is part of the gate. Flutter: `subosito/flutter-action` pinned to
`3.44.4` (the version the Dockerfiles clone), then `flutter pub get`, `flutter analyze`, `flutter test`,
`flutter build web --release --dart-define-from-file=Resources/Configs/appsettings.dev.json`.
Vendored DLLs in `Src/Lib/` are in git, so restore needs nothing extra. Private repos: Actions is included in the
GitHub plan; no external service.

## 4. `check-all.sh` layout

```
general-manager/check-all.sh
  → dcm-web:       Tools/list-shared-modules.sh ; dotnet build Dcm.sln ; dotnet test (unless --fast)
  → 4 downstreams: Tools/sync-dcm-features.sh --check ; dotnet build ; dotnet test (unless --fast)
  → general-manager: bash/lib/test-generate.sh ; docs/app-icons/icons.sh check ; check-intros.sh
  → 3 clients:     flutter analyze (unless --fast)
prints: | target | gate | result | seconds |, exit 1 if any FAIL
```
Paths come from the app table (`introduction.md`); the script carries the same `${X_REPO:-default}` overrides as
`project.sh`. Written in the `bash/lib` style (`set -euo pipefail`, no `-p`, `GM_` env names).

## 5. Phases

| Phase | Scope | Gate |
|---|---|---|
| P0 | `check-all.sh` + README line in `general-manager/introduction.md`; run it once, record today's table in `session_progress.md` | all rows pass or each failure has an owner note |
| P1 | Actions workflow in dcm-web (the one that matters), watch one green run | green on `dev` |
| P2 | Actions in testapp (hunter-web), flash, tapit (path-filtered), racer-web | green ×4 |
| P3 | Flutter workflows ×3 | green ×3 |
| P4 | Docs: manager intros get "CI: build-test on push" one-liner; rule "run `check-all.sh` at the end of a multi-project implementation" in general-manager; move to `implementation-done/` | — |

## 6. Decisions for Fatih

| # | Question | Proposal |
|---|---|---|
| D1 | GitHub Actions at all? (webgl-page-design chose "no Actions" for the Unity/WebGL build) | Yes for **build + test** of .NET and Flutter — nothing to install, nothing deployed; keep the Mac mini for Unity. |
| D2 | `--check` in CI | No; local in `check-all.sh`. Revisit if drift is ever found after a session that ran the script. |
| D3 | racer-web test project | Add `Src/Main.Test` with the route + EF baselines copied from flash (ties in with `sharing-hygiene/`); until then CI builds only. |
| D4 | Flutter CI | Yes, `analyze` + `test` + `build web`; it also protects the future shared package (`flutter-core/`). |

Effort: P0 ½ day, P1–P3 ½ day, P4 ½ hour.
