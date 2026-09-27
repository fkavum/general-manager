# App icons — session progress

Plan: `overview.md`. Strategy doc: `../../docs/app-icons/README.md`.

## Status (2026-09-27) — Hunter ✅, Flash ✅, Tapit ❌
- [x] Compare Hunter vs Flash, decide (Hunter's Swift pipeline)
- [x] Master `general-manager/app-icons/app_icons.swift` (Hunter's script, two comments made generic) + `README.md`
- [x] Hunter: `testapp/client/tool/app_icons.swift` replaced by the master. Regenerating Hunter's masters with it in a
      scratch copy gave byte-identical files (34/34), so no icon in Hunter changed and nothing was regenerated there.
- [x] Flash: adopted (details in `flash/flash-manager/implementations/icon/session_progress.md`); web build + `actool` green
- [x] Docs: `general-manager/introduction.md` (App icons section), hunter-manager introduction + icon progress,
      flash-manager introduction + icon folder

## Step 2 — central control (2026-09-27) ✅
- [x] `app-icons/` moved to `docs/app-icons/`; artwork copied in as `hunter/source.png`, `flash/source.png`
- [x] `apps.txt` registry + `icons.sh` (`list` / `apply` / `check`); master header comment points at the new path
- [x] `apply all` → both clients' icon files byte-identical to before (hash of every file under `Resources/AppIcon`,
      `web/icons`, Android `res`, both appiconsets, Windows `resources`); only `tool/app_icons.swift` changed (comment)
- [x] `check` fails before `apply` (old script header) and passes after
- [x] Hand-drawn override tested on Flash and removed: valid file reaches web + macOS and counts in `list`; a typo name
      and a wrong-sized file are refused before the client is touched; unknown app refused; Flash restored byte-identical
- [x] Docs repointed: general-manager introduction, hunter-manager introduction + icon progress, flash-manager
      introduction + icon folder, both clients' `Resources/AppIcon/README.md`

## Next steps
- Tapit (`tapit/tapit-client`) still has Flutter's default icons — adopt per the README's "Adding a client" steps when
  its artwork exists.
- Nothing is committed in any repo (hard rule).
