# identity-core — dcm-web steps (P0–P2)

Companion to `overview.md`. All under `dcm-web/Src/Main/Src/Features/` unless stated. New shared files: explicit
usings, `ILogger<T>` (shared code) — moved Crossle files keep `Logy` and their namespaces.

## P0 — pin today's wire (before touching anything)

`Src/Main.Test/Src/Features/Auth/LoginWireContractTest.cs` (`DcmWebApplicationFactory`, raw-string assertions):
1. `POST api/login/anonymous {"DeviceId":"<new>","Language":1}` → **201**; body keys in order `UserId, Token, Status{Uid,Status,StartDate,EndDate}, MinVersions, GameServer, SupportedLogins`, PascalCase.
2. Same device → **200**, same `UserId`.
3. `{"DeviceId":""}` → **400** `{"ErrorCode":0,"Message":"No Device Id","Details":""}`.
4. `POST api/login/refresh` with `auth: Bearer <token>` → 200 same `UserId`; without → 401 (empty body).
5. `POST api/login/verify {"Token":"<token>"}` → 200 `{"UserId":<uid>}`; garbage → 400 `Message` starts `Error:`.
6. `POST api/login/facebook {"FacebookToken":""}` → 400 `No Facebook Token`; `POST api/login/firebase {"FirebaseToken":"x"}` → 400 `Invalid Firebase Token`.
7. `POST api/user/change_status` with the server header → 200; without → 401.
8. Token continuity: mint with `Main.Services.JwtService`, verify with the new shared `JwtService` (added in P1; the test is written now against the old one and extended then).

## P1 — build the modules (moves first, new code second)

### Identity/
From `UserOffline/` + new: entities/configs (move), `Contracts/{EUserStatus, UserStatusData}` (move from `AuthOffline/Contracts`), `Contracts/NewUserRequest {DeviceId, Ip, Language:int}`, `IUserBuilder { CreateUserAsync(NewUserRequest, ct); SoftDeleteUserAsync(uid, ct) }`, `IUserNameProvider`, `IUserStatusProvider`, `UserRepository` (implements all three by default), `UserService`, `IdentityModule.AddIdentityModule()` with `TryAddScoped` for the three seams.

### Auth/
- Move from `AuthOffline/`: `AuthProvider`, `IJwtService`, `JwtService`, `LinkedAccountEntity`, `DbConfig/LinkedAccountEntityConfig`, `UserAccessMiddleware` (+pipeline), `Contracts/AnonymousRequestBody` (`Language:int` added, default 0).
- `ILinkedAccountRepository` + `LinkedAccountRepository`: Crossle's full versions from `Auth/Core/` (EF + `DeleteAllForUser(uid, ExecutorArgs)`), namespace `Main.Features.Auth`, `CancellationToken ct = default` added to the EF methods.
- `IAuthProvider`, `Contracts/TokenValidation`, `Contracts/SecondaryLink` (from `AuthServices/TokenValidationResult`).
- `LoginService` — port of Crossle's `AuthServices/LoginService.cs` with: `IJwtService` instead of inline token code; `IUserBuilder`/`IUserStatusProvider` from Identity; `IEnumerable<IAnonymousLoginHook>` instead of the hard-wired legacy fallback; `AuthOptions.RequireSecureLogin`; `HandleProviderLogin(IAuthProvider, token, deviceId)` = old `HandleLogin` (uid via `FindUidByProvider(provider.Key, externalId)`, `AutoRegisterExternalIdentities` creates + links when unknown); returns `LoginResult` (status + `LoginOutcome` or `ErrorResponse`) — every status code and message copied verbatim.
- `LoginResponseWriter`: `LoginOutcome` → ordered fields `UserId, Token, Status` → each `ILoginResponseEnricher.EnrichAsync(ctx)` appends → `JsonConvert` with PascalCase or camelCase per `AuthOptions.ResponseNaming`.
- `AttachService` — Crossle's, generic over `IAuthProvider` (already-attached / taken / link via the repository).
- `LoginController` (`anonymous` with `RateLimiterPipeline` + `LogResponsePipeline`, `refresh`, `verify` with `PrivateAccessPipeline`), `AttachController` (`test`).
- `Contracts/`: `VerifyRequestBody`, `VerifyResponse`, `LoginResponse` (base), `AttachResponse` + `EAttachResult`, `AckResponse` — the Crossle ones move here **keeping `Main.Dtos`** (client DTOs).
- `AuthOptions`, `AuthModule.AddAuthModule(Action<AuthOptions>? configure = null)`.

