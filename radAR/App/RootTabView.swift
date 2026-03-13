import SwiftUI

@MainActor
struct RootTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var productRadarStore: HomeStore
    @State private var compareStore: CompareStore
    @State private var homeMonitorStore: MarketStore

    init(container: AppContainer) {
        _productRadarStore = State(initialValue: container.makeProductRadarStore())
        _compareStore = State(initialValue: container.makeCompareStore())
        _homeMonitorStore = State(initialValue: container.makeHomeMonitorStore())
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(monitorStore: homeMonitorStore)
            }
            .tabItem {
                Label(AppTab.home.title, systemImage: AppTab.home.systemImage)
            }
            .tag(AppTab.home)

            if AppFeatureFlags.showsCompareTab {
                NavigationStack {
                    CompareView(compareStore: compareStore)
                }
                .tabItem {
                    Label(AppTab.compare.title, systemImage: AppTab.compare.systemImage)
                }
                .tag(AppTab.compare)
            }

            if AppFeatureFlags.showsMarketTab {
                NavigationStack {
                    MarketView(
                        productRadarStore: productRadarStore,
                        showsQuickCompare: AppFeatureFlags.showsCompareTab,
                        openCompare: { category in
                            guard AppFeatureFlags.showsCompareTab else {
                                return
                            }

                            compareStore.selectedCategory = category
                            selectedTab = .compare
                        }
                    )
                }
                .tabItem {
                    Label(AppTab.market.title, systemImage: AppTab.market.systemImage)
                }
                .tag(AppTab.market)
            }
        }
        .background(TerminalScreenBackground())
        .toolbarBackground(RadarTheme.Colors.backgroundElevated, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}
