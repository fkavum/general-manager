# Regional card & board games — organic-download opportunity scan

Date: 2026-10-26. Prepared for Dcx Studios (reuse of the Crossle .NET room/bot/leaderboard backend).
Method: Google Play listings fetched directly (download tier, rating, review count, last update, ads/IAP),
AppGoblin pages for total installs + last-4-week ("30d") installs (AppBrain blocked all fetches, see caveats),
plus web searches in local languages. Every number below comes from a fetched page or a search snippet; "n/a" = not found.

## 1. Summary table (sorted by potential score)

Score = 0.35·Demand + 0.25·Openness + 0.20·Fit + 0.20·Organic (each 0–10).
- Demand: sum of Play download tiers of the top apps, weighted by the leader's last-30-day installs (AppGoblin).
- Openness: inverse of incumbent strength (10 = no credible online leader / leader is dated; 1 = global giant with modern app).
- Fit: how well a Crossle-style turn-based room game with bots covers it (10 = 2–4 seat trick/rummy game).
- Organic: do people search the game's name in their language, and is that keyword uncrowded.

| # | Game | Region (rough pop.*) | Demand | Openness | Fit | Organic | Score | One-line verdict |
|---|------|----------------------|--------|----------|-----|---------|-------|------------------|
| 1 | Batak | Turkey (85M) | 6 | 8 | 10 | 9 | 7.9 | Leader is a one-man studio (Alper Games); online version 4.0★ with support/coin complaints; ZingPlay's entry is dead (433 installs/30d). |
| 2 | Truco | Brazil + Argentina (260M) | 8 | 5 | 10 | 8 | 7.65 | Huge and still growing (Blyts +275K/30d), but BR side is split among Spirejoy/MegaJogos/ZingPlay; "rigged algorithm" is the #1 complaint everywhere. |
| 3 | Durak | Russia/CIS (200M+) | 8 | 5 | 10 | 7 | 7.45 | 78M-install leader rated 2.2★ on Play (server/lag complaints); payments/distribution in RU are the risk. |
| 4 | Okey | Turkey + diaspora | 8 | 4 | 10 | 8 | 7.4 | Zynga + Ahoy + Yalla own it; only Yalla is trending (+216K/30d). Hard to win organically. |
| 5 | Tongits | Philippines (115M) | 8 | 4 | 10 | 8 | 7.4 | Playjoy's Tongits Go (44.8M) dominates with slots/colour-game bundling; "offline" apps still pull +178K/30d. |
| 6 | Briscola | Italy (60M) | 5 | 8 | 10 | 8 | 7.35 | WhatWapp leader last updated Oct 2025 and gets 1.5K installs/30d; field is open. |
| 7 | 101 Okey | Turkey | 9 | 2 | 10 | 8 | 7.25 | Zynga's 101 Okey Plus: 52.5M installs, +300K/30d. Do not attack head-on. |
| 8 | Pişti | Turkey | 4 | 9 | 10 | 8 | 7.25 | Best online app (Gamyun) has 692K installs; everything else is offline or stale. Cheap to own. |
| 9 | Scopa | Italy | 6 | 6 | 10 | 8 | 7.2 | WhatWapp 12.4M but "declining"; EpochalStorm equal on 30d installs (25K). |
| 10 | Tavla (Backgammon) | Turkey / global | 8 | 4 | 9 | 7 | 7.0 | Easybrain (global, +154K/30d) now leads; Zynga's new Backgammon Plus only 4.3M. "Dice are rigged" complaints universal. |
| 11 | Sueca / Bisca | Portugal + BR/Angola (50M PT-speakers outside BR) | 4 | 8 | 10 | 8 | 7.0 | MegaJogos 3.1M; the other 1M+ app has not been updated since Mar 2024. |
| 12 | 29 (Twenty-nine) | Bangladesh/India/Nepal | 6 | 6 | 10 | 7 | 7.0 | Z Level's Card Game 29: 27.6M, +280K/30d, 4.2★ with heavy ads complaints; Moonfrog's app is stale. |
| 13 | Pusoy (Pusoy Dos) | Philippines | 6 | 6 | 10 | 7 | 7.0 | Fragmented: Playjoy 3.8★, Red Koda +80K/30d, ZingPlay stale. |
| 14 | Tiến lên | Vietnam (100M) | 6 | 6 | 10 | 7 | 7.0 | Top Play apps are "offline" 3.7★ ad farms; VNG/ZingPlay owns the online side. Regulatory scrutiny on online card games. |
| 15 | Euchre | US Midwest/Canada | 4 | 8 | 10 | 8 | 7.0 | All three 1M+ apps are old (A-Star 2014, AI Factory 2014, Karman Jan-2026 update); clean keyword. |
| 16 | Belote / Coinche | France (9–10M players) | 6 | 5 | 10 | 8 | 6.95 | GameDuell (6.1M) + IsCool (3.7M) are mid-size; coin-economy and "biased deal" complaints. |
| 17 | Baloot | Saudi/Gulf (36M SA) | 6 | 5 | 10 | 8 | 6.95 | Kammelna (VC-funded, 1M MAU claim) + Jawaker; highest ARPU region; VIP Baloot declining. |
| 18 | Ronda | Morocco/Algeria (80M) | 3 | 10 | 9 | 8 | 6.95 | The 5M+ leader is an offline ad app at 3.6★ and declining; no quality online Ronda exists. |
| 19 | Chinchón | Spain/Argentina/Uruguay | 5 | 6 | 10 | 8 | 6.85 | Blyts 6.7M; Quarzo's ad-free app is the one trending (+85K/30d). |
| 20 | Dominoes | LatAm/MENA/Caribbean | 10 | 2 | 9 | 5 | 6.8 | Loop Games 144.6M (+255K/30d, est. $500K+/mo); Bluetile +393K/30d. Global giants. |
| 21 | Basra | Egypt (110M) | 3 | 10 | 9 | 7 | 6.75 | Only one 1M+ app (offline, ads, no timer/no 4-player); nothing online. |
| 22 | Cacheta / Pife | Brazil | 4 | 7 | 10 | 8 | 6.75 | MegaJogos 5.6M leads; ZingPlay 1M+, Pife apps barely move (2.3K/30d). |
| 23 | Callbreak | Nepal/India | 8 | 3 | 10 | 6 | 6.75 | Teslatech Callbreak.com 135.5M, +797K/30d, "pre-decided winners" complaints. |
| 24 | Skat | Germany (84M) | 4 | 7 | 10 | 8 | 6.75 | Isar Interactive 2M (+11K/30d) vs Skat Palast declining; GameDuell's Skat Treff 3.3★ ("opponents 100% bots"). |
| 25 | Spades | US | 8 | 3 | 10 | 6 | 6.75 | Zynga Spades Plus 16.7M but declining; MobilityWare +107K/30d. Crowded English keyword. |
| 26 | Indian Rummy | India | 7 | 5 | 9 | 6 | 6.7 | Real-money leaders (RummyCircle, A23) now 404 on Play after the 2025 Act; social rummy (Octro 19.6M) remains. |
| 27 | Tysiacha (1000) | RU/UA/PL | 3 | 9 | 10 | 7 | 6.7 | Leader 2.8M, ads-only with porn-ad complaints; LiveGames small but 4.4★ no-ads. |
| 28 | Pinochle | US | 3 | 9 | 9 | 8 | 6.7 | Karman 1.4M (3.9K/30d); NeuralPlay has no online play ("why isn't there an option to play with real people?"). |
| 29 | Buraco | Brazil | 5 | 6 | 9 | 8 | 6.65 | Jogatina 16.2M (+43K/30d) with ad-blocking complaints; Gazeus Royal Buraco dead since Jun 2024. |
| 30 | Tute | Spain | 2 | 10 | 10 | 7 | 6.6 | Biggest app 533K and offline; "the robot cheats". |
| 31 | Burraco | Italy | 4 | 7 | 9 | 8 | 6.55 | WhatWapp 2.6M (+18K/30d, ad-wall complaints); EpochalStorm 1M no-ads. |
| 32 | Rummy 500 | US | 4 | 7 | 10 | 7 | 6.55 | Fiogonia's 2025 app at +234K/30d shows the keyword is alive; the only "Live" online app has a dead lobby ("most players I've seen is 6"). |
| 33 | Scala 40 | Italy | 3 | 9 | 9 | 7 | 6.5 | MegaJogos 1M+; indie Scala 40 at 4.8★ (100K+). |
| 34 | Preferans | RU/UA/Balkans | 3 | 9 | 9 | 7 | 6.5 | Leader 1.5M, 4.7★, but porn-ad complaints; 3-player bidding game. |
| 35 | Tressette | Italy (south) | 3 | 8 | 10 | 7 | 6.45 | WhatWapp 1M+ last updated Oct 2025; Spaghetti 500K+ 4.0★. |
| 36 | Schnapsen / 66 | Austria/Hungary | 3 | 8 | 10 | 7 | 6.45 | Schnopsn 1.9M (+9.9K/30d), "rigged" complaints; 2-player. |
| 37 | Phỏm (Tá lả) | Vietnam | 3 | 8 | 10 | 7 | 6.45 | Senspark 1.7M stale (2.9K/30d); tiny 5.0★ offline apps. |
| 38 | Cribbage | US/Canada/UK | 3 | 8 | 9 | 8 | 6.45 | Two 1M+ apps, both with "cards aren't random" complaints; Classic last updated Mar 2026. |
| 39 | Thunee | South Africa (Durban Indian community) | 1 | 10 | 10 | 8 | 6.45 | 236K leader, 3.9★, last updated Nov 2025. Micro-market. |
| 40 | Belot / Bela | Bulgaria/Croatia/Armenia | 3 | 7 | 10 | 8 | 6.4 | Casualino Belot.BG 1.5M (+13K/30d), Middle Hut 2.5M; Croatian Bela apps are weak. |
| 41 | Doppelkopf | Germany (north) | 2 | 9 | 9 | 8 | 6.35 | Isar 631K, Palast 568K; both low velocity. |
| 42 | Schafkopf | Bavaria | 2 | 9 | 9 | 8 | 6.35 | Isar 344K, Palast 539K (867 installs/30d). |
| 43 | Jass | Switzerland (9M, high ARPU) | 2 | 9 | 9 | 8 | 6.35 | SwissJass+ 261K 4.2★ ("no sound", "slow"); JassPro 50K+. |
| 44 | Big Two | HK/TW/SG/MY/PH | 4 | 7 | 10 | 6 | 6.35 | Many names (大老二/鋤大D/Pusoy Dos/Capsa); Gamesofa 3.9★, Cubeage 4.7★ but no real opponents. |
| 45 | Canasta | US/Germany | 3 | 8 | 9 | 7 | 6.25 | Karman 2.7M; GameDuell no-ads version 100K+; rules disputes in reviews. |
| 46 | Carioca | Chile | 1 | 10 | 9 | 8 | 6.25 | No real app: Moonfrog's Cards CLUB 365K uses Mexican sombreros; rest are score keepers. |
| 47 | Cuarenta | Ecuador | 1 | 10 | 9 | 8 | 6.25 | One offline app (345K, last update Dec 2024); zero online. |
| 48 | King (Rıfkı) | Turkey | 2 | 10 | 9 | 6 | 6.2 | Gamyun King Online 397K is the only online option (4.7★); "king" keyword polluted by solitaire apps. |
| 49 | Mus | Spain (Basque/Navarre strongest) | 2 | 10 | 9 | 6 | 6.2 | Don Naipe 574K; Mus Maestro online 100K+ with "community ruins it" complaints; needs signal (señas) UX. |
| 50 | Brisca | Spain | 3 | 7 | 10 | 7 | 6.2 | Quarzo owns it (5.9M legacy + 1M+ new, 4.8★). |
| 51 | Tarneeb | Levant/Gulf | 5 | 4 | 10 | 7 | 6.15 | Jawaker (39.1M, +294K/30d) owns Tarneeb/Hand/Trix/Baloot in one app. |
| 52 | Hearts | US | 4 | 7 | 9 | 6 | 6.15 | MobilityWare 3.6M; AI Factory 3.9M but 312 installs/30d (dead). Keyword polluted. |
| 53 | Teen Patti | India | 9 | 2 | 8 | 4 | 6.05 | Moonfrog 143.7M, Octro 96.9M; regulated (2025 Act bans real money; social-chip games allowed). |
| 54 | Conquian | Mexico/US-Hispanic | 4 | 5 | 10 | 7 | 6.05 | ZingPlay 8.3M, 4.7★, 494K reviews, IAP-only. Strong incumbent. |
| 55 | Ludo | India/Pakistan/MENA | 10 | 1 | 8 | 3 | 5.95 | Ludo King 1.5B installs, +16.5M/30d; three more 100M+ apps. No. |
| 56 | Tarot (French) | France | 4 | 6 | 9 | 5 | 5.7 | GameDuell 1.5M (+45K/30d); keyword drowned by divination apps. |
| 57 | Hand / Trix | Egypt/Levant | 4 | 4 | 9 | 7 | 5.6 | Jawaker owns it; standalone apps (Maysalward, Diwaniya) at ~2K installs/30d. |
| 58 | Estimation | Jordan/Gulf | 3 | 6 | 10 | 5 | 5.55 | Pocket Estimation 1.3M (4.2K/30d); Jawaker bundles it; generic keyword. |
| 59 | Carrom | India | 10 | 1 | 3 | 3 | 4.95 | Miniclip 646M (+5.7M/30d). Physics game; wrong backend fit. |

