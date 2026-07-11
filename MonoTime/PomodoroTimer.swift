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
enum PomodoroPhase: String {
    case work = "Focus"
    case shortBreak = "Short Break"
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

/// Observable model that drives a classic Pomodoro cycle: several focus
/// sessions separated by short breaks, followed by a longer break.
@Observable
final class PomodoroTimer {

    // MARK: - Configuration (in minutes)

    /// Length of a focus session.
    var workMinutes: Int = 25
    /// Length of a short break between focus sessions.
    var shortBreakMinutes: Int = 5
    /// Length of the long break after a full set of focus sessions.
    var longBreakMinutes: Int = 15
    /// How many focus sessions to complete before a long break.
    var sessionsBeforeLongBreak: Int = 4

    // MARK: - State

    /// The interval currently being counted down.
    private(set) var phase: PomodoroPhase = .work
    /// Seconds remaining in the current phase.
    private(set) var remainingSeconds: Int = 25 * 60
    /// Whether the countdown is actively running.
    private(set) var isRunning: Bool = false
    /// Number of focus sessions finished in the current cycle.
    private(set) var completedSessions: Int = 0

    // MARK: - Private

    private var timer: Timer?

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
        remainingSeconds = durationSeconds(for: phase)
    }

    /// Resets the entire cycle back to the first focus session.
    func resetAll() {
        pause()
        phase = .work
        completedSessions = 0
        remainingSeconds = durationSeconds(for: phase)
    }

    /// Immediately finishes the current phase and moves to the next one.
    func skip() {
        advanceToNextPhase()
    }

    // MARK: - Private helpers

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

        remainingSeconds = durationSeconds(for: phase)
        notifyPhaseChange()

        // Auto-continue into the next phase if the timer was running.
        if wasRunning {
            start()
        }
    }

    private func durationSeconds(for phase: PomodoroPhase) -> Int {
        switch phase {
        case .work: return workMinutes * 60
        case .shortBreak: return shortBreakMinutes * 60
        case .longBreak: return longBreakMinutes * 60
        }
    }

    /// Plays a sound so the user notices the phase change even without looking.
    private func notifyPhaseChange() {
        NSSound(named: "Glass")?.play()
    }
}
