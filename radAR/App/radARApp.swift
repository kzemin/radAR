import SwiftUI
import UIKit

@MainActor
@main
struct radARApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let container = AppContainer.bootstrap()
    private let locale = Locale(identifier: "es_AR")

    init() {
        UIScrollView.appearance().bounces = false
    }

    var body: some Scene {
        WindowGroup {
            RootShell(container: container)
                .environment(\.appContainer, container)
                .environment(\.locale, locale)
                .tint(RadarTheme.Colors.accent)
        }
    }
}

/// Brief splash → cross-fade into the main app. The splash always sits on top
/// for a fixed beat so launch feels intentional even when the network is fast.
private struct RootShell: View {
    let container: AppContainer
    @State private var showSplash = true

    var body: some View {
        ZStack {
            RootTabView(container: container)

            if showSplash {
                SplashScreen()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(2.3))
            withAnimation(.easeOut(duration: 0.22)) {
                showSplash = false
            }
        }
        .task {
            // Ask for push permission + register once the app is up. Idempotent:
            // prompts only the first time, silently re-registers afterward.
            await PushService.shared.refreshRegistration()
        }
    }
}
