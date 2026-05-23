# Onedayday — Make Every Day Count / 让每一天都有迹可循

**Onedayday** is a native macOS task management app built around the **Eisenhower Matrix** (urgent/important quadrant method). It helps you capture thoughts, prioritize effectively, and stay focused — all from a polished, offline-first Mac experience.

<p align="center">
  <img src="LOGO.png" width="128" alt="Onedayday logo">
</p>

---

## ✨ Features

### Core — Eisenhower Quadrants
- **Q1 — Important & Urgent:** Do first
- **Q2 — Important & Not Urgent:** Schedule
- **Q3 — Not Important & Urgent:** Delegate
- **Q4 — Not Important & Not Urgent:** Eliminate
- Tasks are color-coded and sorted by priority across all quadrants

### Calendar & Timeline
- **Custom month calendar** with quadrant presence dots (4 colored dots per day)
- **Hour-by-hour timeline** (00:00–23:59) — drag tasks from the quadrants to assign time slots
- **Resizable time blocks** with 5-minute snap, day navigation, and a "now" indicator line

### Inbox / Quick Capture
- Date-less inbox for dumping thoughts quickly
- `Cmd+Shift+N` hotkey to capture instantly
- Drag items from the inbox into quadrants or the timeline

### Pomodoro Timer
- Sidebar timer with 15m / 25m / 45m / 60m presets
- **Fullscreen Focus Mode** — overlay for a single task with a countdown ring
- Motivational messages on completion

### Contribution Heatmap
- GitHub-style heatmap showing daily completed task count (past ~380 days)
- Hover popovers with count, date, and dopamine messages
- Summary stats: total completed, active days, best day, average per day

### Menu Bar Extra
- Quick task completion toggle from the macOS menu bar
- Today's task overview at a glance

### Spotlight Integration
- Index tasks via Core Spotlight — find them with `Cmd+Space`
- Click a search result to jump directly to the task

### Templates & Devices
- Reusable task templates with name, priority, device, description, and duration
- Custom device tags (Computer, Phone, Tablet, Watch, Notebook) with SF Symbols

### Settings & Customisation
- 4 language support: 中文 / English / Français / 日本語
- System / Light / Dark appearance modes
- Customisable keyboard shortcuts
- Device and template management

### Privacy-First
- **100% local** — all data stored in `~/Documents/Onedayday_Data/`
- **No network requests** — no analytics, no tracking, no ads
- Your data stays on your machine, period

---

## 🧱 Tech Stack

| | SwiftUI (primary) | Python (alternative) |
|---|---|---|
| Language | Swift 5 | Python 3 |
| UI | SwiftUI (macOS 13+) | CustomTkinter (dark mode) |
| Architecture | MVVM + `@EnvironmentObject` | Monolithic |
| Persistence | JSON (App Group + Documents) | JSON |
| OS Integration | Spotlight, MenuBarExtra, Haptics | `subprocess.open` |
| Build | Xcode | PyInstaller |

---

## 🚀 Getting Started

### SwiftUI App (Recommended)
1. Open `Onedayday.xcodeproj` in Xcode 15+
2. Select the **Onedayday** scheme → **My Mac**
3. Build & Run (`Cmd+R`)

### Python Alternative
```bash
pip install customtkinter
python3 app.py
```

To bundle as a standalone `.app`:
```bash
pyinstaller app.spec
open dist/app.app
```

---

## 📂 Project Structure

```
Onedayday/
├── Onedayday/                   # SwiftUI native macOS app
│   ├── OnedaydayApp.swift       # @main entry point (Window + MenuBarExtra)
│   ├── Models/
│   │   ├── TodoItem.swift       # Core task data model
│   │   ├── DeviceConfig.swift   # Device configuration
│   │   └── TaskTemplate.swift   # Task template model
│   ├── ViewModels/
│   │   ├── TodoViewModel.swift  # Task CRUD, timeline, heatmap, spotlight
│   │   ├── SettingsViewModel.swift  # Devices & templates persistence
│   │   └── LocalizationManager.swift  # zh/en/fr/ja string tables
│   ├── Services/
│   │   └── SpotlightIndexer.swift   # Core Spotlight indexing
│   └── Views/
│       ├── ContentView.swift        # Main window layout
│       ├── QuadrantPanel.swift      # Eisenhower quadrant (1 of 4)
│       ├── TaskRowView.swift        # Task row with hover actions
│       ├── AddTaskSheet.swift       # Unified add/edit task form
│       ├── CustomCalendarView.swift # Custom month calendar
│       ├── TimelinePanel.swift      # Daily timeline
│       ├── TimeBlockView.swift      # Timeline block with drag-resize
│       ├── HeatmapView.swift        # Contribution heatmap
│       ├── FocusModeView.swift      # Fullscreen Pomodoro overlay
│       ├── MenuBarView.swift        # Menu bar extra popover
│       ├── InboxView.swift          # Inbox/quick capture
│       ├── HeaderView.swift         # Date header with progress ring
│       ├── SettingsGear.swift       # Settings gear icon
│       └── Settings/
│           └── SettingsView.swift   # 4-tab settings panel
├── app.py                       # Python/CustomTkinter alternative
├── app.spec                     # PyInstaller spec for app.py
├── LOGO.png                     # App logo
└── PrivacyInfo.xcprivacy        # Apple privacy manifest
```

---

## 🌍 Localization

Onedayday supports 4 languages, contributed and maintained in a single string-table file per language inside `LocalizationManager.swift`:

- **zh** — 中文（默认）
- **en** — English
- **fr** — Français
- **ja** — 日本語

The UI updates instantly when you switch languages in Settings.

---

## 📄 License

This project is open source. See the privacy policy within the app for contact details.

---

**Onedayday v1.0** — *Make every day count.*
