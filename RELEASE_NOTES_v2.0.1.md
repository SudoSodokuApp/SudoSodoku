# sudo sudoku v2.0.1

**Released TBD · [Download on the App Store](https://apps.apple.com/us/app/sudo-sudoku/id6779813086) · [Official website](https://sudosudoku.kaichen.dev)**

```
$ alias sudosodoku='sudo sudoku'
$ sudo sudoku
> typo patched. root access unchanged.
```

**sudo sudoku — the name finally types itself right.**

v2.0.1 is a small release with one big change: the name. "Sodoku" was a misspelling, so the app is now **sudo sudoku**, which is `sudo` plus `sudoku`, the joke it was always meant to be.

## Same root, new name 🏷️

- The home screen now reads **sudo sudoku**.
- The whole shell session follows: the landing prompt boots in typing `sudo sudoku`, and every screen echoes the full command it was reached with (`root@ios:~$ sudo sudoku breach --easy`).
- Nothing you earned moves. Archive, ELO rating, achievements, and Game Center scores carry over; v2.0.1 updates in place over v2.0.0.

## Errors you can see without color 👁️

- A conflicting digit is now **struck through** as well as shown in red, so a mistake stands out without relying on color, including under Reduce Motion, where the error shake is skipped.

## Housekeeping 🧹

- `cat /privacy` opens the policy at its new home, [sudosudoku.kaichen.dev/privacy](https://sudosudoku.kaichen.dev/privacy). The old address keeps redirecting.
- The source moved to [sudosudoku/sudo-sudoku](https://github.com/sudosudoku/sudo-sudoku); the Xcode project, target, and scheme are now `SudoSudoku`.

---

**Requirements:** iOS 17.0+, iPhone only. Internet optional (Game Center).
Full details in [CHANGELOG.md](CHANGELOG.md).
