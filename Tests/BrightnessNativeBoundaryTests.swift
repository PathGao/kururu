import Foundation

enum BrightnessNativeBoundaryTests {
    static func run(_ expect: (Bool, String) -> Void) {
        expect(BrightnessSupport.shortcutDisplay(followsPointer: true, pointerDisplay: 2,
                   primaryDisplay: 1, eligible: [1, 2]) == 2,
               "display shortcuts follow the pointer onto an external monitor")
        expect(BrightnessSupport.shortcutDisplay(followsPointer: false, pointerDisplay: 2,
                   primaryDisplay: 1, eligible: [1, 2]) == 1,
               "display shortcuts use the primary display when pointer routing is off")
        expect(BrightnessSupport.shortcutDisplay(followsPointer: true, pointerDisplay: 2,
                   primaryDisplay: 1, eligible: [1]) == nil,
               "an unavailable pointer target never changes a different display")
        expect(BrightnessSupport.shortcutDisplay(followsPointer: true, pointerDisplay: nil,
                   primaryDisplay: 1, eligible: [1]) == nil,
               "a missing pointer target does not dim the primary display")
        expect(BrightnessSupport.shortcutDisplay(followsPointer: false, pointerDisplay: 2,
                   primaryDisplay: 1, eligible: [2]) == nil,
               "an unavailable primary display never redirects the shortcut")
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
