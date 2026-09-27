# NuGet packaging — the technical knowledge behind `nuget-feed/`

Written for Fatih, 2026-09-27. Read top to bottom once; every section is one idea, and every example uses our real
names (`Dcm.Core`, `flash-web`, `dcm-web`). Paths relative to `/Users/fkavum/Documents/project/`.

---

## 1. What we do today (so the rest has something to compare against)

1. `Dcm.Core` source lives in `dcm-web/Src/Dcm.Core/`. Inside dcm-web it is a **project reference** — the compiler
   sees the source, everything is checked.
2. Every other web project runs `Tools/sync-dcm-core.sh`. The script builds Dcm.Core in Release, then **copies three
   files** into `Src/Lib/`: `Dcm.Core.dll`, `CommonLib.dll`, `MysqlHelper.dll`, and writes a README stamp
   (commit, branch, dirty count, date).
3. The downstream csproj points at the file:
   ```xml
   <Reference Include="Dcm.Core">
     <HintPath>..\Lib\Dcm.Core.dll</HintPath>
   </Reference>
   ```
4. **A DLL reference carries no information about what the DLL itself needs.** `Dcm.Core.dll` was compiled against
   Serilog 4.3.0, MySqlConnector 2.4.0, Swashbuckle 9.0.0 and eleven more. The downstream must list all fourteen
   itself, at the same versions. That is why `flash-web/Src/Main/Main.csproj` lines 23–36 are a hand-copied block of
   `Dcm.Core.csproj` lines 14–27, and why `Src/Lib/README.md` ends with "must be kept in step".

That is the whole current method: **copy the binary, copy its dependency list by hand, stamp a README.**

---

## 2. What a NuGet package is

A NuGet package is **one file** with the extension `.nupkg`. It is a zip. Inside:

```
Dcm.Core.1.0.0.nupkg
├── lib/net8.0/Dcm.Core.dll          ← the same DLL we copy today
├── lib/net8.0/Dcm.Core.xml          ← doc comments (optional)
└── Dcm.Core.nuspec                  ← metadata: id, version, and the dependency list
```

The `.nuspec` is the part we do not have today. For Dcm.Core it would say, generated automatically from the csproj:

```
id:      Dcm.Core
version: 1.0.0
dependencies (net8.0):
  Serilog >= 4.3.0
  MySqlConnector >= 2.4.0
  Swashbuckle.AspNetCore >= 9.0.0
  … (all fourteen)
```

So: **package = DLL + its name + its version + its dependency list, in one file.** Nothing else is new.

---

## 3. Where packages come from and where they go

Three places, and you already use two of them without noticing:

| Place | What it is | You today |
|---|---|---|
| **Source / feed** | Where packages are looked up. Usually `nuget.org`. Can also be **a plain folder on disk** that contains `.nupkg` files. That folder is called a *local feed* or *folder feed*. Nothing runs; it is just a directory. | nuget.org, implicitly |
| **Global cache** | `~/.nuget/packages/<id>/<version>/` — every package ever restored on this Mac is unzipped here once and shared by all projects. | you have it: `~/.nuget/packages/awssdk.s3/…` |
| **Project** | `<PackageReference Include="Dcm.Core" Version="1.0.0" />` in the csproj. `dotnet restore` (automatic in `dotnet build`) reads it, finds the version in a source, unzips it into the cache, and links the DLL. | you do this for every third-party package already |

`nuget.config` is a small XML file that lists the sources. Put one at the repo root and restore looks there too:

```xml
<configuration>
  <packageSources>
    <add key="dcx-local" value="../general-manager/nuget" />   <!-- a folder, relative to this file -->
  </packageSources>
</configuration>
```

`nuget.org` stays as the default source; the folder is added next to it.

---

## 4. How a package is made — `dotnet pack`

`dotnet pack Src/Dcm.Core -c Release -o ../general-manager/nuget` does three things:

1. builds Dcm.Core (same as today);
2. reads `Dcm.Core.csproj` and writes the `.nuspec` from it — every `<PackageReference>` becomes a dependency,
   `<Version>` becomes the package version;
3. zips DLL + nuspec into `general-manager/nuget/Dcm.Core.1.0.0.nupkg`.

The only csproj change needed upstream:

```xml
<PropertyGroup>
  <PackageId>Dcm.Core</PackageId>
  <Version>1.0.0</Version>        <!-- we bump this by hand -->
</PropertyGroup>
```

`CommonLib` and `MysqlHelper` (source in dcm-generator) get the same two lines and the same `pack` call.

---

## 5. How a downstream consumes it

In `flash-web/Src/Main/Main.csproj`:

```xml
<!-- delete these -->
<Reference Include="Dcm.Core"><HintPath>..\Lib\Dcm.Core.dll</HintPath></Reference>
<Reference Include="CommonLib">…</Reference>
<Reference Include="MysqlHelper">…</Reference>
<!-- delete the fourteen copied Dcm.Core packages (lines 23–36) -->

<!-- add these -->
<PackageReference Include="Dcm.Core"     Version="1.0.0" />
<PackageReference Include="CommonLib"    Version="1.0.0" />
<PackageReference Include="MysqlHelper"  Version="1.0.0" />
```

`dotnet build` → restore reads `nuget.config` → finds `Dcm.Core.1.0.0.nupkg` in the folder → unzips to the cache
→ **also pulls Serilog 4.3.0, MySqlConnector 2.4.0, … automatically because the nuspec lists them.** flash-web's own
packages (EF Core, Pomelo, dbup, AWS S3) stay as they are. `Src/Lib/` and its README disappear.

---

## 6. Versioning — the one rule that matters

