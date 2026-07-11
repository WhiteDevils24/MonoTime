//
//  MenuBarView.swift
//  MonoTime
//
//  Created by Muhammad Fachrizal Akbar on 06/07/26.
//

import SwiftUI

extension Color {
    /// Shared paused-state color used by the ring and the menu bar label.
    static let paused = Color.yellow
}

/// The content shown in the popover when the menu bar item is clicked.
/// Minimalist monochrome design: black on white (light) / white on black (dark).
struct MenuBarView: View {
    /// The shared timer model that drives everything displayed here.
    @Bindable var timer: PomodoroTimer

    /// Respect the system's Reduce Motion setting by not flashing.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The popover layout, top to bottom: header, dial, transport controls,
    /// session count, and quit.
    var body: some View {
        VStack(spacing: 20) {
            header
            timerRing
            controls
            divider
            sessionInfo
            divider
            quitButton
        }
        .padding(24)
        .frame(width: 260)
    }

    // MARK: - Header

    /// The current phase name, centred between an invisible balancing icon
    /// on the left and the settings gear on the right.
    private var header: some View {
        HStack {
            // Balance the trailing gear button so the title stays centred.
            Image(systemName: "gearshape")
                .font(.system(size: 12, weight: .light))
                .frame(width: 24, height: 24)
                .opacity(0)
                .accessibilityHidden(true)

            Spacer()

            Text(timer.phase.rawValue.uppercased())
                .font(.system(size: 11, weight: .medium))
                .tracking(3)
                .foregroundStyle(.secondary)

            Spacer()

            SettingsLink {
                Image(systemName: "gearshape")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Settings")
            .accessibilityLabel("Settings")
            .simultaneousGesture(TapGesture().onEnded {
                // Menu bar apps are background apps; without activating,
                // the settings window opens behind other windows.
                NSApp.activate(ignoringOtherApps: true)
            })
        }
    }

    // MARK: - Timer ring

    /// The phase was started but is currently interrupted.
    private var isPaused: Bool {
        timer.hasStarted && !timer.isRunning
    }

    /// Width of the ring's background track.
    private let trackWidth: CGFloat = 20
    /// Length of the tick marks; the progress arc matches this thickness.
    private let tickLength: CGFloat = 12

    /// The 150 pt dial: a faint background track, one tick per minute, a
    /// progress arc that sweeps over the ticks, and the remaining time in
    /// the centre. Everything turns yellow and flashes while paused.
    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(.primary.opacity(0.08), lineWidth: trackWidth)
                // Inset so the thick stroke stays within the 150 pt frame.
                .padding(trackWidth / 2)

            tickMarks

            // The arc sweeps over the ticks, covering them as time elapses.
            progressArc

            Text(timer.formattedTime)
                .font(.system(size: 36, weight: .light, design: .default))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(isPaused ? AnyShapeStyle(Color.paused) : AnyShapeStyle(.primary))
        }
        // Flash the ring and time in yellow while paused, unless the user
        // has asked the system to reduce motion.
        .phaseAnimator([1.0, 0.3]) { ring, opacity in
            ring.opacity(isPaused && !reduceMotion ? opacity : 1)
        } animation: { _ in
            .easeInOut(duration: 0.6)
        }
        .frame(width: 150, height: 150)
        // Read the ring as one element instead of 25+ ticks.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(timer.phase.rawValue) timer")
        .accessibilityValue(accessibilityStatus)
    }

    /// VoiceOver summary of the remaining time and running state, e.g.
    /// "24:59 remaining, paused".
    private var accessibilityStatus: String {
        let state = timer.isRunning ? "running" : (timer.hasStarted ? "paused" : "not started")
        return "\(timer.formattedTime) remaining, \(state)"
    }

    /// Smooth progress arc drawn on top of the tick marks.
    private var progressArc: some View {
        Circle()
            .trim(from: 0, to: timer.progress)
            .stroke(
                isPaused ? AnyShapeStyle(Color.paused) : AnyShapeStyle(.primary),
                style: StrokeStyle(lineWidth: tickLength, lineCap: .round)
            )
            .padding(trackWidth / 2)
            .rotationEffect(.degrees(-90))
            .animation(.linear(duration: 0.25), value: timer.progress)
    }

    /// One tick per minute of the current phase, so the ring adapts to the
    /// configured focus / short break / long break durations.
    private var tickCount: Int {
        max(1, timer.totalSeconds / 60)
    }

    /// Ruler-style notch marks drawn on the ring track itself, one per
    /// minute of the current phase. The progress arc covers them as it
    /// sweeps around the ring.
    private var tickMarks: some View {
        ForEach(0..<tickCount, id: \.self) { index in
            Rectangle()
                .fill(isPaused ? AnyShapeStyle(Color.paused) : AnyShapeStyle(.primary))
                .opacity(0.3)
                .frame(width: 2, height: tickLength)
                // Centre each tick on the ring's stroke (radius 65).
                .offset(y: -65)
                .rotationEffect(.degrees(Double(index) / Double(tickCount) * 360))
        }
    }

    // MARK: - Controls

    /// Transport controls: reset the current phase, start/pause (also bound
    /// to the space bar), and skip to the next phase.
    private var controls: some View {
        HStack(spacing: 32) {
            Button {
                timer.resetPhase()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .help("Reset current phase")
            .accessibilityLabel("Reset current phase")

            Button {
                timer.toggle()
            } label: {
                Image(systemName: timer.isRunning ? "pause" : "play")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(.primary)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(.primary.opacity(0.2), lineWidth: 1)
                    )
                    .contentShape(Circle())
            }
            .help(timer.isRunning ? "Pause" : "Start")
            .accessibilityLabel(timer.isRunning ? "Pause" : "Start")
            .keyboardShortcut(.space, modifiers: [])

            Button {
                timer.skip()
            } label: {
                Image(systemName: "forward.end")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .help("Skip to next phase")
            .accessibilityLabel("Skip to next phase")
        }
        .buttonStyle(.plain)
    }

    // MARK: - Session info

    /// How many focus sessions have been completed in the current cycle.
    private var sessionInfo: some View {
        HStack {
            Text("Sessions")
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(timer.completedSessions)")
                .monospacedDigit()
        }
        .font(.system(size: 12))
    }

    // MARK: - Quit

    /// Terminates the app; also bound to ⌘Q while the popover is open.
    private var quitButton: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Text("Quit")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(minWidth: 60, minHeight: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut("q")
        .help("Quit MonoTime (⌘Q)")
        .accessibilityLabel("Quit MonoTime")
    }

    // MARK: - Helpers

    /// A hairline separator matching the popover's muted monochrome style.
    private var divider: some View {
        Rectangle()
            .fill(.primary.opacity(0.08))
            .frame(height: 1)
    }
}

#Preview {
    MenuBarView(timer: PomodoroTimer())
}
