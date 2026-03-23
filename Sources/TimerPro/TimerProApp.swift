import SwiftUI
import AppKit

// MARK: - AppState

class AppState: ObservableObject {
    let timerManager = TimerManager()
    let counterManager = CounterManager()
    lazy var hotKeyManager = HotKeyManager(timerManager: timerManager, counterManager: counterManager)
}

// MARK: - AppDelegate

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request accessibility permissions (needed for CGEvent tap)
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// MARK: - Main App

@main
struct TimerProApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            PopoverView(
                timerManager: appState.timerManager,
                counterManager: appState.counterManager
            )
        } label: {
            MenuBarLabel(
                timerManager: appState.timerManager,
                counterManager: appState.counterManager
            )
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(hotKeyManager: appState.hotKeyManager)
        }
    }
}
