import Foundation
import SwiftUI

extension RadarTheme {
    enum Animation {
        /// Quick acknowledgement — 0.18s (chip toggle, button press feedback).
        static let durationQuick: TimeInterval = 0.18
        /// Standard transition — 0.32s (in-card content swap, footer updates).
        static let durationStandard: TimeInterval = 0.32
        /// Long transition — 0.65s (camera fly across the country, large reveals).
        static let durationLong: TimeInterval = 0.65

        /// Fade — overlay opacity in/out, generic dissolves.
        static let fade: SwiftUI.Animation = .easeInOut(duration: 0.16)
        /// Scroll focus — list scrolling a selected card into view.
        static let scrollFocus: SwiftUI.Animation = .easeInOut(duration: 0.3)
        /// Panel reposition — bottom drawer peek/expand, sheet drags.
        static let panel: SwiftUI.Animation = .spring(response: 0.42, dampingFraction: 0.86)
        /// Callout entry — TARGET detail card sliding in from the top edge.
        static let callout: SwiftUI.Animation = .spring(response: 0.28, dampingFraction: 0.92)
        /// Camera fly — pan + zoom to a new location. Smooth curve, no overshoot.
        static let cameraFly: SwiftUI.Animation = .smooth(duration: 0.26)
        /// Duration used by hand-rolled camera interpolation inside `ArgentinaMapCanvas`.
        /// Kept aligned with `cameraFly` so the timing matches the rest of the system.
        static let cameraFlyDuration: TimeInterval = 0.26
    }
}
