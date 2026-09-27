# identity-endpoints — the user's self-service routes move into Identity; Crossle keeps only its aggregate routes

Planned 2026-09-25 (owner: "we will definitely move `UserController` to Identity too, except `get` & `public_profile`
since they will be aggregated data … some features might be server auth for a fully online game, client auth for offline
games"; agreed in chat: Crossle's routes become the shared routes, one name rule for everyone, Crossle's client-auth
`change_language` is old and unused). Follows `implementation-done/identity-core/` (Identity owns `user`, `user_status`,
`log_deleted_users`; this plan gives it the endpoints over them). Multi-project: dcm-web (Crossle), racer-web, flash-web;
hunter-web via `testapp/hunter-manager/implementations/auth-upstream/`. Paths relative to `/Users/fkavum/Documents/project/`.

## 1. The model after this plan

```
   Identity        owns user / user_status / log_deleted_users AND the user's self-service routes:
                     user tier   GET/PUT api/user/me, PUT me/language, POST change_name, POST change_language,
                                 GET delete_my_account, GET dont_delete_my_account
                     server tier POST change_status, POST set_language, POST set_name
                   IdentityOptions.ClientEditable decides which user-tier routes an app lets its client use
                                                                          shared, wired everywhere (Crossle too)
   Auth            unchanged; gains Auth/UserNameLoginEnricher (from UserBasic — it implements Auth's interface)
   Features/User   Crossle only: POST get (server, aggregate), POST public_profile, UserUnitOfWork, ChangeStatusCrossle
   UserBasic       deleted (every route it had is in Identity now)
```

Two controllers share the `api/user` prefix (Identity's and Crossle's). ASP.NET only rejects identical full templates,
so `get` / `public_profile` in Crossle next to Identity's routes is fine; `list-shared-modules.sh` stays green because
`UserBasic` is gone.

## 2. Wire that must not move

| Caller | Route | Contract today (pinned by `UserWireContractTest` in P0) |
|---|---|---|
| dcm-client `PlayerProfilePopup` | `POST change_name` `{Value}` (`StringRequestBody`) | `200` / `423` (length) / `422` (taken) / `400`; body = `ResponseToJson()` text (`"Success"`, `"requirements not satisfied"`, `"Username already exist"`) — the client keys toasts on 422/423 only |
| dcm-client `AreYouSureForDeletePopup` | `GET delete_my_account` | `200` `{uid,status,startDate,endDate}` (camelCase — MVC default JSON, same in every app) / `412` text / `400` text `"User is banned!"` |
| dcm-client `ScheduledForDeletionPopup` | `GET dont_delete_my_account` | `200` status JSON / `400` `"Chill, we are not trying to delete your user!"` / `412` text |
| dcm-client `FriendsController` | `POST public_profile` | stays in Crossle — untouched |
| dcm-game-server `FetchUserDataTask` | `POST get` (server) | stays in Crossle — untouched |
| dcm-game-server `OnLanguageChangeRequestReceived` | `POST set_language` `{Uid, Language}` (server) | `200` `"Success"` / `423` / `400` |
| ops (no code caller) | `POST change_status` `{Uid,Status,StartDate,EndDate}` (server) | `200` status JSON |
| flash client (`auth_service.dart`, `flash_web_service.dart`) | `GET/PUT api/user/me` | `200` `{uid,name,language}`; `PUT` body `{name}` |
| nobody (owner: old, unused) | `POST change_language` `{Language}` | route stays (shared pair), Crossle answers **403** through `ClientEditable` |

Errors keep Dcm.Core's `ErrorResponse`/`GlobalExceptionFilter` behaviour (`UserNotFoundException` → 400, as today).

## 3. Decisions

