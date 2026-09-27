# identity-core — Identity + one unified Auth, shared by every web project including Crossle

Planned 2026-09-25 (owner decisions in chat: Identity = user stuff without auth; JWT belongs to Auth; **one `Auth`
for Crossle and the apps, Crossle's Auth made modular without breaking its shipped clients; login enrichers are
modules too** so MinVersions/SupportedLogins can be added to other apps later). Multi-project: dcm-web (Crossle),
racer-web, flash-web; hunter-web follows through `testapp/hunter-manager/implementations/auth-upstream/`.
Paths relative to `/Users/fkavum/Documents/project/`.

## 1. The model

```
   Identity        "a user exists": user + user_status. No endpoints.            shared, wired everywhere
      ▲            offers IUserBuilder, IUserNameProvider, IUserStatusProvider
      │
   Auth            "how you prove you are that user": linked accounts, JWT, LoginService, AttachService,
      ▲            UserAccessMiddleware, IAuthProvider (per-provider strategy), ILoginResponseEnricher (many),
      │            IAnonymousLoginHook. Endpoints: api/login/{anonymous,refresh,verify}, api/attach/test.
      │                                                                          shared, wired everywhere
   ┌──┴────────────┬──────────────┬──────────────┬──────────────┬─────────────┐
 AuthFacebook  AuthGoogle    AuthApple     AuthFirebase   AuthEmail      ← provider modules: one IAuthProvider +
 (api/login/facebook, api/attach/facebook, …)                            its own controller(s). Crossle registers all
                                                                         five; racer none; flash none; hunter Firebase.
   ┌───────────────────────────┬──────────────────────────┬──────────────────────┐
 AuthCrossle (Crossle-owned)   UserCrossle = Features/User  UserBasic (hosted)     UserHunter (later)
   MinVersions / GameServer /   aggregate + api/user/*       api/user/me,          profile aggregate
   SupportedLogins enrichers,                                change_status for
   legacy anon hook, Crossle's                               apps without an
   client LoginResponse DTO                                  aggregate (racer, flash)
```

- Identity knows nothing about Auth; Auth depends on Identity only through the three interfaces.
- **The login response is composed, not hard-coded**: Auth emits `UserId`, `Token`, `Status`; every registered
  `ILoginResponseEnricher` adds named top-level fields. Crossle registers three enricher modules (`MinVersions`,
  `GameServer`, `SupportedLogins`, in that order → today's exact JSON); flash/racer register `UserName` (the `name` field
  their clients read); any app can register Crossle's enrichers once `Features/Data` is promoted (follow-up).
- Provider modules own their endpoints, so an app registers only the providers it serves — Crossle's monolithic
  `LoginController` (all six providers in one constructor) disappears.
- Crossle-only behaviour becomes Crossle-registered pieces: `LegacyDeviceInfoAnonFallback` → `IAnonymousLoginHook`;
  `RequireSecureLogin` → `AuthOptions`; `AdoptDeviceId`, secondary links and the Banned/Deleted/Ok token rules are
  generic and stay in the shared `LoginService`.
- `AuthOffline`, `UserOffline`, and Crossle's dead `Auth/Core` + `Anon` generation (`CoreLoginService`,
  `AnonLoginService`, `*CoreLoginStrategy`, `*CoreAttachStrategy` — not on the production path, only a unit test uses
  them) are deleted.

## 2. Wire contract that must not move (Crossle's shipped Unity clients + dcm-game-server)

Verified in dcm-client (`WebLoginHandler`, `LoginController`, `EmailAuthController`, `HttpSender`) and dcm-game-server:

| What | Contract |
|---|---|
| Success | any 2xx (`HttpSender`: `responseCode < 200 or >= 300` = failure). `201` on first anonymous login is kept anyway (`AuthOptions.CreatedStatusCode`, Crossle = 201; the test fixture asserts it) |
| Status codes the client branches on | `409` anonymous refused (secure login), `404`/`401`/`400` on refresh = token rejected, `404` email not registered, `401` wrong password, `400` invalid/expired code |
| Body | PascalCase (`JsonConvert` as today): `UserId`, `Token`, `Status{Uid,Status,StartDate,EndDate}`, `MinVersions`, `GameServer`, `SupportedLogins` — read as typed `Main.Dtos.LoginResponse` on the client |
| Errors | `{"ErrorCode":0,"Message":"…","Details":""}` with the same messages (`No Device Id`, `Invalid Firebase Token`, `Firebase not attached!`, `Secure login required`, `User not found`, `Error: Invalid Token`) |
| `verify` | `POST api/login/verify {Token}` → `{"UserId":<int>}` (dcm-game-server) |
| Client DTOs | every class in `../HttpShared/Auth` and `../HttpShared/User` keeps its name, namespace (`Main.Dtos`/`Main.Shared`/`Main.HttpShared`) and fields; the generator's folder layout may change (`HttpShared/AuthFacebook/…`), which only moves Unity `.meta` files |

