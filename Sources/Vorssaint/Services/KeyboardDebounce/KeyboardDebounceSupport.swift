// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct KeyboardDebounceConfig: Equatable {
    var enabled: Bool
    var globalWindowMs: Int
    var keyWindows: [Int64: Int]

    func windowMs(for keyCode: Int64) -> Int {
        keyWindows[keyCode] ?? globalWindowMs
    }

    static func decodeKeyWindows(_ raw: String) -> [Int64: Int] {
        var result: [Int64: Int] = [:]
        for part in raw.split(separator: ",") {
            let pieces = part.split(separator: ":", maxSplits: 1).map(String.init)
            guard pieces.count == 2,
                  let keyCode = Int64(pieces[0]),
                  let window = Int(pieces[1]) else { continue }
            result[keyCode] = Defaults.sanitizedKeyboardDebounceWindow(window)
        }
        return result
    }

    static func encodeKeyWindows(_ windows: [Int64: Int]) -> String {
        windows
            .map { (key: $0.key, value: Defaults.sanitizedKeyboardDebounceWindow($0.value)) }
            .sorted { $0.key < $1.key }
            .map { "\($0.key):\($0.value)" }
            .joined(separator: ",")
    }
}

struct KeyboardDebounceState {
    enum EventKind {
        case keyDown
        case keyUp
    }

    private struct KeyState {
        var isDown = false
        var lastAcceptedPress: UInt64?
        var lastAcceptedRelease: UInt64?
        var lastEventTimestamp: UInt64?
    }

    private static let staleStateGapNanoseconds: UInt64 = 5_000_000_000

    private var stateByKey: [Int64: KeyState] = [:]
    private var lastAcceptedKeyCode: Int64?

    mutating func reset() {
        stateByKey.removeAll()
        lastAcceptedKeyCode = nil
    }

    mutating func shouldSuppress(keyCode: Int64,
                                 isAutoRepeat: Bool,
                                 event: EventKind,
                                 time: TimeInterval,
                                 config: KeyboardDebounceConfig) -> Bool {
        let nanoseconds = max(0, (time * 1_000_000_000.0).rounded())
        return shouldSuppress(keyCode: keyCode,
                              isAutoRepeat: isAutoRepeat,
                              event: event,
                              timestampNanoseconds: UInt64(nanoseconds),
                              config: config)
    }

    mutating func shouldSuppress(keyCode: Int64,
                                 isAutoRepeat: Bool,
                                 event: EventKind,
                                 timestampNanoseconds: UInt64,
                                 config: KeyboardDebounceConfig) -> Bool {
        guard config.enabled else {
            stateByKey.removeValue(forKey: keyCode)
            if lastAcceptedKeyCode == keyCode {
                lastAcceptedKeyCode = nil
            }
            return false
        }

        var keyState = sanitizedState(for: keyCode, timestamp: timestampNanoseconds)
        defer {
            keyState.lastEventTimestamp = timestampNanoseconds
            stateByKey[keyCode] = keyState
        }

        guard event == .keyDown else {
            if keyState.isDown {
                keyState.isDown = false
                keyState.lastAcceptedRelease = timestampNanoseconds
            }
            return false
        }

        guard !isAutoRepeat else {
            keyState.isDown = true
            return false
        }

        let window = UInt64(config.windowMs(for: keyCode)) * 1_000_000
        guard window > 0 else {
            keyState.isDown = true
            keyState.lastAcceptedPress = timestampNanoseconds
            lastAcceptedKeyCode = keyCode
            return false
        }

        if keyState.isDown,
           let press = keyState.lastAcceptedPress,
           timestampNanoseconds >= press,
           timestampNanoseconds - press < window {
            return true
        }

        if let release = keyState.lastAcceptedRelease,
           lastAcceptedKeyCode == keyCode,
           timestampNanoseconds >= release,
           timestampNanoseconds - release < window {
            return true
        }

        keyState.isDown = true
        keyState.lastAcceptedPress = timestampNanoseconds
        lastAcceptedKeyCode = keyCode
        return false
    }

