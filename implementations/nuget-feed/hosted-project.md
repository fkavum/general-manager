# `Src/Main.Hosted` — what it is, what it does, why it exists

Written for Fatih, 2026-09-27. Companion to `technical-knowledge.md`. One idea per section, our real names throughout.
Paths relative to `/Users/fkavum/Documents/project/dcm-web/`.

---

## 1. The one-sentence version

`Main.Hosted` is a **build-only** project that compiles the modules dcm-web *hosts for the other apps but Crossle does
not use*, so that (a) those modules are **kept out of Crossle's DLL** and cannot collide with Crossle's routes, and
(b) they are still **compiled on every dcm-web build**, so a refactor that breaks them fails in dcm-web, not weeks
later in flash-web.

Nothing runs it. Nothing references it. It exists only to be built.

---

## 2. The rule that created the need

On 2026-09-24 we decided: **dcm-web is the only upstream.** A module used by two or more web projects lives in dcm-web
**even when Crossle does not use it**. Such a module gets a marker file `NOT_USED_BY_CROSSLE.md` in its folder and is
not registered in `AppModules.cs`.

First examples that day: `AuthOffline` + `UserOffline` (racer + flash), `Core/Cors` (hunter + flash + tapit).

So dcm-web's source tree now contained code Crossle never calls. The obvious assumption was: "not wired in
`AppModules.cs` → not running → harmless". That assumption is wrong for one kind of class.

---

## 3. The ASP.NET fact that breaks the assumption

`services.AddControllers()` (in `DefaultWebAppRunner`) **scans the whole assembly** and maps **every** class that
inherits `ControllerBase`, whether or not you ever called `AddAuthOfflineModule()`. Module registration wires
services (DI); it does not decide which controllers exist. Controllers exist because they are in the DLL.

Consequence on 2026-09-24, verified against the real `[Route]` attributes:

| Hosted module | Its route | Crossle's route | Result at startup |
|---|---|---|---|
| `AuthOffline` | `POST api/login/anonymous`, `api/login/refresh` | `Auth` has the same two | **AmbiguousMatchException** — Crossle does not start |
| `UserOffline` | `POST api/user/change_status` | `User` has the same | same |

Your warning in chat that day — *"be careful while moving, endpoints should not collide, there are too many
different auth features"* — was exactly this. Leaving the code in the folder was enough to break production.

---

## 4. The mechanism — two halves, one marker file

Everything is driven by the presence of `NOT_USED_BY_CROSSLE.md` in a module folder. No list to maintain.

### Half A — `Src/Main/Main.csproj`: take the marker folders OUT of `DcmCoreWeb.dll`

```xml
<HostedMarker Include="Src\**\NOT_USED_BY_CROSSLE.md" />              <!-- find every marker -->

<Target Name="RemoveHostedModules" BeforeTargets="CoreCompile">
  <Compile Remove="Src\%(HostedMarker.RecursiveDir)**\*.cs" />        <!-- drop that folder's .cs files -->
</Target>
```

`%(HostedMarker.RecursiveDir)` is the marker's folder, e.g. `Core\Cors\`. So every `.cs` under a marker folder is
removed from Crossle's compilation. The controller is not in the DLL → ASP.NET never sees it → no route → no
collision. (Why a target and not a plain `<Compile Remove>`: MSBuild wildcards do not expand inside an item
transform, so the removal has to run per marker inside a target that fires before compile. That is the whole reason
the XML looks more complicated than "remove these files".)

### Half B — `Src/Main.Hosted/Main.Hosted.csproj`: compile exactly those folders somewhere else

```xml
<AssemblyName>DcmCoreWeb.Hosted</AssemblyName>
<EnableDefaultCompileItems>false</EnableDefaultCompileItems>          <!-- start with NO source files -->
<ProjectReference Include="..\Main\Main.csproj" />                    <!-- see all of Main's and Dcm.Core's types -->

<HostedMarker Include="..\Main\Src\**\NOT_USED_BY_CROSSLE.md" />      <!-- the same markers -->
<Target Name="IncludeHostedModules" BeforeTargets="CoreCompile">
  <Compile Include="..\Main\Src\%(HostedMarker.RecursiveDir)**\*.cs" /> <!-- add exactly those folders -->
</Target>
```

It references `Main`, so a hosted module compiles against the real `Dcm.Core`, `Identity`, `AppDbContext`, whatever
it needs — the same types the downstream will compile it against after `sync-dcm-features.sh`. It is in `Dcm.sln`,
so `dotnet build Dcm.sln` builds it every time. `IsPackable=false`, nobody references `DcmCoreWeb.Hosted.dll`, the
Docker image never copies it.

### The two halves are mirror images

| | Main (Crossle) | Main.Hosted |
|---|---|---|
| default compile items | all of `Src/**/*.cs` | none |
| marker folders | **removed** | **included** |
| output | `DcmCoreWeb.dll` — runs in production | `DcmCoreWeb.Hosted.dll` — built, then ignored |

