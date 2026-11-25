# Crossle twins — `sync-upstream.sh` and the exclude manifests

Masters for every twin of a Crossle repo (card-platform P1d, 2026-10-27; plan in
`general-manager/implementations/card-platform/`). A twin is a full copy of its upstream working tree where only the
paths in a manifest differ. Crossle stays the single upstream; a twin never edits a synced path — change the upstream and
re-sync.

| File | Purpose |
|---|---|
| `sync-upstream.sh` | the script, byte-identical in every twin as `<twin repo>/twin/sync-upstream.sh` (`--help` prints the contract) |
| `web.exclude` | per-app paths of a dcm-web twin (`#@upstream=dcm-web`, `#@dest=web`) |
| `game-server.exclude` | per-app paths of a dcm-game-server twin (`#@dest=game-server`) |
| `client.exclude` | per-app paths of a dcm-client twin (`#@dest=.`, one twin repo per store app; add its `Assets/<Game>` lines) |

## Layout of a twin

```
card/card-backend/            one git repo: backend + infra + manager (sharing-hygiene H9: mono repo for new apps)
  twin/sync-upstream.sh       copy of the master
  twin/web.exclude            copy of the master manifest (edit only to add twin-only paths)
  twin/game-server.exclude
  twin/upstream.lock.md       written by the script: one row per kind (upstream branch, commit, clean/DIRTY, submodule commits)
  web/                        = dcm-web minus web.exclude
  game-server/                = dcm-game-server minus game-server.exclude (CCG submodule pinned by git at game-server/DcmGameServer/Src/Core/CommonClientGame)
  docker/                     per-app compose + env (shaped after dcm-docker/crossle, not synced)
  manager/                    the one card manager (intro, implementations/, tools/)
card/batak-client/            one git repo per store app
  twin/{sync-upstream.sh, client.exclude, upstream.lock.md}
  Assets/…                    = dcm-client minus client.exclude (CCG submodule at Assets/CommonClientGame)
```

## Commands (run from the twin repo)

```
twin/sync-upstream.sh --init web game-server      # first copy into an empty folder; prints the per-app paths to write + submodule commands
twin/sync-upstream.sh                             # sync every kind that has a manifest; refuses a dirty upstream (--allow-dirty to override)
twin/sync-upstream.sh --check                     # build gate: lists every path that differs, exit 1 if any (checksum compare)
twin/sync-upstream.sh --upstream-root DIR …       # when the twin is not under /Users/fkavum/Documents/project
```

Rules the script enforces: the manifest paths are neither copied nor deleted; everything the upstream gitignores is
neither copied nor deleted; submodules are not copied (`--check` compares the twin's submodule commit with the upstream's);
`.git`, `.gitmodules`, `.idea`, `twin/` are never touched. Everything else is overwritten, and extra files are deleted
(`rsync --delete`): a twin-only file outside the manifest is lost on the next sync.

## Changing a manifest

Edit the master here, then copy it over the twin's `twin/<kind>.exclude` (the lock records the manifest md5, so a stale
copy is visible). Adding a per-app path means the upstream's version is deleted from the twin on the next sync and the
twin writes its own.

## Lobby pages on a twin (2026-10-28)

