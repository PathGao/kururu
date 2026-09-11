// SPDX-License-Identifier: GPL-3.0-or-later
enum UninstallerSelectionTests {
    static func run(_ expect: (Bool, String) -> Void) {
        expect(UninstallerSelectionSupport.rejection(system: true, protected: true, actualPath: true, valid: true) == .systemApplication, "system protection has a specific reason")
        expect(UninstallerSelectionSupport.rejection(system: false, protected: true, actualPath: true, valid: true) == .protectedApplication, "self namespace is protected, not called malformed")
        expect(UninstallerSelectionSupport.rejection(system: false, protected: false, actualPath: false, valid: true) == .linkedPath, "linked applications require the actual path")
        expect(UninstallerSelectionSupport.rejection(system: false, protected: false, actualPath: true, valid: false) == .invalidApplication, "unverifiable applications are rejected")
        expect(UninstallerSelectionSupport.rejection(system: false, protected: false, actualPath: true, valid: true) == nil, "valid neutral applications remain selectable")
        for system in [false, true] {
            for protected in [false, true] {
                for actualPath in [false, true] {
                    for valid in [false, true] {
                        let error = UninstallerSelectionSupport.rejection(system: system, protected: protected,
                            actualPath: actualPath, valid: valid)
                        expect((error == nil) == (!system && !protected && actualPath && valid),
                               "no rejected validation combination becomes selectable")
                    }
                }
            }
        }
        for error in UninstallerSelectionError.allCases {
            let messages = ["en", "zh-Hans", "de", "fr", "es", "ja"].map { error.message(language: $0) }
            expect(Set(messages).count == 6 && messages.allSatisfy { !$0.isEmpty }, "each reason has six distinct locale messages")
            expect(error.message(language: "ko") == error.message(language: "en"), "other locales have English fallback")
        }
    }
}
