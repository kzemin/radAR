import SwiftUI

struct SettingsView: View {
    let store: SettingsStore

    var body: some View {
        @Bindable var store = store

        ScrollView {
            VStack(alignment: .leading, spacing: RadarTheme.Spacing.section) {
                preferencesPanel(
                    showWatchlistFirstOnHome: Binding(
                        get: { store.settings.showWatchlistFirstOnHome },
                        set: { store.setShowWatchlistFirstOnHome($0) }
                    ),
                    useCompactNumbers: Binding(
                        get: { store.settings.useCompactNumbers },
                        set: { store.setUseCompactNumbers($0) }
                    )
                )
                localDataPanel
                aboutPanel
            }
            .padding(RadarTheme.Spacing.screen)
        }
        .background(TerminalScreenBackground())
        .task {
            await store.loadSavedState()
        }
    }

    private func preferencesPanel(
        showWatchlistFirstOnHome: Binding<Bool>,
        useCompactNumbers: Binding<Bool>
    ) -> some View {
        DashboardBlock {
            VStack(alignment: .leading, spacing: RadarTheme.Spacing.compact) {
                SectionHeader(title: "Settings", subtitle: "Preferencias locales de visualización")

                Toggle("Priorizar watchlist en Home", isOn: showWatchlistFirstOnHome)
                Toggle("Usar números compactos", isOn: useCompactNumbers)
            }
        }
    }

    private var localDataPanel: some View {
        DashboardBlock {
            VStack(alignment: .leading, spacing: RadarTheme.Spacing.compact) {
                SectionHeader(
                    title: "Local data",
                    subtitle: "Favoritos, watchlist y caché",
                    actionTitle: "Limpiar caché",
                    action: {
                        Task {
                            await store.clearCache()
                        }
                    }
                )

                summaryRow(title: "Favoritos de Compare", value: "\(store.savedStateSummary.compareFavoritesCount)")
                summaryRow(title: "Watchlist", value: "\(store.savedStateSummary.watchlistCount)")
                summaryRow(title: "Respuestas en caché", value: "\(store.savedStateSummary.cacheEntries)")

                if let statusMessage = store.statusMessage {
                    Rectangle()
                        .fill(RadarTheme.Colors.separator)
                        .frame(height: 1)
                    Text(statusMessage)
                        .font(RadarTheme.Typography.panelSubtitle)
                        .foregroundStyle(RadarTheme.Colors.textSecondary)
                }
            }
        }
    }

    private var aboutPanel: some View {
        DashboardBlock {
            VStack(alignment: .leading, spacing: RadarTheme.Spacing.compact) {
                SectionHeader(title: "About", subtitle: "Producto y alcance del MVP")
                Text("radAR funciona como un dashboard local de lectura para explorar y comparar datos públicos del BCRA. Esta base no incluye login, backend propio ni flujos sensibles.")
                    .font(RadarTheme.Typography.panelSubtitle)
                    .foregroundStyle(RadarTheme.Colors.textSecondary)

                HStack {
                    Text("Version")
                        .font(RadarTheme.Typography.compactLabel)
                        .foregroundStyle(RadarTheme.Colors.textSecondary)
                    Spacer()
                    Text(store.versionDescription)
                        .font(RadarTheme.Typography.compactLabel)
                        .foregroundStyle(RadarTheme.Colors.textPrimary)
                }
            }
        }
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(RadarTheme.Typography.panelSubtitle)
                .foregroundStyle(RadarTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(RadarTheme.Typography.compactLabel)
                .monospacedDigit()
                .foregroundStyle(RadarTheme.Colors.textPrimary)
        }
    }
}
