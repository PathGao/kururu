import Foundation

enum BrightnessNativeBoundaryTests {
    static func run(_ expect: (Bool, String) -> Void) {
        let displays: [(id: UInt32, isBuiltIn: Bool)] = [(1, true), (2, false), (3, false)]
        expect(BrightnessSupport.commandBrightnessTarget(pointerDisplayID: 1, displays: displays) == nil,
               "a pointer on the built-in display never falls back to an external display")
        expect(BrightnessSupport.commandBrightnessTarget(pointerDisplayID: 3, displays: displays) == 3,
               "the command selects the pointed external display, not the first")
        expect(BrightnessSupport.commandBrightnessTarget(pointerDisplayID: nil, displays: displays) == nil,
               "no pointer target never guesses the first display")
        expect(BrightnessSupport.commandBrightnessTarget(pointerDisplayID: 9, displays: displays) == nil,
               "a display absent from the brightness snapshot is not replaced by another")
        expect(BrightnessSupport.commandBrightnessTarget(pointerDisplayID: 1, displays: []) == nil,
               "no known displays yields no target")
        expect(BrightnessSupport.commandBrightnessRequest(
            direction: -1, pointerDisplayID: 2, displays: displays)
            == BrightnessSupport.CommandBrightnessRequest(
                displayID: 2, delta: -BrightnessSupport.brightnessKeyStep),
               "screen shortcut resolves the pointed external display and safe step")
        expect(BrightnessSupport.commandBrightnessRequest(
            direction: 1, pointerDisplayID: 1, displays: displays) == nil,
               "screen shortcut never redirects a built-in target to another display")
        for followsPointer in [false, true] {
            for overlay in [false, true] {
                expect(!BrightnessSupport.stepsSystemRoutedDisplay(followsPointer: followsPointer,
                                                                   displayIsBuiltIn: true,
                                                                   overlayReplacesNative: overlay),
                       "built-in brightness stays native regardless of pointer routing or overlay")
            }
        }
        expect(BrightnessSupport.stepsSystemRoutedDisplay(followsPointer: true,
                                                          displayIsBuiltIn: false,
                                                          overlayReplacesNative: false),
               "pointer-routed external brightness still steps")
        expect(BrightnessSupport.stepsSystemRoutedDisplay(followsPointer: false,
                                                          displayIsBuiltIn: false,
                                                          overlayReplacesNative: true),
               "external native-target overlay retains stepping")
        expect(!BrightnessSupport.stepsSystemRoutedDisplay(followsPointer: false,
                                                           displayIsBuiltIn: false,
                                                           overlayReplacesNative: false),
               "an external display without routing or overlay stays native")
    }
}
