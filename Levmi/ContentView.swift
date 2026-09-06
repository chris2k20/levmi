import SwiftUI
import LevmiCore

struct ContentView: View {
    var body: some View {
        ZStack(alignment: .top) {
            SceneKitSpikeView()
                .ignoresSafeArea()
            VStack(spacing: 6) {
                Text("LEVMI")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .tracking(6)
                Text("Spike · SceneKit · HDR Bloom · Core \(LevmiCore.version)")
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .glassEffect(.regular, in: .rect(cornerRadius: 22))
            .padding(.top, 12)
        }
        .accessibilityIdentifier("root")
    }
}

#Preview { ContentView() }
