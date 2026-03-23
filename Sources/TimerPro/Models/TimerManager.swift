import Foundation
import AppKit
import Combine

// MARK: - Timer Preset

enum TimerPreset: Int, CaseIterable, Identifiable {
    case fifteen = 15
    case thirty = 30
    case fortyFive = 45
    case sixty = 60
    case ninetyMin = 90

    var id: Int { rawValue }

    var seconds: Int {
        return rawValue * 60
    }

    var displayName: String {
        switch self {
        case .fifteen:   return "15 min"
        case .thirty:    return "30 min"
        case .fortyFive: return "45 min"
        case .sixty:     return "60 min"
        case .ninetyMin: return "90 min"
        }
    }
}

// MARK: - TimerManager

class TimerManager: ObservableObject {
    @Published var timeRemaining: Int
    @Published var isRunning: Bool = false
    @Published var isFinished: Bool = false
    @Published var selectedPreset: TimerPreset = .fifteen

    private var timer: Timer?

    init() {
        self.timeRemaining = TimerPreset.fifteen.seconds
    }

    var displayTime: String {
        if isFinished {
            return "Done!"
        }
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        guard selectedPreset.seconds > 0 else { return 0 }
        return Double(selectedPreset.seconds - timeRemaining) / Double(selectedPreset.seconds)
    }

    func selectPreset(_ preset: TimerPreset) {
        stop()
        selectedPreset = preset
        timeRemaining = preset.seconds
        isFinished = false
    }

    func cyclePreset() {
        let allPresets = TimerPreset.allCases
        guard let currentIndex = allPresets.firstIndex(of: selectedPreset) else { return }
        let nextIndex = (currentIndex + 1) % allPresets.count
        selectPreset(allPresets[nextIndex])
    }

    func startStop() {
        if isFinished {
            reset()
            return
        }
        if isRunning {
            stop()
        } else {
            start()
        }
    }

    func start() {
        guard !isRunning && !isFinished && timeRemaining > 0 else { return }
        isRunning = true
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        stop()
        timeRemaining = selectedPreset.seconds
        isFinished = false
    }

    private func tick() {
        if timeRemaining <= 1 {
            timeRemaining = 0
            finish()
        } else {
            timeRemaining -= 1
        }
    }

    private func finish() {
        stop()
        isFinished = true
        NSSound.beep()
    }
}