\*Population column = country/language population from general knowledge, not from a fetched page; the only sourced
player counts are Belote (9–10M players, Tourmag / Fédération française de belote), Okey (10M regular online players, TBMM figure, 2013)
and Kammelna Baloot (1M MAU, PocketGamer).

## 2. Detail by region

Columns: Play tier / ★ (review count) / last update / AppGoblin total installs → last 4 weeks / monetization / online multiplayer (per listing) / complaints & incumbent flag.
"30d" = AppGoblin "Monthly" installs; "(T)" trending, "(D)" declining, "(S)" steady.

### Turkey

| Game | App (publisher, package) | Tier | ★ (reviews) | Updated | AppGoblin total → 30d | Monet. | Online | Complaints / flag |
|---|---|---|---|---|---|---|---|---|
| 101 Okey | 101 Okey Plus (Zynga, net.peakgames.Yuzbir) | 50M+ | 4.4 (2.65M) | 2026-10-09 | 52.5M → +300K (S) | ads+IAP | yes | "fixed hands", can't invite friends. **Zynga/Peak incumbent** |
| 101 Okey | 101 Okey Yalla – Live & Voice (Yalla Game) | 10M+ | 4.5 (84.1K) | 2026-09-29 | 11.4M → +216K (T) | ads+IAP | yes, voice rooms | fold-screen bugs; only EN-language 101 app |
| 101 Okey | Fun 101 Okey (Fast Game/Elex) | 10M+ | 4.2 (198K) | 2026-09-08 | 11.2M → +38K (S) | ads+IAP | yes | "money trap", freezes |
| 101 Okey | Soho 101 Okey – Eşli Batak (Ziipin HK) | 10M+ | 3.8 (47.4K) | 2026-10-22 | n/a | IAP, no ads | yes | too many ads (old), no language switch |
| Okey | Okey (Ahoy Games, com.ahoygames.okey) | 50M+ | 4.5 (572K) | 2026-08-31 | 58.3M → +117K (S) | ads+IAP | yes (cafes) | "fixed", wants ad-free tier |
| Okey | Okey Plus (Zynga) | 10M+ | 4.6 (1.23M) | 2026-09-30 | 30.2M → +47K (T) | ads+IAP | yes | friends/gift features broken; chip losses. **Zynga** |
| Okey | Çanak Okey Plus (Zynga) | 10M+ | 4.5 (646K) | 2026-10-08 | 20M → +37K (S) | ads+IAP | yes | wrongful cheat bans, no disconnect handling |
| Okey | OKEY – Offline (SNG Games) / OKEY Online (SNG) | 10M+ / 5M+ | 4.3 (74.4K) / 4.5 (124K) | 2026-10-01 / 09-25 | n/a | ads+IAP | no / yes | online: "scam, pushes gold coins", no support |
| Okey | Okey – İnternetsiz (Fuzzy Mobile Games) | 1M+ | 4.2 (34.5K) | 2026-06-03 | 4.9M → +24K (S) | ads+IAP | no | unclosable ads |
| Tavla | Backgammon – Board Game (Easybrain) | 10M+ | 4.6 (199K) | 2026-10-23 | 11M → +154K (S) | ads+IAP | yes | "fixed rolls", $14.99 ad-free. Global leader |
| Tavla | Backgammon Legends Online (Ahoy) | 5M+ | 4.1 (104K) | 2026-09-23 | 6.4M → +40K (S) | ads+IAP | yes | "dice not random" |
| Tavla | Backgammon Plus (Zynga, com.zynga.backgammonplus, rel. 2023) | 1M+ | 4.3 (67.7K) | 2026-10-02 | 4.3M → +28K (S) | ads+IAP | yes | ads/pop-ups, disconnects, no low-bet tables. **Zynga** (old Tavla Plus not in TR top results) |
| Tavla | Backgammon Stars (Dgton) / Backgammon Friends (Gameberry) / Backgammon Online (Gamyun) | 1M+ / 1M+ / 100K+ | 3.5 / 4.4 / 4.2 | 2026-08 / 10-22 / 10-19 | n/a | ads+IAP | yes | "cheats to sell coins" / "all opponents are bots" / "dice control" |
| Batak | Batak HD – İnternetsiz (Alper Games) | 10M+ | 4.1 (133K) | 2026-05-21 | 16.1M → +59K (T) | ads only | no | wants ad-free option; otherwise liked |
| Batak | Spades – Batak Online HD (Alper Games) | 1M+ | 4.0 (68.2K) | 2026-09-28 | 4M → +42K (T) | ads+IAP | yes | no support replies, "table is closed" with friends, coins run out after 3 games |
| Batak | Batak Online (Big Head Games) | 1M+ | 3.9 (21K) | 2026-09-12 | 2.3M → +25K (S) | ads+IAP | yes | guests can't chat |
| Batak | Batak Online: Auction & Spades (CMS Gaming / Fuzzy) | 500K+ | 3.9 (17K) | 2026-05-20 | 792K → +4K (T) | ads+IAP | yes | unskippable ads |
| Batak | Batak ZingPlay (VNG) | 500K+ | 4.2 (2.18K) | 2026-08-25 | 704K → +433 | IAP, no ads | yes | "lost all my coins". Effectively dead |
| Pişti | Pisti Online (Gamyun) | 500K+ | 4.9 (33.8K) | 2026-10-19 | 692K → +5.6K (T) | ads+IAP | yes | none notable; tiny but best-rated |
| Pişti | Pişti Online HD (Alper) / Pişti Tekli-Eşli (Fuzzy) / Pisti (GamerHook) | 1M+ each | 3.5 / 4.6 / 4.8 | 2026-02 / 06 / 2025-10 | 2.3M → +13K / 2.3M → +7.1K / 2.2M → +3.3K | ads+IAP | mostly offline | no English; scoring bug (GamerHook); won't load |
| King | King Online (Gamyun) | 100K+ | 4.7 (38.8K) | 2026-10-19 | 397K → +3.4K (T) | ads+IAP | yes, bots replace leavers | unfair dealing, suits hard to tell apart |
| King | King HD – Rıfkı (Alper) / King Online (Teknopars) | 100K+ / 100K+ | 4.4 / 3.4 | 2026-02 / 08 | 448K → +1.7K / n/a | ads | no / yes | "only if it was multiplayer" |

