// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import CoreGraphics
import Foundation

/// The production take-over service and the quick tools' hotkey, compiled
/// against an in-memory WindowServer table, preferences, Carbon and wake
/// notifications. Nothing here reaches the real symbolic hotkeys.
enum SystemShortcutTakeoverContract {
    // MARK: WindowServer table

    enum SymbolicHotKeys {
        static var table: [Int32: (shortcut: GlobalShortcut, enabled: Bool)] = [:]
        static var writes: [(id: Int32, enabled: Bool)] = []
        static var writeAheadMissing = false
        static var setEnabled: ((Int32, Bool) -> CGError)? = { id, on in
            if !on, !(SystemShortcutTakeoverContract.marker ?? []).contains(Int(id)) {
                SymbolicHotKeys.writeAheadMissing = true
            }
            SymbolicHotKeys.writes.append((id, on))
            SymbolicHotKeys.table[id]?.enabled = on
            return .success
        }
        static var isEnabled: ((Int32) -> Bool)? = { SymbolicHotKeys.table[$0]?.enabled ?? false }
        static func liveEntries() -> [LiveSystemShortcut]? {
            table.keys.sorted().map { LiveSystemShortcut(id: $0, shortcut: table[$0]!.shortcut,
                                                         enabled: table[$0]!.enabled) }
        }
    }

    // MARK: Preferences, wake and the main queue

    final class UserDefaults {
        static var standard = UserDefaults()
        var values: [String: Any] = [:]
        func array(forKey key: String) -> [Any]? { values[key] as? [Any] }
        func stringArray(forKey key: String) -> [String]? { values[key] as? [String] }
        func set(_ value: Any?, forKey key: String) { values[key] = value }
        func removeObject(forKey key: String) { values.removeValue(forKey: key) }
    }

    final class ObserverCenter {
        var observers: [(token: NSObject, block: (Notification) -> Void)] = []
        func addObserver(forName name: Notification.Name?, object: Any?, queue: OperationQueue?,
                         using block: @escaping (Notification) -> Void) -> NSObjectProtocol {
            let token = NSObject()
            observers.append((token, block))
            return token
        }
        func removeObserver(_ observer: Any) {
            observers.removeAll { $0.token === observer as AnyObject }
        }
        func post() {
            for observer in observers { observer.block(Notification(name: NSWorkspace.didWakeNotification)) }
        }
    }

    final class NSWorkspace {
        static var shared = NSWorkspace()
        static let didWakeNotification = Notification.Name("SystemShortcutTakeoverContract.wake")
        let notificationCenter = ObserverCenter()
    }

    final class Queue {
        var jobs: [() -> Void] = []
        func asyncAfter(deadline: DispatchTime, execute work: @escaping () -> Void) { jobs.append(work) }
        func drain() {
            while !jobs.isEmpty { jobs.removeFirst()() }
        }
    }

    enum DispatchQueue { static var main = Queue() }

    // MARK: Carbon

    typealias EventHotKeyRef = Int
    struct EventHotKeyID {
        let signature: UInt32
        let id: UInt32
    }
    static let noErr: Int32 = 0
    static var registeredRefs: Set<EventHotKeyRef> = []
    static var nextRef: EventHotKeyRef = 1
    static func GetEventDispatcherTarget() -> Int { 0 }
    static func RegisterEventHotKey(_ keyCode: UInt32, _ modifiers: UInt32, _ id: EventHotKeyID,
                                    _ target: Int, _ options: UInt32, _ ref: inout EventHotKeyRef?) -> Int32 {
        ref = nextRef
        registeredRefs.insert(nextRef)
        nextRef += 1
        return noErr
    }
    @discardableResult
    static func UnregisterEventHotKey(_ ref: EventHotKeyRef) -> Int32 {
        registeredRefs.remove(ref)
        return noErr
    }

    /// The stored half of `QuickToolHotkey`; the generated subclass carries
    /// the production `sync` and `unregister`.
    class QuickToolHotkeyState {
        static var instances: [UInt32: QuickToolHotkey] = [:]
        let hotKeyID: UInt32
        var hotKeyRef: EventHotKeyRef?
        var registeredShortcut: GlobalShortcut?
        var claimedKey: String?
        var onPress: (() -> Void)?
        init(id: UInt32) { hotKeyID = id }
        static func installSharedHandlerIfNeeded() {}
    }

    // MARK: Fixture

