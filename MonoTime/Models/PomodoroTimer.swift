//
//  PomodoroTimer.swift
//  MonoTime
//
//  Created by Muhammad Fachrizal Akbar on 06/07/26.
//

import Foundation
import Observation
import AppKit

/// The kind of interval the timer is currently counting down.
///
/// The raw value doubles as the user-facing name shown in the popover header.
enum PomodoroPhase: String {
    /// A focus session where the user works.
    case work = "Focus"
    /// A brief rest between focus sessions.
    case shortBreak = "Short Break"
    /// An extended rest after completing a full set of focus sessions.
    case longBreak = "Long Break"

    /// SF Symbol used to represent the phase in the UI.
    var symbolName: String {
        switch self {
        case .work: return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer"
        case .longBreak: return "figure.walk"
        }
    }
}

/// How strongly the menu bar timer stands out while running.
enum MenuBarContrast: String, CaseIterable, Identifiable {
    /// Filled pill with inverted digits.
    case high = "High"
    /// Plain text, like other menu bar items.
    case low = "Low"

    /// Stable identity for SwiftUI pickers; the raw value is unique.
    var id: String { rawValue }
}

/// Observable model that drives a classic Pomodoro cycle: several focus
/// sessions separated by short breaks, followed by a longer break.
///
/// A single shared instance is created by ``MonoTimeApp`` and passed to the
/// popover, the menu bar label, and the settings window. Sound and menu bar
/// preferences persist across launches via `UserDefaults`; durations reset
/// with ``resetAll()``.
@Observable
final class PomodoroTimer {

    // MARK: - Defaults

    /// Default focus session length, in minutes.
    private static let defaultWorkMinutes = 25
    /// Default short break length, in minutes.
    private static let defaultShortBreakMinutes = 5
    /// Default long break length, in minutes.
    private static let defaultLongBreakMinutes = 15
    /// Default number of focus sessions before a long break.
    private static let defaultSessionsBeforeLongBreak = 4
    /// Default alert volume, 0...1.
    private static let defaultSoundVolume = 0.8
    /// Bundled alert sound resource played when a phase ends.
    private static let alertSoundResource = "DigitalClockAlarm"

    // MARK: - Configuration (in minutes)

    /// Length of a focus session.
    var workMinutes: Int = PomodoroTimer.defaultWorkMinutes
    /// Length of a short break between focus sessions.
    var shortBreakMinutes: Int = PomodoroTimer.defaultShortBreakMinutes
    /// Length of the long break after a full set of focus sessions.
    var longBreakMinutes: Int = PomodoroTimer.defaultLongBreakMinutes
    /// How many focus sessions to complete before a long break.
    var sessionsBeforeLongBreak: Int = PomodoroTimer.defaultSessionsBeforeLongBreak

    // MARK: - Preferences (persisted)

    /// Volume of the phase-change sound, 0...1.
    var soundVolume: Double = UserDefaults.standard.object(forKey: "soundVolume") as? Double ?? PomodoroTimer.defaultSoundVolume {
        didSet { UserDefaults.standard.set(soundVolume, forKey: "soundVolume") }
    }

    /// How strongly the menu bar timer stands out while running.
    var menuBarContrast: MenuBarContrast = MenuBarContrast(rawValue: UserDefaults.standard.string(forKey: "menuBarContrast") ?? "") ?? .high {
        didSet { UserDefaults.standard.set(menuBarContrast.rawValue, forKey: "menuBarContrast") }
    }

    // MARK: - State

    /// The interval currently being counted down.
    private(set) var phase: PomodoroPhase = .work
    /// Seconds remaining in the current phase.
    private(set) var remainingSeconds: Int = 25 * 60
    /// Whether the countdown is actively running.
    private(set) var isRunning: Bool = false
    /// Whether the current phase has been started at least once.
    /// False when the timer is fresh, was reset, or just moved to a new phase.
    private(set) var hasStarted: Bool = false
    /// Number of focus sessions finished in the current cycle.
    private(set) var completedSessions: Int = 0

