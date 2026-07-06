# **SudoSodoku**

```
$ sudo solve
[sudo] password for logic: ********
> root access granted.
```

**`sudo solve` — root access for logical purists.**

SudoSodoku is the only sudoku on the App Store that treats you like root. It is a full terminal fantasy: green phosphor on deep dark glass, mechanical-keyboard haptics, and an ELO ladder that climbs from `SCRIPT_KIDDIE` to `THE_ARCHITECT`. You are not filling in numbers — you are breaching a grid, and every victory ends the only way it should: `ACCESS GRANTED`.

## **🧠 Philosophy**

Four rules the whole game is built on:

1. **You're not filling numbers. You're breaching systems.**
   The terminal fantasy is total. Puzzles generate behind a live breach log (`$ sudo breach --target=grid_9x9`), victories detonate matrix rain, and rank-ups get a ceremony. Every touchpoint speaks shell.

2. **Pure logic. Zero noise.**
   No ads. No lives. No pay-to-win. No guilt mechanics. Even the timer is optional — nothing is allowed to interrupt a deduction.

3. **Earn your rank.**
   A real ELO system with anti-smurfing (top players gain nothing from stomping easy grids), and Game Center leaderboards that rank actual performance — fastest solves and rating — never spending.

4. **Juice with respect.**
   Rigid-impact keystrokes, phosphor pulses, CRT-glitch error shakes — and every single animation respects Reduce Motion, sounds are never forced on. Delight is a layer, not a tax.

## **✨ Features**

### **🖥️ The Terminal**

