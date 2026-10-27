# New game candidates: high organic volume, low competition (research 2026-10-26)

Goal: pick a new mobile game for the Dcx portfolio whose downloads come without a marketing budget.
Selection rule used: **(a) large, growing install demand, (b) few serious titles capturing it, (c) a store-search or
word-of-mouth mechanism that brings installs without UA, (d) buildable with what we already have (Unity, Flutter,
dcm-generator + kaikki.org multilingual dictionaries, .NET backend).**

## Market backdrop (2025 → H1 2026)

- Mobile game downloads fell 7% in 2025 to ~50B (Sensor Tower) and ~12% YoY in H1 2026 across every genre; IAP held up. Supply exploded: 1.4M app releases in 2025 (+25%), 72% games, ~10% get any attention (AppMagic landscape).
- Only 1.4% of new launches reach $1M (Gamigion, H1 2025). Match-3 is "one of the hardest categories to break into"; Block puzzle had 2,000+ releases in H1 2026 (+89%) and Sort/Screw ~900K new titles combined → the hybrid-casual puzzle wave is now oversupplied and UA-driven.
- Strategy/4X is the only genre growing on all metrics, but it is capital-heavy and an "increasing oligopoly" (top 10 = 64% of revenue). Not for us.
- Organic share: paid installs are 57% of Android gaming installs overall, but Turkey and Vietnam casual are "organic-heavy" markets (AppsFlyer 2026). Search-driven classic genres are where organic lives.
- Top generic App Store game keywords (AppTweak, volume score 5–100): US "no wifi games" 74, "puzzle games" 72; UK "puzzle games" 76, "no wifi games" 75, "sudoku" 72, "games without wifi" 69; FR "jeux sans wifi" 71; DE "offline spiele" 68; ES "juegos sin wifi" 63; IN "offline games" 64.

## The top 3

### 1. Big-print classic puzzles for 50+ players in non-English languages (crossword, word search, number puzzles)

**Demand.** The single biggest organic story of 2025 was a game built for seniors: Vita Mahjong (Vita Studio, Singapore) hit 121.9M downloads, #7 worldwide, and pushed the whole mahjong-solitaire category from ~90M to 258M downloads (+189% YoY). Tile match grew +28% to 503M. AARP 2026: older adults gravitate to puzzle and word games first, card/tile second; two-thirds play on phones. 55+ is 19–23% of players but under-represented vs population (only ~30% of 55+ play) → the audience is still being unlocked. "Senior Word Game" (500K+) gets reviews complaining of tiny boxes and no zoom → accessibility is still a gap.

**Competition.** Vita Studio has already copied its own formula into Solitaire, Spider, FreeCell, Jigsaw, Block, Color, Color Sort, Crossword and Word Search, in 62 UI languages. But crossword and word-search *content* is language-bound: Vita Crossword/Word Search are English products. Local-language crossword apps (Turkish "bulmaca", German "Kreuzworträtsel", Spanish "crucigrama", Portuguese "palavras cruzadas", Arabic "كلمات متقاطعة") are few, old, and none targets 50+ with big-print, no-timer, hint-friendly design. No "Vita Sudoku" exists either.

**Organic mechanism.** Evergreen local search terms + the "for seniors / büyük puntolu / große Buchstaben" long tail + family word-of-mouth (children install it for parents). Vita reached #1 Board in US, DE, FR, BR, SE on store charts, which compounds organically.

