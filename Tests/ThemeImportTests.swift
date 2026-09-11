import Foundation

enum ThemeImportTests {
    static func run(_ expect: (Bool, String) -> Void) {
        func parse(_ text: String) -> ImportedTheme? { try? ThemeImportSupport.parse(Data(text.utf8)) }
        runLinks(expect)
        let plain = ##"{"name":"Local","colors":{"editor.background":"#123","foreground":"#1234","descriptionForeground":"#11223344","focusBorder":"#abcdef","sideBar.background":"#456789","panel.border":"#AABBCC"}}"##
        let theme = parse(plain)
        expect(theme?.colors.count == 6, "six UI roles are imported")
        expect(theme?.colors[.background]?.hex == "#112233FF", "short RGB expands with opaque alpha")
        expect(theme?.colors[.primaryText]?.hex == "#11223344", "short RGBA expands all channels")
        expect(theme?.colors[.secondaryText]?.alpha == 68.0 / 255, "eight-digit alpha is preserved")
        expect(parse(##"{"colors":{"editor.background":"#123",},}//tail"##)?.colors[.background]?.hex == "#112233FF", "JSONC line comments and trailing commas")
        expect(parse(##"{/* x */"colors":{"editor.background":"#123"/* y */},}"##) != nil, "JSONC block comments")
        expect(parse(##"{"name":"https://example.test/*x*/","colors":{"foreground":"#fff"}}"##)?.name == "https://example.test/*x*/", "comment markers inside strings are preserved")
        expect(parse(##"{"name":"a\"//b","colors":{"foreground":"#fff"}}"##)?.name == "a\"//b", "escaped string quote does not open a comment")
        expect(parse(##"{"include":"/missing/never-read.json","colors":{"foreground":"#fff"}}"##) != nil, "include never loads files")
        expect(parse(##"{"tokenColors":[{"settings":{"foreground":"#fff"}}]}"##) == nil, "syntax colors cannot become UI colors")
        expect(parse(##"{"colors":{"editor.foreground":"#123","foreground":"#456"}}"##)?.colors[.primaryText]?.hex == "#112233FF", "specific UI role precedes fallback")
        expect(parse(##"{"colors":{"foreground":"#fff","unused.role":"not a color"}}"##) != nil, "unknown roles are ignored")
        for text in [
            ##"{'colors': {'foreground': '#fff'}}"##,
            ##"{colors: {foreground: '#fff'}}"##,
            ##"{"colors":{"foreground":"rgb(0,0,0)"}}"##,
            ##"{"colors":{"foreground":"#ggg"}}"##,
            ##"{"colors":{"foreground":"#12345"}}"##,
            ##"{"colors":{"foreground":12}}"##,
            ##"{"colors":{"foreground":null}}"##,
            ##"{"colors":{"foreground":"#fff","editor.foreground":"bad"}}"##,
            ##"{"colors":{"foreground":"#fff"}}/* never closed"##,
            ##"{"colors":{"foreground":"#fff",,}}"##,
            ##"{"colors":[]}"##, ##"[]"##, ##"{}"##
        ] { expect(parse(text) == nil, "invalid theme rejected: \(text)") }
        expect((try? ThemeImportSupport.parse(Data(repeating: 32, count: ThemeImportSupport.maximumBytes + 1))) == nil, "oversize input rejected")
        expect((try? ThemeImportSupport.parse(Data([0xFF, 0xFE]))) == nil, "non-UTF8 input rejected")
        if let theme {
            let saved = try? ThemeImportSupport.savedData(theme)
            expect(saved.flatMap { try? ThemeImportSupport.parse($0) } == theme, "normalized persistence round trips")
        }
        let directory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("build/theme-read-tests-\(UUID().uuidString)", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let file = directory.appendingPathComponent("配色.jsonc")
            try Data(plain.utf8).write(to: file)
            expect((try? ThemeImportSupport.read(file)) == theme, "selected local file imports, including Unicode path")
            try Data(repeating: 32, count: ThemeImportSupport.maximumBytes + 1).write(to: file)
            do {
                _ = try ThemeImportSupport.read(file)
                expect(false, "oversized file throws")
            } catch {
                expect(error as? ThemeImportError == .tooLarge, "oversized file reports the size limit")
            }
            expect((try? ThemeImportSupport.read(directory)) == nil, "directories are not theme files")
            expect((try? ThemeImportSupport.read(URL(string: "https://example.test/theme.json")!)) == nil, "remote URLs are never read")
        } catch { expect(false, "file fixture setup succeeds: \(error)") }
        let suite = "com.vorssaint.tests.theme.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("keep", forKey: "unrelated")
        let preferences = ThemePreferences(defaults: defaults)
        expect(preferences.applied == nil, "no saved theme means default")
        if let theme {
            do { try preferences.apply(theme) } catch { expect(false, "valid apply succeeds") }
            expect(ThemePreferences(defaults: defaults).applied == theme, "applied theme survives a new preferences instance")
            let before = defaults.data(forKey: ThemePreferences.storageKey)
            _ = parse("invalid")
            do {
                try preferences.apply(ImportedTheme(name: "Broken", colors: [:]))
                expect(false, "invalid apply throws")
            } catch { expect(true, "invalid apply throws") }
            expect(defaults.data(forKey: ThemePreferences.storageKey) == before && preferences.applied == theme, "invalid preview leaves active theme unchanged")
            preferences.restoreDefault()
            expect(preferences.applied == nil && defaults.object(forKey: ThemePreferences.storageKey) == nil, "restore removes only theme state")
            expect(defaults.string(forKey: "unrelated") == "keep", "restore preserves other preferences")
        }
        let registrationBeforeBackup = UserDefaults.standard.volatileDomain(forName: UserDefaults.registrationDomain)
        runBackup(expect)
        let registrationAfterBackup = UserDefaults.standard.volatileDomain(forName: UserDefaults.registrationDomain)
        expect(NSDictionary(dictionary: registrationBeforeBackup).isEqual(to: registrationAfterBackup),
               "theme backup tests restore the shared registration domain exactly")
        defaults.set(Data("broken".utf8), forKey: ThemePreferences.storageKey)
        expect(ThemePreferences(defaults: defaults).applied == nil, "corrupt saved data falls back without crashing")
    }
    private static func runLinks(_ expect: (Bool, String) -> Void) {
        let valid = "https://vscodethemes.com/e/teabyii.ayu/ayu-dark-bordered"
        let link = try? ThemeLinkImportSupport.parse("  " + valid + "\n")
        expect(link?.publisher == "teabyii" && link?.extensionName == "ayu" && link?.slug == "ayu-dark-bordered",
               "theme page identifies the exact extension and variant")
        expect(link?.downloadURL.host == "teabyii.gallery.vsassets.io", "theme download uses extension publisher asset host")
        for invalid in ["", "http://vscodethemes.com/e/a.b/dark", "https://example.com/e/a.b/dark",
                        "https://vscodethemes.com.evil.test/e/a.b/dark", "https://user@vscodethemes.com/e/a.b/dark",
                        "https://vscodethemes.com:443/e/a.b/dark", "https://vscodethemes.com/e/a.b",
                        "https://vscodethemes.com/e/a.b/dark/extra", valid + "?x=1", valid + "#fragment",
                        "https://vscodethemes.com/e/a.b/../dark", "https://vscodethemes.com/e/a.b/a%2Fb"] {
            expect((try? ThemeLinkImportSupport.parse(invalid)) == nil, "theme link rejects unsupported destination or path: \(invalid)")
        }
        func manifest(_ themes: [[String: String]]) -> Data {
            try! JSONSerialization.data(withJSONObject: ["contributes": ["themes": themes]])
        }
        let data = manifest([["label": "Ayu Dark", "path": "./themes/dark.json"],
                             ["label": "Ayu Dark Bordered", "path": "./themes/dark-bordered.json"]])
        let selected = try? ThemeLinkImportSupport.selection(manifest: data, slug: "ayu-dark-bordered")
        expect(selected?.path == "extension/themes/dark-bordered.json" && selected?.name == "Ayu Dark Bordered",
               "theme variant matches a whole label rather than first or path substring")
        expect((try? ThemeLinkImportSupport.selection(manifest: data, slug: "dark")) == nil,
               "theme selection rejects partial labels")
        let ambiguous = manifest([["label": "Dark", "path": "a.json"], ["id": "dark", "path": "b.json"]])
        expect((try? ThemeLinkImportSupport.selection(manifest: ambiguous, slug: "dark")) == nil,
               "ambiguous theme selection never silently picks first")
        for path in ["/theme.json", "../theme.json", "themes/../../theme.json", "themes//a.json",
                     "themes/*.json", "themes/a?.json", "themes/[ab].json", "themes\\a.json"] {
            expect((try? ThemeLinkImportSupport.selection(manifest: manifest([["label": "Dark", "path": path]]), slug: "dark")) == nil,
                   "theme archive member rejects traversal and extraction wildcards: \(path)")
        }
    }

    private static func runBackup(_ expect: (Bool, String) -> Void) {
        let registration = UserDefaults.standard.volatileDomain(forName: UserDefaults.registrationDomain)
        defer { UserDefaults.standard.setVolatileDomain(registration, forName: UserDefaults.registrationDomain) }
        let key = ThemePreferences.storageKey
        let suite = "com.vorssaint.tests.theme-backup.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.register(defaults: Defaults.registeredDefaults)
        defaults.set("unchanged", forKey: "unrelated")
        func envelope(_ value: Any?) -> [String: Any] {
            [SettingsBackupSupport.formatVersionKey: SettingsBackupSupport.formatVersion,
             SettingsBackupSupport.settingsKey: value.map { [key: $0] } ?? [:]]
        }
        do {
            let theme = try ThemeImportSupport.parse(Data(##"{"name":"Portable","colors":{"editor.background":"#234","foreground":"#fff"}}"##.utf8))
            try ThemePreferences(defaults: defaults).apply(theme)
            expect(Defaults.registeredDefaults[key] as? Data == Data(), "theme registers an explicit built-in default")
            let payload = SettingsBackupSupport.payload(appVersion: "theme-test") { defaults.object(forKey: $0) }
            let encoded = try PropertyListSerialization.data(fromPropertyList: payload, format: .xml, options: 0)
            let decoded = try PropertyListSerialization.propertyList(from: encoded, options: [], format: nil) as! [String: Any]
            let sanitized = SettingsBackupSupport.sanitizedSettings(from: decoded)
            expect(sanitized?[key] as? Data != nil, "a real plist backup includes imported colors")
            defaults.removeObject(forKey: key)
            if let sanitized { SettingsBackupSupport.replaceExportedSettings(sanitized, in: defaults) }
            expect(ThemePreferences(defaults: defaults).applied == theme, "backup restores the applied theme through the production replacement seam")
            let before = defaults.persistentDomain(forName: suite)! as NSDictionary
            for invalid: Any in ["not data", 42, Data("broken".utf8), Data(repeating: 32, count: ThemeImportSupport.maximumBytes + 1)] {
                let settings = SettingsBackupSupport.sanitizedSettings(from: envelope(invalid))
                expect(settings == nil, "malformed or oversized theme rejects the backup before clearing settings")
                if let settings { SettingsBackupSupport.replaceExportedSettings(settings, in: defaults) }
                expect((defaults.persistentDomain(forName: suite)! as NSDictionary).isEqual(to: before as! [AnyHashable: Any]), "failed restore leaves all existing preferences unchanged")
                let export = SettingsBackupSupport.payload(appVersion: "test") { $0 == key ? invalid : nil }
                expect((export[SettingsBackupSupport.settingsKey] as? [String: Any])?[key] == nil,
                       "invalid local theme cache is not exported")
            }
            let old = SettingsBackupSupport.sanitizedSettings(from: envelope(nil))
            expect(old != nil && old?[key] == nil, "older backups without a theme remain valid")
            if let old { SettingsBackupSupport.replaceExportedSettings(old, in: defaults) }
            expect(ThemePreferences(defaults: defaults).applied == nil, "an older backup restores built-in colors")
            expect(defaults.string(forKey: "unrelated") == "unchanged", "theme backup restore preserves non-exported state")
            let defaultBackup = SettingsBackupSupport.sanitizedSettings(from: envelope(Data()))
            expect(defaultBackup?[key] as? Data == Data(), "explicit built-in default is a valid backup value")
            let extra = Data(##"{"include":"/private/theme.json","tokenColors":[{"scope":"secret"}],"colors":{"foreground":"#abc"}}"##.utf8)
            let portable = SettingsBackupSupport.sanitizedSettings(from: envelope(extra))?[key] as? Data
            let normalized = portable.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
            expect(normalized?["include"] == nil && normalized?["tokenColors"] == nil && portable != nil,
                   "incoming themes retain only normalized portable colors")
        } catch { expect(false, "theme backup fixture succeeds: \(error)") }
    }

}