### AuthFacebook/ AuthGoogle/ AuthApple/ AuthFirebase/
Per provider: `<P>ApiService` (move from `AuthServices/Providers`, `FirebaseApiService` + `FirebaseApp.Create` init from `Firebase:{ProjectId, CredentialsFile}` with `GetApplicationDefault()` fallback), `<P>AuthProvider` (from `<P>LoginStrategy.ValidateToken` incl. secondary links; `Key = AuthProvider.<P>`, `DisplayName = "<P>"`), `<P>LoginController` + `<P>AttachController` (bodies verbatim from the old controllers), `Contracts/` (move, `Main.Dtos` kept), `Auth<P>Module`.

### AuthEmail/
Move `Auth/Email/*`; `EmailCodeService`/`EmailPasswordService` take the shared `LoginService`; `EmailLoginController` (`email`, `email/forgot`, `email/reset`, `email/code/request`, `email/code/confirm` with the same pipelines) + `EmailAttachController` (`email/password`, `email/code/request`, `email/code/confirm`); `AuthEmailModule` (= old `EmailModule`).

### AuthCrossle/
`MinVersionsLoginEnricher` (`DataRepository.GetMinVersionsData` → `MinVersions`), `GameServerLoginEnricher` (`ConfigurationService.GameServer` → `GameServer`), `SupportedLoginsLoginEnricher` (→ `SupportedLogins`); `LegacyDeviceInfoAnonFallback : IAnonymousLoginHook` (move); `Contracts/LoginResponse.cs` (Crossle's full DTO, move, `Main.Dtos`); `AuthCrossleModule.AddAuthCrossleModule()` registering the hook + the three enrichers in order.

### UserBasic/
From `UserOffline/`: `UserController` (uses `Auth.UserAccessPipeline`, `ServerAccessPipeline`), `UserNameLoginEnricher` (`IUserNameProvider` → `Name`), `UserBasicModule`, marker.

### Features/User (Crossle)
`UserStatusRepository` → adapter over `IUserStatusProvider` (maps to `Main.HttpShared.UserStatusData`; `ChangeStatus(data, args)` keeps its signature); `UserUnitOfWork : IUserBuilder` adapter methods; `UserLoginEnricher` + `UserLoginEnrichmentData` deleted (AuthCrossle replaces them; `UserLoginEnrichmentData` stays exported for the client only if the client references it — check `HttpShared/User`); `UserAccountsRepository`(+`_orm`, entity, config) moved in from `Auth/`; `UserModule` registers `IUserBuilder`, `IUserNameProvider` adapters, `LegacyDeviceInfoAnonFallback`'s dependency `UserDeviceInfoRepository` stays here.

### Deletions
`AuthOffline/`, `UserOffline/`, `Auth/Core/`, `Auth/Anon/`, `Auth/AuthServices/` (except what moved), `Auth/LoginController.cs`, `Auth/AttachController.cs`, `Auth/AuthModule.cs`, `Auth/{Facebook,Google,Apple,Firebase}/` (the `Core*` generation), `User/UserLoginEnricher.cs`.

### Wiring (`AppModules.cs`)
`AddIdentityModule(); AddAuthModule(o => { o.CreatedStatusCode = 201; o.ResponseNaming = PascalCase; o.RequireSecureLogin = configuration["Auth:RequireSecureLogin"]; }); AddAuthFacebookModule(); AddAuthGoogleModule(); AddAuthAppleModule(); AddAuthFirebaseModule(configuration); AddAuthEmailModule(); AddAuthCrossleModule();` — `AddUserModule()` stays before Identity so its `IUserBuilder`/`IUserNameProvider` win the `TryAdd`. `Core/Middleware/UserAccessMiddleware.cs` → `Main.Utils.UserAccessPipeline` alias over `Main.Features.Auth.UserAccessMiddleware`. `AppDbContext.OnModelCreating` → `ApplyConfigurationsFromAssembly(asm, t => t != typeof(Identity.DbConfig.UserEntityConfig))` with the D5 comment.

### Tests
`AnonLoginServiceTest` rewritten against `LoginService`; the other auth tests keep compiling (`Main.Dtos` DTOs unchanged); contract test green; token-continuity test extended.

## P2 — verify Crossle
`dotnet test` full; live smoke on `:20100` (P5 list in overview); `Tools/generate-http-shared.sh` into a temp dir before/after → same classes/namespaces/fields, only folders differ; `list-shared-modules.sh`: `Identity`, `Auth`, `Auth*`, `AuthCrossle` WIRED; `UserBasic` HOSTED.