### France

| Game | App (publisher) | Tier | ★ (reviews) | Updated | AppGoblin total → 30d | Monet. | Online | Complaints / flag |
|---|---|---|---|---|---|---|---|---|
| Belote/Coinche | Belote.com – Belote & Coinche (GameDuell) | 5M+ | 4.5 (452K) | 2026-10-02 | 6.1M → +32K (S), ~53K MAU est. | ads+IAP | yes | slot-machine coin model, coin starvation |
| Belote/Coinche | Belote & Coinche Multijoueur (IsCool Entertainment) | 1M+ | 4.3 (173K) | 2026-09-30 | 3.7M → +15K (S) | ads+IAP | yes | "cheated cards", forced ads, bot accounts |
| Belote/Coinche | French Belote / French Coinche (Eryod Soft) | 1M+ / 500K+ | 4.4 / 4.6 | 2026-09 | 3.2M → +7K | ads | no (offline, strong options) | AI cuts with highest trump |
| Belote/Coinche | VIP Belote (Casualino) / Belote le Défi (WhatWapp) / Belote Classique (IsCool) | 1M+ / 1M+ / 500K+ | 4.5 / 3.8 / 4.9 | 2026-10 | 1.3M → +11K / n/a / n/a | ads+IAP | yes | ads everywhere / pay to play, bugs / ad traps |
| Tarot | Tarot – Fun & Friends (GameDuell) / Exoty Tarot / Super Tarot (WCGF) | 1M+ / 1M+ / 100K+ | 4.2 / 4.3 / 3.6 | 2026-10 | 1.5M → +45K / 1.6M → +6.7K / n/a | IAP / ads+IAP | yes | coin gating / "escroquerie", forced ads / bugs |

### Italy

| Game | App (publisher) | Tier | ★ (reviews) | Updated | AppGoblin total → 30d | Monet. | Online | Complaints / flag |
|---|---|---|---|---|---|---|---|---|
| Briscola | Briscola (WhatWapp) | 5M+ | 4.4 (84K) | **2025-10-16** | 5.2M → +1.5K (S) | ads | yes | no tournaments, long delays, quitters not replaced by AI. Stale leader |
| Briscola | Briscola Dal Negro (Digitalmoka) | 1M+ | 4.5 (14.7K) | 2026-10-20 | 1.6M → +13K (S) | ads+IAP | yes | no PvP timer, can't play offline, ad-removal incomplete |
| Briscola | Briscola Tradizionale (Esogames) / Briscola (OutOfTheBit) / Briscola Più (Spaghetti) | 500K+ / 500K+ / 100K+ | 4.4 / 4.7 / 4.3 | 2026-08 / 07 / 10 | n/a | ads+IAP | partial | minute-long ads / anonymous online, only 2P / tiny cards |
| Scopa | Scopa: la Sfida (WhatWapp) | 10M+ | 4.4 (230K) | 2026-10-22 | 12.4M → +25K (D weekly) | ads+IAP | yes | gimmicks/mini-games, battery drain, win-rate drops |
| Scopa | Scopa Online (EpochalStorm) / Traditional Scopa (Digitalmoka) / Scopa Tradizionale (Esogames) | 1M+ each | 4.3 / 4.3 / 4.5 | 2026-06 / 10 / 08 | 2.1M → +25K / n/a / n/a | ads+IAP | yes | coin starvation + long ads / AI awards itself scopas / "how many are bots?" |
| Burraco | Burraco la sfida (WhatWapp) | 1M+ | 4.2 (90K) | 2026-10-23 | 2.6M → +18K (S) | ads+IAP | yes | "3739 ads in 10 minutes", lost coins on disconnect |
| Burraco | Burraco e Pinelle Online (EpochalStorm) / Burraco Friends (EpochalStorm) / Burraco classico (Ace of Clubs) | 1M+ / 100K+ / 100K+ | 4.2 / 3.7 / 3.4 | 2026-10 | 1M → +12K | IAP no-ads / ads+IAP | yes | password reset issues / gem starvation, slow tables |
| Scala 40 | Scala 40 Online (MegaJogos) / Scala 40 (D. Terella) / Scala 40 (Onmadesoft) | 1M+ / 100K+ / 50K+ | 4.5 / 4.8 / 4.5 | 2026-10 / 09 / 10 | n/a | ads+IAP / ads | yes | tournament kicks after one loss / random disconnects → bots |
| Tressette | Tressette (WhatWapp) / Tressette Più (Spaghetti) | 1M+ / 500K+ | 4.3 / 4.0 | **2025-10-24** / 2026-10-21 | n/a | ads / ads+IAP | yes | weird matchmaking after update / leavers unpunished |

### Gulf, Levant, North Africa

| Game | App (publisher) | Tier | ★ (reviews) | Updated | AppGoblin total → 30d | Monet. | Online | Complaints / flag |
|---|---|---|---|---|---|---|---|---|
| Baloot | كملنا Kammelna (Remal IT, Saudi) | 1M+ | 4.0 (104K) | 2026-10-01 | 2.3M → +14K (S); PocketGamer: 6M downloads, 1M MAU, $53M Impact46 investment | ads+IAP | yes | long ads, no support, inactivity kicks. **Local funded incumbent** |
| Baloot | بلوت VIP (Tamatem, Jordan) | 1M+ | 3.8 (96.1K) | 2026-10-14 | 3.1M → +7.5K (D) | ads+IAP | yes | cheating unaddressed, slow, "update makes you lose to buy" |
| Baloot | Tarbi3ah Baloot (sawa games) / Yalla Baloot & Hand (Yalla) / Baloot Pro (Bondonra) / Baloot (Maysalward) | 1M+ / 1M+ / 100K+ / 10K+ | 3.3 / 4.7 / 4.1 / n/a | 2026-10 / 09 / 09 / 06 | 3.7M → +13K / 1.9M → +23K (T) / n/a | IAP | yes | "programmed to lose" / no English / "VIP gets good cards". **Maysalward** present but tiny |
| Tarneeb/Hand/Trix | Jawaker Hand, Tarneeb & Trix (Jawaker) | 10M+ | 4.7 (887K) | 2026-10-26 | 39.1M → +294K (S), est. $50K+/mo | ads+IAP | yes | non-random shuffles, mid-game leavers. **Dominant MENA incumbent** |
| Tarneeb | Tarneeb & Syrian 41 (Jawaker) / Tarneeb Masters (YallaPlay) / VIP Jalsat (Tamatem) / Tarneeb Online (Maysalward) | 1M+ / 1M+ / 1M+ / 500K+ | 4.7 / 4.6 / 3.9 / 3.8 | 2026-10 / 02 / 10 / 03 | 1.6M → +7.9K / 1M → +2.8K / 1.2M → +8.1K / n/a | ads+IAP | yes | bot partner breaks suits / leavers, glitches / ad minefield / "opponents know each other's cards" |
| Trix | Trix (Maysalward) / iTrix (Diwaniya Labs) / Trix ZingPlay | 500K+ / 500K+ / 10K+ | 4.0 / 4.2 / n/a | 2026-02 / 03 / **2022-08** | 975K → +2K / 568K → +1.6K / n/a | ads+IAP | yes | jams, slow / deterministic shuffle, impossible at high level / dead |
| Estimation | Pocket Estimation (Blyxon/Fanella) | 1M+ | 4.4 (47.4K) | 2026-08-05 | 1.3M → +4.2K (S) | ads+IAP | yes | server kicks, foul language, no support |
| Basra | Egyptian Basra (TheDarkSeraph) | 1M+ | 4.1 (8.96K) | 2026-10-22 | 5M → +19K (D) | ads | no | no sound, no timer, no 4-player, too fast. Others ≤1K installs |
| Ronda | Ronda (Saif Lab) | 5M+ | 3.6 (18.9K) | 2026-10-22 | 5.9M → +9.7K (D) | ads | no (2P) | ads before any game, wants 4-player mode, scoring bug |
| Ronda | Ronda: Online Card Game (Birmila) / Ronda (TacSou) | 100K+ / 100K+ | 2.7 / 4.1 | 2026-09 / 07 | n/a | ads | yes | can't get free coins, "am I playing robots?" / VS-CPU broken |