| # | Question | Decision |
|---|---|---|
| D1 | Whose wire is the shared one? | Crossle's (shipped Unity clients). The apps inherit the routes/bodies above; `me` + `me/language` are added to the set (Crossle gets them too — additive, harmless). |
| D2 | Name rule | **One rule for everyone = Crossle's**: 3–10 chars after trim, unique, not the guest name; `423` length / `422` taken. `Identity.UserService.SetNameAsync` becomes that rule; the 2–24 non-unique rule and `IdentityOptions.Name` idea are dropped. flash's `UserProfileTest` names ("Ada Lovelace") shrink to ≤10 and its 400 expectations become 423. |
| D3 | Server vs client tier | **Fixed route pairs + a per-app flag set**, not a tier-switching attribute (a user route takes the uid from the JWT, a server route takes it in the body — different contracts, so one route cannot flip). `IdentityOptions.ClientEditable` (`[Flags] EUserSelfService { Name, Language, DeleteRequest }`), default all. User-tier actions carry `[ClientEditable(EUserSelfService.X)]`; a resource filter answers **403** `ErrorResponse("… is not client-editable in this app")` when the flag is off. Crossle: `Name | DeleteRequest` (its game server owns language via `set_language`). racer/flash: all. |
| D4 | Identity "has no endpoints" rule | Flips: Identity owns the self-service routes. Its *services* still never reference Auth; its **controller** is the one place Identity references Auth (`UserAccessPipeline`) and Dcm.Core's `ServerAccessPipeline`. Written into the rules. |
| D5 | `UserNameLoginEnricher` | Moves to `Features/Auth/UserNameLoginEnricher.cs` (`AddUserNameLoginEnricher()` unchanged) — it implements Auth's `ILoginResponseEnricher`, so it cannot live in Identity without inverting the dependency. Crossle still does not register it. |
| D6 | `set_name` (server) | Added for symmetry with `set_language` (`{Uid, Value}`), so every editable field has both tiers; no caller today. |
| D7 | Delete routes are `GET` | Kept — contract. Documented as the known wart. |
| D8 | `ChangeStatusCrossle` | Shrinks to what Crossle's `public_profile`/aggregate still need (`Get` + `ToCrossle`); the change/delete/cancel methods go with the routes. |

## 4. Phases

| Phase | What | Gate |
|---|---|---|
| P0 | `Src/Main.Test/Src/Features/Identity/UserWireContractTest.cs` on the OLD code: every row of §2 as raw status + body assertions (+ `me` absent in Crossle today = 404, becomes 200 after) | green before any move |
| P1 | dcm-web: Identity controller + options + filter, `SetNameAsync` = Crossle rule, enricher to Auth, Crossle `Features/User` trimmed, `UserBasic` deleted, `AppModules`/tests (`dcm-web_implementation.md`) | dcm-web suite + `UserWireContractTest` + `LoginWireContractTest` green |
| P2 | Crossle live smoke on `:20100` (the 30 checks of identity-core's follow-up + `me`, `set_name`, `change_language` → 403) | 33/33 |
| P3 | racer + flash: `FEATURES` −`UserBasic`, sync, `AppModules`, tests/baselines (`downstream_implementation.md`) | flash 92/92 (adjusted names), racer builds, `--check` ×2, live racer/flash smokes |
| P4 | docs: AI_RULES (master + 5 copies: IDENTITY AND AUTH bullets, "no endpoints" → "self-service endpoints", D3/D4), general-manager + dcm/racer/flash manager intros, `auth-upstream` plan (`UserProfile` keeps only hunter's profile routes; `me`/`change_name`/delete come from Identity), move this folder to `implementation-done/` | — |

## 5. Risks

- `set_language` is the game server's route: it moves file, not behaviour — P0 pins body + codes, P2 hits it with the
  server header.
- The 3–10 rule now applies to flash/racer users that already have longer names (flash dev DB): reads are unaffected,
  only the next rename is validated. No data migration.
- `change_language` answering 403 in Crossle changes an unused route's answer from 200 to 403 — owner-confirmed unused
  (client and game server construct no `ChangeLanguageRequest`).
- Route-baseline diff in flash: `+PUT /api/user/me/language` is already there; this plan adds `POST change_name`,
  `change_language`, `set_language`, `set_name`, `GET delete_my_account`, `dont_delete_my_account` — reviewed, expected.

## 6. Effort

P0 ½ day, P1 1 day, P2–P3 ½ day, P4 ½ day ≈ 2½ days.
