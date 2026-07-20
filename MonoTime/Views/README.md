# MonoTime

> A minimalist Pomodoro timer for macOS, designed to live in your menu bar.

<p align="center">
  <img src="screenshot.png" alt="MonoTime Screenshot" width="600">
</p>

## Overview

MonoTime is a clean, distraction-free Pomodoro timer that stays out of your way. With a monochrome design and menu bar-only interface, it helps you maintain focus through timed work sessions and breaks.

### Features

- 🎯 **Classic Pomodoro Technique** — 25-minute focus sessions with short and long breaks
- 🖤 **Minimalist Design** — Monochrome interface that adapts to light and dark mode
- ⏱️ **Menu Bar Integration** — Always visible timer without cluttering your screen
- 🎨 **Customizable Durations** — Adjust focus, short break, and long break lengths
- 🔔 **Audio Alerts** — Gentle sound notifications when phases change
- ♿️ **Accessibility First** — Full VoiceOver support and Reduce Motion compatibility
- ⚙️ **Flexible Settings** — Configure sessions, contrast, and launch at login
- 🎹 **Keyboard Shortcuts** — Control your timer without touching the mouse

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon or Intel Mac

## Installation

### Download

1. Download the latest release from the [Releases](../../releases) page
2. Open the downloaded `.dmg` file
3. Drag MonoTime to your Applications folder
4. Launch MonoTime from Applications

### Build from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/MonoTime.git
cd MonoTime

# Open in Xcode
open MonoTime.xcodeproj

# Build and run (⌘R)
```

## Usage

### Basic Controls

- **Start/Pause** — Click the play/pause button or press `Space`
- **Reset** — Click the reset button to restart the current phase
- **Skip** — Click the skip button to move to the next phase
- **Settings** — Click the gear icon to customize durations and preferences

### Menu Bar

The menu bar shows your remaining time in a clean, fixed-width format:
- **Running** — Timer counts down normally
- **Paused** — Flashes yellow to grab your attention
- **High Contrast** — Shows as a filled pill (default)
- **Low Contrast** — Shows as plain text

### Phases

1. **Focus** (25 min default) — Work time with full concentration
2. **Short Break** (5 min default) — Quick rest between focus sessions
3. **Long Break** (15 min default) — Extended break after completing 4 focus sessions

### Settings

Customize your workflow in Settings:

#### Durations
- Focus session length (1–60 minutes)
- Short break length (1–30 minutes)
- Long break length (1–60 minutes)
- Sessions before long break (1–10)

#### Sound
- Adjustable volume for phase-change alerts (0–100%)

#### General
- **Start at login** — Launch MonoTime automatically
- **Menu bar contrast** — Choose between high (filled pill) or low (plain text)
- **Reset all** — Restore default settings and clear session count

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Space` | Start/Pause timer |
| `⌘Q` | Quit MonoTime |
| (Settings window must be focused for keyboard shortcuts) |

## Accessibility

MonoTime is designed with accessibility in mind:

- **VoiceOver** — Full screen reader support with descriptive labels
- **Reduce Motion** — Respects system preferences by disabling flash animations
- **High Contrast** — Large, clear controls with strong visual hierarchy
- **Keyboard Navigation** — All controls accessible via keyboard

## Technical Details

### Built With

- **SwiftUI** — Native macOS interface
- **Observation** — Modern state management with `@Observable`
- **SMAppService** — Login item management
- **NSSound** — Audio playback for alerts

### Architecture

- `PomodoroTimer.swift` — Observable timer model with Pomodoro logic
- `MenuBarView.swift` — Main popover interface with timer ring and controls
- `SettingsView.swift` — Configuration window
- `MonoTimeApp.swift` — App entry point with menu bar integration

### Data Persistence

Settings are saved automatically to `UserDefaults`:
- Sound volume
- Menu bar contrast preference
- Login item status (managed by system)

Timer state (current phase, remaining time, session count) resets when the app quits.

## Philosophy

MonoTime embraces simplicity:

- **No distractions** — Menu bar only, no dock icon or main window
- **Monochrome first** — Clean black and white design
- **Opinionated defaults** — Classic 25/5/15 Pomodoro timing
- **Lightweight** — Fast, native SwiftUI with minimal memory footprint

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by the [Pomodoro Technique®](https://francescocirillo.com/pages/pomodoro-technique) by Francesco Cirillo
- Alert sound: Digital Clock Alarm

## Support

If you find MonoTime useful, consider [buying me a coffee ☕️](https://www.buymeacoffee.com/)!

---

Made with ❤️ by Muhammad Fachrizal Akbar

