# AGENTS.md — Developer & AI Agent Guidelines for Slip Mobile

## 1. Project Mission & Core Principle
> **“Learn from others’ mistakes too. You won't have time to make them all yourself before the exam.”**

**Slip** is an open-source peer mistake-inoculation ecosystem for STEM and GATE aspirants across all examination years. Instead of passive flashcards, it indexes cognitive blunders, calculation traps, and misconceptions into personalized review cycles, offline local storage, and peer mesh networks.

---

## 2. Directory Structure & Modular Architecture

```
lib/
├── constants/
│   ├── app_constants.dart          # Configuration, Supabase endpoints, app metadata
│   └── gate_syllabus.dart          # Universal GATE Syllabi (GATE CS, GATE DA, GATE EC, GATE EE)
├── models/
│   ├── slip.dart                   # Core blunder slip model (public/private, comments toggle, author handle)
│   ├── profile.dart                # User profile model with multi-paper tracking
│   ├── comment.dart                # Peer discussion comment model
│   └── task_item.dart              # Google Tasks style task/mock test model with topic blunder linkage
├── services/
│   ├── supabase_service.dart       # Supabase client, local-first offline cache, paper filters
│   ├── native_device_service.dart  # Native Android bridge (Camera, Notifications, Permissions)
│   └── mock_data_service.dart      # Syllabus-accurate offline test slips
├── providers/
│   └── slip_provider.dart          # State management: offline slips, tasks, recommendation engine
├── screens/
│   ├── splash_principle_screen.dart# Centered minimalist emblem & principle on launch
│   ├── auth_screen.dart            # 1-tap anonymous BLE mesh entry & multi-paper selector
│   ├── stream_screen.dart          # In-app notifications bell, FOR YOU default, Filter sheet, dual streams
│   ├── drop_slip_screen.dart       # Voice recording, camera, public vs private, comments toggle, tick modal
│   ├── tasks_screen.dart           # Google Tasks / Nyro Tasks style test scheduler with linked blunder checklist
│   ├── profile_screen.dart         # Instagram-style tabs (Shared, Cleared, Saved), grid/feed, pencil edit & delete
│   └── settings_screen.dart        # Instagram gear hub: alerts schedule, permissions, paper manager, sign-out
├── widgets/
│   ├── slip_card.dart              # Peer handle, public/private badge, Instagram action row & peer profile sheet
│   ├── image_gallery_grid.dart     # LinkedIn-style multi-image collage with full-screen lightbox
│   ├── comment_thread_sheet.dart   # Toggleable discussion thread (hybrid online/mesh)
│   ├── audio_waveform_strip.dart   # Audio autopsy playback strip
│   ├── hairline_input.dart         # Google Tasks non-boxy hairline text inputs
│   └── nav_dock.dart               # Floating bottom navigation dock (Stream, Drop, Tasks, Profile)
└── theme/
    └── slip_theme.dart             # Swiss minimalist palette (Carbon #1F1F1F, Surface #F8F9FA)
```

---

## 3. Strict Architectural Rules

### 3.1 Universal Exam Papers & Strict Isolation
Exam papers must be universal across preparation years:
- `GATE CS` (Computer Science & Information Technology)
- `GATE DA` (Data Science & Artificial Intelligence)
- `GATE EC` (Electronics & Communication Engineering)
- `GATE EE` (Electrical Engineering)
Students preparing for `GATE CS` or `GATE DA` must **never** see slips from `GATE EC` or `GATE EE` (and vice versa). All queries, stream lists, and recommendation feeds must filter using:
```dart
query.inFilter('exam_tag', userAllowedPapers)
```

### 3.2 Offline-First Local Storage
- User's dropped mistakes and tasks are saved directly into on-device local storage (`SharedPreferences` / SQLite / JSON cache).
- Private blunders (`isPublic: false`) are saved strictly on device and never broadcast to the cloud or peers.
- Only the peer blunder feed and embedding recommendation model connect to the network.

### 3.3 Zero Emoji & Clean Typography Rule
- **No emojis** anywhere in UI copy, buttons, or code comments.
- Use only clean vector stroke icons (`Icons.*`).
- Typography is strictly **Roboto** (Google Tasks font family) with clean weights (`w400`, `w500`, `w700`, `w800`).

### 3.4 Navigation Dock Contract (4 Clean Tabs)
1. `STREAM` (`Icons.dynamic_feed_rounded`)
2. `DROP` (`Icons.add_circle_outline_rounded`)
3. `TASKS` (`Icons.task_alt_rounded`)
4. `PROFILE` (`Icons.person_outline_rounded`)
All system settings, alert schedules, and sign-out controls reside inside `SettingsScreen`, opened via the gear icon in `ProfileScreen`.

---

## 4. Contributing & Pull Requests
1. All changes must pass `flutter analyze` without warnings.
2. PR titles must follow semantic commit format: `feat(tasks): google-tasks scheduler with blunder checklist` or `feat(profile): instagram-style swipable grid`.
3. Never bypass access controls or store hardcoded secrets.