    static let screen = GlobalShortcut(keyCode: 20, modifiers: [.command, .shift])
    static let area = GlobalShortcut(keyCode: 21, modifiers: [.command, .shift])
    static let appSwitch = GlobalShortcut(keyCode: 48, modifiers: [.command])
    static let free = GlobalShortcut(keyCode: 40, modifiers: [.control, .option])

    static var marker: [Int]? { UserDefaults.standard.values[DefaultsKey.systemShortcutsSuppressed] as? [Int] }
    static var off: Set<Int32> { Set(SymbolicHotKeys.table.filter { !$0.value.enabled }.keys) }
    static var wakeObservers: Int { NSWorkspace.shared.notificationCenter.observers.count }

    /// A fresh Mac: every macOS key on, no marker, nothing taken over. Hands
    /// back a hotkey that has never registered.
    @discardableResult
    static func freshMac(takeOver: [String] = []) -> QuickToolHotkey {
        SymbolicHotKeys.table = [1: (appSwitch, true), 28: (screen, true), 30: (area, true)]
        SymbolicHotKeys.writes = []
        SymbolicHotKeys.writeAheadMissing = false
        UserDefaults.standard = UserDefaults()
        UserDefaults.standard.values[DefaultsKey.systemShortcutTakeOverKeys] = takeOver
        launch()
        return QuickToolHotkey(id: 1)
    }

    /// A new process on the same Mac: the table and the preferences survive,
    /// everything the service held in memory does not.
    static func launch() {
        NSWorkspace.shared = NSWorkspace()
        DispatchQueue.main = Queue()
        QuickToolHotkey.instances = [:]
        relaunch()
    }

