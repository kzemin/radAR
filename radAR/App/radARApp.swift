import SwiftUI

@MainActor
@main
struct radARApp: App {
    private let container = AppContainer.bootstrap()
    private let locale = Locale(identifier: "es_AR")

    var body: some Scene {
        WindowGroup {
            RootTabView(container: container)
                .environment(\.appContainer, container)
                .environment(\.locale, locale)
                .tint(RadarTheme.Colors.accent)
                .preferredColorScheme(.dark)
        }
    }
}
