# ci-gates — progress

Plan: `overview.md`.

| Step | Status |
|---|---|
| D1–D4 answered | 🔲 |
| P0 `check-all.sh` + first run recorded | 🔲 |
| P1 dcm-web workflow green | 🔲 |
| P2 hunter / flash / tapit / racer-web workflows | 🔲 |
| P3 Flutter ×3 | 🔲 |
| P4 docs + move to done | 🔲 |

Note from `flutter-core` (2026-09-27): the Flutter part of `check-all.sh` is `general-manager/bash/flutter-core-check.sh`
(package + vendored copies + templates + each client's analyze/test/theme gate). Flash and Tapit carry a vendored copy
of `dcx_flutter_core` in `<client>/packages/`, so their P3 workflows need **no** cross-repo checkout; Hunter's sees
`testapp/packages/` in its own checkout.

Nothing committed (hard rule).