Semantic versioning, three numbers `MAJOR.MINOR.PATCH`:

| You changed… | Bump | Example |
|---|---|---|
| a bug fix, no signature change | PATCH | 1.0.0 → 1.0.1 |
| added something; old callers still compile | MINOR | 1.0.1 → 1.1.0 |
| renamed / removed / changed a signature; old callers break | MAJOR | 1.1.0 → 2.0.0 |

A downstream says `Version="1.1.0"` and gets exactly that. Upgrading is editing one number and building; if the
build breaks, the compiler tells you where, and you can stay on the old version until you have time — **each
downstream chooses when to take an upstream change.** Today they cannot: `sync-dcm-core.sh` always gives you HEAD.

### The gotcha you will hit once
If you re-pack **the same version number** with different code, restore does nothing — the cache already has
`Dcm.Core/1.0.0/` and trusts it. Symptom: "I changed Dcm.Core but flash-web still runs the old code." Cure: bump the
version (the rule) or, for a local experiment, `dotnet nuget locals all --clear` and restore again. The pack script
in the plan refuses to overwrite an existing `.nupkg` for that reason.

---

## 7. Day-to-day, side by side

| Step | Today | With the feed |
|---|---|---|
| Change Dcm.Core | edit in dcm-web, build | edit in dcm-web, build |
| Publish the change | — | bump `<Version>`, `Tools/pack-dcm-core.sh` → one new `.nupkg` in `general-manager/nuget/` |
| Take it in flash-web | `Tools/sync-dcm-core.sh` (copies 3 DLLs, rewrites README) **and** check the 14 package versions by hand | change `Version="1.0.0"` → `"1.1.0"` in one csproj line, build |
| Take it in all four | run the script four times | change one line in four csproj files (or not — each can wait) |
| Know which version a project has | read `Src/Lib/README.md` (commit hash + dirty count) | read the csproj line |
| Breaking change in Dcm.Core | discovered when the next sync + build fails, in each downstream, whenever that happens | discovered when you choose to bump; until then nothing changes |
| Dependency versions | hand-copied block in every csproj | come with the package |
| CI (`ci-gates/`) | works: DLLs are in git | works: `.nupkg` files are in git in general-manager, restore reads the folder |
| Git noise | 3 binary DLLs change in 4 repos per sync | 1 `.nupkg` added in general-manager per version; consumers: a one-line csproj diff |

---

## 8. What we gain by dropping the current method

1. **The dependency list travels with the DLL.** The fourteen hand-copied package lines in every downstream csproj
   go away, and "keep versions in step" stops being a rule anyone has to remember. This is the biggest one: it is
   the only part of today's method that can silently produce a wrong build (right DLL, wrong Serilog).
2. **Each downstream picks its moment.** A version number is a contract; HEAD is not. Crossle can ship Dcm.Core 2.0
   while hunter stays on 1.4 until you have a day for it. Today a sync is all-or-nothing.
3. **Breaking changes fail loudly and early** — at restore/build of the consumer that bumped, with the compiler
   pointing at the call site — instead of at the next sync in whichever repo happens to run the script.
4. **"Which Dcm.Core do I have" is a csproj line**, diffable, greppable, no README stamp, no dirty-count caveat.
5. **One fewer script and one fewer folder per repo**: `sync-dcm-core.sh`, `Src/Lib/`, `Src/Lib/README.md` retire in
   four repos; the same `.nupkg` also replaces `sync-libs.sh` and `build-common-libs.sh` for CommonLib/MysqlHelper
   into dcm-web and dcm-game-server (six consumers, one mechanism).
6. **Standard tooling.** Rider/VS show the package, its version and its dependency tree; `dotnet list package
   --outdated` tells you which downstream lags. None of that exists for a HintPath DLL.

## 9. What we do not gain, and what it costs

- Nothing changes about **how code is shared** — Dcm.Core stays one project in dcm-web; the feature folders
  (`sync-dcm-features.sh`) are source copies and are not affected by this at all.
- You now **bump a version on purpose**. Forgetting to bump = the §6 gotcha. The pack script guards it.
- The `.nupkg` files live in git (in general-manager). Same as the DLLs today, just in one place instead of four.
- Debugging into Dcm.Core from a downstream: works if the package includes symbols (`--include-symbols` or
  `<DebugType>embedded</DebugType>` — one csproj line). Today's DLL copy has the same limitation.
- Setup: ~1 day once (three packages, six consumers). Not worth it **before** `crossle-release-discipline/` and
  `ci-gates/`; worth it the first time a Dcm.Core change breaks a downstream at sync time, or when a sixth consumer
  appears (`overview.md` D1).

---

## 10. Glossary (one line each)

- **NuGet** — .NET's package system; the `dotnet` CLI already contains it.
- **`.nupkg`** — one zip: DLL + nuspec.
- **`.nuspec`** — the metadata inside: id, version, dependencies. Generated from the csproj by `dotnet pack`.
- **Feed / source** — a place restore looks for `.nupkg` files; nuget.org or a folder.
- **Folder feed** — a directory with `.nupkg` files in it. No server.
- **`nuget.config`** — the XML that lists sources; lives at the repo root.
- **Restore** — the step inside `dotnet build` that downloads/unzips packages into the cache.
- **Global cache** — `~/.nuget/packages`, shared by every project on the machine.
- **`PackageReference`** — the csproj line that names a package and version.
- **`HintPath` `Reference`** — the csproj line that names a DLL file. What we use today.
- **Transitive dependency** — a package your package needs; comes automatically with `PackageReference`, not with
  `HintPath`.
- **Semver** — MAJOR.MINOR.PATCH; MAJOR changes break callers.
