# App icons — controlled from here for every Flutter client

Decided 2026-09-27 (`../../implementations/app-icons/overview.md`). Every Flutter client's app icon is set **from this
folder**: the artwork, the pipeline and the list of clients live here, and `icons.sh` pushes them into each client.
No packages — bash, plus the Swift that Xcode's command-line tools already provide for iOS/macOS builds.

```
docs/app-icons/
├── icons.sh           the driver: list / apply / check
├── app_icons.swift    the pipeline (master) — copied byte-identical into <client>/tool/
├── apps.txt           registry: <app> <client path>
├── hunter/source.png  artwork per app (+ optional hand-drawn icon_*.png)
└── flash/source.png
```

## Everyday use (from this folder)

```bash
./icons.sh list             # apps, clients, artwork size, hand-drawn count
./icons.sh apply flash      # push artwork + pipeline into flash/client and regenerate every platform icon
./icons.sh apply all        # same for every app in apps.txt
./icons.sh check            # every client in sync with this folder? exit 1 if not
```

### Change an app's icon

Replace `<app>/source.png` (square, ≥ 1024×1024, transparent is fine) → `./icons.sh apply <app>`.

### Hand-draw a size

Small sizes often need their own drawing. Put the file next to the source with the **exact master name** from the
client's `Resources/AppIcon/README.md`, e.g. `flash/icon_32x32.png` or `flash/icon_180x180_opaque.png`, then
`./icons.sh apply flash`. It replaces the generated master and goes to every platform file that master feeds.
`apply` refuses a name the pipeline does not generate and a file whose pixels don't match the size in its name,
before touching the client. Delete the file and `apply` again to go back to the generated one.

Don't edit anything under a client's `Resources/AppIcon/` or its platform icon folders by hand — the next `apply`
overwrites it. `check` catches a client whose script, source or hand-drawn files drifted from here.

### Change the pipeline

Edit `app_icons.swift` here only → `./icons.sh apply all` → `./icons.sh check`.

## What the pipeline produces

`swift tool/app_icons.swift generate` turns `Resources/AppIcon/source.png` into 33 masters in `Resources/AppIcon/`,
named by what they are; `install` copies them to the platform files.

| Master | Background | Artwork | Used for |
|---|---|---|---|
| `icon_<N>x<N>.png` | transparent | full canvas | favicon, PWA "any", Android legacy launcher, macOS, Windows `.ico` |
| `icon_<N>x<N>_opaque.png` | white, no alpha | full canvas | iOS (App Store rejects alpha), web apple-touch-icon |
| `icon_maskable_<N>x<N>.png` | white, no alpha | 62%, centred | PWA maskable (launcher crops to a shape inside an 80% circle) |
| `icon_adaptive_fg_<N>x<N>.png` | transparent | 47%, centred | Android 8+ adaptive foreground (only the central 66dp of 108dp is always visible) |

Platform file names stay Flutter's defaults (`ic_launcher.png`, `Icon-App-*.png`, `app_icon_*.png`, `app_icon.ico`)
and `Contents.json` is never touched. Full file → destination list: any adopted client's `Resources/AppIcon/README.md`.

## Adding a client (one-time)

1. Add `<app> <client path>` to `apps.txt` and the artwork at `<app>/source.png`.
2. In the client, add the Android adaptive icon (copy from an adopted client):
   `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` and `values/ic_launcher_background.xml` (`#FFFFFF`).
3. `web/manifest.json` icons → `icons/icon_{192,512}x…png` + `icons/icon_maskable_{192,512}x…png`;
   `web/index.html` → favicon `icons/icon_32x32.png` (sizes 32x32), apple-touch-icon `icons/icon_180x180_opaque.png`
   (sizes 180x180). Delete Flutter's `web/favicon.png` and `web/icons/Icon-*.png`.
4. `./icons.sh apply <app>`, then copy an adopted client's `Resources/AppIcon/README.md` and adjust its first paragraph.
5. Add a row below.

## Clients

| App | Client | Since | Artwork |
|---|---|---|---|
| 02 Hunter | `testapp/client` | 2026-09-27 (origin of the pipeline) | placeholder `hunter-icon-v1`, 256 px |
| 03 Flash | `flash/client` | 2026-09-27 | placeholder `flash-icon.png`, 447 px |
| 04 Tapit | `tapit/tapit-client` | ❌ not yet — Flutter's default icons | — |

DCM/Crossle and Racer ship Unity clients; their icons are set in Unity, not here.

## Not covered

Linux (Flutter's Linux runner sets no app icon), the Android 13 themed/monochrome icon, splash screens, store listing
graphics (the Play 512 px icon can be `icon_512x512.png`).
