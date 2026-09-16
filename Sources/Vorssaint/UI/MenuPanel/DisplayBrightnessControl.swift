import SwiftUI

/// Unknown hardware readings have no slider thumb; setting an absolute target
/// remains possible without presenting an invented midpoint as a measurement.
struct DisplayBrightnessControl: View {
    @ObservedObject private var service = BrightnessService.shared
    @ObservedObject private var l10n = L10n.shared
    let display: BrightnessDisplay
    let showOSD: Bool
    @State private var target = ""

    private var text: FeatureBehaviorStrings { .init(language: l10n.language) }
    private var parsedTarget: Double? {
        guard let value = Double(target), value.isFinite, (0...100).contains(value) else { return nil }
        return value / 100
    }

    var body: some View {
        Group {
            if display.observedBrightness != nil || display.requestedBrightness != nil {
                Slider(value: Binding(get: { display.requestedBrightness ?? display.observedBrightness ?? display.brightness },
                                      set: { service.setBrightness($0, for: display.id, showOSD: showOSD) }),
                       in: 0...1)
                    .controlSize(.small)
                    .accessibilityLabel(display.name)
            } else {
                HStack {
                    TextField(text.level, text: $target)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 150)
                        .accessibilityLabel(text.level)
                        .onSubmit { submit() }
                    Button(text.setLevel) { submit() }
                        .disabled(parsedTarget == nil)
                        .controlSize(.small)
                }
            }
        }
        .disabled(service.isDisplayPending(display.id))
    }

    private func submit() {
        guard let parsedTarget else { return }
        service.setBrightness(parsedTarget, for: display.id, showOSD: showOSD)
    }
}
