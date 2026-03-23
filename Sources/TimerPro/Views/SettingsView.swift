import SwiftUI
import AppKit
import CoreGraphics

// MARK: - HotKey Recording State

class HotKeyRecorder: ObservableObject {
    @Published var recordingAction: HotKeyAction? = nil
    private var localMonitor: Any?

    func startRecording(for action: HotKeyAction, completion: @escaping (HotKey) -> Void) {
        stopRecording()
        recordingAction = action

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard self?.recordingAction == action else { return event }

            // Convert NSEvent modifiers to CGEventFlags
            let nsFlags = event.modifierFlags
            var cgFlags: UInt64 = 0
            if nsFlags.contains(.command)  { cgFlags |= CGEventFlags.maskCommand.rawValue }
            if nsFlags.contains(.option)   { cgFlags |= CGEventFlags.maskAlternate.rawValue }
            if nsFlags.contains(.shift)    { cgFlags |= CGEventFlags.maskShift.rawValue }
            if nsFlags.contains(.control)  { cgFlags |= CGEventFlags.maskControl.rawValue }

            // Require at least one modifier
            guard cgFlags != 0 else { return event }

            // Ignore lone modifier keys (keyCode >= 54 for common modifiers)
            let keyCode = Int64(event.keyCode)
            let modifierKeyCodes: Set<Int64> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
            guard !modifierKeyCodes.contains(keyCode) else { return event }

            let hotKey = HotKey(keyCode: keyCode, modifierFlags: cgFlags)
            completion(hotKey)
            self?.stopRecording()
            return nil // Consume the event
        }
    }

    func stopRecording() {
        recordingAction = nil
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    deinit {
        stopRecording()
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    @ObservedObject var hotKeyManager: HotKeyManager
    @StateObject private var recorder = HotKeyRecorder()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hotKeySection
                    infoSection
                }
                .padding(24)
            }
        }
        .frame(width: 480, height: 420)
        .onDisappear {
            recorder.stopRecording()
        }
    }

    // MARK: - HotKey Section

    private var hotKeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keyboard Shortcuts")
                .font(.headline)
                .foregroundColor(.primary)

            Text("These shortcuts work globally in any app. Accessibility permission is required.")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(spacing: 2) {
                ForEach(HotKeyAction.allCases, id: \.self) { action in
                    hotKeyRow(action: action)
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)

            HStack {
                Spacer()
                Button(action: {
                    recorder.stopRecording()
                    hotKeyManager.resetToDefaults()
                }) {
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    @ViewBuilder
    private func hotKeyRow(action: HotKeyAction) -> some View {
        let isRecording = recorder.recordingAction == action
        let hotKey = hotKeyManager.settings.hotKey(for: action)

        HStack {
            Text(action.displayName)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            if isRecording {
                Text("Press shortcut…")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.12))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.accentColor, lineWidth: 1.5)
                    )
            } else {
                Text(hotKey?.displayString ?? "—")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }

            Button(action: {
                if isRecording {
                    recorder.stopRecording()
                } else {
                    recorder.startRecording(for: action) { newHotKey in
                        hotKeyManager.settings.setHotKey(newHotKey, for: action)
                    }
                }
            }) {
                Text(isRecording ? "Cancel" : "Record")
                    .font(.caption)
                    .frame(width: 56)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(isRecording ? .red : .accentColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.secondary.opacity(0.1)),
            alignment: .bottom
        )
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                infoRow(label: "Version", value: "1.0.0")
                infoRow(label: "Build", value: "Swift 5.9 · macOS 13+")
                infoRow(label: "Bundle ID", value: "com.huntermott.timerpro")
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)

            // Accessibility permissions
            HStack(spacing: 8) {
                let trusted = AXIsProcessTrusted()
                Image(systemName: trusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(trusted ? .green : .orange)
                Text(trusted
                    ? "Accessibility access granted — global shortcuts are active."
                    : "Accessibility access not granted. Global shortcuts won't work."
                )
                .font(.caption)
                .foregroundColor(trusted ? .secondary : .orange)

                if !trusted {
                    Button("Open Privacy Settings") {
                        NSWorkspace.shared.open(
                            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                        )
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}
