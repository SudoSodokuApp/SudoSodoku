# Security Policy

## Supported versions

Security fixes are provided for the current App Store release.

| Version | Supported |
| --- | --- |
| 2.0.x | Yes |
| Earlier versions | No |

## Report a vulnerability privately

Do not open a public issue or discussion for a suspected vulnerability.

Use the repository’s [private vulnerability reporting form](https://github.com/SudoSodokuApp/SudoSodoku/security/advisories/new). If that form is unavailable, contact Kai T. Chen using the contact details at [kaichen.dev](https://kaichen.dev).

Include, when possible:

- the affected version or commit;
- a clear description of the impact;
- reliable reproduction steps;
- a minimal proof of concept;
- any suggested mitigation;
- whether the issue has been disclosed elsewhere.

Remove Apple Account credentials, Game Center identifiers, save files, and other personal information that is not necessary to reproduce the issue.

## What to expect

The maintainer will acknowledge a complete report as soon as practical, validate it, and coordinate next steps privately. Timing depends on severity and App Store review requirements. Please allow a reasonable remediation window before public disclosure.

Confirmed fixes are documented in `CHANGELOG.md` and the relevant GitHub Release. Credit is offered with the reporter’s permission.

## Security model

SudoSodoku intentionally has a small attack surface:

- gameplay data is stored locally in one atomic JSON save file;
- there is no developer account system or backend;
- there are no third-party packages, analytics SDKs, advertising SDKs, or trackers;
- Game Center is optional and accessed through Apple’s GameKit framework;
- the only app entitlement is Game Center.

The app displays a Game Center name and profile image supplied by GameKit, and submits eligible solve times, ELO ratings, and achievement events to Apple when Game Center is enabled. See [PRIVACY.md](../PRIVACY.md) for the full data-handling policy.

## Safe installation

Players should install the shipping app only from the [App Store](https://apps.apple.com/us/app/sudosodoku/id6779813086). Developers building from source should use this repository, review changes, and configure their own signing identity.
