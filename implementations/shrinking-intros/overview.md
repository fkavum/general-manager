# shrinking-intros — every manager `introduction.md` becomes a map again, not a log

Owner, 2026-09-27: "right now I am paying too much for new sessions because introduction.md is becoming larger and
larger with each implementation plan for all projects … do it asap." Multi-project: every manager
(`general-manager`, `dcm-manager` + `dict-manager` + `admin-manager`, `hunter-manager`, `flash-manager`,
`tapit-manager`, `racer-manager`). Paths relative to `/Users/fkavum/Documents/project/`.

## 1. The problem, measured (2026-09-27)

| Intro | Lines | Words | Biggest sections (words) |
|---|---|---|---|
| `dcm-manager/introduction.md` | 406 | 8,484 | How We Work With AI **4,940** (18 active bullets, 37–844 words each; `meta-art` alone 844, `tutorial-system` 646, `meta` 529), Shared Code Systems **1,471** (five dated change logs), Hard rules 333, Infrastructure 343 (port table duplicating `PORTS.md`), Unity Editor access 358 |
| `racer/racer-manager/introduction.md` | 304 | 5,091 | How We Work With AI **2,017**, racer-web project rules **1,364**, Unity Editor access 350 (same text as dcm's), Offline-first rule 343 |
| `testapp/hunter-manager/introduction.md` | 311 | 4,312 | Test account **1,493**, hunter-web project rules **788**, hunter-web Structure 366 |
| `flash/flash-manager/introduction.md` | 286 | 3,637 | flash-web project rules **927**, How We Work With AI 600, Client Structure 453 + 138, Current State 295 |
| `tapit/tapit-manager/introduction.md` | 286 | 3,387 | tapit-web project rules **862**, Server Structure **672**, How We Work With AI 477, Client Structure 297 |
| `general-manager/introduction.md` | 96 | 1,039 | fine; Upstream ownership 261 duplicates dcm-manager |
| `dcm-manager/dict-manager/introduction.md` | 152 | 1,382 | fine |
| `dcm-manager/admin-manager/introduction.md` | 228 | 1,897 | Learning rules/subjects 286, Project Layout 246 — borderline |

`dcm-manager/introduction.md` alone is ~29k tokens when read; the convention says every session starts with it. The
active-implementation bullets are the growth engine: each session appends its result to the bullet, so the intro grows
with every plan and never shrinks, and the same text also exists in the feature's `overview.md`/`session_progress.md`.

## 2. Decision

**An intro is a map: what exists, where it is, and one line per open implementation. Everything with a date in it
is a log and lives elsewhere.** Hard caps, enforced by a script: **≤ 150 lines and ≤ 2,000 words** per intro; an
active-implementation line **≤ 30 words**. Nothing is deleted — every paragraph that leaves an intro is moved to a
named destination (§3), so no information is lost and no plan has to be re-derived.

Allowed sections (template in §4), in this order: title + one-paragraph purpose · Projects table (role, path) ·
Communication (diagram, ≤ 10 lines) · Shared code (one line per system: what, where, how to sync → link) ·
Infrastructure (ports → `PORTS.md`, containers, Dokploy target ports, where backups live; ≤ 12 lines) · How we work
with AI (≤ 8 lines: convention + link to `general-manager/introduction.md`) · **Active implementations (one line
each)** · AI rules (2 lines: hard rules pointer + which files to read) · Cross-project workflows (≤ 12 lines, or a link).

## 3. What moves where (per section type — the same rule in every manager)

| Section type today | Destination | Intro keeps |
|---|---|---|
| Active implementation paragraph (dcm: 18 × 37–844 words; racer/hunter/flash/tapit similar) | The feature's own folder: the paragraph is appended verbatim to `implementations/<x>/session_progress.md` under `## Intro summary as of 2026-09-27 (moved from introduction.md)`. If the folder has no `session_progress.md`, create it with that section. | `- \`implementations/<x>/\` — <purpose, ≤ 15 words> (<state words: web ✅ · client 🔲 · blocked D1–D4>)` |
| Shared-change logs (dcm Shared Code Systems, five dated entries, 1,471 words) | `dcm-manager/docs/shared-change-log.md`, append-only, newest first, same text. Future entries go there; the upstream rule "note shared changes here" now points to that file. | One paragraph per shared system: what it is, source path, sync command, link to the log. |
| Project-specific AI rules (`### <app>-web — project-specific AI rules`, 788–1,364 words) | **`<app>-web/Src/Docs/AI_RULES.local.md`** (project-owned, next to the byte-identical generic `AI_RULES.md`). The generic master gets one new first line: "Also read `AI_RULES.local.md` in this folder if it exists." → master + 4 copies re-synced. Client-side rules stay in each client's `AI_RULES.md`. (D2) | `AI rules: Src/Docs/AI_RULES.md (generic, synced) + AI_RULES.local.md (this app).` |
| Hard rules block (333 words in dcm, 102 in others, ×6 copies) | Already in `general-manager/introduction.md`. | Two lines: `Hard rules (no exceptions): never commit; no secret-management advice — full text in general-manager/introduction.md → Hard rules.` |
| Unity Editor access (dcm 358 + racer 350 words, plus `docs/unity-cli-adoption-guide.md` duplicated in both managers) | `general-manager/docs/unity/README.md` (the section) + one copy of the adoption guide and cheat sheet there; `dcm-manager/docs/` and `racer-manager/docs/` keep a 1-line pointer file or are deleted (D4). | Three lines: project, Unity version, "how the AI drives the Editor → general-manager/docs/unity/". |
| Port tables in intros (dcm Infrastructure 343 words) | Already in `PORTS.md`. | Container names, networks, Dokploy target-port line, backup location (D5), links. |
| Long reference material: hunter "Test account" (1,493), tapit "Server Structure" (672) and "Data Model" (195), flash/tapit "Client Structure" (453+138 / 297), dcm "dcm-generator Structure" + "DontCrossMe" + "Word Data Sources" (482), flash "Before the Next flash-web Deploy" (208), racer "Offline-First Porting" (343) | `<manager>/docs/<topic>.md` — one file per topic, same text (`docs/test-account.md`, `docs/server-structure.md`, `docs/client-structure.md`, `docs/generator.md`, `docs/deploy-checklist.md`, `docs/offline-first-rule.md`). Where a repo README already covers it (`dcm-generator/Docs/README.md`, each web `Src/Docs/README.md`) link there instead of copying. | One line per topic with the link. |
| "Current State / Next Steps" narratives (hunter 128, flash 295) | `session_progress.md` of the implementation they describe, or `docs/roadmap.md` if they are not tied to one. | Nothing (the active list is the state). |
| Upstream ownership paragraph (general-manager 261 words, repeated in dcm-manager) | Stays only in `general-manager/introduction.md`; dcm-manager links to it. | Link. |

## 4. Template — `general-manager/docs/introduction.template.md`

```markdown
# <App> — Project Introduction
<Two or three sentences: what it is, status (production / pre-MVP / local), what the client and server are.>
All paths are relative to `/Users/fkavum/Documents/project/`.

## Projects
| Project | Role | Path | Run/build |
|---|---|---|---|

## Communication
<≤ 10-line diagram>

## Shared code
- **<System>** — <what>. Source `<path>`. Sync: `<command>`. Log: `docs/shared-change-log.md`.

## Infrastructure
- Ports: `general-manager/PORTS.md` (app NN). Containers: … Networks: … Dokploy target ports: … Backups: …

## How we work with AI
Convention: `general-manager/introduction.md` → How we work with AI. Feature folders under `implementations/`,
finished ones under `implementation-done/`. Resume a feature with this file + its folder only.

## Active implementations (one line each, ≤ 30 words; details live in the folder)
- `implementations/<x>/` — <purpose> (<state>)

## Parked (decisions pending or not scheduled)
- `implementations/_parked/<y>/` — <purpose> (blocked on D1–D3)

## AI rules
Hard rules (no exceptions): never commit; no secret-management advice — `general-manager/introduction.md` → Hard rules.
Read `<repo>/Src/Docs/AI_RULES.md` (generic, synced) + `AI_RULES.local.md` (this app) before implementing.

## Reference docs
- `docs/<topic>.md` — <one line>
```

## 5. Tooling — `general-manager/check-intros.sh`

Bash, no dependencies. For every `*/introduction.md` known to the app table (plus dict/admin sub-managers):
- lines ≤ 150 and words ≤ 2,000 → otherwise print the numbers and exit 1 at the end;
- every line under `## Active implementations` ≤ 30 words and starts with `` - `implementations/ ``;
- every folder in `implementations/` (excluding `_parked/`) has exactly one line in the active list and vice versa
  (catches the hunter `global-product-moderation` in-both-folders case and forgotten entries);
- `implementations/<x>/session_progress.md` exists for every active folder.
Prints one table (manager · lines · words · active · parked · problems). Becomes one row of the future `check-all.sh`
(`implementations/ci-gates/`). Rule for the AI, written into `general-manager/introduction.md` → How we work with AI:
**"When an implementation changes state, edit its `session_progress.md`. The intro line changes only when the state
words change. Never add narrative to `introduction.md`; run `check-intros.sh` before ending a multi-project session."**

## 6. WIP triage (owner agreed to the review's §3.3)

`dcm-manager/implementations/` has 22 folders + a stray `migrationguide.md`. Proposal, applied in P1 with the owner's
one-word answer per row (keep active / park / done):

| Folder | Proposal | Why |
|---|---|---|
| auth, email-login, friends, tutorial-system | **active** (the 1.0.9 content, `crossle-release-discipline/`) | code-complete, waiting on editor pass/smoke |
| app-icon, splash-screen, meta-art, font-decisions, asset-cleaning | **active** — the "one month of art" | owner: art is the release blocker |
| webgl-support, webgl-page-design | **park** until `wss://` router + mini setup | code ✅, ops open, not in 1.0.9 |
| mail-provider | **active** (unblocks email-login) or park if not in 1.0.9 | all steps are account/DNS work |
| meta, teams, mini-game-ideas, seasonal-leaderboard, first-time-experience | **park** (`_parked/`) | blocked on decisions or Phase-2 scope |
| android-bundle-optimization | **park** (deadline Feb 2027) | research done, no decisions yet |
| notification-upgrade, support-image-attachment | **park** | small, not scheduled |
| GlobalHelpers, helpers-to-take, `migrationguide.md` | owner to say — look like notes, move to `docs/` | not implementations |

Same pass for hunter (12 open), racer (8), flash (6), tapit (6): the owner answers per row in `session_progress.md`.
Target after triage: **≤ 5 active per manager**, the rest under `implementations/_parked/` (folder move only, nothing
edited inside). `_parked/` is excluded from the intro's active list and from the "one line per folder" check.

## 7. Docs to update

| File | Change |
|---|---|
| `general-manager/introduction.md` | How we work with AI: caps, the "never add narrative" rule, `check-intros.sh`, `_parked/`; link the template |
| `general-manager/docs/introduction.template.md`, `general-manager/docs/unity/` | new |
| `testapp/hunter-manager/docs/web-modularization/AI_RULES.web.md` + 4 copies | first line: read `AI_RULES.local.md` if present (re-sync, md5 check) |
| Each manager intro | rewritten to the template; moved text lands per §3 in the same change |
| `dcm-manager/docs/shared-change-log.md` and per-manager `docs/*.md` | new, verbatim moved text with a "moved from introduction.md on <date>" first line |

## 8. Phases

| Phase | Scope | Gate |
|---|---|---|
| **P0 Tooling + template** | `check-intros.sh`, `introduction.template.md`, convention text in general-manager, `AI_RULES.web.md` first line + 4 copies | script runs, reports today's numbers (all red), md5 of the 5 rules copies identical |
| **P1 dcm-manager** | Triage table (§6) answered; 18 bullets → one line each + text appended to each `session_progress.md`; change logs → `docs/shared-change-log.md`; Unity section → `general-manager/docs/unity/`; generator/DontCrossMe/word-data → `docs/generator.md` (or links to `dcm-generator/Docs/README.md`); port table → links; hard rules → pointer | `check-intros.sh` green for dcm-manager; **resume test**: a fresh session given only the new intro + `implementations/friends/` must list the remaining friends steps correctly (compare with the old bullet) |
| **P2 hunter, flash, tapit** | project rules → `AI_RULES.local.md`; Test account / Server Structure / Client Structure / deploy checklist → `docs/`; active lists shortened; triage answered | green ×3, same resume test on one feature each |
| **P3 racer + sub-managers** | racer: rules → `racer-web/Src/Docs/AI_RULES.local.md`, offline-first rule → `docs/offline-first-rule.md`, Unity section → shared; dict/admin: trim to caps | green for all 8 |
| **P4 general-manager itself** | intro trimmed (Upstream ownership → 5 lines + link to `implementation-done/upstream-ownership/overview.md`); `check-intros.sh` wired into `check-all.sh` when `ci-gates/` lands; move this folder to `implementation-done/` | green |

## 9. Decisions for Fatih

| # | Question | Proposal |
|---|---|---|
| D1 | Caps | 150 lines / 2,000 words per intro; 30 words per active line. (dcm-manager goes 406 → ~130 lines.) |
| D2 | Where do project-specific web rules live? | `<app>-web/Src/Docs/AI_RULES.local.md` next to the synced generic file (rules next to the code they govern; monorepos keep them in the same repo anyway). Alternative: `<manager>/docs/ai-rules.md`. |
| D3 | Where does a moved active-bullet paragraph go? | Appended to that feature's `session_progress.md` (it is state, not plan). Never deleted. |
| D4 | Unity CLI docs | One copy under `general-manager/docs/unity/`; the two manager copies become 1-line pointers. |
| D5 | Backups line | dcm-manager Infrastructure gets "Backups: daily on the Dokploy server (owner 2026-09-27); `bash-scripts` `backup_mysql` is the older Mac-side path" — the review found no scheduler in the repos. |
| D6 | Triage answers (§6 table, and the same for the other four managers) | Owner answers per row in `session_progress.md`; default if unanswered = park. |
| D7 | `_parked/` vs a `parked.md` list | Folder move (`implementations/_parked/<x>/`): nothing inside changes, `check-intros.sh` skips it, and un-parking is `mv`. |

## 10. Effort

P0 ½ day · P1 ½ day (the resume test included) · P2 ½ day · P3–P4 ½ day ≈ 2 days. Payoff: every future session on
Crossle starts ~25k tokens lighter, and the intro stops growing.
