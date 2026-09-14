import AppKit
@main struct UpstreamIntegrationMain {
    static func main() {
        let suite = TestSuite()
        suite.run("cleaner filesystem") { CleanerEligibilityTests.run(suite) }
        suite.run("switcher native scroll") { SwitcherScrollContract.run(suite) }
        suite.run("screenshot refresh") { ScreenshotSelectionRefreshContract.run(suite) }
        suite.run("recorder sample timing") { RecorderSampleTimingTests.run(expect: { suite.expect($0, $1) }) }
        suite.run("recorder MOV tracks") { RecorderWriterTests.run(expect: { suite.expect($0, $1) }) }
        suite.run("shelf delivery") { ShelfFilePromiseTests.run(expect: { suite.expect($0, $1) }) }
        suite.run("shelf routing") { ShelfDropRoutingTests.run(expect: { suite.expect($0, $1) }) }
        suite.run("uninstaller and status placement") { UpstreamPolicyTests.run { suite.expect($0, $1) } }
        suite.run("shelf promise cleanup") { ShelfPromiseCleanupTests.run { suite.expect($0, $1) } }
        suite.finish()
    }
}
