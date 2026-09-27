# nuget-feed — versioned packages instead of DLLs copied into five repos (PARKED)

Review §3.5, owner 2026-09-27: plan it. Multi-project: dcm-generator, dcm-web, hunter-web, flash-web, tapit-web,
racer-web, dcm-game-server. Paths relative to `/Users/fkavum/Documents/project/`.

## 1. State

- Chain: dcm-generator (`CommonLib`, `MysqlHelper` source) → `dcm-web/Tools/sync-libs.sh` → `dcm-web/Src/Lib/`
  → `Tools/sync-dcm-core.sh` in 4 downstreams (adds `Dcm.Core.dll` built from `dcm-web/Src/Dcm.Core`) → `Src/Lib/`.
  dcm-game-server gets its copy via `dcm-generator/Tools/build-common-libs.sh`.
- Version = a README stamp (commit, branch, dirty count). Rule in dcm-manager: "keep the consumer's NuGet versions in
  step with `Dcm.Core.csproj`" — manual.
- All four downstream `Src/Lib/*.dll` are md5-identical today (2026-09-27). It works because one person runs every sync.

## 2. Proposal (when triggered)

- `dotnet pack` for `Dcm.Core`, `CommonLib`, `MysqlHelper` with `<Version>` in the csproj (semver, bumped by hand on
  a breaking change) into a folder feed `general-manager/nuget/` (or `dcm-web/nuget/`); every consumer gets a
  `nuget.config` with that folder as a source and a `<PackageReference Include="Dcm.Core" Version="1.x.y" />`.
- `sync-dcm-core.sh` becomes `pack-dcm-core.sh` (upstream side, produces the `.nupkg`) and the downstream "sync" is a
  version bump in the csproj — visible in the diff, refused by restore if the package does not exist.
- Transitive NuGet versions (EF Core, Serilog…) come with the package metadata, which retires the "keep versions in
  step" rule.
- CI (`ci-gates/`) restores from the folder feed because the `.nupkg` files are committed next to the DLLs they replace.

## 3. Trigger and decisions

| # | Question | Proposal |
|---|---|---|
| D1 | When | The first time a Dcm.Core change breaks a downstream at sync time instead of build time, or when a sixth consumer appears. Not before `crossle-release-discipline/` and `ci-gates/` are done. |
| D2 | Feed location | `general-manager/nuget/` (cross-app home, already holds cross-app masters). |
| D3 | Versioning | Semver by hand; `pack-dcm-core.sh` refuses to pack a dirty tree (same rule as `sharing-hygiene/` H1). |

Effort when started: 1 day for the three packages + five consumers.
