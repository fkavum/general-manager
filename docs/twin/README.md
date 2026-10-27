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

## P1d dry run (2026-10-27)

Scratch `card/card-backend` + `card/batak-client` from the live `dev` trees (`--allow-dirty`): web twin builds `Dcm.sln`
with a stub `AppModules` + `CardStatsExtension`; game-server twin builds with `GameModules/Stub` (one lobby, 4 seats) and
runs the shared tests (125 pass, the 3 known upstream failures); client twin synced (1.3 GB, every per-app path absent;
compile waits for P1c). `--check` green for all three except the expected "submodule missing" of a twin without git.
