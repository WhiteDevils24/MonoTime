//
//  MenuBarView.swift
//  MonoTime
//
//  Created by Muhammad Fachrizal Akbar on 06/07/26.
//

import SwiftUI

/// The content shown in the popover when the menu bar item is clicked.
/// Minimalist monochrome design: black on white (light) / white on black (dark).
struct MenuBarView: View {
    @Bindable var timer: PomodoroTimer

    var body: some View {
        VStack(spacing: 20) {
            header
            timerRing
            controls
            divider
            sessionInfo
            settings
            divider
            quitButton
        }
        .padding(24)
        .frame(width: 260)
    }

    // MARK: - Header

    private var header: some View {
        Text(timer.phase.rawValue.uppercased())
            .font(.system(size: 11, weight: .medium))
            .tracking(3)
            .foregroundStyle(.secondary)
    }

    // MARK: - Timer ring

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(.primary.opacity(0.08), lineWidth: 2)

            Circle()
                .trim(from: 0, to: timer.progress)
                .stroke(.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: timer.progress)

            VStack(spacing: 2) {
                Text(timer.formattedTime)
                    .font(.system(size: 36, weight: .light, design: .default))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text(timer.isRunning ? "running" : "paused")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: 150, height: 150)
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 32) {
            Button {
                timer.resetPhase()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(.secondary)
            }
            .help("Reset current phase")

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
            }
            .help(timer.isRunning ? "Pause" : "Start")

            Button {
                timer.skip()
            } label: {
                Image(systemName: "forward.end")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(.secondary)
            }
            .help("Skip to next phase")
        }
        .buttonStyle(.plain)
    }

    // MARK: - Session info

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

    // MARK: - Settings

    private var settings: some View {
        VStack(spacing: 10) {
            durationRow(label: "Focus", value: $timer.workMinutes, range: 1...60)
            durationRow(label: "Short break", value: $timer.shortBreakMinutes, range: 1...30)
            durationRow(label: "Long break", value: $timer.longBreakMinutes, range: 1...60)
        }
        .font(.system(size: 12))
    }

    private func durationRow(label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        Stepper(value: value, in: range) {
            HStack {
                Text(label)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(value.wrappedValue) min")
                    .monospacedDigit()
            }
        }
        .onChange(of: value.wrappedValue) {
            // Reflect duration changes immediately when the phase is idle.
            if !timer.isRunning {
                timer.resetPhase()
            }
        }
    }

    // MARK: - Quit

    private var quitButton: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Text("Quit")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var divider: some View {
        Rectangle()
            .fill(.primary.opacity(0.08))
            .frame(height: 1)
    }
}

#Preview {
    MenuBarView(timer: PomodoroTimer())
}
