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
            // Live label shown in the menu bar: phase icon + remaining time.
            Image(systemName: timer.phase.symbolName)
            Text(timer.formattedTime)
        }
        // `.window` gives us a rich SwiftUI popover instead of a plain menu.
        .menuBarExtraStyle(.window)
    }
}