Gate: `LoginWireContractTest` recorded in P0 **before** any change asserts raw JSON strings for all of the above.

## 3. Module contents

| Module | Folder (`dcm-web/Src/Main/Src/Features/`) | Content | Crossle |
|---|---|---|---|
| **Identity** | `Identity/` | `UserEntity`, `UserStatusEntity`, `DbConfig/`, `IUserRepository`+`UserRepository` (EF, `Set<T>()`; default `IUserBuilder`/`IUserNameProvider`/`IUserStatusProvider`), `UserService`, `Contracts/{EUserStatus, UserStatusData, NewUserRequest, UserResponse, UpdateUserNameRequest}`, `IdentityModule` (`TryAdd` so an app's own seam registration wins) | wired; Crossle keeps `UserUnitOfWork` as `IUserBuilder` (adapter for `NewUserRequest`/`SoftDelete`), its `UserCoreRepository` behind `IUserNameProvider`, and takes Identity's `IUserStatusProvider`; its `AppDbContext` excludes `Identity.DbConfig.UserEntityConfig` (the `user` table is already mapped by `UserCoreEntity`) |
| **Auth** | `Auth/` (replaces Crossle's folder of the same name — its files move to the provider/Crossle modules) | `AuthProvider` keys, `LinkedAccountEntity`+`DbConfig`, `ILinkedAccountRepository` (full incl. `DeleteAllForUser(uid, ExecutorArgs)`), `IJwtService`/`JwtService`, `IAuthProvider {Key, DisplayName, ValidateToken → TokenValidation{ExternalId, SecondaryLinks, Email?, DisplayName?}}`, `LoginService` (`HandleAnonymous`, `HandleProviderLogin`, `RefreshToken`, `VerifyToken`, `AdoptDeviceId`, status rules) returning `LoginResult {Status, LoginOutcome?, ErrorResponse?}`, `AttachService` (generic over `IAuthProvider`), `ILoginResponseEnricher` (+ context), `IAnonymousLoginHook`, `AuthOptions {CreatedStatusCode, RequireSecureLogin, AutoRegisterExternalIdentities, ResponseNaming}`, `LoginResponseWriter` (composes fields + enrichers → JSON in the configured naming), `UserAccessMiddleware`/`UserAccessPipeline`, `LoginController` (`anonymous`, `refresh`, `verify`), `AttachController` (`test`), `Contracts/{AnonymousRequestBody, VerifyRequestBody, VerifyResponse, LoginResponse (base: UserId, Token, Status), AttachResponse, EAttachResult, AckResponse, TokenValidation}`, `AuthModule(Action<AuthOptions>?)` | wired |
| **AuthFacebook / AuthGoogle / AuthApple / AuthFirebase** | `AuthFacebook/` … | `<P>ApiService` (moved), `<P>AuthProvider : IAuthProvider` (from the legacy `<P>LoginStrategy` + `<P>AttachStrategy`, one class), `<P>LoginController` (`[Route("api/login")] [HttpPost("<p>")]`), `<P>AttachController` (`[Route("api/attach")] [HttpPost("<p>")]`), `Contracts/{Login<P>RequestBody, Attach<P>RequestBody}` (moved, namespaces kept), `Auth<P>Module` | wired (Crossle-owned until a second consumer; hunter takes `AuthFirebase`, which also gets the `FirebaseApp.Create` init) |
| **AuthEmail** | `AuthEmail/` | everything from `Auth/Email/` + the six `api/login/email*` and three `api/attach/email/*` actions in `EmailLoginController`/`EmailAttachController`, `SmtpConfig`, entities/configs/repos; depends on `Auth.LoginService` (`RefreshToken`, `AdoptDeviceId`) | wired |
| **AuthCrossle** | `AuthCrossle/` | `MinVersionsLoginEnricher`, `GameServerLoginEnricher`, `SupportedLoginsLoginEnricher` (each `Add…Enricher()` registration = enricher module), `LegacyDeviceInfoAnonFallback : IAnonymousLoginHook`, `Contracts/LoginResponse.cs` (Crossle's composed client DTO in `Main.Dtos`, kept for the Unity client and the tests), `AuthCrossleModule` | wired, Crossle-only |
| **UserBasic** | `UserBasic/` (from `UserOffline`) | `UserController` (`api/user/me` GET/PUT, `api/user/change_status`), `UserNameLoginEnricher` (adds `Name`), `UserBasicModule` | hosted, marker (routes equal Crossle's `User`) |
| **Features/User** (UserCrossle) | unchanged folder | aggregate, `UserController`, `UserLoginEnricher` deleted (replaced by AuthCrossle's three), `UserStatusRepository` → adapter over `IUserStatusProvider`, `UserAccountsRepository`+entity+config moved here from `Auth/` | Crossle-owned |

Namespaces: new shared files use `Main.Features.<Module>[.Contracts|.DbConfig]`; **moved Crossle files keep their
namespaces** (`Main.Dtos`, `Main.Services`, `Main.Repository`, `Main.Entities`) so the Unity client's generated DTOs
and every existing `using` stay valid.

## 4. Decisions

| # | Question | Decision / proposal |
|---|---|---|
| D1 | Names | ✅ owner: `Identity`, `Auth` (shared, replaces Crossle's), provider modules `Auth<Provider>`, `AuthCrossle`, `UserBasic`, Crossle's `Features/User` unchanged (rename to `UserCrossle` optional, not done — it would only move Unity `.meta` files) |
| D2 | `user_status` | ✅ owner: Identity |
| D3 | JWT | ✅ owner: Auth |
| D4 | Crossle wire | ✅ applied: byte-for-byte: `AuthOptions.ResponseNaming = PascalCase` + `CreatedStatusCode = 201` for Crossle; flash/racer `CamelCase` + `200` (their clients read `userId/token/name`). Error bodies stay `ErrorResponse(0, message)` via `LoginResult`, not exceptions |
| D5 | `Identity.DbConfig.UserEntityConfig` vs Crossle's `UserCoreEntityConfig` on the same `user` table | ✅ applied: Crossle's `AppDbContext` applies configurations with a predicate that skips `UserEntityConfig` (documented there); `UserStatusEntityConfig` is applied — Crossle's `UserStatusRepository` becomes an adapter over Identity's EF provider |
| D6 | The dead `Core*`/`Anon` generation in Crossle's Auth | ✅ deleted (only `AnonLoginServiceTest` uses it; that test is rewritten against the shared `LoginService`) |
| D7 | `ILoginStrategy.GetUser` + per-provider `IAttachStrategy` boilerplate | ✅ collapsed into one `IAuthProvider` per provider; `LoginService`/`AttachService` resolve uids through `ILinkedAccountRepository` with `provider.Key` |
| D8 | Where MinVersions/SupportedLogins data lives | stays in Crossle's `Features/Data`; only the enricher *mechanism* is shared now. Promoting `Features/Data` (hosted) is the follow-up that lets other apps register the same enrichers |
| D9 | Multiple `LoginResponse` classes | ✅ shared base in `Main.Features.Auth.Contracts` (what racer's Unity client and flash read) + Crossle's composed DTO in `Main.Dtos` under `AuthCrossle/Contracts` (what dcm-client reads). Different namespaces; the generator exports both |

## 5. Phases

| Phase | Scope | Gate |
|---|---|---|
| **P0** | `LoginWireContractTest` in dcm-web on today's code: raw JSON for anonymous 201/200/400, refresh 200/401, verify 200/400, provider login 400s (`No Facebook Token`, `Invalid Firebase Token`), `change_status` 200; plus the token-continuity test (old `JwtService` ↔ new) | 153 → ~160 green |
| **P1** | Build `Identity`, `Auth`, `AuthFacebook/Google/Apple/Firebase/Email`, `AuthCrossle`, `UserBasic` in dcm-web from the existing code (moves, not rewrites, wherever a class already exists); delete `AuthOffline`, `UserOffline`, `Auth/Core`, `Auth/Anon`, `Auth/AuthServices/{LoginService, LoginStrategy, AttachStrategy}`, `Auth/LoginController`, `Auth/AttachController`; wire `AppModules` (Identity → Auth → providers → AuthCrossle → User); `Main.Utils.UserAccessPipeline` alias | `Dcm.sln` builds, all tests incl. P0 green, `list-shared-modules.sh` sane |
| **P2** | Crossle verification: live smoke on `:20100` — anonymous (201/200), refresh, verify (game-server shape), a facebook/firebase call with a bad token, `change_status`, attach test; `generate-http-shared.sh` diff (names/namespaces/fields identical, folders moved) | contract test + smoke |
| **P3** | racer + flash: `FEATURES` = `Identity`, `Auth`, `UserBasic` (+ existing); `AppModules` (`AddIdentityModule`, `AddAuthModule(o => …camel/200)`, `AddUserBasicModule`, `AddUserNameLoginEnricher`); aliases/usings; old folders removed; baselines (flash `routes.txt` gains `verify` + `attach/test`) | flash 92/92 + live smoke 15/15; racer build + live smoke 20/20 |
| **P4** | docs: AI_RULES ×2 (+4 copies) — Identity/Auth/provider/enricher rules and the client-DTO rule; dcm-manager (module list, shared-change log, Identity-vs-Auth paragraph); racer/flash managers; general-manager intro; `auth-upstream` re-based (P1 there = `AuthFirebase` sync + hunter enricher); move to `implementation-done/` | — |

## 6. Risks

- **Production login controller is rewritten** (into provider controllers + a composed response). Mitigation: P0
  contract test on raw JSON, existing 8 auth test files, live smoke, `HttpShared` diff, and the release-branch review
  by the owner before it ships. Status codes and messages are copied verbatim from `LoginService`.
- **Property order / casing** in the composed JSON — `LoginResponseWriter` uses an ordered dictionary and Newtonsoft with
  the configured resolver; the contract test compares strings.
- **EF model in Crossle** (D5) — `EfMappingsResolve`-style test plus the live `/health/deep`.
- **Provider services need external config** (Facebook app secret, Apple keys, SMTP, Firebase credentials) — unchanged
  per module; the contract test only exercises the deterministic 400 paths.

## 7. Notes from the implementation (2026-09-25)

- `ILinkedAccountRepository` has no `CancellationToken` parameters: Crossle's `EmailCodeServiceUnitTest`/`EmailPasswordServiceUnitTest` set up its methods in Moq expression trees, which cannot carry optional arguments. The EF calls run without a token as before.
- The Google/Apple providers now catch validation exceptions (→ 400 `Invalid … Token`) where the legacy login strategies let them surface as 500; the attach strategies already caught them. Deliberate, tiny, and only reachable with a malformed provider token.
- The base `Main.Features.Auth.Contracts.LoginResponse` carries `Name` (what UserBasic's enricher adds) so the apps' clients and tests have one DTO; Crossle's `Main.Dtos.LoginResponse` stays the Crossle client's.
- The `RateLimiterMiddleware` buckets by User-Agent process-wide: the new contract test uses its own fingerprint, or it eats the other fixtures' 10-per-2-minutes budget (flash hit the same thing earlier).
- dcm-web HEAD moved to `4b103dd` ("real big upstream", owner commit) during the work; the lock files record it.

- Follow-up (owner, same day): "UserStatusRepository.ChangeStatus should belong to Identity; Language is identity data; same
  for DeletedUserRepository and UserCoreRepository — the user table belongs to Identity." Done: Identity owns `user`,
  `user_status`, `log_deleted_users` with `IdentityOptions` for the app policy; Crossle keeps only a read model
  (`UserCoreEntity.From(identity, level, exp)`), `ChangeStatusCrossle` (DTO conversion) and its own name/language rules;
  its unit of work shares one transaction between EF (Identity) and MySqlExecutor (satellites) via
  `Database.BeginTransactionAsync()` + `ExecutorArgs(connection, transaction)`. Found on the way: after an expired delete
  request the anon link survived the soft delete, so the same device never became a new user — `LoginService` now drops
  the links (Auth owns them). `UserNotFoundException` from login/`me` is answered 400 by Dcm.Core's global filter (it does
  not know the type) — unchanged behaviour, noted so nobody expects 404.

## 8. Effort

P0 ½ day, P1 2 days, P2 ½ day, P3 ½ day, P4 ½ day ≈ 4 days; hunter's `auth-upstream` afterwards ≈ 3 days.
