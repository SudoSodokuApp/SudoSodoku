<p align="center">
  <img src="SudoSodoku/AppIcon_V3.png" alt="SudoSodoku app icon" width="128" height="128">
</p>

<h1 align="center">SudoSodoku</h1>

<p align="center"><strong><code>sudo solve</code> — logic is root access.</strong></p>

<p align="center">
  <a href="https://apps.apple.com/us/app/sudosodoku/id6779813086">Download on the App Store</a>
  · <a href="https://sudosodoku.kaichen.dev">Website</a>
  · <a href="https://github.com/SudoSodokuApp/SudoSodoku/releases/tag/v2.0.0">v2.0.0</a>
</p>

```text
root@ios:~$ sudo sudosodoku breach --master
[sudo] password for logic: ********
> uniqueness_check ........ [OK]
> difficulty_index ........ 84
> ACCESS GRANTED
```

SudoSodoku is a pure-logic Sudoku for iPhone wrapped in a full terminal fantasy. Puzzles generate behind a live breach log, victories end in `ACCESS GRANTED`, and a real ELO ladder runs from `SCRIPT_KIDDIE` to `THE_ARCHITECT`.

Free. No ads. No in-app purchases. No tracking.

## Designed with intent

SudoSodoku is built around four product principles:

1. **The fantasy is complete.** The app behaves like one continuous shell session, from the launch prompt to the final victory sequence.
2. **Logic stays in focus.** There are no lives, fail states, paywalls, or interruption mechanics. The timer is optional and undo is never punished.
3. **Progress is earned.** Game Center ranks solve time and ELO performance, never spending. Eleven achievements mark meaningful milestones.
4. **Delight respects the player.** Haptics, phosphor pulses, and matrix rain add character without getting in the way. Every animation respects Reduce Motion; sound is never forced.

That approach follows the same fundamentals Apple recommends in its [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/design-principles): purpose, agency, responsibility, simplicity, craft, and delight.

## The experience

### A terminal you can play

- One accumulating command line: `breach`, `archives`, `stats`, and `whoami` are subcommands entered from a live prompt.
- A typewriter breach log reports the real uniqueness check and difficulty index for each generated puzzle.
- Victory unfolds in three acts: matrix rain, `ACCESS GRANTED`, then an ELO ticker and rank-up ceremony.
- A semantic haptic vocabulary distinguishes selection, placement, removal, conflicts, completed units, and victory.

### Grids grown, not stored

- Infinite, unique-solution puzzles generated on device — never a canned database.
- Four difficulty flags: `--easy`, `--medium`, `--hard`, and `--master`.
- A logical solver grades every grid from 0–100; the v2.1 roadmap is refining technique-specific separation between difficulty levels.
- Pencil notes auto-clear from peers, and undo restores the entire move as one action.
- The play clock counts active time only, pauses in the background, and freezes on completion.

### A fair ladder

- ELO starts at 1200 with an adaptive K-factor and anti-smurfing.
- Six ranks: `SCRIPT_KIDDIE` → `USER` → `SUDOER` → `SYS_ADMIN` → `KERNEL_HACKER` → `THE_ARCHITECT`.
- Five Game Center leaderboards: global ELO plus fastest solve per difficulty.
- Eleven achievements, including one secret.
- Honest statistics and immutable solved archives: viewing or replaying an old puzzle never rewrites history.

## Privacy by construction

Game history, rating, statistics, and achievements stay in one local save file on your device. SudoSodoku has no developer account system, analytics, advertising, tracking, or third-party SDKs. Game Center is optional, operated by Apple, and used only for leaderboards and achievements.

Read the full [Privacy Policy](PRIVACY.md) or visit [sudosodoku.kaichen.dev/privacy](https://sudosodoku.kaichen.dev/privacy).

## Build from source

### Requirements

- macOS 13 or later
- Xcode 15 or later with iOS 17 SDK support
- iPhone or iPhone Simulator running iOS 17 or later

### Setup

```bash
git clone https://github.com/SudoSodokuApp/SudoSodoku.git
cd SudoSodoku
open SudoSodoku.xcodeproj
```

Select the `SudoSodoku` target, choose your own development team under **Signing & Capabilities**, then run with `Command-R`.

Command-line helpers are also available:

```bash
./build.sh          # Debug build
./build.sh release  # Release build
./play.sh           # Build and launch in Simulator

xcodebuild test \
  -project SudoSodoku.xcodeproj \
  -scheme SudoSodoku \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Do not accept an Xcode recommendation that replaces the literal `IPHONEOS_DEPLOYMENT_TARGET = 17.0`; see [CONTRIBUTING.md](CONTRIBUTING.md) for the project-specific reason.

## Architecture

SudoSodoku is an iPhone-only SwiftUI app using MVVM and Combine, with no external dependencies.

```text
SudoSodoku/
├── Algorithms/       Puzzle generation, uniqueness, and difficulty grading
├── Managers/         Storage, rating, Game Center, achievements, statistics, haptics
├── Models/           Game, record, difficulty, rank, and achievement types
├── ViewModels/       Game state and gameplay orchestration
├── Views/            Screens and reusable SwiftUI components
└── Utils/            Shared constants and formatting

SudoSodokuTests/      Generator, gameplay, rating, storage, and regression tests
Config/               Launch-screen Info.plist values
```

For invariants, data flow, and release engineering, see [DEVELOPER.md](DEVELOPER.md).

## Community

Choose the path that best fits what you need:

- **Need help using the app?** Start with [Support](SUPPORT.md), then ask in [GitHub Discussions](https://github.com/SudoSodokuApp/SudoSodoku/discussions/categories/q-a).
- **Found a reproducible bug?** Open a [bug report](https://github.com/SudoSodokuApp/SudoSodoku/issues/new/choose).
- **Have an idea?** Share it in [Ideas](https://github.com/SudoSodokuApp/SudoSodoku/discussions/categories/ideas) before opening an implementation issue.
- **Want to contribute?** Read [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md).
- **Found a security issue?** Follow the private process in [.github/SECURITY.md](.github/SECURITY.md).

## Documentation

- [Support](SUPPORT.md)
- [Development and roadmap](DEVELOPER.md)
- [Contributing](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)
- [v2.0.0 release notes](RELEASE_NOTES_v2.0.0.md)
- [Privacy Policy](PRIVACY.md)
- [Security Policy](.github/SECURITY.md)

## License

SudoSodoku is available under the [MIT License](LICENSE).

Created by [Kai T. Chen](https://kaichen.dev).
