# card-platform — dcm-client (upstream, P1c) and batak-client (twin, P2/P3)

Paths relative to `dcm-client/Assets/`. Map source: read-only scan 2026-10-27. Unity 6000.0.60f1, no first-party asmdefs.
Decisions applied: D9 (generic → `GameComponents/`), D10, D11 (one client repo per store app, proposed), D14 (runs on `dev` now).

## 1. Upstream extraction (P1c) — a pure move, no behaviour change

| # | Today | Change |
|---|---|---|
| C1 | Generic shell inside `DontCrossMe/Scripts/Core` (AppBootstrapper, LoaderController, MainCommands/Signals, Network/ incl. Telepathy + WS + WebGL transports, SceneLoader, Preferences, Kvp, Time, Timer, Internet, MonoUtils, CheatPanel) and `DontCrossMe/Scripts/GamePlay` (Login/Reconnect controllers, Models Login/User, Services/InventoryService, generic lobby header / coin / trophy views), `Task/` (AppLaunch, Login, PostLogin, LaunchLobby, CheckTosPP), `SignalAndCommands/NetworkCommands` generic handlers | Move into **`GameComponents/`**: the app shell (bootstrap, tasks, network client + transports, scene loader, preferences, time/timer/internet utils, user model, inventory service, generic response handlers) → `GameComponents/Core/` (next to the theme sprites already there); pieces that belong to an existing system go to that system's folder (login controllers → `GameComponents/Login`, lobby header / coin / trophy views → `GameComponents/Items`/`Leaderboard` as fits, Kvp → `GameComponents/Kvp`). Namespaces kept for this phase (rename comes with the unity-core package). Crossword-only parts stay in `DontCrossMe`: `Cross/`, `ZipZap/`, `GamePlay/Controllers/{Cross,Wheel,AI input, PlayPage, OnlineGame, Game scene}`, `Models/{Game,Level}`, `UI/{LevelPanelView, ExtraWords…}`, crossword response handlers (StartRound, TurnChange, GamePlay, BreakCell, LockWordOwner, GameSnapshot reader), `Tutorial/`, `Scene/Game/Game.unity`, `GameSolo.unity`. |
| C2 | 68 `GameComponents` files `using DontCrossMe.Scripts.*` (GamePlay.UI 24, GamePlay.Models 16, GamePlay 16, Core.Time 9, NetworkCommands 4) | After C1 most resolve inside `GameComponents`. The remainder (crossword game/level models and views) get the dependency inverted: the component exposes an interface or event, the game folder implements it. Gate: `grep -r "using DontCrossMe" Assets/GameComponents` = 0. |
| C3 | `AppBootstrapper` holds the MessageId→handler table mixing generic and crossword handlers, and the module registration list | `IClientGameModule { void Register(); IReadOnlyDictionary<int, IResponseHandler> Handlers; SceneName GameScene; IEnumerable<string> LobbyPageAddresses; }` (D10). `GameComponents/Core/AppBootstrapper` registers the GameComponents and the one game module named in `AppConfig.GameModule` (`"DontCrossMe"` / `"Batak"`); `DontCrossMe/DcmClientGameModule.cs` carries the crossword handlers and pages. |
| C4 | Lobby selection = language (`LanguageSettingsView`; game language via `LanguageChange` 207); `LoginRequest(token, protocolVersion)` | `LoginRequest` gains `GameId` from `AppConfig.GameId` (Crossle config = 0 → wire unchanged in meaning). Lobby flow keyed by `LobbyInfo.LobbyId`; Crossle still sends the language int in 207 (server maps it to `100 + language`); a card client sends the lobby id of the variant (201…). `AppConfig.GameId` also drives the anonymous `DeviceId` suffix (`deviceId:gameId`; Crossle: no suffix) in the login task — D5. |
| C5 | Builders + CLI inside `DontCrossMe/Editor` (`CommonBuilder`, `iOSBuilder`/`AndroidBuilder`/`WebGLBuilder`, `iOSPostProcess`, `PodfileNormalizer`, `AddressableBuilder`, `AppBuilderWindow`, `Cli/*`) | Move generic ones to **`Assets/Editor/Dcx/{Build,Cli}`**, class names and namespaces unchanged so `bash-scripts/apps/dcm-mini/z_dcm_client/env_*.sh` (`EXECUTE_METHOD=iOSBuilder.Build` …) keep working. `CommonBuilder`'s hardcoded default bundle id → `Resources/buildInfo.json`; provisioning profile names → build args. Crossle-specific builders (`HeartStatsBuilder`, `BoosterAnimationBuilder`, `ProfileTrophiesBuilder` + their `Cli/`) stay in `DontCrossMe/Editor`; the `LeaderboardSeason` CLI wrapper moves next to its builder in `GameComponents/Leaderboard/Editor/Cli`. |
| C6 | Addressables: 28 of ~55 entries point into DontCrossMe inside shared groups (Popups, Lobby, Scenes) | Groups split: `Shared_*` (GameComponents, DCMAssets sounds) vs `Game_*` (game folder). Addresses unchanged. |
| C7 | `GameComponents/Read.md` TODO "Move Scripts/Core to Here"; `Docs/AI_RULES.md` says `DontCrossMe/Scripts/Core` must not move into `GameComponents/Core` | Both rewritten (D9): `GameComponents/Core` = app shell + theme; `GameComponents/<System>` = plug-in systems (incl. systems Crossle does not use, e.g. `CardKit`, marked `NOT_USED_BY_CROSSLE.md` like the web rule); `<Game>/` = gameplay; the twin manifest is the definition. |

