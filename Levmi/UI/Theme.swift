import SwiftUI

// MARK: - Levmi Theme
//
// Reine Präsentation (poc-spec.md §2): Farben, Schrift, Abstände. Keine Domain-Logik, kein
// SceneKit. Die Pain-Kachel-Lichtfarbe (`PainTile` → Hex) lebt bewusst in
// `Levmi/Scene/SceneKitRenderer.swift` (Kommentar dort) — nicht doppelt hier pflegen.

/// Visuelle Sprache der App: Farben, Schriften, Abstände, Bewegungs-Konstanten.
enum Theme {

    // MARK: Farben (poc-spec §2)

    enum Color {
        /// Nebelmeer — tiefes Blauschwarz, Hintergrund der Welt.
        static let fogSea = SwiftUI.Color(hex: "04040E")
        /// Nebel, kühl, nah am Betrachter.
        static let fogNear = SwiftUI.Color(hex: "0B0E22")
        /// Nebel am Horizont.
        static let fogHorizon = SwiftUI.Color(hex: "1A2447")
        /// Licht des Spielers, warm (Standard — färbt sich dauerhaft durch „Wofür?").
        static let lightWarm = SwiftUI.Color(hex: "FFB347")
        /// Wurzeln.
        static let gold = SwiftUI.Color(hex: "FFD37A")
        /// Kristall-Durchbruch.
        static let cyan = SwiftUI.Color(hex: "7FE7FF")
    }

    // MARK: Schrift — SF Rounded für Titel, sonst Standard. Immer Text-Styles (Dynamic Type).

    enum Font {
        static func title(_ style: SwiftUI.Font.TextStyle = .title2) -> SwiftUI.Font {
            .system(style, design: .rounded).weight(.semibold)
        }
        static func eyebrow() -> SwiftUI.Font {
            .system(.caption, design: .rounded).weight(.semibold)
        }
        static func body() -> SwiftUI.Font {
            .system(.body, design: .default)
        }
        static func footnote() -> SwiftUI.Font {
            .system(.footnote, design: .default)
        }
    }

    // MARK: Abstände — keine festen Höhen, nur Innen-/Außenabstände.

    enum Spacing {
        static let xs: CGFloat = 6
        static let s: CGFloat = 10
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 36
    }

    // MARK: Bewegung — respektiert Reduce Motion an den Aufrufstellen (nicht hier zentral, da
    // `@Environment` nur in Views lesbar ist).

    enum Motion {
        static let cardAppearDuration: Double = 0.45
        static let cardSlideOffset: CGFloat = 28
    }

    static let cardCornerRadius: CGFloat = 24
    /// Mindestgröße für Tap-Ziele (Buttons, Kacheln, Schalter).
    static let minTapTarget: CGFloat = 44
}

extension SwiftUI.Color {
    /// `"RRGGBB"` oder `"#RRGGBB"`, optional mit Alpha (`"RRGGBBAA"`).
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let r, g, b, a: Double
        if cleaned.count > 6 {
            r = Double((value & 0xFF00_0000) >> 24) / 255
            g = Double((value & 0x00FF_0000) >> 16) / 255
            b = Double((value & 0x0000_FF00) >> 8) / 255
            a = Double(value & 0x0000_00FF) / 255
        } else {
            r = Double((value & 0xFF_0000) >> 16) / 255
            g = Double((value & 0x00_FF00) >> 8) / 255
            b = Double(value & 0x00_00FF) / 255
            a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