### Brazil, Portugal, Spain, Latin America

| Game | App (publisher) | Tier | ★ (reviews) | Updated | AppGoblin total → 30d | Monet. | Online | Complaints / flag |
|---|---|---|---|---|---|---|---|---|
| Truco (AR) | Truco Blyts (Blyts) | 10M+ | 4.3 (624K) | 2026-10-08 | 26.8M → +275K (T), est. $50K+/mo | ads+IAP | yes (2v2, 3v3) | ads after each game, ranking unreachable |
| Truco (BR) | Truco Vamos (Spirejoy, HK) | 10M+ | 4.3 (108K) | 2026-10-15 | 13.5M → +74K (T) | ads+IAP | yes | lag, "steals tokens when you have many" |
| Truco (BR) | Truco MegaJogos (MegaJogos) / Truco ZingPlay (VNG) / Truco Brasil (Brasmobi) | 5M+ / 5M+ / 1M+ | 4.6 / 4.3 / 4.4 | 2026-10 / 03 / 08 | 7.6M → +49K / 7.4M → +43K / n/a | ads+IAP / IAP | yes | coins needed even for casual / "predictable, not random" / disconnects. **MegaJogos** |
| Buraco | Buraco Jogatina (Jogatina.com) | 10M+ | 4.2 (308K) | 2026-09-24 | 16.2M → +43K (S) | ads+IAP | yes | ads block the game, worse than the 2015 version |
| Buraco | Buraco Canasta GameVelvet (MegaJogos) / Canasta Online (MegaJogos) / Buraco ZingPlay / Royal Buraco (Gazeus) / Buraco Loco (Playspace) | 1M+ / 1M+ / 1M+ / 500K+ / 100K+ | 4.6 / 4.1 / 3.9 / 3.8 / 3.9 | 2026-10 / 10 / 2025-11 / **2024-06** / 2026-05 | n/a | ads+IAP | yes | freezes, unclosable ads / wins 1 in 10 / forced FB login / coins vanish / leavers. **Playspace (Space Go)** weak here |
| Cacheta/Pife | Cacheta Gin Rummy Online (MegaJogos) / Cacheta ZingPlay / Cacheta League (Ironforge) / Pife (Bodega) / Pif Paf (MegaJogos) | 5M+ / 1M+ / 500K+ / 1M+ / 1M+ | 4.3 / n/a / 4.5 / 4.3 / 4.1 | 2026-10 / 07 / 08 / 08 / 10 | 5.6M → +21K / n/a / n/a / 3.2M → +2.3K / n/a | ads+IAP / IAP | yes | hidden ad pop-ups / phone-number login / crashes / ads, forced level pick |
| Sueca | Sueca Online GameVelvet (MegaJogos) | 1M+ | 4.3 (43.3K) | 2026-10-25 | 3.1M → +18K (S) | ads+IAP | yes | ad every hand, "fixed", slow server |
| Sueca | Sueca (Hugo Rosário) / Sueca Portuguesa (Tiago Interactive) / Sueca (ConectaGames) | 1M+ / 100K+ / 100K+ | 3.9 / 4.3 / n/a | **2024-03** / 2026-10 / 2026-10 | 2.1M → +3.5K / n/a | ads / ads+IAP | yes | leavers keep points, flawed AI / bot partner plays badly |
| Bisca | served by Quarzo "Briscola – La Brisca" (5M+, 4.5, 5.9M → +3.4K) and new "La Brisca" (1M+, 4.8); Bisca 61 (10K+) | — | — | 2026-10 | — | ads+IAP | yes | legacy UI "impossible" |
| Mus | El Mus (Don Naipe) / Mus Online Maestro (Kangaroo) / Mus (Las40) / Mus Online (Puzztime) | 500K+ / 100K+ / 50K+ / 10K+ | 4.6 / 4.5 / n/a / n/a | 2026-08 / 08 / 10 / 10 | 574K → +2K (S) | ads+IAP | no / yes / yes | gets stuck, ads / "no bots?", rude community |
| Tute | Tute a Cuatro (Don Naipe) / Tute Online Casual Arena / Tute (Melele) / Tute Offline (Zariba) | 500K+ / 50K+ / 50K+ / 10K+ | 4.7 / n/a / 4.2 / 4.8 | 2026-08 / 10 / 06 / 10 | 533K → +1.5K | ads | no / yes / no | "robot cheats" / CPU breaks rules |
| Chinchón | Chinchón Blyts / Chinchón ZingPlay / Chinchon (Quarzo) / Chinchon Loco (Playspace) | 5M+ / 1M+ / 1M+ / 100K+ | 4.4 / 4.7 (272K) / 4.2 / 3.9 | 2026-10 / 2025-11 / 2026-10 / 2025-12 | 6.7M → +15K / n/a / 3.2M → +85K (T) / n/a | ads+IAP / IAP / none / ads+IAP | yes | 30s ads mid-match, Bluetooth removed / coins lost fast / praised: no ads, fair bots / coin waits |
| Dominoes | Dominoes: Classic (Loop Games) / Domino Legends (Bluetile) / Dominoes Online (MegaJogos) / Dominos Jogatina / Domino (ZiMAD) / Domino! (Flyclops) / Classic Dominoes (Big Cake) | 100M+ / 10M+ / 10M+ / 10M+ / 10M+ / 5M+ / 5M+ | 4.7 / 4.7 / 4.6 / 4.3 / 4.5 / 4.7 / 4.9 | 2026-10 / 10 / 10 / 08 / 10 / 10 / 09 | 144.6M → +255K / 25.8M → +393K (T) / 18.3M → +107K / 45.4M → +26K / n/a / n/a / n/a | ads+IAP | mixed | minute-long ads every round (all); explicit ads (MegaJogos); algorithm change (Jogatina) |
| Conquian | Conquian ZingPlay / Conquian (MegaJogos) / Conquian 333 (alexga) / Conquian La Viuda (CosyTime) | 5M+ / 1M+ / 500K+ / 100K+ | 4.7 (494K) / 4.5 / 3.8 / 4.8 | 2026-06 / 10 / 03 / 06 | 8.3M → +38K (S) | IAP / ads+IAP / ads | yes / yes / no / yes | "my card is always last" / white-screen scam reports / "steals winnings" |
| Carioca | Cards CLUB with Carioca (Moonfrog) + score-keeper apps (<1K) | 100K+ | 4.4 (6K) | 2026-10-23 | 365K → +2.8K (S) | ads+IAP | yes | Mexican sombreros for a Chilean game; can't see game cost |
| Cuarenta | 40 Caída y Limpia (J. A. Arias) + three apps ≤1K | 100K+ | 3.9 (3.73K) | **2024-12-17** | 345K → +481 | none | no | glitches, invalid-combination bug |

### India, Nepal, Bangladesh

