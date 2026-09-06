import Testing
@testable import LevmiCore

@Suite("LevmiCore smoke")
struct LevmiCoreSmokeTests {
    @Test("Package exposes a version")
    func versionIsSet() {
        #expect(LevmiCore.version == "0.1.0")
    }
}
