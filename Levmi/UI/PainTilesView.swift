import SwiftUI
import LevmiCore

// MARK: - PainTilesView
//
// Onboarding-Schritt „Was hat dich diese Woche am meisten aufgehalten?" (poc-spec 1.2.1/1.2.2).
// Sechs Kacheln (`PainTile.allCases`), Mehrfachauswahl, „Weiter" auch bei leerer Auswahl aktiv
// (überspringbar). Danach dreht sich jede GEWÄHLTE Kachel per 3D-Rotation um und zeigt ihr
// Gegenteil (`tile.inverted`) — 3 s Gesamtdauer, Haptik pro Flip, dann `onContinue` mit der
// ursprünglichen (nicht der invertierten) Auswahl. Reduce Motion: Cross-Dissolve statt Drehung.

struct PainTilesView: View {

    var onFlipHaptic: () -> Void = {}
    var onContinue: ([PainTile]) -> Void

    @State private var selected: Set<PainTile> = []
    @State private var rotation: [PainTile: Double] = [:]
    @State private var revealed: Set<PainTile> = []
    @State private var isAnimating = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        let count = dynamicTypeSize >= .accessibility5 ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: Theme.Spacing.s), count: count)
    }

    var body: some View {
        LevmiCard(
            title: "Was hat dich diese Woche am meisten aufgehalten?",
            primary: LevmiCardButton(title: "Weiter", isEnabled: !isAnimating, action: continueTapped)
        ) {
            LazyVGrid(columns: columns, spacing: Theme.Spacing.s) {
                ForEach(PainTile.allCases, id: \.self) { tile in
                    tileView(tile)
                }
            }
        }
    }

    @ViewBuilder
    private func tileView(_ tile: PainTile) -> some View {
        let isSelected = selected.contains(tile)
        let showBack = revealed.contains(tile)
        let angle = rotation[tile] ?? 0

        Button {
            guard !isAnimating else { return }
            if isSelected { selected.remove(tile) } else { selected.insert(tile) }
        } label: {
            Text(showBack ? tile.inverted : tile.label)
                .font(Theme.Font.body().weight(.medium))
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .padding(Theme.Spacing.s)
                .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
                .scaleEffect(x: showBack && !reduceMotion ? -1 : 1, y: 1)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Theme.Color.lightWarm.opacity(0.28) : SwiftUI.Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isSelected ? Theme.Color.lightWarm : SwiftUI.Color.white.opacity(0.18),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .contentTransition(.opacity)
        }
        .buttonStyle(.plain)
        .rotation3DEffect(.degrees(reduceMotion ? 0 : angle), axis: (x: 0, y: 1, z: 0))
        .opacity(reduceMotion && angle > 0 && !showBack ? 0 : 1)
        .disabled(isAnimating)
        .accessibilityLabel(showBack ? tile.inverted : tile.label)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isSelected ? "ausgewählt" : "nicht ausgewählt")
    }

    private func continueTapped() {
        guard !isAnimating else { return }
        let chosen = Array(selected)
        guard !chosen.isEmpty else {
            onContinue(chosen)
            return
        }

        isAnimating = true
        let totalDuration = 3.0
        let halfFlip = 0.3
        let stagger = chosen.count > 1 ? min(0.35, (totalDuration - halfFlip * 2) / Double(chosen.count)) : 0

        for (index, tile) in chosen.enumerated() {
            let startDelay = Double(index) * stagger
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(startDelay))
                withAnimation(.easeIn(duration: halfFlip)) { rotation[tile] = 90 }
                try? await Task.sleep(for: .seconds(halfFlip))
                withAnimation(.easeInOut(duration: 0.2)) { revealed.insert(tile) }
                onFlipHaptic()
                withAnimation(.easeOut(duration: halfFlip)) { rotation[tile] = 180 }
            }
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(totalDuration))
            isAnimating = false
            onContinue(chosen)
        }
    }
}