* Authentic green phosphor (#00FF00) on deep dark background (#0D121A), all-monospaced UI
* Typewriter **breach-log loading screen** whose verdict lines report the real uniqueness check and difficulty index of your puzzle
* Three-act **victory sequence**: Canvas-drawn matrix rain → typewriter `ACCESS GRANTED` → ELO ticker rolling to your new rating, with a glowing `>> RANK_UP <<` ceremony on tier crossings
* A semantic **haptic vocabulary**: cell selection ticks, rigid key-press placements, error notifications, and a custom CoreHaptics victory rumble

### **♾️ The Grid**

* Real-time procedural generation — unique, human-gradable puzzles with a logical-solver difficulty score (0–100), never a canned database
* Four difficulty flags: `--easy` `--medium` `--hard` `--master`
* Pencil notes with **auto-clear**: placing a digit sweeps it from peer notes, and undo restores everything as one compound move
* Numpad that thinks: exhausted digits strike through, dead taps nudge instead of being swallowed, the selection frame glides between cells
* Optional play clock (`T+MM:SS`) that only counts active time — backgrounding pauses it, victory freezes it

### **🏆 The Ladder**

* ELO rating from 1200 with adaptive K-factor and anti-smurfing
* Six ranks: `SCRIPT_KIDDIE` → `USER` → `SUDOER` → `SYS_ADMIN` → `KERNEL_HACKER` → `THE_ARCHITECT`
* **Game Center leaderboards**: a global ELO ranking plus fastest-time boards per difficulty (`cat /leaderboard`)
* Personal bests, logical-efficiency scoring, and full session archives with favorites and replay

## **🛠️ Technical Architecture**

* **Language**: Swift 5.9 · **UI**: SwiftUI · **Pattern**: MVVM · **State**: Combine
* **Platform**: iPhone-only, iOS 17.0+
* **Persistence**: single local JSON file, atomic writes, versioned migration chain
* **Game services**: GameKit (auth, leaderboards) · CoreHaptics
* **Testing**: `SudoSodokuTests` unit suite (generator, rating, storage, gameplay logic) run locally and on Xcode Cloud

### **Directory Structure**

```
SudoSodoku/
├── SudoSodokuApp.swift           # @main entry
├── Models/                       # GameRecord, SudokuCell, MoveHistory, Difficulty, RankTier, ...
├── ViewModels/
│   └── SudokuGame.swift          # Core game logic, play clock, undo/redo, conflict signals
├── Managers/
│   ├── GameCenterManager.swift   # Auth + leaderboard submissions
│   ├── RatingManager.swift       # ELO calculation
│   ├── HapticManager.swift       # Semantic haptic vocabulary (+ CoreHaptics victory)
│   ├── StatisticsManager.swift   # Stats aggregation
│   └── StorageManager.swift      # Atomic JSON persistence + migrations
├── Algorithms/
│   └── SudokuGenerator.swift     # Backtracking generation + logical difficulty grading
├── Utils/                        # AppConstants (leaderboard IDs), DateFormatting, ...
└── Views/
    ├── GameView.swift            # The board screen
    ├── LeaderboardView.swift     # Terminal-styled Game Center rankings
    ├── ...                       # Landing, Archive, Stats, Profile, ModeSelection
    └── Components/               # BreachLogView, MatrixVictoryOverlay, CellView, ...

SudoSodokuTests/                  # Unit tests (picked up automatically by the shared scheme)
```

## **🚀 Building the Project**

### **Method 1: Using Xcode (Traditional)**

1. **Clone the repository**:

  ```bash
  git clone https://github.com/kaiiiichen/SudoSodoku.git
  ```

1. **Open in Xcode**:
   Double-click `SudoSodoku.xcodeproj`. Ensure you have Xcode 15.0+ installed.

2. **Configure Signing**:
   * Go to the Project Navigator (blue icon).
   * Select the SudoSodoku target.
   * Click **Signing & Capabilities**.
   * Change the **Team** to your own Apple Developer account.

3. **Run**:
   Connect your iPhone or select a Simulator and press `Cmd + R`.

### **Method 2: Using Command Line (Cursor/VS Code)**

We provide convenient build scripts for command-line development:

#### **Build Scripts**

* **`build.sh`** - Build the project (similar to Xcode's Cmd+B)

  ```bash
  ./build.sh          # Debug build (default)
  ./build.sh release  # Release build
  ./build.sh clean    # Clean build artifacts
  ```

* **`play.sh`** - Build and run in iOS Simulator

  ```bash
  ./play.sh
  ```

#### **Running Tests**

```bash
xcodebuild test -project SudoSodoku.xcodeproj -scheme SudoSodoku \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### **Build Requirements**

* macOS 13.0+ (for iOS development)
* Xcode 15.0+ with Command Line Tools
* iOS 17.0+ deployment target
* iPhone only (portrait and landscape)

## **🤝 Contributing**

Contributions are welcome! We appreciate your help in making SudoSodoku better.

**Getting Started:**

1. Read our [Contributing Guidelines](CONTRIBUTING.md)
2. Check our [Code of Conduct](CODE_OF_CONDUCT.md)
3. Look for issues labeled `good first issue`
4. Fork, make changes, and submit a Pull Request

All changes go through feature branches and pull requests — never direct commits to `main`. Update `CHANGELOG.md` in the same PR, and keep new generator/rating/storage logic covered by unit tests.

### **Code Style Guidelines**

* All code comments and documentation in English
* Follow Swift naming conventions and the MVVM architecture
* Match the terminal aesthetic in UI copy (monospaced, `UPPER_SNAKE` labels, shell-flavored strings)
* Every animation must respect Reduce Motion; sounds are never forced on

## **📚 Additional Documentation**

* **[CHANGELOG.md](CHANGELOG.md)** - Version history and release notes
* **[DEVELOPER.md](DEVELOPER.md)** - Feature roadmap, testing checklist, and development guidelines
* **[CONTRIBUTING.md](CONTRIBUTING.md)** - Guidelines for contributing to the project
* **[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)** - Community code of conduct
* **[SECURITY.md](.github/SECURITY.md)** - Security policy and vulnerability reporting

## **📄 License**

Distributed under the MIT License. See LICENSE for more information.

*Created with logic and ❤️ by Kai Chen.*
