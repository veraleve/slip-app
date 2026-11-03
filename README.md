# Slip — Peer Mistake Inoculation Platform

> **Ask doubts. Learn from mistakes. Master together.**

Slip is an open-source mobile platform designed for competitive STEM and GATE aspirants. Instead of scrolling through generic social feeds or passive flashcards, Slip operates as a decentralized, mistake-first learning network where students inoculate against exam blunders and conceptual traps together.

---

## Key Features & Experience

* **The Feed (`feed_screen.dart`):** Continuous, non-boxy learning ledger inspired by Swiss International Style (Massimo Vignelli, Dieter Rams, Teenage Engineering). Clean typography, hairline rules, zero emoji vanity clutter.
  * **Interactive Action Row:** Left-aligned doubt reactions, comment counters, and cleared status indicators; right-aligned save/bookmark icon.
  * **Deep Post Detail (`post_detail_screen.dart`):** Tap any blunder card to view full conceptual explanations, high-resolution scratchpad photos, audio voice notes, and student discussion threads.
* **Drop Slip (`drop_slip_screen.dart`):** Curved, distraction-free composer to log exam traps or post doubts.
  * Native camera capture for handwritten notes and formulas.
  * Native on-device voice note recording with live timer and audio player.
  * Structured subject taxonomy (GATE CS, DA, EC, ME) and trap classification.
* **Tasks & Revision (`tasks_screen.dart`):** Google Tasks-inspired scheduler with integrated blunder traps.
  * Rendered directly on the canvas without boxy containers.
  * Multi-list sliding tabs (`Starred`, `My Tasks`, custom lists) and due-date tracking.
* **Profile (`profile_screen.dart`):** Full profile screen showcasing shared blunders and cleared inoculations.
  * Reddit-style text-first feed layout prioritizing formulas, traps, and misconceptions.
  * Curved dropdown subject filter and in-place voice note editing.
* **In-App GitHub Self-Updater (`app_update_service.dart`):**
  * Built-in connection to [GitHub Releases](https://github.com/veraleve/slip-app/releases).
  * Check for updates directly inside `Settings > Check for Updates`.
  * Review official release notes and changelogs before choosing to update.
  * Live streaming download progress and one-tap in-place APK installation.
  * **Zero Data Loss Guarantee:** Android updates the package in-place (`PACKAGE_REPLACED`), preserving all local tasks, blunders, preferences, and session data.
* **Offline-First Resilience:**
  * Persistent authentication via `SharedPreferences` (no repeated login prompts upon relaunching the app).
  * Local caching for offline campus study rooms and libraries.

---

## Project Structure

```
slip-app/
├── .github/
│   └── workflows/
│       ├── ci.yml                 # Automated formatting, lint & test gating for PRs
│       └── release.yml            # Automated APK build & GitHub Releases publisher
├── android/                       # Native Android container (FileProvider, APK installer)
│   └── app/src/main/
│       ├── AndroidManifest.xml   # Permissions: REQUEST_INSTALL_PACKAGES, CAMERA, RECORD_AUDIO
│       └── kotlin/.../
│           └── MainActivity.kt    # MethodChannel for audio, camera, and in-place APK installer
├── lib/
│   ├── constants/                 # GATE syllabus taxonomy & network configuration
│   ├── models/                    # Typed models (Slip, TaskItem, Profile, Interaction)
│   ├── providers/                 # Riverpod state managers
│   ├── screens/
│   │   ├── auth_screen.dart       # Centered minimalist auth & BLE mesh entry
│   │   ├── feed_screen.dart       # Main peer mistake & doubt ledger
│   │   ├── drop_slip_screen.dart  # Curved blunder & voice note composer
│   │   ├── tasks_screen.dart      # Canvas-style task scheduler with revision traps
│   │   ├── profile_screen.dart    # Reddit-style text-first profile & blunder archive
│   │   ├── post_detail_screen.dart# Blunder discussions & comment replies
│   │   ├── notifications_screen.dart# Mistake inoculation reminders & alert tray
│   │   ├── settings_screen.dart   # Preferences, syllabus selection & GitHub self-updater
│   │   └── splash_principle_screen.dart # Core inoculation principles intro
│   ├── services/
│   │   ├── app_update_service.dart# GitHub Releases OTA updater & changelog parser
│   │   ├── native_device_service.dart # Platform channel bridge (Audio, Camera, Package Installer)
│   │   └── supabase_service.dart  # Supabase client, mesh fallback, session persistence
│   ├── theme/                     # Swiss typography & monochrome palette
│   ├── widgets/                   # Non-boxy slip cards, audio players, hairline inputs
│   └── main.dart                  # Application entry point & session bootstrap
├── pubspec.yaml
└── README.md
```

---

## Download & Installation

The latest production APK (`slip.apk`) is published with every release on GitHub:

* **Direct Release Downloads:** [GitHub Releases](https://github.com/veraleve/slip-app/releases)
* **In-App Updates:** Once installed, open `Settings > Check for Updates` inside Slip to view the latest changelog and update in-place without losing your data.

---

## Contributing

1. Fork the repository and create your feature branch (`git checkout -b feature/blunder-recommendations`).
2. Adhere strictly to the Swiss Minimalist design principles: zero emojis in UI titles/buttons, clean typography, non-boxy curved surfaces.
3. Ensure the project builds cleanly:
   ```bash
   flutter analyze
   flutter test
   ```
4. Submit a Pull Request targeting `main`. All PRs undergo automated CI verification.
