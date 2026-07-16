# Contributing to SudoSodoku

Thank you for helping improve SudoSodoku. This guide describes the project’s actual workflow and the product constraints that keep the app coherent.

## Before you begin

- Use [GitHub Discussions](https://github.com/SudoSodokuApp/SudoSodoku/discussions/categories/q-a) for questions.
- Share early product ideas in [Ideas](https://github.com/SudoSodokuApp/SudoSodoku/discussions/categories/ideas).
- Use Issues for reproducible bugs and accepted, actionable work.
- Never include personal, Game Center, or security-sensitive information in a public post. Report vulnerabilities through the process in [.github/SECURITY.md](.github/SECURITY.md).

## What fits the project

We welcome focused improvements to gameplay correctness, puzzle quality, accessibility, performance, tests, documentation, and the native iPhone experience.

We generally decline:

- ads, paywalls, lives, guilt mechanics, or pay-to-win systems;
- analytics, tracking, or third-party SDKs that move gameplay data off device;
- iPad or macOS work while the product remains intentionally iPhone-only;
- forced sound or animations that ignore Reduce Motion;
- features that add surface area without improving the core deduction experience.

When tradeoffs are close, subtraction wins.

## Set up the project

Requirements: macOS 13 or later, Xcode 15 or later, Git, and an iOS 17 simulator or device.

```bash
git clone https://github.com/YOUR_USERNAME/SudoSodoku.git
cd SudoSodoku
open SudoSodoku.xcodeproj
```

Choose your own development team under **Signing & Capabilities**. You can then run the app with `Command-R`, `./build.sh`, or `./play.sh`.

## Project rules

These constraints are easy to miss and can break CI or an App Store build:

1. **Work on a branch and open a pull request.** Do not commit directly to `main`, including for documentation-only changes.
2. **Keep `IPHONEOS_DEPLOYMENT_TARGET` as the literal `17.0`.** Do not accept Xcode’s recommendation to replace it with `$(RECOMMENDED_IPHONEOS_DEPLOYMENT_TARGET)`; that macro has failed to resolve in Xcode Cloud.
3. **Do not hand-register source files in `project.pbxproj`.** The project uses synchronized folder groups. Files under `SudoSodoku/` and `SudoSodokuTests/` are discovered automatically.
4. **Update `[Unreleased]` in `CHANGELOG.md`** in the same pull request as a user-visible change.
5. **Preserve saved data.** New persisted fields need decoding defaults and migration coverage.
6. **Keep solved records immutable.** Viewing never writes; restart and replay create a new record.

## Workflow

Create a focused branch:

```bash
git switch -c feature/short-name
# Also accepted: fix/, docs/, refactor/, test/, chore/
```

Use a Conventional Commit:

```text
feat: add technique trace to generated puzzles
fix: preserve solved record when replaying
docs: update post-launch support paths
```

Before opening a pull request:

```bash
xcodebuild test \
  -project SudoSodoku.xcodeproj \
  -scheme SudoSodoku \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

In the pull request, explain the user-visible outcome, link the issue with `Closes #N` when appropriate, describe validation, and include before/after media for interface changes.

## Engineering style

- Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
- Views render state; `SudokuGame` owns gameplay; managers own storage, rating, Game Center, achievements, statistics, and haptics.
- Prefer small functions, explicit names, `let`, and early-exit `guard` statements.
- Comments explain why an invariant exists, not what the next line does.
- Code, documentation, issues, and pull requests are written in English.

## Product and interface quality

- Preserve the terminal fiction in user-facing copy: monospaced text, shell-flavored commands, and established `UPPER_SNAKE` labels.
- Keep controls clear even when terminal styling is applied. Character should never obscure meaning.
- Respect Dynamic Type where layouts allow, VoiceOver semantics, sufficient contrast, and Reduce Motion.
- Never rely on color, motion, or haptics as the only signal.
- Route haptics through `HapticManager` so feedback remains semantic and consistent.
- Test the smallest supported iPhone layout and at least one current device size.

## Data and privacy

SudoSodoku stores gameplay data locally and has no analytics, advertising, or third-party SDKs. Game Center is the only online service and must remain optional. Any proposal that changes data handling must update `PRIVACY.md`, App Store privacy metadata, in-app disclosure, and tests before release.

## License and conduct

By contributing, you agree that your contribution is licensed under the [MIT License](LICENSE). Participation is governed by the [Code of Conduct](CODE_OF_CONDUCT.md).
