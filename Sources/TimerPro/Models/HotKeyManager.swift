import Foundation
import CoreGraphics
import AppKit

// MARK: - HotKey

struct HotKey: Codable, Equatable, Hashable {
    var keyCode: Int64
    var modifierFlags: UInt64  // CGEventFlags raw value

    func matches(keyCode: Int64, flags: CGEventFlags) -> Bool {
        let relevantFlags: CGEventFlags = [.maskCommand, .maskShift, .maskAlternate, .maskControl]
        let storedFlags = CGEventFlags(rawValue: modifierFlags)
        return self.keyCode == keyCode &&
               storedFlags.intersection(relevantFlags) == flags.intersection(relevantFlags)
    }

    var displayString: String {
        var parts: [String] = []
        let flags = CGEventFlags(rawValue: modifierFlags)
        if flags.contains(.maskControl)   { parts.append("⌃") }
        if flags.contains(.maskAlternate) { parts.append("⌥") }
        if flags.contains(.maskShift)     { parts.append("⇧") }
        if flags.contains(.maskCommand)   { parts.append("⌘") }
        parts.append(HotKey.keyCodeToString(keyCode))
        return parts.joined()
    }

    static func keyCodeToString(_ keyCode: Int64) -> String {
        switch keyCode {
        case 0:  return "A"
        case 1:  return "S"
        case 2:  return "D"
        case 3:  return "F"
        case 4:  return "H"
        case 5:  return "G"
        case 6:  return "Z"
        case 7:  return "X"
        case 8:  return "C"
        case 9:  return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 36: return "↩"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 48: return "⇥"
        case 49: return "Space"
        case 50: return "`"
        case 51: return "⌫"
        case 53: return "⎋"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 99: return "F3"
        case 100: return "F8"
        case 101: return "F9"
        case 103: return "F11"
        case 109: return "F10"
        case 111: return "F12"
        case 115: return "↖"
        case 116: return "⇞"
        case 117: return "⌦"
        case 118: return "F4"
        case 119: return "↘"
        case 120: return "F2"
        case 121: return "⇟"
        case 122: return "F1"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default: return "(\(keyCode))"
        }
    }
}

// MARK: - HotKeyAction

enum HotKeyAction: String, CaseIterable, Codable {
    case startStopTimer   = "startStopTimer"
    case resetTimer       = "resetTimer"
    case cyclePreset      = "cyclePreset"
    case incrementCounter = "incrementCounter"
    case decrementCounter = "decrementCounter"
    case resetCounter     = "resetCounter"

    var displayName: String {
        switch self {
        case .startStopTimer:   return "Start / Stop Timer"
        case .resetTimer:       return "Reset Timer"
        case .cyclePreset:      return "Cycle Preset"
        case .incrementCounter: return "Increment Counter"
        case .decrementCounter: return "Decrement Counter"
        case .resetCounter:     return "Reset Counter"
        }
    }
}

// MARK: - HotKeySettings

struct HotKeySettings: Codable {
    var hotKeys: [String: HotKey]

    static var defaults: HotKeySettings {
        let optCmd = CGEventFlags.maskAlternate.rawValue | CGEventFlags.maskCommand.rawValue
        return HotKeySettings(hotKeys: [
            HotKeyAction.startStopTimer.rawValue:   HotKey(keyCode: 17, modifierFlags: optCmd), // ⌥⌘T
            HotKeyAction.resetTimer.rawValue:       HotKey(keyCode: 15, modifierFlags: optCmd), // ⌥⌘R
            HotKeyAction.cyclePreset.rawValue:      HotKey(keyCode: 35, modifierFlags: optCmd), // ⌥⌘P
            HotKeyAction.incrementCounter.rawValue: HotKey(keyCode: 24, modifierFlags: optCmd), // ⌥⌘=
            HotKeyAction.decrementCounter.rawValue: HotKey(keyCode: 27, modifierFlags: optCmd), // ⌥⌘-
            HotKeyAction.resetCounter.rawValue:     HotKey(keyCode: 29, modifierFlags: optCmd), // ⌥⌘0
        ])
    }

    func hotKey(for action: HotKeyAction) -> HotKey? {
        return hotKeys[action.rawValue]
    }

    mutating func setHotKey(_ hotKey: HotKey, for action: HotKeyAction) {
        hotKeys[action.rawValue] = hotKey
    }
}

// MARK: - Module-level weak ref for CGEvent callback

private class HotKeyManagerRef {
    weak var manager: HotKeyManager?
}
nonisolated(unsafe) private let managerRef = HotKeyManagerRef()

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    if type == .keyDown {
        if let result = managerRef.manager?.processEvent(event) {
            return result
        }
    }
    // Re-enable tap if it gets disabled
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = managerRef.manager?.eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }
    return Unmanaged.passRetained(event)
}

// MARK: - HotKeyManager

class HotKeyManager: ObservableObject, @unchecked Sendable {
    @Published var settings: HotKeySettings {
        didSet { saveSettings() }
    }

    private weak var timerManager: TimerManager?
    private weak var counterManager: CounterManager?

    fileprivate var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private static let settingsKey = "HotKeySettings"

    init(timerManager: TimerManager, counterManager: CounterManager) {
        self.timerManager = timerManager
        self.counterManager = counterManager

        // Load or use defaults
        if let data = UserDefaults.standard.data(forKey: Self.settingsKey),
           let decoded = try? JSONDecoder().decode(HotKeySettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = HotKeySettings.defaults
        }

        managerRef.manager = self
        setupEventTap()
    }

    deinit {
        tearDownEventTap()
    }

    // MARK: - Event Tap Setup

    private func setupEventTap() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: eventTapCallback,
            userInfo: nil
        ) else {
            print("[HotKeyManager] Failed to create event tap - check Accessibility permissions")
            return
        }

        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func tearDownEventTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    // MARK: - Event Processing

    func processEvent(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        for action in HotKeyAction.allCases {
            if let hotKey = settings.hotKey(for: action), hotKey.matches(keyCode: keyCode, flags: flags) {
                Task { @MainActor [weak self] in
                    self?.perform(action: action)
                }
                return nil // Consume the event
            }
        }

        return Unmanaged.passRetained(event)
    }

    private func perform(action: HotKeyAction) {
        switch action {
        case .startStopTimer:   timerManager?.startStop()
        case .resetTimer:       timerManager?.reset()
        case .cyclePreset:      timerManager?.cyclePreset()
        case .incrementCounter: counterManager?.increment()
        case .decrementCounter: counterManager?.decrement()
        case .resetCounter:     counterManager?.reset()
        }
    }

    // MARK: - Persistence

    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: Self.settingsKey)
        }
    }

    func resetToDefaults() {
        settings = HotKeySettings.defaults
    }
}
