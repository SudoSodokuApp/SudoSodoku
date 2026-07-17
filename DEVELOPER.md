# Development and roadmap

SudoSodoku is a native, iPhone-only Sudoku game built with SwiftUI. This document is the engineering map: architecture, invariants, validation, and the public roadmap after the first App Store release.

For setup and pull request rules, start with [CONTRIBUTING.md](CONTRIBUTING.md).

## Current product state

- **App Store:** [SudoSodoku 2.0](https://apps.apple.com/us/app/sudosodoku/id6779813086), released July 16, 2026
- **Source release:** [v2.0.0](https://github.com/SudoSodokuApp/SudoSodoku/releases/tag/v2.0.0)
- **Platform:** iPhone, iOS 17 or later
- **Stack:** Swift 5.9, SwiftUI, Combine, GameKit, Core Haptics
- **Persistence:** one atomic, versioned local JSON save file
- **External dependencies:** none
- **Online service:** optional Apple Game Center only

Shipping is not the finish line. The quality bar remains stability, accessibility, privacy, and careful iteration on the core deduction experience.

## Product principles

Every proposal is evaluated against the same four constraints:

1. The terminal fantasy should feel complete and internally consistent.
2. The puzzle remains primary; interruption and pressure mechanics do not belong.
3. Progress measures play, never spending or engagement manipulation.
4. Delight must respect accessibility settings and the player’s attention.

These constraints intentionally keep the product small. New capability must earn its place.

## Architecture

```text
SudoSodokuApp
└── ContentView / navigation
    ├── Views
    │   └── reusable Components and Styles
    ├── SudokuGame
    │   ├── board state and move history
    │   ├── play clock and completion pipeline
    │   └── generator orchestration
    └── Managers
        ├── StorageManager
        ├── StatisticsManager
        ├── RatingManager
        ├── AchievementManager
        ├── GameCenterManager
        └── HapticManager
```

### State ownership

- SwiftUI views render state and emit intent.
- `SudokuGame` owns a live game session, undo/redo, the clock, conflicts, and victory state.
- `SudokuGenerator` creates, grades, and verifies puzzles.
- Managers own one domain each and expose stable interfaces to the view model and views.
- `StorageManager` is the only persistence boundary.

### Persistence

The current save format is `save_data_v4.json`. Writes are atomic and decoding supports legacy formats.

Non-negotiable invariants:

- A completed record is immutable history.
- Viewing a record is read-only.
- Restarting or replaying forks a new record.
- New persisted fields have safe decode defaults.
- Statistics derive from emitted record values, not stale singleton read-backs.

### Game Center

Game Center authentication is optional and initiated once at the app root. The app is fully playable as a guest.

- Global leaderboard values are ELO ratings; higher is better.
- Difficulty leaderboards receive positive, whole-second solve durations; lower is better.
- Achievement reporting has an offline retry queue.
- Looking at a solution never submits a score or achievement.

Leaderboard and achievement identifiers are centralized in `SudoSodoku/Utils/AppConstants.swift`.

## Quality baseline

### Automated validation

The shared `SudoSodoku` scheme includes `SudoSodokuTests`. Run the full suite before every pull request:

```bash
xcodebuild test \
  -project SudoSodoku.xcodeproj \
  -scheme SudoSodoku \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Generator, rating, persistence, Game Center mapping, and regression changes require targeted tests. Generator quality assertions should verify solvability, uniqueness, technique gates, score bands, clue distribution, and performance.

### Manual validation

For user-visible changes, check:

- first launch and returning launch;
- the smallest supported iPhone and a current Pro-size device;
- light and dark system appearance, even though the app renders a dark terminal surface;
- larger text sizes and VoiceOver labels for changed controls;
- Reduce Motion enabled;
- Game Center signed in and signed out;
- background/resume during an active game;
- an upgraded save and a clean install;
- offline play;
- screenshots and copy against the shipping App Store experience.

### Build configuration guardrail

`IPHONEOS_DEPLOYMENT_TARGET` must remain the literal `17.0` in every target. Xcode’s recommended-settings rewrite to `$(RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET)` has caused Xcode Cloud availability failures.

## Roadmap

GitHub milestones and issues are the canonical roadmap. This summary explains direction without promising dates.

### v2.1 — Generator algorithm overhaul

The first post-launch update focuses on the heart of the app: honest, explainable puzzle quality.

- [#70](https://github.com/SudoSodokuApp/SudoSodoku/issues/70) — trace-producing logical solver and defensible difficulty index
- [#71](https://github.com/SudoSodokuApp/SudoSodoku/issues/71) — give MEDIUM a distinct technique identity
- [#72](https://github.com/SudoSodokuApp/SudoSodoku/issues/72) — define a meaningful MASTER ceiling
- [#73](https://github.com/SudoSodokuApp/SudoSodoku/issues/73) — shape solve arcs and rotate signature techniques
- [#74](https://github.com/SudoSodokuApp/SudoSodoku/issues/74) — broaden clue texture beyond symmetry labels

### v2.2 — Gameplay and progression

Exploration includes daily seeded puzzles, reproducible seed sharing, multi-difficulty gauntlets, seasonal competition, and reasoning-aware feedback. Each idea must preserve offline play, privacy, and the no-pressure philosophy.

### Parked

Technique training, platform expansion, themes, variants, and other large surfaces remain parked until the core generator and progression work prove their value. iPad and macOS are not currently planned.

Use [Ideas](https://github.com/SudoSodokuApp/SudoSodoku/discussions/categories/ideas) for product discussion. An idea becomes an Issue only when it is sufficiently defined and actionable.

## Release process

1. Confirm the milestone scope and move unfinished work out of the release.
2. Update `MARKETING_VERSION`, build number, `CHANGELOG.md`, release notes, README status, and website copy.
3. Run the full automated suite and the manual matrix above.
4. Verify privacy policy, support URL, App Store screenshots, description, age rating, and Game Center configuration.
5. Archive and validate the distribution build; submit through App Store Connect.
6. After approval, verify the public App Store page and all website links.
7. Publish the matching GitHub Release, close the release issue and milestone, and post a Discussions announcement.
8. Recheck repository About metadata, topics, support paths, and documentation for stale “beta,” “submission,” or prior-version language.

## Documentation ownership

- `README.md` is the product and repository front door.
- `SUPPORT.md` is for players.
- `CONTRIBUTING.md` is for contributors.
- `DEVELOPER.md` is for architecture, invariants, and roadmap.
- `PRIVACY.md` and `.github/SECURITY.md` are policy documents.
- `CHANGELOG.md` records shipped changes; release notes tell the release story.

The GitHub Wiki remains disabled so these versioned files stay the single source of truth. Discussions provide the living community layer without copying canonical documentation.
