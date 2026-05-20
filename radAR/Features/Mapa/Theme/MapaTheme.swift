import SwiftUI

/// Local-to-Mapa dark "situation room" palette. Lives apart from `RadarTheme` so
/// the rest of the (light) app is unaffected.
enum MapaTheme {
    enum Colors {
        static let background = Color(red: 0.039, green: 0.051, blue: 0.071)        // #0a0d12
        static let backgroundDeep = Color(red: 0.020, green: 0.027, blue: 0.043)    // #05070b
        static let surface = Color(red: 0.082, green: 0.106, blue: 0.137)           // #151b23
        static let surfaceElevated = Color(red: 0.118, green: 0.149, blue: 0.188)   // #1e2630
        static let border = Color(red: 0.169, green: 0.196, blue: 0.227)            // #2b323a
        static let borderStrong = Color(red: 0.247, green: 0.275, blue: 0.314)      // #3f4650
        static let hairline = Color.white.opacity(0.08)

        static let textPrimary = Color(red: 0.949, green: 0.953, blue: 0.965)       // #f2f3f6
        static let textSecondary = Color(red: 0.643, green: 0.671, blue: 0.706)     // #a4abb4
        static let textTertiary = Color(red: 0.443, green: 0.475, blue: 0.518)      // #717984
        static let textInverse = Color(red: 0.024, green: 0.031, blue: 0.047)       // for text on accent fills

        static let accent = Color(red: 0.973, green: 0.369, blue: 0.133)            // #f85e22 — reserved for URGENTE / breaking
        static let accentMuted = accent.opacity(0.18)
        static let accentGlow = accent.opacity(0.35)

        /// Informational / selection accent (blue). Used for selected pins,
        /// active provinces, target callouts — anything that isn't an alert.
        static let info = Color(red: 0.302, green: 0.635, blue: 1.0)                // #4da2ff
        static let infoMuted = info.opacity(0.18)
        static let infoGlow = info.opacity(0.35)

        static let mapLand = Color(red: 0.110, green: 0.137, blue: 0.176)          // clearly lifted — Argentine territory
        static let mapBorder = Color.white.opacity(0.26)
        static let mapBorderSelected = accent
        static let mapGraticule = Color.white.opacity(0.04)
        static let mapActiveFill = info.opacity(0.10)
        static let mapSelectedFill = Color.clear                                    // no fill — selection signalled via glowing border

        /// Neighboring countries / world backdrop. Sits between background and mapLand so Argentina pops.
        static let mapWorldLand = Color(red: 0.055, green: 0.072, blue: 0.094)     // between bg and Argentina
        static let mapWorldBorder = Color.white.opacity(0.09)

        static let pinNormal = Color(red: 0.87, green: 0.89, blue: 0.91)
        static let pinBreaking = accent

        static let positive = Color(red: 0.30, green: 0.85, blue: 0.55)
        static let negative = Color(red: 0.95, green: 0.42, blue: 0.40)
    }

    enum Metrics {
        static let cardPadding: CGFloat = 12
        static let overlayInset: CGFloat = 12
        static let drawerPeekHeight: CGFloat = 156
        static let drawerExpandedFraction: CGFloat = 0.72
        static let cornerRadius: CGFloat = 4
    }
}
