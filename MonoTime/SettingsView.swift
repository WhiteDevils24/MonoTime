//
//  SettingsView.swift
//  MonoTime
//
//  Created by Muhammad Fachrizal Akbar on 11/07/26.
//

import SwiftUI
import ServiceManagement

/// The separate settings window opened from the popover's gear button.
struct SettingsView: View {
    @Bindable var timer: PomodoroTimer

    /// Mirrors the login item registration; SMAppService has no publisher.
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    /// Replace with the developer's real page before release.
    private let coffeeURL = URL(string: "https://www.buymeacoffee.com/")!

    var body: some View {
        Form {
            Section("Durations") {
                settingRow(label: "Focus", value: $timer.workMinutes, range: 1...60, suffix: "min")
                settingRow(label: "Short break", value: $timer.shortBreakMinutes, range: 1...30, suffix: "min")
                settingRow(label: "Long break", value: $timer.longBreakMinutes, range: 1...60, suffix: "min")
                settingRow(label: "Long break every", value: $timer.sessionsBeforeLongBreak, range: 1...10, suffix: nil)

                Button("Reset all") {
                    timer.resetAll()
                }
                .help("Reset sessions, timer, and settings back to defaults")
            }

            Section("Sound") {
                HStack {
                    Image(systemName: "speaker.fill")
                        .foregroundStyle(.secondary)
                    Slider(value: $timer.soundVolume, in: 0...1) {
                        Text("Volume")
                    }
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundStyle(.secondary)
                }
                .help("Volume of the sound played when a phase ends")
            }

            Section("General") {
                Toggle("Start at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) {
                        updateLoginItem(enabled: launchAtLogin)
                    }

                Picker("Progress style", selection: $timer.ringStyle) {
                    ForEach(RingStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                LabeledContent("Version", value: appVersion)

                Button("About MonoTime") {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.orderFrontStandardAboutPanel(nil)
                }

                Link("Buy me a coffee ☕️", destination: coffeeURL)
                    .help("Support the developer")
            }
        }
        .formStyle(.grouped)
        .frame(width: 340)
        .fixedSize()
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        return version
    }

    /// Registers or unregisters the app as a login item, reverting the
    /// toggle if the system refuses.
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
    /// typing directly into the text field.
    private func settingRow(label: String, value: Binding<Int>, range: ClosedRange<Int>, suffix: String?) -> some View {
        Stepper(value: value, in: range) {
            HStack(spacing: 4) {
                Text(label)
                Spacer()
                TextField("", value: value, format: .number)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .frame(width: 32)
                if let suffix {
                    Text(suffix)
                        .foregroundStyle(.secondary)
                }
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
