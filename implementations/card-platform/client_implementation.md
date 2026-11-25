# card-platform — dcm-client (upstream, P1c) and batak-client (twin, P2/P3)

Paths relative to `dcm-client/Assets/`. Map source: read-only scan 2026-10-27. Unity 6000.0.60f1, no first-party asmdefs.
Decisions applied: D9 (generic → `GameComponents/`), D10, D11 (one client repo per store app, proposed), D14 (runs on `dev` now).

## 1. Upstream extraction (P1c) — a pure move, no behaviour change — **implemented 2026-10-27** (see `session_progress.md` P1c row; C6 group split deferred, validators pending the editor)

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

## 3. `GameComponents/CardKit` (upstream, P3) and `Assets/Batak` (twin, P3) — **built 2026-10-27**: CardKit = generated card sprites (`Sprites/Cards`, 52 + back, metas with fixed GUIDs), `CardCodec`, `CardSpriteSet`, `CardView`, `HandFanView`, `TrickAreaView`, `SeatView` (with the turn ring), `BidPanelView`, `TrumpPanelView`, `CardTableLayout`, `Editor/CardKitBuilder` + `Cli/CardKitCli` (`cardkit_build`, `cardkit_validate`; prefabs are built in the twin's batch editor and copied upstream); batak-client `Assets/Batak` = `BatakModel`, `BatakRules` (client copy of the legality rules), `BatakGameController : IGameController`, `Handlers/` (500–505 + snapshot, `BatakSceneFlow` enters the Game scene), `BatakClientGameModule`, `UI/BatakPlayPage`, `UI/BatakEndGamePopup`, `Editor/BatakSceneBuilder` + `Cli/BatakCli` (`batak_build`, `batak_validate`, batch `-executeMethod Batak.Editor.Cli.BatakCli.BuildAll`): Game.unity (overlay canvas 1125×2436 + table + controller), Lobby.unity (copy of dcm-client's lobby, crossword pages/tab removed, Batak Play page second, 4 pages / 4 tabs), Addressables (`EndGamePopup`, `Lobby`, `Game`, `BatakPage_Play Page`; crossword entries pruned), build list (Main enabled, Lobby/Game disabled — they load through Addressables). **2026-10-28:** page prefabs with their own canvas need a `GraphicRaycaster` (Crossle's have one; the Batak page did not → Play not clickable); `BuildAll` ends on Main because play mode must start there (EventSystem, camera, popup canvases); Crossle's meta progression ships on the twin — `DcmPage_Album Page.prefab` (the Puzzle tab) now lives upstream in `GameComponents/MetaProgression/PuzzleProgress/Prefab`, the twin lobby keeps Crossle's Shop / Puzzle / Play / Board / Friends order and only the crossword Play page is swapped, `BatakClientGameModule` registers `PuzzleProgressModule.RegisterLive`, the Play page carries the "Find a piece!" shortcut and the end popup the `ItemIconDatabase` reward row; card web seeds the puzzle cities (migration 0003).

| Piece | Where | Content |
|---|---|---|
| `CardKit` | `dcm-client/Assets/GameComponents/CardKit/` (+ `NOT_USED_BY_CROSSLE.md`) | `CardKitModule`, card sprite atlas + `CardView`, `HandFanView`, `SeatView` ×4, `TrickAreaView`, `BidPanelView`, `TurnTimerRing`, generic `CardTableLayout` prefab; no game rules. Reused by Pişti/King twins. |
| `BatakClientGameModule` : `IClientGameModule` | `Assets/Batak/` | handlers 500–5xx, `GameScene = Game`, lobby page `BatakPage_Play` (variant chip, lobby 201 for MVP) |
| Scene `Scene/Game/Game.unity` | `Assets/Batak/` | `CardTableLayout` + Batak controllers (`BatakGameController : IGameController`, `BidController`, `HandController`), reconnect via snapshot payload |
| Editor | `Assets/Batak/Editor/` | `BatakTableBuilder` + `Cli/BatakTableCli` (`unity command batak_table_build|validate`), HeartStats-builder shape |
| Store | ProjectSettings (twin) | product "Batak", bundle `com.dcxstudios.batak`; icons via `general-manager/docs/app-icons/` pipeline (Unity adoption = open point) |

## 4. `card/pisti-client` (twin, second game — 2026-10-28)

Same shape as §3 on a second dcm-client twin (`docs/twin/README.md` "Second client twin"): `Assets/Pisti` = `PistiModel`,
`PistiGameController` (every card in hand is legal: input = "my turn"), `Handlers/` (600–603 + snapshot, `PistiSceneFlow`),
`PistiClientGameModule` (registers Crossle's Puzzle Progress like Batak), `UI/PistiTableView` (a two-seat table built on CardKit's
`CardView` / `SeatView` / `HandFanView`: my hand, the opponent's face-down cards, the pile = top card + under card + count with
play / capture tweens, deck count), `UI/PistiPlayPage`, `UI/PistiEndGamePopup` (2 rows + the reward row), `Editor/PistiSceneBuilder` +
`Cli/PistiCli` (`pisti_build`, `pisti_validate`; CardKit's prefabs are only validated, never rebuilt — a rebuild regenerates fileIDs and
drifts the synced prefab). `AppConfig*.json` GameId 3 → lobby 301. Per-app files copied from batak-client; details and the smoke in
`card/card-backend/manager/implementations/pisti-mvp/session_progress.md`.
