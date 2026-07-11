//
//  SettingsView.swift
//  MonoTime
//
//  Created by Muhammad Fachrizal Akbar on 11/07/26.
//

import SwiftUI
import ServiceManagement

/// The separate settings window opened from the popover's gear button.
///
/// Grouped into four sections: durations of each phase, alert sound,
/// general behavior (login item, menu bar contrast, reset), and support
/// links for the developer.
struct SettingsView: View {
    /// The shared timer model whose configuration this window edits.
    @Bindable var timer: PomodoroTimer

    /// Mirrors the login item registration; SMAppService has no publisher.
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    /// Reset all is destructive (wipes progress and settings), so confirm first.
    @State private var confirmingReset = false

    /// Replace with the developer's real page before release.
    private let coffeeURL = URL(string: "https://www.buymeacoffee.com/")!

    var body: some View {
        Form {
            Section("Durations") {
                settingRow(label: "Focus", value: $timer.workMinutes, range: 1...60, suffix: "min")
                settingRow(label: "Short break", value: $timer.shortBreakMinutes, range: 1...30, suffix: "min")
                settingRow(label: "Long break", value: $timer.longBreakMinutes, range: 1...60, suffix: "min")
                settingRow(label: "Long break every", value: $timer.sessionsBeforeLongBreak, range: 1...10, suffix: nil)
            }

            // Kept outside the durations list: it acts on progress, not settings.
            Section {
                Button {
                    timer.resetSessions()
                } label: {
                    Text("Reset session")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.borderless)
                .help("Reset the timer and session count without changing settings")
            }

            Section("Sound") {
                HStack {
                    Slider(value: $timer.soundVolume, in: 0...1) {
                        Text("Volume")
                    }
                    Text(timer.soundVolume, format: .percent.precision(.fractionLength(0)))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
                .help("Volume of the sound played when a phase ends")
            }

            Section("General") {
                Toggle("Start at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) {
                        updateLoginItem(enabled: launchAtLogin)
                    }

                Picker("Menu bar contrast", selection: $timer.menuBarContrast) {
                    ForEach(MenuBarContrast.allCases) { contrast in
                        Text(contrast.rawValue).tag(contrast)
                    }
                }
                .pickerStyle(.segmented)
                .help("High shows the running timer as a filled pill; low keeps plain text")

                Button(role: .destructive) {
                    confirmingReset = true
                } label: {
                    Text("Reset all")
                        .foregroundStyle(.red)
                }
                // Text-style button, matching the "Buy me a coffee" link.
                .buttonStyle(.borderless)
                .help("Reset sessions, timer, and settings back to defaults")
                .confirmationDialog(
                    "Reset the timer, sessions, and all settings to their defaults?",
                    isPresented: $confirmingReset
                ) {
                    Button("Reset All", role: .destructive) {
                        timer.resetAll()
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }

            Section("Support") {
                LabeledContent("Version", value: appVersion)

                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.orderFrontStandardAboutPanel(nil)
                } label: {
                    Text("About MonoTime")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.borderless)

                Link(destination: coffeeURL) {
                    Text("Buy me a coffee ☕️")
                        .foregroundStyle(.blue)
                }
                .help("Support the developer")
            }
        }
        .formStyle(.grouped)
        .frame(width: 340)
        .fixedSize()
    }

    /// The app's marketing version from the bundle's Info.plist.
    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        return version
    }

    /// Registers or unregisters the app as a login item, reverting the
    /// toggle if the system refuses.
    ///
    /// - Parameter enabled: Whether the app should launch at login.
    private func updateLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    /// A row whose value can be adjusted with the stepper arrows or by
    /// typing directly into the text field. Typed values are clamped to
    /// `range`, and duration changes apply immediately while the timer is
    /// not running.
    ///
    /// - Parameters:
    ///   - label: The row's leading title, also used as the stepper's
    ///     accessibility label.
    ///   - value: Binding to the setting being edited.
    ///   - range: The allowed values; anything typed outside is clamped.
    ///   - suffix: Optional unit shown after the value (e.g. "min"). Rows
    ///     without a unit still reserve the space so values align.
    private func settingRow(label: String, value: Binding<Int>, range: ClosedRange<Int>, suffix: String?) -> some View {
        // LabeledContent centers the label and the whole value group on the
        // same row centerline, keeping the text level with the stepper.
        LabeledContent(label) {
            HStack(spacing: 4) {
                TextField("", value: value, format: .number)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.center)
                    .monospacedDigit()
                    .frame(width: 32)
                // Fixed-width suffix slot keeps the values in one column
                // across rows with and without a unit.
                Text(suffix ?? "")
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .leading)
                Stepper("", value: value, in: range)
                    .labelsHidden()
                    .accessibilityLabel(label)
            }
        }
        .onChange(of: value.wrappedValue) {
            // Typed values can be anything; clamp them to the allowed range.
            let clamped = min(max(value.wrappedValue, range.lowerBound), range.upperBound)
            if clamped != value.wrappedValue {
                value.wrappedValue = clamped
            }
            // Reflect duration changes immediately when the phase is idle.
            if !timer.isRunning {
                timer.resetPhase()
            }
        }
    }
}

#Preview {
    SettingsView(timer: PomodoroTimer())
}
