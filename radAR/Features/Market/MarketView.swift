import SwiftUI

struct MarketView: View {
    let productRadarStore: HomeStore
    let showsQuickCompare: Bool
    let openCompare: (ProductCategory) -> Void

    init(
        productRadarStore: HomeStore,
        showsQuickCompare: Bool = true,
        openCompare: @escaping (ProductCategory) -> Void
    ) {
        self.productRadarStore = productRadarStore
        self.showsQuickCompare = showsQuickCompare
        self.openCompare = openCompare
    }

    private var updatedLabel: String {
        RadarFormatters.timestamp(productRadarStore.state.value?.updatedAt ?? .now)
    }

    var body: some View {
        ZStack {
            TerminalScreenBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: RadarTheme.Spacing.section) {
                    headerPanel
                    content
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(RadarTheme.Spacing.screen)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await productRadarStore.loadIfNeeded()
        }
        .refreshable {
            await productRadarStore.refresh()
        }
    }

    private var headerPanel: some View {
        DashboardPanel(
            title: "Product Monitor",
            subtitle: "radAR · barrido compacto de productos públicos del BCRA",
            metadataItems: [
                .updated(updatedLabel),
                PanelMetadataItem(title: "Mode", value: "Read only"),
                PanelMetadataItem(title: "Focus", value: "Compare")
            ],
            badges: [
                PanelBadge("BCRA", style: .category),
                PanelBadge("SCAN", style: .warning),
                PanelBadge("TERMINAL", style: .neutral)
            ]
        ) {
            if let dashboard = productRadarStore.state.value {
                DashboardGrid {
                    if showsQuickCompare {
                        HomeMonitorStatView(
                            title: "Compare",
                            value: "\(dashboard.quickActions.count)"
                        )
                    }
                    HomeMonitorStatView(
                        title: "Featured",
                        value: "\(dashboard.featuredProducts.count)"
                    )
                    HomeMonitorStatView(
                        title: "Rates",
                        value: "\(dashboard.featuredProducts.filter { $0.primaryMetric.format == .percentage }.count)"
                    )
                    HomeMonitorStatView(
                        title: "Products",
                        value: "\(dashboard.featuredProducts.count)"
                    )
                }
            } else {
                DashboardGrid {
                    if showsQuickCompare {
                        HomeMonitorStatView(title: "Compare", value: "00")
                    }
                    HomeMonitorStatView(title: "Featured", value: "00")
                    HomeMonitorStatView(title: "Rates", value: "00")
                    HomeMonitorStatView(title: "Products", value: "00")
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch productRadarStore.state {
        case .idle, .loading:
            LoadingStateView(title: "Armando panel de productos")
        case let .empty(message):
            EmptyStateView(title: "Panel sin datos", message: message)
        case let .failed(error):
            ErrorStateView(
                title: "Panel de productos no disponible",
                message: error.localizedDescription,
                retryAction: {
                    Task {
                        await productRadarStore.refresh()
                    }
                }
            )
        case let .loaded(dashboard):
            if showsQuickCompare {
                compareSection(dashboard)
            }
            featuredProductsSection(dashboard)
        }
    }

    private func compareSection(_ dashboard: HomeDashboard) -> some View {
        DashboardPanel(
            title: "Quick Compare",
            subtitle: "Entrada directa por categoría",
            metadataItems: [
                PanelMetadataItem(title: "Rows", value: "\(dashboard.quickActions.count)")
            ],
            badges: [
                PanelBadge("BCRA", style: .category)
            ]
        ) {
            MonitorFrame {
                PanelRowStack(dashboard.quickActions) { item in
                    HomeQuickCompareRowView(
                        action: item,
                        compactNumbers: productRadarStore.usesCompactNumbers,
                        perform: openCompare
                    )
                }
            }
        }
    }

    private func featuredProductsSection(_ dashboard: HomeDashboard) -> some View {
        DashboardPanel(
            title: "Featured Rates / Products",
            subtitle: "Selección táctica por mejor condición observada",
            metadataItems: [
                PanelMetadataItem(title: "Rows", value: "\(dashboard.featuredProducts.count)")
            ],
            badges: [
                PanelBadge("SCAN", style: .warning)
            ]
        ) {
            MonitorFrame {
                PanelRowStack(dashboard.featuredProducts) { item in
                    HomeFeaturedProductRowView(
                        item: item,
                        compactNumbers: productRadarStore.usesCompactNumbers,
                        perform: openCompare
                    )
                }
            }
        }
    }
}

@MainActor
private struct MarketPreviewScene: View {
    @State private var store = HomeFixtures.previewStore()

    var body: some View {
        NavigationStack {
            MarketView(
                productRadarStore: store,
                showsQuickCompare: true,
                openCompare: { _ in }
            )
        }
    }
}

#Preview("Product Monitor") {
    MarketPreviewScene()
}