| Game | App (publisher) | Tier | ★ (reviews) | Updated | AppGoblin total → 30d | Monet. | Online | Complaints / flag |
|---|---|---|---|---|---|---|---|---|
| Ludo | Ludo King (Gametion) | 1B+ | 4.1 (10.3M) | 2026-09-28 | 1.5B → +16.5M | ads+IAP | yes | crashes, wrong player count. **Gametion** |
| Ludo | Ludo Club (Moonfrog) / Ludo (Yarsa) / Ludo STAR (Gameberry) / Ludo Offline (AlignIt) | 100M+ ×3 / 10M+ | 4.3 / 4.6 / 4.6 / 4.4 | 2026-10 | 238.5M → +1.2M / 200.3M → +1.5M / 104.8M → +1.4M / n/a | IAP / ads+IAP | yes | whales rig dice / rage-bait RNG / "programmed to lose after wins" |
| Teen Patti | Teen Patti Gold (Moonfrog) / Teen Patti Octro / Teen Patti King (Gametion) | 100M+ / 50M+ / 1M+ | 4.5 / 4.4 / n/a | 2026-10 | 143.7M → +648K / 96.9M → +161K / n/a | ads+IAP | yes | win-then-lose chip pushing, collusion at tables. Regulation: Promotion and Regulation of Online Gaming Act 2025 bans real-money games incl. rummy/card games; social chip games stay legal |
| Indian Rummy | RummyCircle (Games24x7) / A23 — Play listing returns "not found" (real-money, post-Act); Indian Rummy (Octro) / Indian Rummy Offline (Mobilix) | 404 / 404 / 10M+ / 1M+ | — / — / 4.2 / 4.3 | — / — / 2026-10 / 06 | 19.6M → +48K (T) | ads+IAP | yes | 2–3 ads at once, chip-purchase pressure |
| Carrom | Carrom Pool (Miniclip) / Carrom King (Gametion) / World of Carrom (AppOn) | 500M+ / 50M+ / 50M+ | 4.4 / 4.0 / 4.4 | 2026-10 | 646.2M → +5.7M | ads+IAP | yes (real-time physics) | level mismatch, ads. Not a turn-based fit |
| Callbreak | Callbreak.com (Teslatech) / Callbreak, Ludo & 29 (Yarsa) / Call break (Yarsa) | 100M+ / 10M+ / 1M+ | 4.3 / 4.1 / 4.0 | 2026-10 / 10 / 09 | 135.5M → +797K (T) / 15.1M → +80K / n/a | ads+IAP | yes | "pre-decided who wins", slow co-players / rule variants wrong |
| 29 | Card Game 29 (Z Level Labs) / Play 29 Gold (Moonfrog) / 29 King (Evonix) | 10M+ / 5M+ / 1M+ | 4.2 / 4.0 / 4.5 | 2026-10 / 03 / 10 | 27.6M → +280K (T) / n/a / n/a | ads+IAP / ads | yes / no / no | bot gets stronger cards, slow timer, long ads / same cards repeatedly |

### Russia / CIS / Central Europe

| Game | App (publisher) | Tier | ★ (reviews) | Updated | AppGoblin total → 30d | Monet. | Online | Complaints / flag |
|---|---|---|---|---|---|---|---|---|
| Durak | Durak Online (Magic Board / RST Games) | 50M+ | **2.2** (689K) | 2026-10-15 | 78.3M → +437K (T), est. $200K+/mo | ads+IAP | yes | servers "absolutely awful", lag, lost coins. Big but hated |
| Durak | Durak Online 3D (Playvision) / Durak (Frigate Studios) / Durak Online by Pokerist (KamaGames) / Durak (Vesna) | 10M+ / 10M+ / 5M+ / 500K+ | 4.0 / 4.0 / 4.0 / 3.6 | 2026-10 / 08 / 09 / 10 | 10M → +197K (T) / 31.2M → +240K / 7M → +18K / n/a | ads+IAP / ads / ads+IAP / none | yes / no / yes / no | "rigged after free chips" / praised offline AI, wants team mode / pay-to-win, no private tables / ads mid-game |
| Tysiacha | Thousand (1000) (Thousand Card Game) / Thousand LiveGames (NanoFlash) / Thousand (E. Fragner) | 1M+ / 100K+ / 1K+ | 4.1 / 4.4 / n/a | 2026-09 / 06 / 10 | 2.8M → +19K (S) / n/a | ads / IAP no-ads | Bluetooth / yes | not random at high levels, inappropriate ads / praised |
| Preferans | Preferans (Play-On-Smart, ferp.android) / Preferans (Azur) / Preference LiveGames | 1M+ / 100K+ / 50K+ | 4.7 (82.9K) / 3.8 / 4.6 | 2026-10 / 07 / 09 | 1.5M → +3.6K (S) / n/a | ads+IAP / IAP | yes | pornographic ads, no premium / leavers, "worst algorithm" |
| Skat | Skat (Isar Interactive) / Skat Palace (Spiele-Palast) / Skat Treff (GameDuell, DSKV partner) / Skat HD (Isar, paid) | 1M+ / 1M+ / 500K+ / 50K+ | 4.6 / 4.2 / **3.3** / 4.8 | 2026-10 / 09 / 10 / 10 | 2M → +11K (T) / 2M → +3.4K (D) / n/a / n/a | ads+IAP / ads+IAP / IAP / IAP | yes | German-only UI parts / intrusive ads during your turn / "opponents 100% bots, 25% rake" / license checks |
| Doppelkopf | Doppelkopf (Isar) / Doppelkopf Palast (Spiele-Palast) / Doppelkopf HD (Isar, paid) | 500K+ / 500K+ / 10K+ | 4.6 / 4.1 / 4.9 | 2026-09 / 09 / 09 | 631K → +2.8K / 568K → +1.1K / n/a | ads+IAP / ads+IAP / IAP | yes | ad banner covers hand / missing rule options, "a year of bad cards" / praised |
| Schafkopf | Schafkopf (Isar) / Schafkopf Palast (Spiele-Palast) / Schafkopf HD (Isar) | 100K+ / 500K+ / 5K+ | 4.7 / 3.8 / n/a | 2026-10 / 09 / 10 | 344K → +2.2K / 539K → +867 / n/a | ads+IAP / ads+IAP / IAP | yes | bots break rules, dev silent / pay for basic options, 4× bet penalty on disconnect |
| Jass | SwissJass+ (Sweetware) / JassPro (Cartel) / Jassen Online (DonkeyCat) | 100K+ / 50K+ / 10K+ | 4.2 / 4.2 / n/a | 2026-10 | 261K → +3.6K (S) / n/a | ads+IAP | yes | no sound, slow card movement, camera notch / small play area, slow animations |
| Schnapsen | Schnopsn Online (DonkeyCat) / Schnapsen Offline (Zariba) | 1M+ / 10K+ | 4.3 / n/a | 2026-10 | 1.9M → +9.9K (T) | ads+IAP / ads | yes / no | "ad collection app", "rigged" |
| Belot/Bela | Belot.BG (Casualino) / Belot (Middle Hut) / Bela (gameon) / Bela Online (Sombrerito) / Belot (Fortegames) | 1M+ / 1M+ / 500K+ / 50K+ / 100K+ | 4.2 / 4.3 / 3.9 / 3.6 / 3.3 | 2026-10 / 10 / 08 / 10 / 08 | 1.5M → +13K (T) / 2.5M → +13K / 623K → +1.5K / n/a / n/a | ads+IAP / ads+IAP / none / none / IAP | yes / mixed / no / yes / yes | excessive ads, "1000 € for chips", cheating unmoderated / no landscape / bad algorithm / room bugs / price ×10 |

### Southeast / East Asia

| Game | App (publisher) | Tier | ★ (reviews) | Updated | AppGoblin total → 30d | Monet. | Online | Complaints / flag |
|---|---|---|---|---|---|---|---|---|
| Tongits | Tongits Go – Pusoy, Super Ace (Playjoy) | 10M+ | 4.5 (591K) | 2026-09-24 | 44.8M → +116K (S) | ads+IAP | yes (bundles slots, Color Game, Mines) | app won't open, free-coin bonus shrinking, balance wiped. Gambling-adjacent bundle |
| Tongits | Tongits Offline (Greenleaf) / Tongits ZingPlay (VNG) / Tongits Star (Higgs) / Tongits (Classic Card Games Global) | 10M+ / 10M+ / 5M+ / 1M+ | 4.6 / 3.9 / 4.6 / 4.5 | 2026-09 / 06 / 2025-10 / 2026-07 | 15.1M → +178K (S) / 16.5M → +23K / 9.4M → +24K / n/a | ads / IAP / ads+IAP / ads | no / yes / yes / no | "100% rigged" / can't sustain gold / disconnects, IAP not credited / "lose 99%" |
| Pusoy | Pusoy Go (Playjoy PH) / Chinese Poker KK Pusoy (Red Koda) / Pusoy ZingPlay / Pusoy King Offline (Play Boom) | 5M+ / 5M+ / 5M+ / 500K+ | 3.8 / 4.5 / 4.1 / 3.9 | 2026-09 / 08 / 05 / 10 | 8.3M → +16K / 6.8M → +80K / n/a / n/a | ads+IAP / ads+IAP / IAP / ads+IAP | yes / yes / yes / no | "scam, losing hands to sell coins", high commission / wrong suit ranking / no support after failed IAP |
| Tiến lên | Tien Len Mien Nam (Son Dev) / Tien Len Mien Nam (Senspark) / TLMN: Phỏm, Tá Lả (Sảnh Offline) / Tiến Lên (52PLAY) | 5M+ / 5M+ / 500K+ / 1M+ | 3.7 / 4.2 / 4.7 / n/a | 2026-08 / 06 / 07 / 2025-10 | 6.2M → +64K / 7.7M → +5.9K (D) / 939K → +37K / n/a | ads+IAP / ads+IAP / ads+IAP / ads | no (offline apps dominate Play search) | "ads every 2 games", "AI never loses points", prompts to watch video on every action. Online side = VNG ZingPlay portal (not fetched) |
| Phỏm | Phom, Ta la (Senspark) / Phỏm – Tá Lả (Sảnh Offline) / Phỏm (52PLAY) + 10K+ apps | 1M+ / 100K+ / 100K+ | 4.3 / 5.0 / n/a | 2026-06 / 05 / 2025-10 | 1.7M → +2.9K / n/a | ads+IAP | no | too many ads |
| Big Two | Big 2 Offline – Pusoy Dos (Greenleaf) / 神來也撲克 (Gamesofa) / Fun Big 2 Taiwan (Cubeage) / Big 2 (JJPlay) | 1M+ ×4 | 4.3 / 3.9 (79.6K) / 4.7 (87.1K) / 4.2 | 2026-09 / 09 / 10 / 09 | 2.1M → +46K / 2.9M → +1.5K / 1.1M → +60 / n/a | ads / ads+IAP / ads+IAP / ads | no / yes / no / no | AI wins 3 of 4 / "complete fraud", bugs / wants real opponents / praised minimal UI |