    static func run(_ suite: TestSuite) {
        let row = DefaultsKey.screenshotShortcut

        // A row nobody opted into never switches anything off in macOS, even
        // when its feature registers the very combination macOS answers.
        var hotkey = freshMac()
        _ = hotkey.sync(enabled: true, shortcut: area, storageKey: row)
        SystemShortcutTakeover.claim(DefaultsKey.keepAwakeShortcut, shortcut: screen)
        SystemShortcutTakeover.reconcile()
        _ = hotkey.sync(enabled: false, shortcut: area, storageKey: row)
        SystemShortcutTakeover.restoreAll()
        suite.expect(SymbolicHotKeys.writes.isEmpty && off.isEmpty && marker == nil && wakeObservers == 0,
                     "a claim with no opt-in writes nothing to the WindowServer and installs no wake observer")

        // Opting in takes exactly the matching id, after the marker names it.
        hotkey = freshMac(takeOver: [row])
        _ = hotkey.sync(enabled: true, shortcut: area, storageKey: row)
        suite.expect(off == [30] && marker == [30] && !SymbolicHotKeys.writeAheadMissing && wakeObservers == 1,
                     "an opted-in row switches off only its own id, with the marker written first")

        // Feature off: the hotkey unregisters and the key goes back.
        _ = hotkey.sync(enabled: false, shortcut: area, storageKey: row)
        suite.expect(off.isEmpty && marker == nil && wakeObservers == 0,
                     "switching the feature off gives the key back and drops the wake observer")

        // Row moved: the old key goes back, the new macOS key is taken, and a
        // move to a key macOS does not answer leaves nothing switched off.
        _ = hotkey.sync(enabled: true, shortcut: area, storageKey: row)
        _ = hotkey.sync(enabled: true, shortcut: screen, storageKey: row)
        suite.expect(off == [28] && marker == [28], "moving an opted-in row hands back its old key")
        _ = hotkey.sync(enabled: true, shortcut: free, storageKey: row)
        suite.expect(off.isEmpty && marker == nil, "moving to a key macOS does not answer hands everything back")

        // Row reset: the recorder drops the opt-in while the feature keeps running.
        _ = hotkey.sync(enabled: true, shortcut: area, storageKey: row)
        SystemShortcutTakeover.setTakeOver(row, false)
        suite.expect(off.isEmpty && marker == nil && hotkey.hotKeyRef != nil
                     && UserDefaults.standard.stringArray(forKey: DefaultsKey.systemShortcutTakeOverKeys) == [],
                     "resetting the row gives the key back even while its hotkey stays registered")

        // Quit: every key any feature holds goes back from one place.
        SystemShortcutTakeover.setTakeOver(row, true)
        SystemShortcutTakeover.setTakeOver(DefaultsKey.keepAwakeShortcut, true)
        SystemShortcutTakeover.claim(DefaultsKey.keepAwakeShortcut, shortcut: screen)
        suite.expect(off == [28, 30], "two opted-in features hold their keys together")
        SystemShortcutTakeover.restoreAll()
        suite.expect(off.isEmpty && marker == nil && wakeObservers == 0, "quitting hands back every key")

        // Crash: the process dies holding a key. The next launch reads the
        // marker and gives the key back before any feature claims again.
        hotkey = freshMac(takeOver: [row])
        _ = hotkey.sync(enabled: true, shortcut: area, storageKey: row)
        launch()
        suite.expect(off == [30] && marker == [30], "a crash leaves the key off and the marker naming it")
        SystemShortcutTakeover.recoverIfNeeded(keeping: [])
        suite.expect(off.isEmpty && marker == nil, "the next launch gives back a key a crash left switched off")

        // An older build's switcher marker is folded in and given back too.
        freshMac()
        SymbolicHotKeys.table[28]?.enabled = false
        UserDefaults.standard.values[DefaultsKey.switcherNativeHotkeysSuppressed] = [28]
        launch()
        SystemShortcutTakeover.recoverIfNeeded(keeping: [])
        suite.expect(off.isEmpty && marker == nil
                     && UserDefaults.standard.values[DefaultsKey.switcherNativeHotkeysSuppressed] == nil,
                     "recovery gives back a key named only by the old switcher marker")

        // Launch keeps what the switcher will take again, and the first claim
        // of the launch, opted in or not, neither hands it back nor takes more.
        freshMac()
        SymbolicHotKeys.table[1]?.enabled = false
        SymbolicHotKeys.table[30]?.enabled = false
        UserDefaults.standard.values[DefaultsKey.systemShortcutsSuppressed] = [1, 30]
        launch()
        SystemShortcutTakeover.recoverIfNeeded(keeping: [1])
        SystemShortcutTakeover.claim(DefaultsKey.keepAwakeShortcut, shortcut: free)
        suite.expect(off == [1] && marker == [1], "recovery keeps the switcher's key and gives back the rest")
        SystemShortcutTakeover.setWanted([], for: SystemShortcutTakeover.switcherSource)
        suite.expect(off.isEmpty && marker == nil, "the switcher going away gives its key back")

        // Wake: System Settings moved the combination to another id while the
        // Mac slept. The held key is re-resolved and the stale id goes back.
        hotkey = freshMac(takeOver: [row])
        _ = hotkey.sync(enabled: true, shortcut: area, storageKey: row)
        SymbolicHotKeys.table[30] = (GlobalShortcut(keyCode: 23, modifiers: [.command, .shift]), false)
        SymbolicHotKeys.table[31] = (area, true)
        NSWorkspace.shared.notificationCenter.post()
        suite.expect(off == [30], "nothing is re-resolved until the wake delay has passed")
        DispatchQueue.main.drain()
        suite.expect(off == [31] && marker == [31], "after wake the claim follows its combination to the new id")
        _ = hotkey.sync(enabled: false, shortcut: area, storageKey: row)
        suite.expect(off.isEmpty && marker == nil && wakeObservers == 0,
                     "the key found after wake goes back like any other")
    }

