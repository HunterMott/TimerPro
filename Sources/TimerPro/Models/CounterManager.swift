import Foundation

// MARK: - CounterManager

class CounterManager: ObservableObject {
    @Published var count: Int = 0

    private let minValue = 0
    private let maxValue = 999

    func increment() {
        if count < maxValue {
            count += 1
        }
    }

    func decrement() {
        if count > minValue {
            count -= 1
        }
    }

    func reset() {
        count = 0
    }
}
