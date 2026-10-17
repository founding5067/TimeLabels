# Contributing to TimeLabels

## How to Contribute

We welcome contributions! However, please note:

### Merge Restrictions

- **This repository is public** for reference and educational purposes
- **Only the maintainer can merge pull requests**
- You cannot merge PRs yourself - you must wait for maintainer approval

### Contribution Process

1. **Fork** this repository
2. **Clone** your fork: `git clone https://github.com/YOUR_USERNAME/TimeLabels.git`
3. **Create a branch**: `git checkout -b feature/your-feature-name`
4. **Make your changes** and test thoroughly: `swift build && swift test`
5. **Push to your fork**: `git push origin feature/your-feature-name`
6. **Open a Pull Request** against `founding5067/TimeLabels:main`
7. **Request review** by tagging `@founding5067` in the PR
8. Once approved, the maintainer will merge it

### What We Accept

- ✅ Bug fixes
- ✅ Feature improvements  
- ✅ Documentation improvements
- ✅ Performance optimizations
- ✅ Test additions

### Code Style

- Follow Swift naming conventions
- Add tests for new features
- Include clear descriptions of changes

### Guidelines

- **Commit as often as you like** on your branch. The maintainer squash-merges, so `main` gets one commit per PR and the PR title becomes its message
- **Write a clear PR title:** short, imperative, and specific (e.g. "Add week unit to timeAgo"). The description explains *why*
- **Keep unrelated changes in separate PRs** (a new feature, a refactor, and CI changes should be three PRs)
- **All CI checks must pass**
- **Documentation** must be updated for public API changes

## License

This project is open source and available under the terms of the repository license.

---

**Maintained by:** founding5067