**Why us.** dcm-generator + the kaikki.org dictionary pipeline already produce crossword/word content per language; this is the one candidate where we have a content moat a reskin studio does not. Ads + optional subscription (Vita's model); word-game IAP is declining, so do not plan on IAP.

**Risks.** Vita could add languages to its word titles; seniors monetize low per install; needs 3–5 languages at launch to get volume.

### 2. Logic / number puzzles (sudoku family, nonogram, number match, kakuro, star-battle…) with a daily format

**Demand.** Logic puzzle = 596M downloads in 2025 (Gamigion), the **highest hit rate of any puzzle subgenre (9%)** vs 1.4% for puzzle launches overall. AppMagic's 2025 landscape names "Logic Puzzle" and "Sudoku" as casual revenue-growth leaders. "sudoku" is a top-20 generic App Store keyword in the UK (72). Demand is search-driven and evergreen, not creative-driven.

**Competition.** Easybrain (Sudoku.com 100M+, Nonogram.com 50M+) owns the head terms; the long tail of variants is thin and old. Small teams still break through: Logic Wiz (sudoku variants, founded 2020) passed 10M downloads; Clues by Sam (solo dev, launched May 2025) reached 50K DAU in under a year on a pure daily-puzzle loop. Easybrain's own "Logic Puzzles" (10M+) shows the variant space has room.

**Organic mechanism.** Search ("sudoku", "nonogram", "killer sudoku", "kakuro", local spellings), daily-puzzle habit/retention (Google Play now ranks by retention, not raw installs), and share-your-result virality from the Wordle/Connections era.

**Why us.** 100% procedural content → zero content cost; a generator + difficulty rater is exactly the backend/generator work we are good at. Localization is trivial (numbers). Can be shipped in Flutter.

**Risks.** Category downloads are -5% YoY; a plain sudoku clone will not rank. Must lead with variants nobody serves well (killer/kakuro/star-battle/hashi/"Queens"-style) plus a daily format, and ASO per language.

### 3. Offline mini-game hub ("no wifi games" collection)

**Demand.** "No wifi / offline games" is the #2 generic game search in the US and UK and top-20 in FR, DE, ES, IN (AppTweak). AppMagic's "Game Collection" genre is the smallest genre but the fastest-growing by revenue (+29.6% in 2025; +138% in H1 2025). Sensor Tower's May 2026 growth chart called out "demand for lightweight mini-game hubs" (Mini Challenges: Calm Games). That app launched Jan 2026 and is at 10M+ on Play by October (~1M installs/month per AppBrain). Mini Games: Calm & Relax (Unicorn Studio) sits at 100M+.

**Competition.** A handful of serious hubs; the rest of the "offline games" results are low-quality bundles with hundreds of installs. "Smallest genre" = fewest titles chasing a top-3 keyword.

**Organic mechanism.** Pure store search on a huge intent keyword, plus the fact that the app works with no network (travel, kids, low-data markets), which drives ratings and word of mouth. Retention is high because the hub always has "one more game".

**Why us.** We already have small games (Flash, Tapit, Racer) and a shared Flutter core; a hub is mostly packaging plus 10–20 polished minis (solitaire, sudoku, 2048, snake, minesweeper, word search, tic-tac-toe, dominoes, backgammon…). Ads-only monetization, so no economy design.

**Risks.** Each mini has to feel finished or ratings sink; ads-only ARPU; Google Play quality policies on "bundle" apps; needs a distinct name/brand to win the keyword long term.

## Considered and rejected

| Candidate | Why not |
|---|---|
| Block / Sort / Screw / Fill & Organize | Fastest-growing but 2,000+ block releases in H1 2026; hybrid-casual = paid UA business. Fill & Organize (+30%, 80M) is small and UA-driven. |
| Match-3, Merge | 1.4% success; Merge top-10 = 80% of revenue. |
| Generic word / trivia | Word IAP $270M and falling; English-dominated; Turkish word market owned by Kelimelik (10M+) / Kelime Gezmece (10M+). (Local-language *senior* word is candidate 1.) |
| Strategy / 4X | Only growing genre, but Eastern-publisher oligopoly and UA-heavy. |
| Daily Wordle-likes | Web-first, NYT-dominated; Termo-style local clones work but monetize poorly. Folded into candidate 2 as a format. |
| Regional card/board (Okey, Tavla, Batak, Baloot, Truco, Ludo) | Strong local demand but Zynga/local incumbents; could not verify 2025 volumes. Keep as minis inside candidate 3. |
| Kids games | Organic relies on Play "Similar Apps" placement (unreliable); policy overhead. |
| Idle, text/chat fiction | No reliable 2025 download data; small. |

## Recommended order

1. **Candidate 1** (our content moat, biggest proven 2025 demand signal). Start with Turkish + German + Spanish + Portuguese crossword/word search, big-print, no timer, offline.
2. **Candidate 2** as the second title or as modes inside 1 (same audience, same "brain game" positioning, zero content cost).
3. **Candidate 3** as the long-term portfolio wrapper that bundles 1, 2 and the existing minis under one "offline games" listing.

## Sources

- Sensor Tower State of Gaming 2026 (via GameDev Reports): https://gamedevreports.substack.com/p/sensor-tower-state-of-gaming-2026
- Sensor Tower H1 2026 (via GameDev Reports): https://gamedevreports.substack.com/p/sensor-tower-the-gaming-market-in
- Sensor Tower top 10, May 2026: https://sensortower.com/blog/top-10-worldwide-mobile-games-by-revenue-and-downloads-in-may-2026
- AppMagic Mobile Market Landscape 2026 (via GameDev Reports): https://gamedevreports.substack.com/p/appmagic-mobile-market-landscape
- AppMagic Casual Report H1 2026: https://appmagic.rocks/research/casual-report-H12026
- AppMagic New Puzzle Order: https://appmagic.rocks/blog/new-puzzle-order-sort-block-screw/?hl=en
- Gamigion, Performance of mobile puzzle genres in 2025: https://www.gamigion.com/performance-of-mobile-puzzle-genres-in-2025/
- Gamigion, genres with successful launches 2025: https://www.gamigion.com/what-mobile-game-genres-see-successful-launches-in-2025/
- PocketGamer.biz, most downloaded games of 2025 (mahjong +189%, tile match +28%): https://www.pocketgamer.biz/the-most-downloaded-mobile-games-of-2025/
- Business of Apps, most popular mobile games 2026: https://www.businessofapps.com/data/most-popular-mobile-games/
- AppTweak, most popular App Store keywords (H1 2024, updated Mar 2025): https://www.apptweak.com/en/aso-blog/the-most-popular-app-store-keywords
- AppsFlyer State of Gaming Marketing 2026 (via GameDev Reports): https://gamedevreports.substack.com/p/appsflyer-the-state-of-the-mobile
- Vita Studio site and Play developer page: https://www.vitastudio.ai/ , https://play.google.com/store/apps/dev?id=5970603563954352511
- Vita Mahjong country ranks: https://www.similarweb.com/app/google/com.vitastudio.mahjong/ , https://www.appbrain.com/app/vita-mahjong/com.vitastudio.mahjong
- AARP, why more older adults play games: https://www.aarp.org/personal-technology/why-more-older-adults-play-video-games/
- Mini Challenges: Calm Games (AppBrain): https://www.appbrain.com/app/mini-challenges-calm-games/com.u1.relax.minigame3
- Clues by Sam: https://en.wikipedia.org/wiki/Clues_By_Sam ; Logic Wiz: https://logic-wiz.com/
- Türkiye market 2025 (AppMagic/Gamigion via GameDev Reports): https://gamedevreports.substack.com/p/appmagic-and-gamigion-turkiyes-mobile

## Deep dives (2026-10-26)

- `big-print-classic-puzzles.md` — game × language matrix (crossword, word search, word connect, trivia per language; sudoku/solitaire/mahjong/jigsaw once), Vita baseline, ranked top-10 cells.
- `no-wifi-game-hubs.md` — 30 hub apps with live Play/App Store data, keyword top-5 per market, momentum ranking, gaps.
- `regional-card-board-games.md` — 59 regional card/board games scored (demand, openness, backend fit, organic keyword), Turkey view.
