import SwiftUI

// MARK: - DayBadge
//
// „+1 Tag" (poc-spec 1.3). Erscheint groß mit Scale-Bounce (Reduce Motion: Fade), wandert nach
// 2,5 s klein an den oberen Rand und bleibt dort — kein Balken, kein Zähler.

struct DayBadge: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSmall = false
    @State private var isVisible = false

    var body: some View {
        Text("+1 Tag")
            .font(.system(isSmall ? .headline : .largeTitle, design: .rounded).weight(.bold))
            .foregroundStyle(Theme.Color.gold)
            .padding(.horizontal, isSmall ? Theme.Spacing.m : Theme.Spacing.l)
            .padding(.vertical, isSmall ? Theme.Spacing.xs : Theme.Spacing.m)
            .glassEffect(.regular, in: .capsule)
            .scaleEffect(isVisible ? 1 : 0.4)
            .opacity(isVisible ? 1 : 0)
            .padding(.top, isSmall ? Theme.Spacing.l : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isSmall ? .top : .center)
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Ein Tag geschafft")
            .task {
                if reduceMotion {
                    withAnimation(.easeOut(duration: 0.4)) { isVisible = true }
                } else {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { isVisible = true }
                }
                try? await Task.sleep(for: .seconds(2.5))
                withAnimation(.easeInOut(duration: 0.4)) { isSmall = true }
            }
    }
}
