# App icons — one strategy for every Flutter client

Owner, 2026-09-27: "centralize our icon strategy for all apps … if they are not same, use the best method and apply
it to the one not using. Less dependency always better."

## Before (2026-09-27, both uncommitted)

| | Hunter (`testapp/client`) | Flash (`flash/client`) |
|---|---|---|
| Tool | `tool/app_icons.swift` — CoreGraphics, one file | `tool/generate_icons.sh` — bash + `sips` + inline `python3` |
| Toolchain | Swift (Xcode CLT, already required for iOS/macOS builds) | bash, `sips`, `python3` |
| Per-size masters | `Resources/AppIcon/icon_<N>x<N>[_opaque].png`, `icon_maskable_…`, `icon_adaptive_fg_…` + `README.md` | none — one source, platform files renamed to `icon_<N>x<N>.png` |
| Hand-drawn sizes later | yes: replace a master, run `install` | no: every size is always derived from the source |
| Transparent source | handled: opaque variants get a white plate, no alpha channel (iOS rule) | **broken**: `sips` keeps alpha → App Store rejects the iOS icon |
| Platform file names | Flutter defaults kept (`Icon-App-*`, `app_icon_*`), `Contents.json` untouched | renamed, both `Contents.json` rewritten |
| Safe zones | maskable 62%, adaptive 47% (fits any artwork within a circle) | maskable 80%, adaptive 61% (assumes square artwork with its own margin — corners get cropped by a circle mask) |
| Windows ICO | PNG entries 16–256 | PNG entries 16–256 |

## Decision

**Hunter's method wins** on every axis the owner cares about: one tool instead of three, correct for transparent
artwork, the masters folder *is* the list of sizes to draw (the owner's `icon_256x256` naming ask), and smaller diffs
against the Flutter template. Flash's script is retired.

## Centralization (borrow-and-sync, like `AI_RULES.web.md`)

- Master: `general-manager/app-icons/app_icons.swift` — the only place the script is edited. (Moved to
  `general-manager/docs/app-icons/` in Step 2 below.)
- Every Flutter client carries a **byte-identical** copy at `client/tool/app_icons.swift`; check with
  `cmp general-manager/app-icons/app_icons.swift <client>/tool/app_icons.swift`.
- Per app (not synced): `Resources/AppIcon/source.png`, the generated masters, `Resources/AppIcon/README.md`, and the
  two Android XML files.
- Strategy doc + adoption table: `general-manager/app-icons/README.md`.

The only change to Hunter's script when it became the master: the safe-zone comment described Hunter's magnifier
artwork; it is now generic. Numbers and code are unchanged, so Hunter's output is byte-identical.

## Scope

- Hunter: copy of the master (comment-only diff). Nothing regenerated.
- Flash: adopt — remove `generate_icons.sh` + `Resources/Icon/`, restore Flutter's `Contents.json` and file names,
  add `Resources/AppIcon/`, run `all`.
- Tapit (`tapit/tapit-client`, Flutter): not touched — adoption listed as a next step.
- DCM / Racer: Unity clients, out of scope.

## Step 2 — control every app's icon from general-manager (owner, 2026-09-27)

"write the icon pipeline to the docs folder of general-manager, so we can control/add icons from there for all projects."

- Move `general-manager/app-icons/` → `general-manager/docs/app-icons/`.
- Artwork moves there too: `docs/app-icons/<app>/source.png` is the source of truth; a client's
  `Resources/AppIcon/source.png` becomes a copy. Optional hand-drawn masters go next to it
  (`docs/app-icons/<app>/icon_256x256.png`, exact master names) and override the generated ones.
- Registry `docs/app-icons/apps.txt`: `<app> <client path>` per adopted Flutter client.
- Driver `docs/app-icons/icons.sh` (bash only, no new tool):
  - `list` — apps, clients, what is in each art folder
  - `apply <app|all>` — copy the script + source into the client, `generate`, lay the hand-drawn overrides over the
    masters, `install`
  - `check [app|all]` — script, source and overrides in each client identical to general-manager (the sync gate)
- First-time adoption (manifest, `index.html`, Android XML) stays a documented manual step.
- Proof: `apply all` leaves Hunter's and Flash's icons byte-identical to what they are now (only the script's header
  comment changes, for the new master path).