    static func flat(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// The body of the first function whose declaration contains `signature`,
    /// comments stripped so a mention in prose never satisfies a check.
    static func body(_ path: String, _ signature: String) -> String {
        let source = (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
        let lines = source.components(separatedBy: "\n").map { line in
            line.range(of: "//").map { String(line[..<$0.lowerBound]) } ?? line
        }
        guard let start = lines.firstIndex(where: { $0.contains(signature) }) else { return "" }
        var depth = 0
        var opened = false
        var result: [String] = []
        for line in lines[start...] {
            result.append(line)
            depth += line.filter { $0 == "{" }.count - line.filter { $0 == "}" }.count
            if line.contains("{") { opened = true }
            if opened, depth <= 0 { break }
        }
        return result.joined(separator: "\n")
    }

    /// Every feature that registers its own Carbon hotkey or tap, rather than
    /// through `QuickToolHotkey`, claims where it registers and releases where
    /// it unregisters, under the same key.
    static func wiring(_ suite: TestSuite) {
        let services = "Sources/Vorssaint/Services/"
        let owners: [(file: String, register: String, unregister: String, key: String)] = [
            ("HotkeyManager.swift", "private func register(", "private func unregister()",
             "DefaultsKey.keepAwakeShortcut"),
            ("Shelf/ShelfService.swift", "private func registerHotkey()", "private func unregisterHotkey()",
             "DefaultsKey.shelfShortcut"),
            ("Clipboard/ClipboardHistoryService.swift", "private func registerHotkey()",
             "private func unregisterHotkey()", "DefaultsKey.clipboardHistoryShortcut"),
            ("Audio/SoundOutputSwitcher.swift", "private func registerHotkey()", "private func unregisterHotkey()",
             "DefaultsKey.soundOutputSwitcherShortcut"),
            ("Finder/FinderRenameService.swift", "func syncWithPreferences()", "private func removeTap()",
             "DefaultsKey.finderRenameShortcut"),
            ("WindowLayout/WindowLayoutService.swift", "private func registerHotkeys()",
             "private func unregisterHotkeys()", "action.shortcutKey"),
            ("WindowLayout/WindowLayoutService.swift", "private func registerDirectionalHotkey()",
             "private func unregisterDirectionalHotkey()", "DefaultsKey.windowDirectionalShortcut"),
        ]
        for owner in owners {
            let path = services + owner.file
            suite.expect(body(path, owner.register).contains("SystemShortcutTakeover.claim(\(owner.key),"),
                         "\(owner.file) claims \(owner.key) where it registers")
            suite.expect(body(path, owner.unregister).contains("SystemShortcutTakeover.release(\(owner.key))"),
                         "\(owner.file) releases \(owner.key) where it unregisters")
        }
        let quickTool = services + "QuickTools/QuickToolHotkey.swift"
        suite.expect(body(quickTool, "func unregister()").contains("SystemShortcutTakeover.release(claimedKey)"),
                     "every quick tool hotkey releases its claim when it unregisters")

        // Quit and launch, from the app delegate.
        let delegate = "Sources/Vorssaint/App/AppDelegate.swift"
        suite.expect(body(delegate, "func applicationWillTerminate(").contains("SystemShortcutTakeover.restoreAll()"),
                     "quitting hands every taken-over key back")
        let launch = body(delegate, "func applicationDidFinishLaunching(")
        let recovery = launch.range(of: "SystemShortcutTakeover.recoverIfNeeded(")
        let firstClaim = launch.range(of: "HotkeyManager.shared.syncWithPreferences()")
        suite.expect(recovery != nil && firstClaim != nil && recovery!.lowerBound < firstClaim!.lowerBound,
                     "crash recovery runs before the first claim of the launch")

        // The recorder rows: one decision, and a move off macOS keys, a reset
        // or a clear each drop the opt-in (`drops` counts those places), and
        // only rows whose key a feature claims may offer.
        let rows: [(file: String, view: String, save: String, key: String, drops: Int)] = [
            ("Sources/Vorssaint/UI/ShortcutRecorderButton.swift", "struct ShortcutPreferenceRow:",
             "private func save(", "role.storageKey", 3),
            ("Sources/Vorssaint/UI/Settings/WindowLayoutSettings.swift", "struct WindowLayoutActionRow:",
             "private func save(", "action.shortcutKey", 3),
            ("Sources/Vorssaint/UI/Settings/CutPasteSettings.swift", "struct CutPasteSettings:",
             "private func saveRenameShortcut(", "DefaultsKey.finderRenameShortcut", 2),
        ]
        for row in rows {
            let save = flat(body(row.file, row.save))
            let whole = body(row.file, row.view)
            suite.expect(save.contains("SystemShortcutTakeoverSupport.recorderDecision(")
                         && save.contains("if clearTakeOver { SystemShortcutTakeover.setTakeOver(\(row.key), false) }")
                         && !save.contains("conflictsWithSystemShortcut {"),
                         "\(row.file) asks the take-over decision instead of refusing macOS keys outright")
            suite.expect(whole.components(separatedBy: "SystemShortcutTakeover.setTakeOver(\(row.key), false)").count
                         == row.drops + 1
                         && whole.contains("SystemShortcutTakeover.setTakeOver(\(row.key), true)"),
                         "\(row.file) records the opt-in on accept and drops it on reset")
        }
        let roleSave = flat(body(rows[0].file, rows[0].save))
        suite.expect(roleSave.contains("if !role.supportsTakeOver, shortcut.conflictsWithSystemShortcut(for: role) {")
                     && roleSave.contains("conflictsWithMacOS: role.supportsTakeOver && SystemShortcutTakeover.conflictsWithMacOS("),
                     "a row nothing claims through keeps refusing macOS keys instead of offering")
        suite.expect(flat(body(rows[1].file, rows[1].save)).contains("includeInactive: true"),
                     "window layout keeps checking inactive features for conflicts")
    }
}