A lobby page prefab is shared when everything it references is under `GameComponents/` — `DcmPage_Album Page.prefab`
(the Puzzle tab of Crossle's meta progression) moved from `DontCrossMe/Prefabs/Views` to
`GameComponents/MetaProgression/PuzzleProgress/Prefab` for that reason (GUID kept). The twin's lobby scene is a copy of
Crossle's `DontCrossMe/Scene/Game/Lobby.unity` whose per-app page (the crossword Play page) loads as a stripped
missing-prefab instance; `batak-client/Assets/Batak/Editor/BatakSceneBuilder` swaps only that slot. Two editor rules found
on the way: a page prefab with its own canvas needs a `GraphicRaycaster`, and play mode must start from Main.

## Second client twin: pisti-client (2026-10-28)

`card/pisti-client` was made the same way as batak-client (`--init --allow-dirty client` from the dirty dcm-client, `git init`, the
printed `git submodule add` at the lock's CCG commit), then the per-app files were copied from batak-client (`Assets/AppData`,
`AppConfig*.json` with `GameId 3`, `IAPProductCatalog`, `buildInfo`, `ProjectSettings.asset` product `Pisti` / `com.dcxstudios.pisti`,
`EditorBuildSettings`, the Addressables settings + groups) and the manifest got its own `/Assets/Pisti` + `Game/Pisti` lines (the master
keeps those lines as `<Game>` templates). Its DTOs come from the card server with `generate-socket-shared.sh --game=Pisti --client-dir=…`:
a server that hosts several games exports each game into its own client. Nothing on dcm-client changed for the second client; the
Lobby scene copy + builder rule above applies as is (`Assets/Pisti/Editor/PistiSceneBuilder`).
First-run notes for any new client twin: the editor's backend environment is a per-app PlayerPref (`Environment`, 0 = local; the
default is prod), so set it once (`PlayerPrefs.SetInt("Environment", 0)` from the CLI eval or the in-game cheat panel); the editor's
anonymous device id is `zzz12333:<gameId>` since 2026-10-28, one account per card editor.

## P2 (2026-10-27)

`card/card-backend` and `card/batak-client` exist, created by `--init` (lock rows written, CCG submodule added at the
upstream commit). Two upstream seams the real twin exposed that the dry run (whole CCG synced) had hidden: the LoadBot's
crossword personas/parsers (now `DcmGameServer.LoadBot/Games/CrossWord/` + registries, S11) and the crossword builder in
`Tests/Helpers/TestDataBuilder` (now a partial in `Tests/Game/`). A twin's own game tests go under `DcmGameServer.Tests/GameModules/<G>/`
but must not use a `DcmGameServer.Tests.GameModules` namespace (it shadows the server's `GameModules.<G>` for relative references).

P1c (2026-10-27): the generic client shell lives in `GameComponents/Core`; a client twin compiles without `Assets/DontCrossMe`.
Gate tool: `unity-csproj-regen.py <project-root> [--exclude Assets/DontCrossMe --suffix twin]` regenerates the `<Compile Include>`
lists of the Unity-generated `Assembly-CSharp(.Editor).csproj` from disk (same rules as Unity: asmdef folders, Editor folders,
Plugins, `~` folders), so `dotnet build Assembly-CSharp.csproj` is a 5-second compile gate with the editor open; `--suffix twin`
writes `twin.Assembly-CSharp.csproj` with `Assets/DontCrossMe` excluded (same assembly name, separate output folder). For a twin
repo copy dcm-client's generated csproj set next to it and run the tool there. `Assets/AppData/` is per-app (manifest line):
assets that shared scenes reference by GUID — every twin ships its own files with the same GUIDs.

Process names: a twin that runs from source next to Crossle gets its own assembly names from a `Directory.Build.props` at
its repo root (`card/card-backend/Directory.Build.props`: `Main` → `CardWeb`, `DcmGameServer` → `CardGameServer`), outside
the synced folders and the Docker build contexts, so the sync never sees it and the images keep the upstream names.
Upstream `Main.csproj` sets `DcmCoreWeb` only when nothing pre-set another name (the SDK's default is the project name).

## P1d dry run (2026-10-27)

Scratch `card/card-backend` + `card/batak-client` from the live `dev` trees (`--allow-dirty`): web twin builds `Dcm.sln`
with a stub `AppModules` + `CardStatsExtension`; game-server twin builds with `GameModules/Stub` (one lobby, 4 seats) and
runs the shared tests (125 pass, the 3 known upstream failures); client twin synced (1.3 GB, every per-app path absent;
compile waits for P1c). `--check` green for all three except the expected "submodule missing" of a twin without git.
