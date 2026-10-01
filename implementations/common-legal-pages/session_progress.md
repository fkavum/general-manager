# Common Legal Pages — Session Progress

Plan: `overview.md`. Planned 2026-09-28 from racer's `store-compliance` (C8).

## Status

| Step | Status | Notes |
|------|--------|-------|
| planning | ✅ 2026-09-28 | G1 ✅ `/apps/` underscored, G5 ✅ developer names + `dcxstudios@gmail.com` — Fatih 2026-09-29; G2–G4, G6–G8 ✅ 2026-09-29 — all decided |
| P1 content collection | 🔲 | `legal` collection schema in `content.config.ts` + `src/content/legal/racer.md` |
| P2 privacy page | 🔲 | `src/pages/apps/privacy_policy.astro` |
| P3 terms page | 🔲 | `src/pages/apps/terms.astro` |
| P4 delete-account + support | 🔲 | `src/pages/apps/{delete_account,support}.astro` |
| P5 root pages + footer | 🔲 | trim `/privacy-policy`, `/terms` to the website's own policy (G3); footer links to `/apps/*` |
| P6 build + deploy + verify | 🔲 | `npm run build` (`dist/` is committed today — regenerate), redeploy, open all four URLs + anchors on a phone |
| P4b Crossle delete section | 🔲 | `src/content/legal/crossle.md` (`pages: [delete_account]`), link from `crossle_privacy_policy.html`; worded for soft delete (G8 wording rule); then Play Console + Meta data-deletion URL |
| P7 adoption | 🔲 | racer: `LegalLinks` + store consoles (racer store-compliance P0/P8); flash, hunter: when they ship |
| text review | 🔲 | one review of the final text before racer's first submission (Fatih) |

## Phases

1. **P1** — collection schema (G2): `name`, `storeNames`, `platforms`, `data[] {data, where,
   purpose, linkedToUser}`, `thirdParties[] {name, policyUrl}`, `retention`, `deletion[]`,
   `support[]`, `lastUpdated`, `order`. First file: `racer.md` from the racer table in
   `overview.md`.
2. **P2–P4** — pages under `src/pages/apps/`, `Layout.astro`, same styling as the existing
   `privacy-policy.astro`. Shared text from the outline in `overview.md`; per-app sections looped
   from the collection with `id={app}` anchors.
3. **P5** — root policy/terms trimmed to the website itself; `Footer.astro` gets "App Privacy",
   "App Terms", "Support", "Delete account".
4. **P6** — build, deploy, verify.
5. **P7** — each app links the anchored URLs from inside the app and in its store listings.

## Cross-references

- `dcm-manager/implementations/account-deletion/` (2026-09-29): Crossle stays on soft delete, hard-delete cron later — the `#crossle` text follows G8's wording rule.

## Next step

P1–P6 (+ P4b written, not yet linked) in one session. Crossle's deletion text follows G8's wording
rule (soft delete now, cron later).
