import SwiftUI
import AppKit

// MARK: - PopoverView

struct PopoverView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var counterManager: CounterManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("TimerPro")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                settingsButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()

            // Timer Section
            timerSection
                .padding(.horizontal, 16)
                .padding(.top, 16)

            Divider()
                .padding(.top, 16)

            // Counter Section
            counterSection
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

            Divider()

            // Quit button
            Button(action: { NSApp.terminate(nil) }) {
                Text("Quit TimerPro")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 8)
        }
        .frame(width: 280)
    }

    // MARK: - Timer Section

    private var timerSection: some View {
        VStack(spacing: 12) {
            // Time display
            ZStack {
                // Progress ring
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 6)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: timerManager.isFinished ? 1.0 : timerManager.progress)
                    .stroke(
                        timerManager.isFinished ? Color.red : Color.accentColor,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: timerManager.progress)

                VStack(spacing: 2) {
                    Text(timerManager.displayTime)
                        .font(.system(size: 26, weight: .semibold, design: .monospaced))
                        .foregroundColor(timerManager.isFinished ? .red : .primary)

                    if timerManager.isRunning {
                        Text("running")
                            .font(.caption2)
                            .foregroundColor(.green)
                    } else if timerManager.isFinished {
                        Text("finished")
                            .font(.caption2)
                            .foregroundColor(.red)
                    } else {
                        Text(timerManager.selectedPreset.displayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.bottom, 4)

            // Preset buttons
            HStack(spacing: 6) {
                ForEach(TimerPreset.allCases) { preset in
                    presetButton(preset)
                }
            }

            // Control buttons
            HStack(spacing: 10) {
                // Start/Stop
                Button(action: { timerManager.startStop() }) {
                    HStack(spacing: 4) {
                        Image(systemName: timerManager.isRunning ? "pause.fill" : "play.fill")
                        Text(timerManager.isRunning ? "Pause" : (timerManager.isFinished ? "Restart" : "Start"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .tint(timerManager.isRunning ? .orange : .accentColor)

                // Reset
                Button(action: { timerManager.reset() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
        }
    }

    @ViewBuilder
    private func presetButton(_ preset: TimerPreset) -> some View {
        let isSelected = timerManager.selectedPreset == preset

        Button(action: { timerManager.selectPreset(preset) }) {
            Text(shortPresetLabel(preset))
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? .accentColor : .secondary)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }

    private func shortPresetLabel(_ preset: TimerPreset) -> String {
        switch preset {
        case .fifteen:   return "15m"
        case .thirty:    return "30m"
        case .fortyFive: return "45m"
        case .sixty:     return "60m"
        case .ninetyMin: return "90m"
        }
    }

    // MARK: - Counter Section

    private var counterSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Counter")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { counterManager.reset() }) {
                    Text("Reset")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 16) {
                // Decrement
                Button(action: { counterManager.decrement() }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(counterManager.count > 0 ? .accentColor : .secondary.opacity(0.4))
                }
                .buttonStyle(.plain)
                .disabled(counterManager.count <= 0)

                Spacer()

                // Count display
                Text("\(counterManager.count)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .frame(minWidth: 60)
                    .multilineTextAlignment(.center)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: counterManager.count)

                Spacer()

                // Increment
                Button(action: { counterManager.increment() }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(counterManager.count < 999 ? .accentColor : .secondary.opacity(0.4))
                }
                .buttonStyle(.plain)
                .disabled(counterManager.count >= 999)
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Settings Button

    private var settingsButton: some View {
        Button(action: openSettings) {
            Image(systemName: "gearshape")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
        .help("Open Settings")
    }

    private func openSettings() {
        if #available(macOS 13, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}
