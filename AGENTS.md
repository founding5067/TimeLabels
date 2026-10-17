# Agent Instructions

### Git
- Only commit or push when the user explicitly asks in the current conversation. Never on your own initiative.
- Never commit or push directly to `main`; work on a branch and open a PR. Never create or push tags (tags trigger a release).
- Prefer a new commit over amending or force-pushing a branch that's already pushed. PRs are squash-merged, so extra commits are fine.
- Read-only and local commands are always fine: `git status`, `git diff`, `git log`, file edits, builds, tests.
- Before finishing work, summarize what you changed and ask the user how they want it committed.

### Layout (one file per concern; tests mirror sources)
- `Sources/TimeLabels/`
  - `TimeLabel.swift` — namespace + `Unit`
  - `TimeLabel+Relative.swift` — `timeRemaining`, `timeAgo`, `relative`
  - `TimeLabel+Calendar.swift` — `time`, `dateLabel`
  - `TimeLabel+Duration.swift` — `duration`
  - `TimeLabel+Formatting.swift` — internal helpers
  - `Date+TimeLabel.swift` — `Date` forwarding extensions (no logic)
  - `TimeLabelText.swift` — the SwiftUI view, inside `#if canImport(SwiftUI)`
  - `TimeLabelPreviews.swift` — all SwiftUI `#Preview`s (SwiftUI + `DEBUG` only). Keep every preview in this one self-contained file (private sample data, no helpers shared across files): Xcode's canvas doesn't reliably see symbols from other files.
- `Tests/TimeLabelsTests/`: `<Concern>Tests.swift` per source file. Shared fixtures (`fixedDate`, `utcCalendar()`, `ago`, `ahead`, `day`, `week`) live in `TestFixtures.swift`; don't redefine them.

### Conventions
- **Never change existing output.** New behavior is opt-in via new parameters whose defaults reproduce today's strings exactly. The existing tests are the regression guard; don't edit their expectations.
- Output is deterministic: `en_US_POSIX` locale + explicit `dateFormat` patterns, Gregorian calendar; `calendar:` only sets the timezone.
- Numeric inputs go through `clampedSeconds` so NaN/negative/infinite values never trap.
- Anything using SwiftUI/UIKit stays behind `#if canImport(...)` — CI builds on Linux.
- Group code in Swift files with `// MARK: - Section` (not `// ----` banners) so Xcode's jump bar shows the sections. Skip it in files with only one group.
- Public API changes need a README update (Features, API Reference, and a usage section).

### Testing
- Run `swift build` and `swift test`. If you hit `plugin for module TestingMacros not found`, that's a toolchain issue, not a code failure; fall back to Xcode or verify statically.
- For changes that could affect platforms, also run `xcodebuild build -scheme TimeLabels -destination generic/platform=<iOS|watchOS|tvOS|visionOS>` (CI does this).

### Spacing contract (must match in any tests you write)
- `expand` and `spellNumber` only choose the **word**; they never add a space. Only the `space` flag inserts a space before the unit. The default is no space. `expand` and `space` are independent and can be combined. This applies to `duration` too; its parts are always separated by a single space.

### Releases
- Versions are plain semver tags without a `v` (`1.1.0`), created by the maintainer on `main` after the PR is squash-merged. Pushing the tag runs `release.yml`, which creates the GitHub Release. Additive changes are a minor bump.