    // MARK: - Private

    /// Fires once per second while running; nil whenever the timer is paused.
    private var timer: Timer?
    /// Keeps the alert sound alive while it plays; NSSound stops if released.
    private var alertSound: NSSound?

    // MARK: - Derived values

    /// Total number of seconds in the current phase.
    var totalSeconds: Int {
        durationSeconds(for: phase)
    }

    /// Progress from 0 (just started) to 1 (finished) for the current phase.
    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    /// Remaining time formatted as `MM:SS`.
    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Controls

    /// Starts or resumes the countdown.
    func start() {
        guard !isRunning else { return }
        isRunning = true
        hasStarted = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        // Keep the timer firing while menus/tracking loops are active.
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    /// Pauses the countdown, keeping the remaining time.
    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    /// Toggles between running and paused.
    func toggle() {
        isRunning ? pause() : start()
    }

    /// Resets the current phase back to its full duration.
    func resetPhase() {
        pause()
        hasStarted = false
        remainingSeconds = durationSeconds(for: phase)
    }

    /// Resets the timer and session count back to the first focus session,
    /// leaving all settings untouched.
    func resetSessions() {
        pause()
        hasStarted = false
        phase = .work
        completedSessions = 0
        remainingSeconds = durationSeconds(for: phase)
    }

    /// Resets the entire cycle back to the first focus session and restores
    /// all settings to their defaults.
    func resetAll() {
        workMinutes = Self.defaultWorkMinutes
        shortBreakMinutes = Self.defaultShortBreakMinutes
        longBreakMinutes = Self.defaultLongBreakMinutes
        sessionsBeforeLongBreak = Self.defaultSessionsBeforeLongBreak
        soundVolume = Self.defaultSoundVolume
        resetSessions()
    }

    /// Immediately finishes the current phase and moves to the next one.
    func skip() {
        advanceToNextPhase()
    }

    // MARK: - Private helpers

    /// Advances the countdown by one second, moving to the next phase when
    /// the current one runs out.
    private func tick() {
        guard remainingSeconds > 0 else {
            advanceToNextPhase()
            return
        }
        remainingSeconds -= 1
        if remainingSeconds == 0 {
            advanceToNextPhase()
        }
    }

    /// Moves to the next phase in the Pomodoro cycle and notifies the user.
    ///
    /// After a focus session, picks a long break every
    /// ``sessionsBeforeLongBreak`` sessions and a short break otherwise;
    /// after any break, returns to focus. If the timer was running it keeps
    /// running into the new phase.
    private func advanceToNextPhase() {
        let wasRunning = isRunning
        pause()

        switch phase {
        case .work:
            completedSessions += 1
            if completedSessions % sessionsBeforeLongBreak == 0 {
                phase = .longBreak
            } else {
                phase = .shortBreak
            }
        case .shortBreak, .longBreak:
            phase = .work
        }

        // The new phase is fresh until it is started (below or manually).
        hasStarted = false
        remainingSeconds = durationSeconds(for: phase)
        notifyPhaseChange()

        // Auto-continue into the next phase if the timer was running.
        if wasRunning {
            start()
        }
    }

    /// The configured full duration of a phase.
    ///
    /// - Parameter phase: The phase to look up.
    /// - Returns: The phase's length in seconds, derived from the
    ///   user-configurable minute settings.
    private func durationSeconds(for phase: PomodoroPhase) -> Int {
        switch phase {
        case .work: return workMinutes * 60
        case .shortBreak: return shortBreakMinutes * 60
        case .longBreak: return longBreakMinutes * 60
        }
    }

    /// Plays the bundled alert so the user notices the phase change even
    /// without looking.
    private func notifyPhaseChange() {
        guard let url = Bundle.main.url(forResource: Self.alertSoundResource, withExtension: "mp3"),
              let sound = NSSound(contentsOf: url, byReference: true) else { return }
        sound.volume = Float(soundVolume)
        alertSound = sound
        sound.play()
    }
}
