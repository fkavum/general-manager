# identity-endpoints — racer-web + flash-web (P3), hunter pointer

Companion to `overview.md`.

## racer-web
| Step | Change |
|---|---|
| `Tools/sync-dcm-features.sh` | `FEATURES`: remove `Features/UserBasic`; run (Identity + Auth re-sync); delete `Src/Main/Src/Features/UserBasic/` by hand (rsync `--delete` only cleans inside listed folders) |
| `AppModules.cs` | `AddIdentityModule(); AddAuthModule(camelCase, 200); AddUserNameLoginEnricher();` — `AddUserBasicModule()` removed; `ClientEditable` left at `All` |
| Gate | build; `--check`; live smoke: the 13 identity-core checks + `change_name` 423/422/200, `delete_my_account`/`dont_delete_my_account`, `set_language` (server), `change_language` 200 (offline app: client-editable) |

## flash-web
| Step | Change |
|---|---|
| `FEATURES` / `AppModules.cs` | as racer |
| Tests | `Features/UserBasic/UserProfileTest.cs` → `Features/Identity/UserProfileTest.cs`: names ≤10 chars (`"Ada L."`, `"Zeynep Ç"`), invalid-name cases expect **423**, add a taken-name **422** case; usings `Main.Features.Identity[.Contracts]` |
| Baselines | `routes.txt`: −nothing, +`POST /api/user/change_name`, `change_language`, `set_language`, `set_name`, +`GET /api/user/delete_my_account`, `dont_delete_my_account` — reviewed; `efmodel.txt` unchanged |
| Client (`flash/client`) | nothing now — it only uses `me`. When the Flutter profile screen adds rename, it may call `PUT me` (JSON, 423/422) or `change_name` (text body) — prefer `PUT me` |
| Gate | 92/92 + the new cases; `--check`; live smoke as racer on `:20300` |

## hunter-web
`auth-upstream` B3 shrinks: `UserProfile` keeps hunter's profile/search/scanner routes and `HunterLoginEnricher`; `me`,
rename, language and delete-request come from Identity (routes.txt gains them). `AddIdentityModule(o => { o.SupportedLanguages
= …; o.ClientEditable = All; })`. Written into that plan in P4.
