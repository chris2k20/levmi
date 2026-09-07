import SwiftUI

struct ContentView: View {
    @State private var appModel = AppModel()

    var body: some View {
        // TEMPORÄR während der Szenen-Abnahme auf IslandDemoView umgeschaltet — GameEngine/
        // SceneProjection sind noch im Umbau (Stub-Implementierungen, siehe LevmiCore), daher lässt
        // sich die Choreografie darüber gerade nicht deterministisch prüfen. Vor Abgabe zurück auf
        // `GameView(appModel: appModel)` stellen, sobald die Domain steht.
        IslandDemoView()
            .accessibilityIdentifier("root")
    }
}

#Preview { ContentView() }
