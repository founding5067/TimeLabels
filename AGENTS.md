# Agent Instructions

- **Never run git commit / push.** The user is the sole authority on commits.
- You may safely run read-only and local commands: `git status`, `git diff`, `git log`, file reads/writes, builds, and tests.
- Before finishing work, summarize what you changed and ask the user for a go-ahead before committing.

### Testing
- `swift test` may fail to build in this environment because the `TestingMacros` plugin (required by swift-testing) is not discoverable on the command-line toolchain — it lives in a `testing/` subdir, so SwiftPM does not auto-load it. The suite builds and passes in Xcode / your environment. Do **not** treat a `plugin for module TestingMacros not found` error as a code failure. Verify coverage by reading the source and tests statically instead of relying on `swift test`.

### Spacing contract (must match in any tests you write)
- `expand` and `spellNumber` only choose the **word**; they never add a space. Only the `space` flag inserts a space before the unit. The default is no space. `expand` and `space` are independent and can be combined.
