#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
python3 Tests/generate_upstream_sources.py
swiftc -Onone "$@" \
    Sources/Vorssaint/Services/Recorder/RecorderComposition.swift \
    Sources/Vorssaint/Services/Recorder/RecorderCaptureEngine.swift \
    Sources/Vorssaint/Services/Recorder/RecorderWriter.swift \
    Sources/Vorssaint/Services/Recorder/RecorderSampleTiming.swift \
    Sources/Vorssaint/Core/ShelfPromiseDeliveryStrings.swift \
    Sources/Vorssaint/Services/Shelf/ShelfFilePromiseTransfer.swift \
    Tests/UpstreamTestSuite.swift Tests/UpstreamIntegrationMain.swift Tests/UpstreamPolicyTests.swift Tests/ShelfPromiseCleanupTests.swift \
    Tests/CleanerEligibilityTests.swift Tests/SwitcherScrollTests.swift \
    Tests/ScreenshotSelectionRefreshTests.swift \
    Tests/RecorderSampleTimingTests.swift Tests/RecorderWriterTests.swift \
    Tests/ShelfFilePromiseTests.swift Tests/ShelfDropRoutingTests.swift \
    build/generated-tests/*.swift \
    -o build/upstream-integration-tests
./build/upstream-integration-tests
