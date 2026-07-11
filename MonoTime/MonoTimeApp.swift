//
//  MonoTimeApp.swift
//  MonoTime
//
//  Created by Muhammad Fachrizal Akbar on 06/07/26.
//

import SwiftUI

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
    }
}

/// The menu bar title: just the time, no icon, at a fixed width so it never
/// shifts as the digits change.
///
/// Rendered to an `NSImage` because the menu bar strips colors from plain
/// SwiftUI labels. Idle and running states are template images (they adapt
/// to the menu bar's light/dark appearance); the paused state keeps its own
/// amber color and flashes.
private struct MenuBarLabel: View {
    var timer: PomodoroTimer

    /// Paused flash color: yellow pushed a little toward orange.
    private static let pausedColor = Color(red: 1.0, green: 0.72, blue: 0.15)

    /// Fixed label size so the menu bar item width stays constant.
    private static let labelSize = CGSize(width: 46, height: 18)

    var body: some View {
        Image(nsImage: renderedLabel())
    }

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

    @ViewBuilder
    private func labelContent(isPaused: Bool) -> some View {
        ZStack {
            if timer.hasStarted {
                // Filled pill with the time knocked out (inverted).
                RoundedRectangle(cornerRadius: 4)
                    .fill(isPaused ? Self.pausedColor : Color.black)
                    .opacity(isPaused && !timer.blinkOn ? 0.35 : 1)

                timeText
                    .blendMode(.destinationOut)
            } else {
                // Not started yet: plain text on a blank background.
                timeText
                    .foregroundStyle(.black)
            }
        }
        .compositingGroup()
        .frame(width: Self.labelSize.width, height: Self.labelSize.height)
    }

    private var timeText: some View {
        Text(timer.formattedTime)
            .font(.system(size: 12, weight: .medium))
            .monospacedDigit()
    }
}
