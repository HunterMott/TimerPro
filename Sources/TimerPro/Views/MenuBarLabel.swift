import SwiftUI

// MARK: - MenuBarLabel

struct MenuBarLabel: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var counterManager: CounterManager

    var body: some View {
        HStack(spacing: 4) {
            Text("\(timerManager.displayTime) · \(counterManager.count)")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(timerManager.isFinished ? .red : .primary)
        }
    }
}
