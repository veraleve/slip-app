# Slip — Peer Mistake Inoculation Platform

> **Learn from others' blunders before the exam does.**

Slip is an open-source, non-boxy mobile platform designed for competitive STEM and GATE aspirants. Instead of scrolling through generic social feeds or passive flashcards, Slip operates as a decentralized, telemetry-driven mistake recommendation engine.

---

## Architectural Highlights

* **The Stream:** Continuous, non-boxy mistake ledger inspired by Swiss International Style (Massimo Vignelli, Dieter Rams, Teenage Engineering). Zero emojis, clean typography, hairline baseline rules.
* **4-Second Core Loop:**
  * `Same` — Social proof reaction indicating "I fell for this exact trap too" (powers the recommendation algorithm).
  * `The Fix` — Seamless toggle revealing the mathematical truth and core misconception.
  * `Keep` — Save into your personal pre-exam revision notebook.
  * `Pass` — Share to classmates or peers across local Bluetooth mesh.
* **Offline-First & Mesh Ready:** Built to interoperate with local BLE Mesh (BitChat protocol) in university libraries and campus hostels, backed by Supabase with `pgvector` dense concept embeddings.
* **Continuous Kaggle CPU Inference:** 24/7 background recommendation generation without exhausting weekly GPU quotas.

---

## Project Structure

```
slip-app/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                 # Automated lint & test gating for PRs
│   │   ├── release.yml            # Automated APK build & GitHub Releases publisher
│   │   └── pr-label-check.yml     # Mandatory PR label verification
│   └── pull_request_template.md
├── android/                       # Native Android container
├── lib/
│   ├── constants/                 # Network & styling constants
│   ├── models/                    # Typed data models (Slip, Profile, Interaction)
│   ├── providers/                 # Riverpod state managers
│   ├── screens/                   # Auth, Stream, Drop Slip, Profile, Settings
│   ├── services/                  # Supabase & mock data fallback services
│   ├── theme/                     # Swiss typography & palette definition
│   ├── widgets/                   # Hairline inputs, audio waveforms, navigation dock
│   └── main.dart                  # Application entry point
├── test/                          # Unit and widget test suite
├── CONTRIBUTING.md
└── pubspec.yaml
```

---

## Contributing & Releases

Please review [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request. Direct pushes to `main` are restricted.

To download the latest compiled Android APK, visit [Releases](https://github.com/veraleve/slip-app/releases).
