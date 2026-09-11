// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum JSONPreviewFormatter {
    static func format(_ text: String, outputLimit: Int = 1_048_576) -> String? {
        guard text.utf8.count <= 262_144, outputLimit >= 0 else { return nil }
        var parser = Parser(bytes: Array(text.utf8), limit: outputLimit)
        parser.space()
        guard parser.peek == 123 || parser.peek == 91 else { return nil }
        guard parser.value(depth: 0) else { return nil }
        parser.space()
        guard parser.index == parser.bytes.count else { return nil }
        return String(bytes: parser.output, encoding: .utf8)
    }

    private struct Parser {
        let bytes: [UInt8]
        let limit: Int
        var index = 0
        var output: [UInt8] = []
        var peek: UInt8? { index < bytes.count ? bytes[index] : nil }
        mutating func space() { while let b = peek, [9,10,13,32].contains(b) { index += 1 } }
        mutating func emit(_ slice: [UInt8]) -> Bool {
            guard slice.count <= limit - output.count else { return false }
            output.append(contentsOf: slice)
            return true
        }
        mutating func newline(_ depth: Int) -> Bool { emit([10] + Array(repeating: 32, count: depth * 2)) }
        mutating func value(depth: Int) -> Bool {
            space()
            guard let b = peek else { return false }
            if b == 123 || b == 91 { return container(depth: depth) }
            if b == 34 { return string() }
            if b == 116 { return literal(Array("true".utf8)) }
            if b == 102 { return literal(Array("false".utf8)) }
            if b == 110 { return literal(Array("null".utf8)) }
            return number()
        }
        mutating func literal(_ token: [UInt8]) -> Bool {
            guard bytes.count - index >= token.count,
                  Array(bytes[index..<index+token.count]) == token else { return false }
            index += token.count
            return emit(token)
        }
        mutating func container(depth: Int) -> Bool {
            guard depth < 64, let open = peek else { return false }
            let object = open == 123
            let close: UInt8 = object ? 125 : 93
            index += 1
            guard emit([open]) else { return false }
            space()
            if peek == close { index += 1; return emit([close]) }
            guard newline(depth + 1) else { return false }
            while true {
                if object {
                    guard string() else { return false }
                    space()
                    guard peek == 58 else { return false }
                    index += 1
                    guard emit([58,32]) else { return false }
                }
                guard value(depth: depth + 1) else { return false }
                space()
                if peek == close {
                    index += 1
                    return newline(depth) && emit([close])
                }
                guard peek == 44 else { return false }
                index += 1
                guard emit([44]), newline(depth + 1) else { return false }
                space()
            }
        }
        mutating func string() -> Bool {
            guard peek == 34 else { return false }
            let start = index
            index += 1
            while let b = peek {
                index += 1
                if b == 34 { return emit(Array(bytes[start..<index])) }
                guard b >= 32 else { return false }
                if b == 92 {
                    guard let escape = peek else { return false }
                    index += 1
                    if escape == 117 {
                        for _ in 0..<4 {
                            guard let hex = peek,
                                  (48...57).contains(hex) || (65...70).contains(hex) || (97...102).contains(hex)
                            else { return false }
                            index += 1
                        }
                    } else if ![34,92,47,98,102,110,114,116].contains(escape) { return false }
                }
            }
            return false
        }
        mutating func number() -> Bool {
            let start = index
            if peek == 45 { index += 1 }
            if peek == 48 { index += 1 }
            else {
                guard let first = peek, (49...57).contains(first) else { return false }
                digits()
            }
            if peek == 46 {
                index += 1
                let first = index
                digits()
                guard index > first else { return false }
            }
            if peek == 101 || peek == 69 {
                index += 1
                if peek == 43 || peek == 45 { index += 1 }
                let first = index
                digits()
                guard index > first else { return false }
            }
            return emit(Array(bytes[start..<index]))
        }
        mutating func digits() { while let b = peek, (48...57).contains(b) { index += 1 } }
    }
}