### United States / English-speaking

| Game | App (publisher) | Tier | ★ (reviews) | Updated | AppGoblin total → 30d | Monet. | Online | Complaints / flag |
|---|---|---|---|---|---|---|---|---|
| Spades | Spades Plus (Zynga) / Spades (MobilityWare) / Spades (Blackout Lab) / Spades Royale (Beach Bum) / Spades Masters (YallaPlay) | 10M+ / 10M+ / 10M+ / 5M+ / 1M+ | 4.8 / 4.7 / 4.8 / 4.7 / 4.6 | 2026-10 | 16.7M → +37K (D) / 14.8M → +107K / 11.1M → +63K (D) / n/a / n/a | ads+IAP | yes / mixed / no / yes / yes | "too many nil hands, not random", pay-to-play / ads / ads every round / Appcharge payments / rigged matchmaking. **Zynga** |
| Euchre | Euchre 3D (A-Star) / Euchre (Karman) / Euchre (AI Factory) / Euchre (Jeffreys) / Euchre (WhatWapp) | 1M+ / 1M+ / 1M+ / 10K+ / 50K+ | 4.6 / 4.4 / 4.4 / 4.0 / 4.5 | 2026-10 / **01** / 08 / 10 / 09 | 2.1M → +3.9K / n/a / 1.3M → +2.4K / n/a / n/a | ads+IAP / ads+IAP / ads / paid / ads+IAP | yes / yes / no / no / yes | glitchy ads, brutal AI / non-random deals, 10-min matchmaking / greyed-out legal cards / "money grab" |
| Hearts | Hearts (MobilityWare) / Hearts (Karman) / Hearts (AI Factory) / Hearts (SNG) | 1M+ ×3 / 500K+ | 4.6 / 4.4 / 4.5 / 4.2 | 2026-09 / 07 / 08 / 09 | 3.6M → +18K / n/a / 3.9M → +312 / n/a | ads+IAP / ads+IAP / ads / ads | no / yes / no / no | same ad every time / 10-sec timer wanted, weak players / portrait only |
| Pinochle | Pinochle (Karman) / Pinochle Expert AI (NeuralPlay) / Pinochle Palace (Spiele-Palast) / Pinochle Circle (Eadrom, new) | 1M+ / 100K+ / 100K+ / 0+ | 4.6 / 4.4 / 4.4 / n/a | 2026-02 / 09 / 09 / 10 | 1.4M → +3.9K / n/a | ads+IAP | yes / no / yes / yes | week-long bans, dealer "controls the game" / no real people / ads jump from none to overwhelming |
| Canasta | Canasta (Karman) / Canasta (North Sky) / Canasta Online (Spiele-Palast) / Canasta Treff (GameDuell) / Canasta (Fiogonia) | 1M+ / 500K+ / 500K+ / 100K+ / 100K+ | 4.3 / 4.5 / 4.3 / 4.4 / 4.5 | 2026-10 / 09 / 09 / 10 / 07 | 2.7M → +5.2K / 635K → +1.7K / n/a | ads+IAP / ads+IAP / ads+IAP / IAP / ads+IAP | yes / no / yes / yes / no | offline freezes / rigged above easy / ads with sound / wild-card streaks / rules wrong |
| Rummy 500 | Rummy 500 (Fiogonia, rel. May 2025) / Rummy (MobilityWare) / Rummy 500 Live (Supergrade) / Rummy 500 (SNG) | 1M+ / 1M+ / 10K+ / 50K+ | 4.6 / 4.7 / 3.9 / 4.5 | 2026-10 / 08 / 2025-10 / 2026-08 | 1.5M → +234K (S) / n/a | ads+IAP / ads+IAP / IAP / ads | no / no / yes / no | too easy / 30-second hands to serve ads / "most players I've seen online is 6", crashes 50% |
| Cribbage | Cribbage Classic (Games By Post) / Cribbage Pro (Fuller Systems) | 1M+ / 1M+ | 4.6 / 4.5 | 2026-03 / 09 | 2.3M → +6.8K / n/a | ads / ads+IAP | yes / yes | "anything but random", pro mode evens scores / ad traps, AI always pegs |
| Thunee (ZA) | Thunee (Ugen Govender) / Durban League (Durban Classic Games) | 100K+ / 100K+ | 3.9 / n/a | 2025-11 / 2026-09 | 236K → +1.2K / n/a | ads+IAP / IAP | yes | login loops, hostile support reply, ads |

## 3. Turkey-specific view

Who owns the top spots today (Play tier; AppGoblin last-4-week installs):
- Okey / 101 Okey: Zynga/Peak holds three 10M+–50M+ apps (101 Okey Plus +300K, Okey Plus +47K, Çanak Okey Plus +37K). Ahoy Games' Okey is the same size (58.3M, +117K). The only app with real momentum is Yalla's 101 Okey (voice rooms, +216K, "trending"). Fast Game's Fun 101 Okey (+38K) and Ziipin's Soho 101 Okey (10M+, updated 2026-10-22, no ads) are the Chinese entrants. SNG Games holds the offline slot (10M+). Fuzzy Mobile Games' Okey İnternetsiz: 1M+, +24K.
- Tavla: Zynga no longer leads. Its 2023 "Backgammon Plus" has 4.3M installs (+28K) vs Easybrain's global Backgammon at 11M (+154K) and Ahoy at 6.4M (+40K). Gamyun's Turkish-first Backgammon Online is only 100K+.
- Batak: Alper Games (one developer: Batak HD offline 16.1M +59K, Batak Online HD 4M +42K, both "trending"), Big Head Games (2.3M, +25K), Fuzzy/CMS (792K, +4K), ZingPlay (704K, +433 — abandoned). No Zynga, no Yalla, no quality-studio entry.
- Pişti: nobody above 2.3M installs; the best online product (Gamyun, 4.9★) is at 692K (+5.6K). Alper (+13K) and Fuzzy (+7.1K) are offline apps.
- King: Gamyun King Online 397K (+3.4K) is effectively the only online King; Alper's 448K app is offline.
- "Tiramisu": no publisher of that name was found on Google Play or in search for okey/batak/tavla. "Alictus" is a hyper-casual studio (SciPlay bought a majority stake for $100M in 2022) with no card/board titles found. The Turkish studios that actually hold these keywords are Alper Games, Gamyun, Fuzzy Mobile Games (hyilmaz), SNG Games, Ahoy Games, Big Head Games, Digitoy and Supergrade.

Gaps for a Crossle-backend game:
1. A modern online Batak (tekli/eşli/koz maça/ihaleli) with bots that take over leavers, friend rooms that work and a visible fair-deal policy: every current online Batak is 3.9–4.0★ with complaints about support, closed tables and coin starvation; the biggest Batak app is offline-only.
2. A Pişti + King + Batak "kahve" bundle under one account/leaderboard/season system (Crossle already has seasons, friends, leaderboards). Each keyword is uncrowded; a bundle shares the backend and the organic traffic (Soho/Altınstar/Digitoy already bundle, but at 3.4–3.8★).
3. Tavla and Okey are owned by global studios with 100K+ monthly installs; only attack them with a differentiated angle (e.g. voice rooms like Yalla, or a tournament/ladder product), never on the generic keyword.

## 4. Data caveats

- AppBrain (search and app pages) returned HTTP 403 to every fetch, including a plain curl; AppGoblin (appgoblin.info) was used instead for total installs and 4-week installs ("30d"). It is an estimate service; its "total installs" are not the Play tier and its pages sometimes say "Price: Paid" for free apps.
- Google Play numbers were read from the public listing (hl=en, gl=US) on 2026-10-26; download tiers are Google's buckets, review counts are rounded by Google, and "last update" is the store date.
- Review complaints are the 3–4 reviews Google shows on the public listing page (usually "most relevant"), not a full review mining; they skew negative and toward English reviewers.
- "Online multiplayer" is taken from the listing title/description ("Online", "İnternetsiz", "Offline"), not verified in-app.
- Store search ranking was done with gl set to the home country but hl=en; real local rankings may differ. RummyCircle/A23 listings returned "not found" from the US store; they may still exist in India.
- Vietnam online card games (ZingPlay/VNG portal) and Russian alternative stores (RuStore) were not fetched; Durak numbers are Play-only although Google Play billing is unavailable in Russia.
- Population figures are approximate and from general knowledge except where a source is cited; app-publisher claims ("over 5 million players") are not used in the scoring.
- Scoring weights are a judgement call; change the weights in section 1 and the ranking of the 6.2–7.0 band will move.

