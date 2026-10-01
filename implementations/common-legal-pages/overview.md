# Common Legal Pages — Overview

One privacy policy, one terms of service, one account-deletion page and one support page on
`dcxstudios.org`, shared by the studio's smaller apps. Crossle keeps its own pages
(`dcxstudios-website/www/crossle/`, served at `crossle.dcxstudios.org`) — it's big enough to
earn its own, and it ships ads/analytics SDKs the small apps don't.

Born from `racer/racer-manager/implementations/store-compliance/` (decision C8, Fatih
2026-09-28): racer needs a privacy-policy URL, a support URL (Apple) and an account-deletion URL
(Google Play) before submission. Racer is the first app on these pages; the others add their
section when they ship.

## Where

`dcxstudios-website/www/dcxstudiosv2/` — the Astro studio site (`site: 'https://dcxstudios.org'`,
nginx container in `docker/`). It already has `/privacy-policy`, `/terms`, `/cookie-policy`,
`/contact` and the game pages `/games/[slug]` (content collection `src/content/games/`, today
only `crossle.md`). No new subdomain, container or DNS.

## What makes a shared policy acceptable (the rules every change here follows)

Both stores accept a developer-wide policy as long as it covers each app specifically:

1. It names the legal entity **exactly as the developer name on the store listings**.
2. It lists **every app** it covers.
3. It states **per app** what data is collected, why, where it's stored and which third
   parties receive it — matching that app's Apple privacy label and Google Data safety form
   word for word in substance. A generic "we may collect analytics…" text fails review; the
   current `/privacy-policy` is exactly that (and mentions analytics racer doesn't have).
4. It's a public HTML page (not a PDF), not geofenced, linked from the store listing and from
   inside the app.

Hence the shape: **shared sections written once + one section per app** (`#racer`, `#flash`, …).
An app that adds or removes an SDK or a data type updates its section in the same release —
that is a release-checklist item in every app manager, not something this folder polices.

Not legal advice: have the final text reviewed once before the first store submission.

## Apps

| App | Store / distribution | On the common pages? | Why |
|-----|----------------------|----------------------|-----|
| 05 Racer | App Store + Google Play (Unity) | ✅ first section | anonymous account, KVS cloud save, IP for rate limiting, Unity only |
| 03 Flash | PWA today; optional stores later | ✅ when it ships publicly | anonymous device id, optional email account (`AuthEmail`, SMTP provider), **public user content** (Community decks) |
| 02 Hunter | PWA, pre-MVP | ✅ when it ships | Firebase Auth (Google as a third party, email), friends + shared shopping lists (data shared between users) |
| 04 Tapit | B2B PWA | ❌ own pages later | businesses manage their workers' data (tasks, photos, WhatsApp-link identity): the **employer is the controller and DCX a processor** — that needs a B2B privacy notice + customer terms / data processing agreement, not a consumer policy |
| 01 Crossle | App Store + Google Play | **delete page only** (G8) | own policy/terms/support at `crossle.dcxstudios.org`; ads/analytics/Facebook — but it has **no account-deletion URL**, so it gets a `#crossle` section on `/apps/delete_account` |

## Decisions (all ✅ — Fatih 2026-09-29)

- ✅ **G1 — URLs: `dcxstudios.org/apps/…`, underscored (Fatih 2026-09-29).** Fatih proposed
  `/games/privacy_policy`; `/apps/` was chosen because of the apps on these pages only racer is a
  game, and the underscores were kept (the site's other URLs are hyphenated — accepted, legally
  and technically irrelevant). A static `src/pages/apps/*.astro` has no clash with
  `games/[slug].astro`.

  Final URLs: `https://dcxstudios.org/apps/privacy_policy`, `/apps/terms`,
  `/apps/delete_account`, `/apps/support`, with per-app anchors
  (`/apps/privacy_policy#racer`). Store consoles and in-app links use the anchored URL.
- ✅ **G2 — Per-app data lives in a content collection, not in the page.** `src/content/legal/<app>.md`
  (schema in `content.config.ts` next to `games`): app name, store listing names, platforms,
  data rows (`data`, `where`, `purpose`, `linkedToUser`), third parties (name + policy URL),
  deletion steps, support notes, `lastUpdated`. The four pages render the shared text once and
  loop over the collection. Adding an app = adding one file; each file is owned by that app's
  manager, the shared text by this folder. (Fatih asked whether per-app facts are legally needed:
  yes — both stores check that the policy describes *this* app's data and third parties, and
  that it matches the app's privacy label / Data safety form, so they stay.)
- ✅ **G3 — Keep the root `/privacy-policy` and `/terms` as the website's own policy.** They cover
  visitors of `dcxstudios.org` (contact form, cookies — `/cookie-policy` stays). Remove "including
  Crossle" and the app wording; add links to `/apps/*` and to Crossle's own pages.
- ✅ **G4 — Tapit is out** (see the table). It gets its own B2B plan in `tapit-manager` when it has
  paying customers.
- ✅ **G5 — Entity: two developer names, one publisher; contact `dcxstudios@gmail.com` (Fatih 2026-09-29).**
  Google Play lists the developer as **"Dcx Studios"**, the App Store as **"Mehmet Fatih Kavum"**
  (individual Apple account). Rule 1 needs the policy to match *each* listing, so the opening
  "Who we are" line names both, e.g.:

  > These apps are published by **Mehmet Fatih Kavum**, trading as **Dcx Studios** ("Dcx
  > Studios", "we", "us"). On Google Play the developer is listed as "Dcx Studios"; on the App
  > Store as "Mehmet Fatih Kavum". Mehmet Fatih Kavum is responsible for your data (the data
  > controller) for every app listed on this page.

  Use the store strings **exactly** ("Dcx Studios", not the site's "DCX Studios") in that line;
  the rest of the page may use the brand spelling. If Dcx Studios is ever registered as a company
  and the store accounts move to it, this line changes. Terms use the same wording for the
  contracting party. **Contact (Fatih 2026-09-29): `dcxstudios@gmail.com`** on all four pages.
- ✅ **G6 — English only for v1.** A translated policy is optional; add languages when an app ships
  localized store listings.
- ✅ **G7 — Versioning.** Each app section carries its own "last updated" date; the page date is the
  newest one. A short changelog at the bottom of the privacy page records material changes
  (a new data type or third party), so users and reviewers can see what changed.

- ✅ **G8 — Crossle gets a section on `/apps/delete_account` (Fatih 2026-09-29: "we don't have a
  delete_account URL for Crossle").** Google Play requires the URL for every app that creates
  accounts; Crossle has none (`www/crossle/` has privacy, terms, support, store pages only).
  **Rec:** add `#crossle` to the common deletion page rather than a `crossle_delete_account.html`
  — it is instructions, not policy, so sharing it doesn't blur Crossle's own policy, and it keeps
  one deletion page to maintain. The section is driven by a `src/content/legal/crossle.md` entry
  with a `pages: [delete_account]` flag so Crossle does **not** appear on the common privacy
  policy / terms. Crossle's own `crossle_privacy_policy.html` then links to it.

  **Wording rule — describe what the delete does today.** Crossle's delete is a soft delete
  (Fatih 2026-09-29, `dcm-manager/implementations/account-deletion/` A1): after the 10-day
  grace the account is closed on the next login (device info + login links removed, uid
  logged); the rest of the data stays until a future hard-delete cron job erases it. So the
  `#crossle` section says the account is closed after 10 days and cannot be recovered, and either
  states the erase window ("data permanently erased within N days" — N chosen so the cron job
  ships first) or leaves that clause out until it does. The same URL is Crossle's Play Console
  deletion URL and the Meta app's Data Deletion Instructions URL (A4).

## Shared text — outline

**Privacy policy (`/apps/privacy_policy`)**
Who we are (G5 publisher line, contact) · apps covered (list with anchors; Crossle and Tapit excluded, with
links) · accounts (anonymous device-based account by default; optional sign-in where an app has it)
· how data is protected (HTTPS, servers location — the VPS region) · retention and deletion (per app,
e.g. racer: 10-day revertible grace, then account + cloud save erased, uid kept in a deletion log)
· your rights (in-app deletion, contact for access/correction/questions; GDPR/UK GDPR/CCPA
wording kept generic and truthful) · children (not directed at children under 13) · changes ·
per-app sections (rendered from G2).

**Terms (`/apps/terms`)**
Licence to use · acceptable use · accounts, suspension and bans (racer and the shared `Identity`
enforce bans at login) · **user content** (flash Community decks, hunter shared lists: the user
owns it, grants us a licence to host/show it, we may remove content that breaks the rules, how to
report) · virtual items have no cash value (racer) · service changes and termination · disclaimer,
limitation of liability · governing law · contact.

**Delete account (`/apps/delete_account`)** — Google Play's "account deletion URL"
Covers every app including Crossle (G8). Per app: the in-app path, what is deleted vs kept, grace period and how to cancel, and the
fallback for users who uninstalled (email the contact with the in-app player/user id).

**Support (`/apps/support`)** — Apple's "Support URL"
Contact, per-app FAQ (bug report, lost progress → id shown in Settings, delete account → link).

## Racer section (first entry — facts from racer's store-compliance plan)

| Data | Where | Purpose | Linked to user? |
|------|-------|---------|-----------------|
| Device identifier | racer-web `user_linked_accounts` (`anon` row) | anonymous account | yes |
| Player id (uid) | racer-web `user` | account, cloud save | yes |
| IP address | racer-web `user.last_ip` | abuse prevention / rate limiting | yes |
| Game progress, profile name, avatar/frame, inventory, settings | racer-web `kvp_client`/`kvp_server` + on device | cloud save / sync | yes |
| Ghost recordings | on device only | ghost racing | no |

Third parties: Unity. Deletion: Settings → Delete account, 10-day revertible grace, then account +
cloud save erased (needs dcm-web's `IUserDataEraser`, racer store-compliance C2). The dormant
`AppTracking` / `Features/Legal` ports add nothing until they're wired; when they are, this
section changes in the same release.

Flash and hunter sections are drafted by their managers from the facts in the Apps table when
they ship — this plan only reserves the slots.
