// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum RadialTrackpadBindingTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let old = Data("[{\"name\":\"Legacy\",\"items\":[]}]".utf8)
        expect(RadialMenuSupport.decodedStoredProfiles(old)?.first?.trackpadTapFingers == 0,
               "Legacy profiles have no trackpad binding")
        for raw in ["2", "5", "-1", "\"four\"", "null"] {
            let data = Data("[{\"name\":\"Preserved\",\"trackpadTapFingers\":\(raw),\"items\":[]}]".utf8)
            let profile = RadialMenuSupport.decodedStoredProfiles(data)?.first
            expect(profile?.name == "Preserved" && profile?.trackpadTapFingers == 0,
                   "Invalid tap value falls back to off without dropping the profile")
        }
        let first = RadialMenuProfile(name: "First", trackpadTapFingers: 3)
        let second = RadialMenuProfile(name: "Second", trackpadTapFingers: 3)
        let fourth = RadialMenuProfile(name: "Fourth", trackpadTapFingers: 4)
        let data = RadialMenuSupport.encodeProfiles([first, second, fourth])
        let roundTrip = RadialMenuSupport.decodedStoredProfiles(data) ?? []
        expect(roundTrip.map(\.trackpadTapFingers) == [3, 3, 4],
               "Backup round trip preserves conflicting assignments for explicit resolution")
        expect(TrackpadGestureRouting.owner(fingers: 3, middleClickTapFingers: 0, profiles: roundTrip) == nil,
               "Conflicting imported assignments do not silently choose the first profile")
        expect(TrackpadGestureRouting.owner(fingers: 3, middleClickTapFingers: 0, profiles: [first, fourth]) == .radial(first.id),
               "Deleting or clearing the competing binding makes the remaining assignment usable")
        expect(RadialMenuSupport.needsAccessibility([first]),
               "A trackpad-only radial profile requires Accessibility")
        expect(!RadialMenuSupport.needsAccessibility([RadialMenuProfile(name: "No input control")]),
               "A profile without gesture or input actions does not add Accessibility")
    }
}