## 5. Sources

Google Play listings (all of the form https://play.google.com/store/apps/details?id=PACKAGE, fetched 2026-10-26) for packages:
net.peakgames.Yuzbir, net.peakgames.OkeyPlus, net.peakgames.mobile.canakokey.android, com.ahoygames.okey, com.ahoygames.Okey101, com.yalla.okey101yalla, com.badambiz.okeyYuzbir, com.elex.rummyfun101.tr, com.sngict.okey, com.sngict.okeyextra, com.hyilmaz.okey, com.okeyland.app, com.digitoygames.canokey, com.zynga.backgammonplus, net.gamyun.android.backgammon, com.easybrain.backgammon.board.games, net.backgammonstars.android, com.ahoygames.backgammon, com.gameberrylabs.backgammonfriends, com.sngict.backgammon, com.alper.batak.hd, com.alper.batakhdpro.online, com.bhgames.batakonline, com.fuzzymobilegames.batakonline, com.zingplay.batak, com.eylulgames.batak, net.gamyun.android.pisti, air.com.mmkgames.pisti, net.gamerhook.games.pisti, com.alper.pistihd, com.hyilmaz.pisti, com.sng.pisti.online, com.alper.king.hd, net.gamyun.android.king, com.teknopars.SuperKing,
com.gameduell.mobile.belote, com.iscoolentertainment.belote, com.iscoolentertainment.belote.classique, com.eryodsoft.android.cards.belote.lite, com.eryodsoft.android.cards.coinche.lite, com.WhatWapp.BeloteLeDefi, com.casualino.vipbelote, com.summitgames.coinche, com.doocogames.belote, com.gameduell.tarot, com.tradigames.tarot, com.exoty.tarot,
com.WhatWapp.Briscola, com.digitalmoka.briscoladalnegro, com.briscolatradizionale.briscola, it.spaghettiinteractive.briscolapiu, com.outofthebit.labriscola, com.WhatWapp.Scopa, com.epochalstorm.scopa, com.digitalmoka.scopadalnegro, com.scopatradizionale.scopa, com.iscoolentertainment.scopa.classica, com.WhatWapp.BurracoOnline, com.epochalstorm.burraco, com.ep.burracofree, com.aceofclubs.burraco, it.spaghettiinteractive.burracopiu, it.dt.scala40.ui, com.onmadesoft.android.scala40, air.br.com.scala40.mobile, it.spaghettiinteractive.tressettepiu, com.WhatWapp.Tressette,
com.remalit.kammelna, co.tamatem.vipbaloot, com.badambiz.saubaloot, com.yalla.yallabaloot, com.balootpro.app, org.imperiaonline.balootmasters, com.maysalward.balote, com.boundless.jawaker, com.jawaker.tarneeb, com.yallaplay.tarneebmasters, co.tamatem.tarneeb, com.maysalward.Tarneeb, com.devmazzi.tarneeb, com.zps.tarneeb, com.maysalward.Trix, com.diwaniyalabs.iTrix, com.oengines.trix, com.zps.trix.mea, com.fanellapro.pocketestimation.android, com.abyadtherock.egybasraarab, dev.rootsoft.basra, com.dynamitegamesstudio.basracardgameegyptialbasra, com.bendev.ronda.game.activity, com.sandukhan.ronda, com.tacsou.ronda, com.ElaSoft.Ronda,
com.blyts.trucolite.activities, com.trucovamos.play, air.br.com.trucopro.mobile, com.gsn.truco, com.brasmobi.truco, com.goldenjogos.game, com.zps.truco4a, com.jogatina.truco, com.jogatina.buraco, air.br.com.buracopro.mobile, air.br.com.buraco.mobile, com.zingplay.buraco, com.epochalstorm.buraco, com.mediasouls.buraco, com.gazeus.buracoiap, com.playspace.buraco, air.br.com.cacheta.mobile, gsn.game.cacheta, com.kk.cacheta, com.supercacheta.game, com.cachetaxp.app, com.tobias.pife, air.br.com.pifpaf.mobile, com.upperx.rei_do_pife, air.br.com.sueca.mobile, com.hugorosario.sueca, com.TiagoInteractive.Sueca, air.conectagames.sueca, com.gamevelvet.sueca, com.castelodavid.bisca61, com.jaimetjr.bisca, com.quarzo.brisca, com.jdpapps.brisca, donnaipe.mus, com.kangaroo.musmaestro, es.las40.mus, com.IRGamesMusOnline.com.unity, com.musreal.app, donnaipe.tutegratis, com.CasualArena.Tute, com.melele.tute, com.zariba.vipgames.tute.offline, com.five2.play.tute, com.blyts.chinchon, com.gsn.chinchon, com.quarzo.chinchon, com.playspace.chinchon, com.oengines.chinchon, com.melostudio.chinchon,
com.LoopGames.Domino, com.playvalve.dominoes, air.br.com.domino.mobile, air.com.jogatina.domino.android, ru.skillcap.dominoes, com.flyclops.domino.android, com.bigcake.android.classicdominoes, com.zimad.domino.rivals, com.gsn.conquian, air.br.com.conquian.mobile, com.alexga.Conquian333, com.yourfun.conquian, com.moonfroglabs.cardsClub, dev.pewen.carioca, cl.jpgames.cariocas, com.cariocapp.cariocapp, com.iglooJuan.ficto40, com.omenius.cuarenta, io.cuarenta.app, com.vinibenal.cuarenta,
com.ludo.king, com.moonfrog.ludo.club, io.yarsa.games.ludo, com.superking.ludo.star, com.alignit.ludo, com.teenpatti.hd.gold, com.octro.teenpatti, com.gametion.teenpatti, com.games24x7.rummycircle.rummy, in.a23.rummy, com.octro.rummy, com.eastudios.indianrummy, com.miniclip.carrom, com.git.carromking, com.appon.carrom, io.teslatech.callbreak, io.yarsa.games.cardgame, io.cardgame.callbreak, com.bhoos.callbreak, com.zlevelapps.cardgame29, com.ulkagames.twentynine, com.vipgames.twentynine,
com.rstgames.durak, ru.playvision.durak, com.frigatestudios.durak, com.kamagames.durak, com.vesna.cards.durak, ru.thousandcardgame.android, ru.livegames.tysacha, tech.rh1.thousand, ferp.android, com.dp.preferance, ru.livegames.pref, com.isarinteractive.skat.android.ad, com.isarinteractive.skat.android.hd, air.de.rgerlach.skatpalast, de.spielepalast.skatpalastpro, com.gameduell.skat.treff.kartenspiel, com.isarinteractive.doppelkopf.android.ad, com.isarinteractive.doppelkopf.android.hd, air.de.rgerlach.doppelkopfpalast, de.hebr3.doppelkopf, com.isarinteractive.schafkopf.android.ad, com.isarinteractive.schafkopf.android.hd, air.de.rgerlach.schafkopfpalast, ch.sweetware.swissjass_plus, ch.cartel.jasspro, com.donkeycat.jassen, com.yminds.Jass, com.ste.android.schnopsnfree, com.zariba.schnapsen.offline, com.casualino.bgbelot, com.middlehut.android.belot, com.gameon.bela, co.sombrerito.belaonline, air.com.forteGames.beloteMobile, agency.dotproduct.cardgames.belapro,
com.tongitsgo.play, com.emagssob.tongits, com.zingplay.tongits, com.higgs.tongitsstar, com.tongits.play.cardgames, com.playjoygame.pg, com.redkoda.chinesepokermultiplayernew, gsn.game.pusoy1, com.zp.pusoy.af, com.playboom.pusoyking, com.fiveplay.tlmn, com.senspark.android.southernthirteen, com.tienlen.sanhoffline.tlmn, tienlen.miennam.tlmn.offline, com.five2.play.tienlen.tienlen, com.senspark.android.phom, phom.tala.tulokho, com.five2.play.phom, com.danhbai.tienlen.phom, com.game.talaNew, com.emagssob.big2, com.godgame.bigtwo.android, com.luckystargame.funbig2_tw, com.jjplaycardgames.big2, com.vietgameplay.bigtwo,
net.peakgames.mobile.spades.android, com.mobilityware.Spades, com.blackout.spades, com.bbumgames.spadesroyale, com.yallaplay.spadesmasters, com.zimad.spades, com.astarsoftware.euchre, com.karmangames.euchre, uk.co.aifactory.euchrefree, com.jeffreys.euchrepay, com.WhatWapp.Euchre, com.mobilityware.Hearts, com.karmangames.hearts, uk.co.aifactory.heartsfree, com.sngict.Hearts, com.karmangames.pinochle, com.neuralplay.android.pinochle, de.spielepalast.pinochlepalace, com.eadromlabs.pinochlecircle, com.karmangames.canasta, com.northskygames.Canasta, de.spielepalast.canastapalace, com.gameduell.canasta.treff.kartenspiel, com.fiogonia.canasta, com.fiogonia.rummy500, com.mobilityware.Rummy, com.mmkgames.rummy500, com.sng.rummy500, com.gamesbypost.cribbageclassic, com.fullersystems.cribbage, ugen.co.za.thunee, com.sadev.durbandeal.google.

Google Play search pages (https://play.google.com/store/search?q=QUERY&c=apps&gl=COUNTRY) for: okey, 101 okey, tavla, batak, pişti, king kart oyunu (TR); belote, coinche, tarot (FR); briscola, scopa, burraco, scala 40, tressette (IT); baloot, بلوت, طرنيب (SA); tarneeb, estimation cards (JO); hand trix, basra (EG); ronda (MA); truco, buraco, cacheta, pife, domino (BR); truco (AR); sueca, bisca (PT); mus, tute, chinchón, brisca (ES); dominoes, euchre, spades, hearts, pinochle, canasta, rummy 500, cribbage (US); dominó, conquian (MX); ludo, teen patti, rummy, carrom (IN); дурак, тысяча, преферанс (RU); durak (UA); skat, doppelkopf, schafkopf (DE); jass (CH); schnapsen (AT); tongits, pusoy (PH); tiến lên, phỏm (VN); big two (HK); 大老二 (TW); carioca (CL); cuarenta (EC); callbreak (NP); 29 card game (BD); belot (BG); bela (HR); thunee (ZA).

AppGoblin pages (https://www.appgoblin.info/apps/PACKAGE) for: net.peakgames.Yuzbir, net.peakgames.OkeyPlus, net.peakgames.mobile.canakokey.android, com.ahoygames.okey, com.yalla.okey101yalla, com.elex.rummyfun101.tr, com.hyilmaz.okey, com.zynga.backgammonplus, com.easybrain.backgammon.board.games, com.ahoygames.backgammon, com.alper.batak.hd, com.alper.batakhdpro.online, com.bhgames.batakonline, com.fuzzymobilegames.batakonline, com.zingplay.batak, net.gamyun.android.pisti, net.gamerhook.games.pisti, com.alper.pistihd, com.hyilmaz.pisti, net.gamyun.android.king, com.alper.king.hd, com.gameduell.mobile.belote, com.iscoolentertainment.belote, com.eryodsoft.android.cards.belote.lite, com.casualino.vipbelote, com.gameduell.tarot, com.exoty.tarot, com.WhatWapp.Briscola, com.digitalmoka.briscoladalnegro, com.WhatWapp.Scopa, com.epochalstorm.scopa, com.WhatWapp.BurracoOnline, com.epochalstorm.burraco, com.remalit.kammelna, co.tamatem.vipbaloot, com.badambiz.saubaloot, com.yalla.yallabaloot, com.boundless.jawaker, com.jawaker.tarneeb, com.yallaplay.tarneebmasters, co.tamatem.tarneeb, com.maysalward.Trix, com.diwaniyalabs.iTrix, com.fanellapro.pocketestimation.android, com.abyadtherock.egybasraarab, com.bendev.ronda.game.activity, com.blyts.trucolite.activities, com.trucovamos.play, air.br.com.trucopro.mobile, com.gsn.truco, com.jogatina.buraco, air.br.com.cacheta.mobile, com.tobias.pife, air.br.com.sueca.mobile, com.hugorosario.sueca, com.jdpapps.brisca, donnaipe.mus, donnaipe.tutegratis, com.blyts.chinchon, com.quarzo.chinchon, com.LoopGames.Domino, com.playvalve.dominoes, air.br.com.domino.mobile, air.com.jogatina.domino.android, com.gsn.conquian, com.moonfroglabs.cardsClub, com.iglooJuan.ficto40, com.ludo.king, com.moonfrog.ludo.club, io.yarsa.games.ludo, com.superking.ludo.star, com.teenpatti.hd.gold, com.octro.teenpatti, com.octro.rummy, com.miniclip.carrom, io.teslatech.callbreak, io.yarsa.games.cardgame, com.zlevelapps.cardgame29, com.rstgames.durak, ru.playvision.durak, com.frigatestudios.durak, com.kamagames.durak, ru.thousandcardgame.android, ferp.android, com.isarinteractive.skat.android.ad, air.de.rgerlach.skatpalast, com.isarinteractive.doppelkopf.android.ad, air.de.rgerlach.doppelkopfpalast, com.isarinteractive.schafkopf.android.ad, air.de.rgerlach.schafkopfpalast, ch.sweetware.swissjass_plus, com.ste.android.schnopsnfree, com.casualino.bgbelot, com.middlehut.android.belot, com.gameon.bela, com.tongitsgo.play, com.emagssob.tongits, com.zingplay.tongits, com.higgs.tongitsstar, com.playjoygame.pg, com.redkoda.chinesepokermultiplayernew, com.fiveplay.tlmn, com.senspark.android.southernthirteen, com.tienlen.sanhoffline.tlmn, com.senspark.android.phom, com.emagssob.big2, com.godgame.bigtwo.android, com.luckystargame.funbig2_tw, net.peakgames.mobile.spades.android, com.mobilityware.Spades, com.blackout.spades, com.astarsoftware.euchre, uk.co.aifactory.euchrefree, com.mobilityware.Hearts, uk.co.aifactory.heartsfree, com.karmangames.pinochle, com.karmangames.canasta, com.northskygames.Canasta, com.fiogonia.rummy500, com.gamesbypost.cribbageclassic, ugen.co.za.thunee.

Other pages and search snippets used:
- https://www.takvim.com.tr/Yasam/2013/01/12/10-milyon-kisi-okeye-dondu (10M regular online okey players, TBMM, 2013)
- https://www.tourmag.com/Futuroscopie-jeux-de-societe-une-passion-francaise-%F0%9F%94%91_a117675.html and https://info.fr/comment-jouer-a-la-belote-a-2/ (9–10M belote players)
- https://www.pocketgamer.biz/impact46-invests-over-53m-in-saudi-game-studio-kammelna and https://www.agbi.com/gaming/2025/09/investors-go-all-in-as-saudi-card-game-baloot-moves-online/ (Kammelna 6M downloads, 1M MAU, funding)
- https://pagat.com/jass/baloot.html, https://arabnews.com/node/1249291/ (Baloot popularity in Saudi)
- https://blog.mygov.in/?p=210583, https://www.drishtiias.com/daily-updates/daily-news-analysis/promotion-and-regulation-of-online-gaming-act,-2025/print_manually, https://www.onmanorama.com/news/india/2025/08/20/online-game-banning-bill-passed-in-lok-sabha.html (India Promotion and Regulation of Online Gaming Act 2025)
- https://mixrank.com/playstore/apps/net.peakgames.Yuzbir, https://mixrank.com/playstore/apps/net.peakgames.OkeyPlus (older snapshots: 47.8M / 28.9M downloads)
- https://www.appgoblin.info/apps/com.blackout.spades, https://www.appbrain.com/app/pinochle-expert-ai/com.neuralplay.android.pinochle (search snippets only; AppBrain itself returned 403)
- https://apps.apple.com/FR/app/id737698958 (Belote.com iOS: 4.6★, ~302K ratings, "250,000 players online daily" claim), https://apps.apple.com/FR/app/id1023399449 (Belote Multijoueur iOS)
- https://apps.apple.com/DE/app/id526976110 (Skat Palast iOS, 12,949 ratings 4.5), https://apps.apple.com/DE/app/id1076626842 (Schafkopf LITE iOS, 15,461 ratings)
- https://www.cbinsights.com/company/alictus, https://builtin.com/company/alictus (Alictus = hyper-casual, SciPlay stake 2022); https://logokit.com/brands/he2apps.com (He2 Apps okey titles)
- https://fptshop.com.vn/tin-tuc/thu-thuat/tai-tien-len-mien-nam-mien-phi-180067 (ZingPlay Tiến Lên "5 million players" claim)
- https://www.bluestacks.com/campaign/com.tongitsgo.play/en/ (Tongits Go bundle description), https://www.bluestacks.com/de/apps/card/sk-at-on-pc.html (Skat Palast "100,000 active players/month" claim)
- https://www.buscape.com.br/baralho/conteudo/como-jogar-truco, https://focusgn.com/brasil/como-jogar-truco (Truco regional popularity)
- https://en.wikipedia.org/wiki/Doppelkopf, https://en.wikipedia.org/wiki/German_Schafkopf (regional distribution of German games)
