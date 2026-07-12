//
//  MonoTimeApp.swift
//  MonoTime
//
//  Created by Muhammad Fachrizal Akbar on 06/07/26.
//

import SwiftUI

/// The app entry point: a menu bar-only Pomodoro timer.
///
/// MonoTime has no dock icon or main window — just a menu bar item whose
/// label shows the remaining time, a popover with the timer controls
/// (``MenuBarView``), and a standard settings window (``SettingsView``).
@main
struct MonoTimeApp: App {
    /// Shared timer model that lives for the app's lifetime.
    @State private var timer = PomodoroTimer()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(timer: timer)
        } label: {
            MenuBarLabel(timer: timer)
        }
        // `.window` gives us a rich SwiftUI popover instead of a plain menu.
        .menuBarExtraStyle(.window)

        // Separate settings window, opened from the popover's gear button.
        Settings {
            SettingsView(timer: timer)
        }
    }
}

/// The menu bar title: just the time, no icon, at a fixed width so it never
/// shifts as the digits change.
///
/// Rendered to an `NSImage` because the menu bar strips colors from plain
/// SwiftUI labels. Idle and running states are template images (they adapt
/// to the menu bar's light/dark appearance); the paused state keeps its own
/// amber color.
private struct MenuBarLabel: View {
    /// The shared timer model providing the time and state to display.
    var timer: PomodoroTimer

    /// Fixed label size so the menu bar item width stays constant.
    private static let labelSize = CGSize(width: 46, height: 18)

    var body: some View {
        Image(nsImage: renderedLabel())
            .accessibilityLabel(accessibilityDescription)
    }

    /// VoiceOver description of the menu bar item, e.g.
    /// "MonoTime, 24:59 remaining, running".
    private var accessibilityDescription: String {
        let state = timer.isRunning ? "running" : (timer.hasStarted ? "paused" : "not started")
        return "MonoTime, \(timer.formattedTime) remaining, \(state)"
    }

    /// Renders the label content into a retina `NSImage`.
    ///
    /// - Returns: A template image for the idle and running states (so the
    ///   system tints it to match the menu bar), or a colored image while
    ///   paused to preserve the yellow.
    private func renderedLabel() -> NSImage {
        let isPaused = timer.hasStarted && !timer.isRunning

        let renderer = ImageRenderer(content: labelContent(isPaused: isPaused))
        renderer.scale = 2
        let image = renderer.nsImage ?? NSImage()
        // Template images get tinted by the system to match the menu bar;
        // the paused state opts out to keep its amber color.
        image.isTemplate = !isPaused
        return image
    }

    /// The SwiftUI content captured into the label image: a filled pill
    /// with knocked-out digits in high contrast, or plain text otherwise.
    ///
    /// - Parameter isPaused: Whether the timer is started but not running,
    ///   which switches the color to the shared paused yellow.
    @ViewBuilder
    private func labelContent(isPaused: Bool) -> some View {
        ZStack {
            if timer.hasStarted && timer.menuBarContrast == .high {
                // Filled pill with the time knocked out (inverted).
                RoundedRectangle(cornerRadius: 4)
                    .fill(isPaused ? Color.paused : Color.black)

                timeText
                    .blendMode(.destinationOut)
            } else {
                // Plain text: idle state, or low contrast while started.
                timeText
                    .foregroundStyle(isPaused ? Color.paused : Color.black)
            }
        }
        .compositingGroup()
        .frame(width: Self.labelSize.width, height: Self.labelSize.height)
    }

    /// The remaining time in a small, fixed-width (monospaced digit) font.
    private var timeText: some View {
        Text(timer.formattedTime)
            .font(.system(size: 12, weight: .medium))
            .monospacedDigit()
    }
}
