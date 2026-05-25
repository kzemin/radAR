import SwiftUI
import UIKit

@MainActor
@main
struct radARApp: App {
    private let container = AppContainer.bootstrap()
    private let locale = Locale(identifier: "es_AR")

    init() {
        // No rubber-band overscroll on the drawer list — it reads as a solid panel.
        UIScrollView.appearance().bounces = false
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(container: container)
                .environment(\.appContainer, container)
                .environment(\.locale, locale)
                .tint(RadarTheme.Colors.accent)
        }
    }
}
