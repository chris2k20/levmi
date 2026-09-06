import SwiftUI
import LevmiCore

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                Text("LEVMI")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Core \(LevmiCore.version) · skeleton")
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityIdentifier("root")
    }
}

#Preview { ContentView() }
