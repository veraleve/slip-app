# AGENTS.md — Developer & AI Agent Guidelines for Slip Mobile

## 1. Project Mission & Core Principle
> **“Learn from others’ mistakes too. You won't have time to make them all yourself before GATE 2027.”**

**Slip** is an open-source peer mistake-inoculation ecosystem for STEM and GATE aspirants. Instead of passive flashcards, it indexes cognitive blunders, calculation traps, and misconceptions into personalized review cycles and offline peer mesh networks.

---

## 2. Directory Structure & Modular Architecture

```
lib/
├── constants/
│   ├── app_constants.dart          # Configuration, Supabase endpoints, app metadata
│   └── gate_syllabus.dart          # Canonical IIT Madras GATE 2027 Syllabi (CS, DA, EC, EE)
├── models/
│   ├── slip.dart                   # Core blunder slip model with multi-image support
│   ├── profile.dart                # User profile model with multi-paper tracking
│   └── comment.dart                # Peer discussion comment model
├── services/
│   ├── supabase_service.dart       # Supabase pgvector client, auth fallback & paper filters
│   ├── native_device_service.dart  # Native Android bridge (Camera, Notifications, Permissions)
│   └── mock_data_service.dart      # Syllabus-accurate offline test slips
├── providers/
│   └── slip_provider.dart          # Riverpod/ChangeNotifier state for streams & reactions
├── screens/
│   ├── splash_principle_screen.dart# Principle splash on launch
│   ├── auth_screen.dart            # 1-tap anonymous BLE mesh entry & multi-paper selector
│   ├── stream_screen.dart          # Dual-Stream: My Review Cycle & Peer Feed
│   ├── drop_slip_screen.dart       # Hierarchical Dept/Subject/Topic logger with camera
│   ├── notifications_screen.dart   # Inoculation digests, peer mesh alerts & schedule
│   ├── profile_screen.dart         # Living stats, registered paper manager, permissions
│   └── settings_screen.dart        # Campus BLE mesh toggle, offline caching & sign-out
├── widgets/
│   ├── slip_card.dart              # Instagram-style icon actions (Same, Save, Solve, Comment, Share)
│   ├── image_gallery_grid.dart     # LinkedIn-style multi-image collage with full-screen lightbox
│   ├── comment_thread_sheet.dart   # Toggleable discussion thread (hybrid online/mesh)
│   ├── audio_waveform_strip.dart   # Audio autopsy playback strip
│   ├── hairline_input.dart         # Google Tasks non-boxy hairline text inputs
│   └── nav_dock.dart               # Floating bottom navigation dock
└── theme/
    └── slip_theme.dart             # Swiss minimalist palette (Carbon #1F1F1F, Surface #F8F9FA)
```

---

## 3. Strict Architectural Rules

### 3.1 Strict Paper Isolation
Students preparing for `GATE CS 2027` or `GATE DA 2027` must **never** see slips from `GATE EC 2027` or `GATE EE 2027` (and vice versa). All queries, stream lists, and recommendation feeds must filter using:
```dart
query.inFilter('exam_tag', userAllowedPapers)
```

### 3.2 Canonical Syllabus Taxonomy
Never allow free-form subject typing. All dropdowns and dense vector prompts must use the canonical taxonomy defined in `gate_syllabus.dart`:
- `GATE CS 2027` (13 Subjects)
- `GATE DA 2027` (7 Subjects)
- `GATE EC 2027` (8 Subjects)
- `GATE EE 2027` (10 Subjects)

### 3.3 Zero Emoji & Clean Typography Rule
- **No emojis** anywhere in UI copy, buttons, or code comments.
- Use only clean vector stroke icons (`Icons.*`).
- Typography is strictly **Roboto** (Google Tasks font family) with clean weights (`w400`, `w500`, `w700`, `w800`).

### 3.4 Instagram-Style Icon Action Row
Action bars on `SlipCard` must not use long textual buttons. Use clean icons:
1. `Icons.warning_amber_rounded` / `Icons.warning_rounded`: Same ("I fell for this too") with numeric count.
2. `Icons.bookmark_border_rounded` / `Icons.bookmark_rounded`: Save to My Review Cycle.
3. `Icons.check_circle_outline_rounded` / `Icons.check_circle_rounded`: Mark as Solved / Mastered (moves to Solved Archive).
4. `Icons.chat_bubble_outline_rounded` / `Icons.chat_bubble_rounded`: Toggle discussion comments (off by default).
5. `Icons.bluetooth_audio_rounded`: Broadcast blunder to campus peers via BLE Mesh.

### 3.5 Native Device Bridge (No Fragile Plugins)
All camera captures, native Android notifications, and runtime permissions (`CAMERA`, `POST_NOTIFICATIONS`, `BLUETOOTH_SCAN`) are handled directly via native Kotlin in `MainActivity.kt` over `MethodChannel("com.veraleve.slip/native")`.

---

## 4. Contributing & Pull Requests
1. All changes must pass `flutter analyze` without warnings.
2. PR titles must follow semantic commit format: `feat(stream): dual-cycle layout` or `fix(auth): multi-paper persistence`.
3. Never bypass access controls or store hardcoded secrets.
