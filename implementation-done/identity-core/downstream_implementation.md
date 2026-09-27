# identity-core — racer-web + flash-web (P3), hunter-web pointer

Companion to `overview.md`. Both projects already run the code; this is the resplit + rename sync.

## racer-web

| Step | Change |
|---|---|
| `Tools/sync-dcm-features.sh` | `FEATURES`: replace `Features/AuthOffline`, `Features/UserOffline` with `Features/Identity`, `Features/Auth`, `Features/UserBasic`; run; delete the two old folders by hand |
| `AppModules.cs` | `AddIdentityModule(); AddAuthModule(o => { o.ResponseNaming = CamelCase; o.CreatedStatusCode = 200; }); AddUserBasicModule(); AddUserNameLoginEnricher();` |
| `Core/Middleware/UserAccessMiddleware.cs` | alias over `Main.Features.Auth.UserAccessMiddleware` |
| `Core/Database/AppDbContext.cs` | usings → `Main.Features.Identity`, `Main.Features.Auth` |
| `appsettings*.json` | unchanged (`JWT:SecretKey`, `Auth:AllowDevUidTokens`) |
| Gate | build; `--check`; the 20-check live smoke (routes/bodies identical; `api/login/verify` and `api/attach/test` are new but unused) |

## flash-web

| Step | Change |
|---|---|
| `FEATURES` | same three; run; delete old folders |
| `AppModules.cs` | as racer |
| `DeckController.cs`, `AppDbContext.cs`, tests (`CommunityListTest`, `DeckOwnershipTest`, `AuthOffline/*`, `UserOffline/*`) | usings → `Main.Features.Auth[.Contracts]`, `Main.Features.Identity[.Contracts]`, `Main.Features.UserBasic`; test folders renamed to match |
| Baselines | `routes.txt` +`POST /api/login/verify`, +`POST /api/attach/test`; `efmodel.txt` unchanged — regenerate |
| Gate | 92/92; `--check`; the 15-check live smoke |

## hunter-web

`testapp/hunter-manager/implementations/auth-upstream/` starts after P4: syncs `Identity`, `Auth`, `AuthFirebase` (+ its own
`UserHunter` aggregate and `HunterLoginEnricher`). Its former upstream step (Firebase strategy + enricher seam) is done
by this plan.