Gate: iOS / Android / WebGL builds through the existing bash chains; `unity command heart_stats_validate`, `season_ui_validate`,
`booster_validate`, `trophies_validate` OK; Play-Mode smoke login → lobby → online game → end → profile; C2 grep gate.
Runs on `dev` in parallel with the 1.0.9 polish (D14); re-sync after 1.0.9 (P4).

## 2. Twin exclude manifest — `general-manager/docs/twin/client.exclude` (P1d ✅ 2026-10-27, finalised in P1c)

Copied into `batak-client/twin/client.exclude` by `--init` (`#@upstream=dcm-client`, `#@dest=.`); the twin adds its
`/Assets/Batak` + `/Assets/Batak.meta` lines. Per-app: `Assets/DontCrossMe` (+ `.meta`), `Assets/Resources/AppConfig*.json`,
`IAPProductCatalog.json`, `buildInfo.json`, `ProjectSettings/ProjectSettings.asset`, `EditorBuildSettings.asset`,
`AndroidResolverDependencies.xml`, `user_keystores/`, the Firebase files (`google-services.json`, `GoogleService-Info.plist`,
`StreamingAssets/google-services-desktop.json`, `GeneratedLocalRepo/`), Addressables `AddressableAssetSettings.asset` +
`AssetGroups/` + `Android/` + `Windows/` (whole, until C6 splits shared vs game groups), and the stray tracked `fbg.log` /
`mono_crash.mem.*`. Gitignored trees (`Library/`, `Temp/`, `Logs/`, `obj/`, `*.csproj`, `*.sln`) are neither copied nor deleted;
the CCG submodule is pinned by git on the twin. Dry run: 1.3 GB synced, every per-app path absent, `--check` green.
Found on the way (→ C5): `GameComponents/Store/StoreController.cs` and `Store/iap/IAPManagerOld.cs` hardcode
`com.dcxstudios.dcm` — the bundle id must come from `buildInfo.json`/`AppConfig` before the twin can build a store release.

## 3. `GameComponents/CardKit` (upstream, P3) and `Assets/Batak` (twin, P3)

| Piece | Where | Content |
|---|---|---|
| `CardKit` | `dcm-client/Assets/GameComponents/CardKit/` (+ `NOT_USED_BY_CROSSLE.md`) | `CardKitModule`, card sprite atlas + `CardView`, `HandFanView`, `SeatView` ×4, `TrickAreaView`, `BidPanelView`, `TurnTimerRing`, generic `CardTableLayout` prefab; no game rules. Reused by Pişti/King twins. |
| `BatakClientGameModule` : `IClientGameModule` | `Assets/Batak/` | handlers 500–5xx, `GameScene = Game`, lobby page `BatakPage_Play` (variant chip, lobby 201 for MVP) |
| Scene `Scene/Game/Game.unity` | `Assets/Batak/` | `CardTableLayout` + Batak controllers (`BatakGameController : IGameController`, `BidController`, `HandController`), reconnect via snapshot payload |
| Editor | `Assets/Batak/Editor/` | `BatakTableBuilder` + `Cli/BatakTableCli` (`unity command batak_table_build|validate`), HeartStats-builder shape |
| Store | ProjectSettings (twin) | product "Batak", bundle `com.dcxstudios.batak`; icons via `general-manager/docs/app-icons/` pipeline (Unity adoption = open point) |
