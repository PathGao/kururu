import Foundation

enum CleanerRunResultTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let name = "CleanerRunResultTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(123.0, forKey: DefaultsKey.cleanerLastAutoRun)
        defaults.set(4096, forKey: DefaultsKey.cleanerLastAutoFreed)
        expect(CleanerRunResult(defaults: defaults).outcome == .unknown,
               "legacy timestamps and bytes cannot establish that every item succeeded")
        CleanerRunResult(failed: 2, attempted: 3).save(
            freed: 4096, at: Date(timeIntervalSince1970: 456), defaults: defaults)
        expect(defaults.double(forKey: DefaultsKey.cleanerLastAutoRun) == 456,
               "the saved outcome belongs to the latest run timestamp")
        expect(CleanerRunResult(defaults: defaults).outcome == .partialFailure,
               "reopening a saved run must retain its partial failure")
        defaults.set(0, forKey: DefaultsKey.cleanerLastAutoFreed)
        expect(CleanerRunResult(defaults: defaults).outcome == .partialFailure,
               "successful zero-byte items still make a run partially successful")
        defaults.set(2, forKey: DefaultsKey.cleanerLastAutoAttempted)
        expect(CleanerRunResult(defaults: defaults).outcome == .failure,
               "a run with every attempted item failed must report failure")
        defaults.set(0, forKey: DefaultsKey.cleanerLastAutoFailed)
        defaults.set(0, forKey: DefaultsKey.cleanerLastAutoAttempted)
        expect(CleanerRunResult(defaults: defaults).outcome == .success,
               "a completed scan with no eligible items succeeds")
        expect(CleanerRunResult(failed: 2, attempted: 1).outcome == .unknown,
               "inconsistent result metadata must not report success")
        CleanerRunResult(failed: 0, attempted: 4).save(
            freed: 8192, at: Date(timeIntervalSince1970: 789), defaults: defaults)
        expect(CleanerRunResult(defaults: defaults).outcome == .success,
               "a later successful run replaces a previous failed result")
        expect(defaults.integer(forKey: DefaultsKey.cleanerLastAutoFreed) == 8192,
               "saved byte count belongs to the latest result")

        for language in [AppLanguage.enUS, .zhHans, .de, .fr, .es, .ja] {
            let strings = CleanerRunStrings.localized(language)
            let results = [CleanerRunResult(failed: 0, attempted: 4),
                           CleanerRunResult(failed: 3, attempted: 4),
                           CleanerRunResult(failed: 3, attempted: 3),
                           CleanerRunResult(failed: -1, attempted: -1)]
            let summaries = results.map {
                strings.summary(result: $0, ranAt: "DATE", freed: "BYTES")
            }
            expect(Set(summaries).count == 4,
                   "\(language): success, partial failure, total failure and legacy results stay distinguishable")
            expect(summaries.allSatisfy { $0.contains("DATE") && !$0.contains("%") },
                   "\(language): every result keeps its timestamp and renders its placeholders")
            expect(summaries[1].contains("3") && summaries[1].contains("BYTES")
                   && summaries[2].contains("3"),
                   "\(language): failure counts survive formatting, along with partial progress")
        }
    }
}