Add a marker → the folder moves from the left column to the right. Delete the marker → it moves back. No other edit.

---

## 5. What you get from it

1. **Route safety for Crossle.** A hosted module can declare `api/login/anonymous` and Crossle still boots, because
   that controller is physically not in Crossle's assembly. Probe-tested 2026-09-24: marker present → route absent
   from the DLL and from Swagger; marker removed → present again.
2. **Upstream breakage is caught upstream.** If you rename something in `Dcm.Core` or `Identity` that `Core/Cors`
   uses, `dotnet build Dcm.sln` fails in dcm-web *today*, with the error pointing at the hosted file. Without
   Main.Hosted the folder would be dead text in dcm-web and the error would appear in hunter-web after the next sync,
   with no hint that dcm-web caused it.
3. **No list to maintain.** The marker file you already write for documentation ("Used by: hunter-web, flash-web,
   tapit-web") is the switch. `Tools/list-shared-modules.sh` reads the same markers and exits 1 if a folder is
   hosted **and** wired in `AppModules.cs` — the one inconsistent state.

---

## 6. State today (2026-09-27)

```
$ Tools/list-shared-modules.sh
HOSTED   Core/Cors   (used by: hunter-web, flash-web, tapit-web)
WIRED    Features/Auth, Features/Identity, Features/Kvp, Core/Storage, Core/Database, …
HELPER   Core/Common, Core/Mapping, Core/Middleware, Core/Redis, Core/Swagger, Features/Legal, Features/Test
```

Only **one** module is hosted, `Core/Cors` (`CorsConfig.cs`, `CorsModule.cs`), and it has no controller. So right
now the collision guard (§5.1) is idle and the compile guard (§5.2) is what is working for you. `AuthOffline` /
`UserOffline`, the modules that motivated all this, were hosted for one day and then replaced by the shared
`Identity` + `Auth` that Crossle itself runs (identity-core, 2026-09-25) — which is the better outcome: a module
Crossle also uses needs no hosting at all.

Small leftover: the comments in both csproj files still cite `AuthOffline` as the example. `sharing-hygiene/` H5
changes them to `Core/Cors`.

---

## 7. When it matters again

The next time a module is promoted to dcm-web that Crossle will **not** register and that **has controllers** —
for example hunter's `Community` if flash ever needs the same shape, or a future `UserHunter`-style aggregate shared
by two apps. The checklist is short:

1. create the folder under `Src/Main/Src/Features/<Name>/` with `NOT_USED_BY_CROSSLE.md` (template in `Src/Docs/`);
2. `dotnet build Dcm.sln` — Main prints `hosted module excluded from DcmCoreWeb.dll: Src\Features\<Name>\`,
   Main.Hosted prints `compiling hosted module …`;
3. `Tools/list-shared-modules.sh` shows `HOSTED`;
4. run Crossle locally and check Swagger does **not** list the hosted routes;
5. downstreams add the folder to `FEATURES` in `sync-dcm-features.sh` and wire `Add<Name>Module()` themselves.

---

## 8. How to see it with your own eyes (five minutes)

```bash
cd ~/Documents/project/dcm-web
dotnet build Dcm.sln -v m | grep -i hosted            # both messages from §7 step 2
ls Src/Main/bin/Debug/net8.0/DcmCoreWeb.dll Src/Main.Hosted/bin/Debug/net8.0/DcmCoreWeb.Hosted.dll
# proof the guard works: temporarily copy the marker into a WIRED folder, e.g. Features/Kvp, build, and watch
# Main fail with "AddKvpModule not found" (Kvp left the main DLL) — then delete the copied marker again.
```

---

## 9. FAQ

- **Is it deployed?** No. Only `DcmCoreWeb.dll` ships (Dockerfile publishes `Main.csproj`). `DcmCoreWeb.Hosted.dll`
  stays in `bin/`.
- **Does it slow the build?** A few hundred milliseconds for one folder today.
- **Why not a separate repo for hosted modules?** That was the "extract a shared repo" option, deferred on 2026-09-24
  as a five-repo migration for a problem one marker solves. Main.Hosted is the cheap version of the same isolation.
- **Why not just `[ApiExplorerSettings(IgnoreApi)]` or a route prefix?** Those hide or move routes; the ambiguity
  error happens at startup regardless. The only reliable fix is the controller not being in the assembly.
- **Can tests cover hosted code?** `Main.Test` may reference `Main.Hosted` for construction tests; the real runtime
  coverage is the downstream test suites (hunter 46, flash 93, tapit 20 attributes) after they sync.
- **Relation to `nuget-feed/`?** None directly. Hosting is about *source* modules copied by `sync-dcm-features.sh`;
  the NuGet plan is about the *binary* `Dcm.Core`. Both would coexist unchanged.
