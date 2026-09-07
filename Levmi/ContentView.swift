import SwiftUI

struct ContentView: View {
    @State private var appModel = AppModel()

    var body: some View {
        GameView(appModel: appModel)
            .accessibilityIdentifier("root")
    }
}

#Preview { ContentView() }
