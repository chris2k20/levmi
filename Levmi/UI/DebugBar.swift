import SwiftUI

// MARK: - DebugBar
//
// Nur im Debug-Build sichtbar (poc-spec 1.4): „Demo" schaltet `Rules.demo`/`Rules.standard` um,
// „Neu" setzt den Spielstand zurück. Im Release nicht vorhanden.

#if DEBUG
struct DebugBar: View {

    @Binding var isDemo: Bool
    var onReset: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            Button {
                isDemo.toggle()
            } label: {
                Label(isDemo ? "Demo an" : "Demo", systemImage: isDemo ? "hare.fill" : "hare")
                    .font(Theme.Font.footnote())
            }
            .buttonStyle(.glass)
            .frame(minHeight: Theme.minTapTarget)
            .accessibilityLabel(isDemo ? "Demo-Modus, aktiv" : "Demo-Modus, aus")
            .accessibilityHint("Verkürzt Wartezeiten für den Test")

            Button {
                onReset()
            } label: {
                Label("Neu", systemImage: "arrow.counterclockwise")
                    .font(Theme.Font.footnote())
            }
            .buttonStyle(.glass)
            .frame(minHeight: Theme.minTapTarget)
            .accessibilityLabel("Spielstand zurücksetzen")
        }
        .labelStyle(.titleAndIcon)
        .controlSize(.small)
        .accessibilityElement(children: .contain)
    }
}
#endif