    private mutating func sanitizedState(for keyCode: Int64,
                                         timestamp: UInt64) -> KeyState {
        var keyState = stateByKey[keyCode] ?? KeyState()
        guard let previousTimestamp = keyState.lastEventTimestamp else {
            return keyState
        }
        if timestamp < previousTimestamp
            || timestamp - previousTimestamp > Self.staleStateGapNanoseconds {
            keyState = KeyState()
            if lastAcceptedKeyCode == keyCode {
                lastAcceptedKeyCode = nil
            }
        }
        return keyState
    }
}

struct KeyboardDebounceKey: Identifiable, Hashable {
    let code: Int64
    let label: String

    var id: Int64 { code }
}

enum KeyboardDebounceKeyCatalog {
    static let common: [KeyboardDebounceKey] = [
        KeyboardDebounceKey(code: 0, label: "A"),
        KeyboardDebounceKey(code: 11, label: "B"),
        KeyboardDebounceKey(code: 8, label: "C"),
        KeyboardDebounceKey(code: 2, label: "D"),
        KeyboardDebounceKey(code: 14, label: "E"),
        KeyboardDebounceKey(code: 3, label: "F"),
        KeyboardDebounceKey(code: 5, label: "G"),
        KeyboardDebounceKey(code: 4, label: "H"),
        KeyboardDebounceKey(code: 34, label: "I"),
        KeyboardDebounceKey(code: 38, label: "J"),
        KeyboardDebounceKey(code: 40, label: "K"),
        KeyboardDebounceKey(code: 37, label: "L"),
        KeyboardDebounceKey(code: 46, label: "M"),
        KeyboardDebounceKey(code: 45, label: "N"),
        KeyboardDebounceKey(code: 31, label: "O"),
        KeyboardDebounceKey(code: 35, label: "P"),
        KeyboardDebounceKey(code: 12, label: "Q"),
        KeyboardDebounceKey(code: 15, label: "R"),
        KeyboardDebounceKey(code: 1, label: "S"),
        KeyboardDebounceKey(code: 17, label: "T"),
        KeyboardDebounceKey(code: 32, label: "U"),
        KeyboardDebounceKey(code: 9, label: "V"),
        KeyboardDebounceKey(code: 13, label: "W"),
        KeyboardDebounceKey(code: 7, label: "X"),
        KeyboardDebounceKey(code: 16, label: "Y"),
        KeyboardDebounceKey(code: 6, label: "Z"),
        KeyboardDebounceKey(code: 29, label: "0"),
        KeyboardDebounceKey(code: 18, label: "1"),
        KeyboardDebounceKey(code: 19, label: "2"),
        KeyboardDebounceKey(code: 20, label: "3"),
        KeyboardDebounceKey(code: 21, label: "4"),
        KeyboardDebounceKey(code: 23, label: "5"),
        KeyboardDebounceKey(code: 22, label: "6"),
        KeyboardDebounceKey(code: 26, label: "7"),
        KeyboardDebounceKey(code: 28, label: "8"),
        KeyboardDebounceKey(code: 25, label: "9"),
        KeyboardDebounceKey(code: 49, label: "Space"),
        KeyboardDebounceKey(code: 36, label: "Return"),
        KeyboardDebounceKey(code: 48, label: "Tab"),
        KeyboardDebounceKey(code: 51, label: "Delete"),
        KeyboardDebounceKey(code: 53, label: "Escape"),
        KeyboardDebounceKey(code: 43, label: ","),
        KeyboardDebounceKey(code: 47, label: "."),
        KeyboardDebounceKey(code: 44, label: "/"),
        KeyboardDebounceKey(code: 41, label: ";"),
        KeyboardDebounceKey(code: 39, label: "'"),
        KeyboardDebounceKey(code: 27, label: "-"),
        KeyboardDebounceKey(code: 24, label: "="),
        KeyboardDebounceKey(code: 33, label: "["),
        KeyboardDebounceKey(code: 30, label: "]"),
        KeyboardDebounceKey(code: 42, label: "\\"),
        KeyboardDebounceKey(code: 50, label: "`"),
    ]

    private static let labelsByCode = Dictionary(uniqueKeysWithValues: common.map { ($0.code, $0.label) })

    static func label(for keyCode: Int64) -> String {
        labelsByCode[keyCode] ?? "#\(keyCode)"
    }
}
