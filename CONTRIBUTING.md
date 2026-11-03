# Contributing to Slip

Thank you for your interest in contributing to **Slip**! We are building a revolutionary, open-source peer learning platform where students learn from each other's exam blunders.

---

## 1. Code of Conduct & Design Philosophy

Slip adheres to a strict, world-class design standard:
* **Radical Minimalism:** Dieter Rams / Teenage Engineering / Linear design language.
* **Strictly ZERO Emojis:** Never use emojis in code, UI copy, buttons, or error messages. Use hairline vector stroke icons or monospaced notation.
* **Non-Boxy Architecture:** Avoid wrapping content in heavy card boxes or drop-shadow containers. Rely on white space, typography, and hairline datum lines.
* **Modular Architecture:** All components must be decoupled, typed, and well-tested.

---

## 2. Pull Request Workflow

Direct pushes to the `main` branch are disabled. All contributions must be submitted via a Pull Request.

### PR Requirements
1. **Branch Naming:**
   * Feature: `feat/feature-name`
   * Bug fix: `fix/bug-name`
   * UI refinement: `ui/screen-name`
   * Exam Trap: `trap/gate-topic-name`

2. **Mandatory PR Labels:**
   Every PR must have at least **one** of the following labels to pass automated CI:
   * `feat` — New feature or capability
   * `fix` — Bug fix or error correction
   * `ui` — Swiss typography, non-boxy UI enhancements
   * `slip-trap` — Real, verified GATE exam traps & conceptual blunders
   * `docs` — Documentation updates
   * `chore` — Dependency updates or build tooling

3. **Automated CI Checks:**
   All PRs automatically trigger:
   * `flutter analyze`: Must pass with 0 errors and 0 warnings.
   * `flutter test`: All unit and widget tests must pass.

---

## 3. Local Development Setup

```bash
# 1. Clone the repository
git clone https://github.com/veraleve/slip-app.git
cd slip-app

# 2. Install Flutter dependencies
flutter pub get

# 3. Run analysis
flutter analyze

# 4. Run tests
flutter test

# 5. Launch the application
flutter run
```

---

## 4. Releasing New Versions

Tagging a commit with `v*` (e.g. `git tag v0.1.0 && git push origin v0.1.0`) triggers the automated **GitHub Actions Release Workflow**, which builds `app-release.apk` and publishes it to GitHub Releases.
