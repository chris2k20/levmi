import SwiftUI

// MARK: - LevmiCard
//
// Die eine Overlay-Komponente, aus der alle Karten in Konfiguration entstehen (poc-spec §3 nennt
// „Overlays" als eigenes Modul — hier als Konfigurationen EINER Komponente statt zwölf eigener
// Layouts). Glass-Karte mit festen Slots: eyebrow, title, body, content, primary/secondary,
// footnote. Erscheint mit weichem Fade+Slide von unten (Reduce Motion: nur Fade).

/// Ein Button-Slot auf `LevmiCard` (primary/secondary).
struct LevmiCardButton {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    init(title: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }
}

struct LevmiCard<Content: View>: View {

    var eyebrow: String?
    var title: String
    var bodyText: String?
    var footnote: String?
    var primary: LevmiCardButton?
    var secondary: LevmiCardButton?
    private let content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false

    init(
        eyebrow: String? = nil,
        title: String,
        bodyText: String? = nil,
        footnote: String? = nil,
        primary: LevmiCardButton? = nil,
        secondary: LevmiCardButton? = nil,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.bodyText = bodyText
        self.footnote = footnote
        self.primary = primary
        self.secondary = secondary
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            if let eyebrow {
                Text(eyebrow)
                    .font(Theme.Font.eyebrow())
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(Theme.Font.title())
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            if let bodyText {
                Text(bodyText)
                    .font(Theme.Font.body())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            content()

            if primary != nil || secondary != nil {
                VStack(spacing: Theme.Spacing.s) {
                    if let primary {
                        Button(primary.title, action: primary.action)
                            .buttonStyle(.glassProminent)
                            .disabled(!primary.isEnabled)
                            .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
                    }
                    if let secondary {
                        Button(secondary.title, action: secondary.action)
                            .buttonStyle(.glass)
                            .disabled(!secondary.isEnabled)
                            .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
                    }
                }
            }

            if let footnote {
                Text(footnote)
                    .font(Theme.Font.footnote())
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(Theme.Spacing.l)
        .frame(maxWidth: 520)
        .glassEffect(.regular, in: .rect(cornerRadius: Theme.cardCornerRadius))
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible || reduceMotion ? 0 : Theme.Motion.cardSlideOffset)
        .onAppear {
            if reduceMotion {
                withAnimation(.easeOut(duration: Theme.Motion.cardAppearDuration)) { isVisible = true }
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { isVisible = true }
            }
        }
    }
}
