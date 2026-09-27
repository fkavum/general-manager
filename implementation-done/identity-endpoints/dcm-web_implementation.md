# identity-endpoints — dcm-web steps (P0–P2)

Companion to `overview.md`. Paths under `dcm-web/Src/Main/Src/` unless stated; shared files use explicit usings and
`ILogger<T>`.

## P0 — pin today's wire

`Src/Main.Test/Src/Features/Identity/UserWireContractTest.cs` (`DcmWebApplicationFactory`, own User-Agent — the rate
limiter buckets by it). Arrange: one anonymous login → token + uid; a second user for the "taken" case.
1. `POST api/user/change_name {"Value":"ab"}` → **423**, body text `"requirements not satisfied"`; `{"Value":"<taken>"}` → **422** `"Username already exist"`; valid → **200** `"Success"`; no token → 401.
2. `GET api/user/delete_my_account` → **200** `{"uid":…,"status":2,"startDate":…,"endDate":…}` (camelCase); again → 200 same; `GET dont_delete_my_account` → 200 `status:0`; again → **400** `Chill, we are not trying to delete your user!`.
3. Ban through `POST change_status` (server header) → `GET delete_my_account` → **400** `User is banned!`; unban.
4. `POST api/user/set_language {"Uid":…,"Language":2}` with server header → **200** `"Success"`; `Language:7` → **423**; without header → 401.
5. `POST api/user/change_status` without header → 401 (already in `LoginWireContractTest`; keep one here for the move).
6. `GET api/user/me` → **404** today (asserted so the flip to 200 in P1 is a deliberate edit of this test).
7. `POST api/user/change_language {"Language":1}` → **200** today; P1 edits this to **403** (D3, owner: unused).

## P1 — the move

### Identity/
| File | Change |
|---|---|
| `Contracts/EUserSelfService.cs` | `[Flags] enum EUserSelfService { None = 0, Name = 1, Language = 2, DeleteRequest = 4, All = 7 }` |
| `IdentityOptions.cs` | `+ EUserSelfService ClientEditable = All`; `bool IsClientEditable(EUserSelfService)` |
| `ClientEditableAttribute.cs` | `[AttributeUsage(Method)] class ClientEditableAttribute : Attribute, IAsyncResourceFilter` — resolves `IdentityOptions` from `HttpContext.RequestServices`; when the flag is off writes **403** `ErrorResponse(0, "<field> is not client-editable in this app")` and short-circuits |
| `UserService.cs` | `SetNameAsync` = Crossle's rule (D2): trim → `3..10` else `ValidationApiException` carrying **423**; `IsNameTakenAsync` → **422**; then `UpdateNameAsync`. Check what Dcm.Core's `ValidationApiException` maps to — if it is fixed at 400, add `NameRuleException(423/422) : ApiException` in Identity so the filter emits the codes. `MinNameLength = 3`, `MaxNameLength = 10`. `SetLanguageAsync` unchanged |
| `UserController.cs` (from `UserBasic/UserController.cs` + Crossle's actions) | `[Route("api/user")]`; user tier `[MiddlewareFilter(typeof(UserAccessPipeline))]`: `GET me`, `PUT me` (`UpdateUserNameRequest`), `PUT me/language` (`UpdateUserLanguageRequest`), `POST change_name` (`StringRequestBody`, `[ClientEditable(Name)]`, responses via `ResponseResult` exactly as Crossle's `UserService.ChangeUserName` — or the controller maps the exceptions to `StatusCode(423/422, ResponseToJson)`), `POST change_language` (`ChangeLanguageRequestBody`-shaped body `{Language:int}`, `[ClientEditable(Language)]`), `GET delete_my_account` / `GET dont_delete_my_account` (`[ClientEditable(DeleteRequest)]`, the outcome→response mapping from Crossle's controller, `Ok(UserStatusData)` = Identity's DTO — same camelCase JSON on the wire); server tier `[MiddlewareFilter(typeof(ServerAccessPipeline))]`: `POST change_status`, `POST set_language` (`{Uid, Language}`), `POST set_name` (`{Uid, Value}`). `[ApiExplorerSettings(GroupName = "private")]` on the server ones as today |
| `Contracts/` | `+ SetLanguageRequest {Uid, Language:int}`, `+ SetNameRequest {Uid, Value}`, `+ ChangeLanguageRequest {Language:int}` — Identity's own DTOs (int codes); Crossle's `Main.HttpShared.{ChangeLanguageRequestBody, SetLanguageRequestBody}` stay exported for the clients (same JSON shape, `ELanguage` serialises as int) |
| `IdentityModule.cs` | unchanged registration; the controller is picked up by MVC |
| `NOT_USED_BY_CROSSLE.md` | none — Identity is wired in Crossle |

### Auth/
`UserNameLoginEnricher.cs` moved from `UserBasic/` (namespace `Main.Features.Auth`), `AddUserNameLoginEnricher()` kept.

### UserBasic/
Deleted (controller, module, marker, enricher). `list-shared-modules.sh` no longer lists it.

### Crossle `Features/User/`
| File | Change |
|---|---|
| `UserController.cs` | keeps `POST get` (server) and `POST public_profile` only |
| `UserService.cs` | `ChangeUserName` / `ChangeUserLanguage` deleted (Identity's), `IUserRepository`/`IdentityOptions` deps dropped if unused |
| `ChangeStatusCrossle.cs` | keeps `Get` + `ToCrossle`; `ChangeStatus`, `RequestDelete`, `CancelDelete`, `ToIdentity` deleted |
| `Contracts/{ChangeLanguageRequestBody, SetLanguageRequestBody}.cs` | stay (client export); no server code binds them any more — note in the file header |
| `LanguageConstants.cs` | unchanged (feeds `IdentityOptions`) |
| `AppModules.cs` | `AddIdentityModule(options => { …existing…; options.ClientEditable = EUserSelfService.Name \| EUserSelfService.DeleteRequest; })` |

### Tests
- `UserWireContractTest`: edit rows 6 (→ 200 `{uid,name,language}`) and 7 (→ 403), add `set_name`, `me/language`.
- `Features/Identity/UserServiceTest.cs` (new, unit): name rule boundaries (2 → 423, 3 ok, 10 ok, 11 → 423, taken → 422, `Guest` → 423), `ClientEditable` filter (flag off → 403).
- Any test that referenced `Main.Features.UserBasic` → `Main.Features.Identity`.
- Swagger: the "private" group still lists the server routes; `SwaggerCustomHeader` unaffected.

## P2 — Crossle live smoke (`:20100`)
identity-core follow-up's 30 checks (same script, `scratchpad/smoke_identity_crossle.sh`) + `GET me` 200 with `language`,
`POST set_name` (server) 200 then `public_profile` shows it, `POST change_language` → 403 with the message, `PUT me/language`
→ 403 too (same flag). `list-shared-modules.sh` shows no `UserBasic`. HttpShared export: `generate-http-shared.sh` (no arg)
— Crossle's `User/Contracts` unchanged, Identity's contracts gain three DTOs.
