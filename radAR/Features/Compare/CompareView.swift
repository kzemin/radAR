import SwiftUI

struct CompareView: View {
    let compareStore: CompareStore

    init(compareStore: CompareStore) {
        self.compareStore = compareStore
    }

    var body: some View {
        @Bindable var compareStore = compareStore

        ZStack {
            TerminalScreenBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: RadarTheme.Spacing.section) {
                    topPanel

                    if let snapshot = compareStore.comparisonSnapshot {
                        DashboardPanel(
                            title: "Comparison Mode",
                            subtitle: compareStore.selectionDetails,
                            metadataItems: [
                                PanelMetadataItem(title: "Rows", value: "\(snapshot.products.count)"),
                                PanelMetadataItem(title: "Mode", value: "Side by side")
                            ],
                            badges: [
                                PanelBadge("LIVE COMPARE", style: .live),
                                PanelBadge(compareStore.selectedCategory.rawValue, style: .category)
                            ],
                            trailingContent: {
                                TerminalButton(
                                    title: "Limpiar",
                                    style: .secondary,
                                    action: compareStore.clearSelection
                                )
                            }
                        ) {
                            ProductComparisonMatrixView(snapshot: snapshot)
                        }
                    }

                    content
                }
                .padding(RadarTheme.Spacing.screen)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task(id: compareStore.selectedCategory) {
            await compareStore.refresh()
        }
        .refreshable {
            await compareStore.refresh()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch compareStore.state {
        case .idle, .loading:
            LoadingStateView(title: "Actualizando panel comparativo")
        case let .empty(message):
            EmptyStateView(title: "Sin resultados", message: message)
        case let .failed(error):
            ErrorStateView(
                title: "Compare no disponible",
                message: error.localizedDescription,
                retryAction: {
                    Task {
                        await compareStore.refresh()
                    }
                }
            )
        case .loaded:
            if compareStore.filteredProducts.isEmpty {
                EmptyStateView(
                    title: "Sin coincidencias",
                    message: "Ajustá la búsqueda o desactivá el filtro de favoritos."
                )
            } else {
                DashboardPanel(
                    title: "Comparison Table",
                    subtitle: "Monitor analítico de productos",
                    metadataItems: [
                        PanelMetadataItem(title: "Rows", value: "\(compareStore.filteredProducts.count)"),
                        PanelMetadataItem(title: "Selected", value: "\(compareStore.selectedProductIDs.count)")
                    ],
                    badges: [
                        PanelBadge("BCRA", style: .category),
                        PanelBadge(compareStore.selectedCategory.rawValue, style: .category)
                    ]
                ) {
                    CompareTableView(
                        columns: compareStore.tableColumns,
                        products: compareStore.filteredProducts,
                        isFavorite: { product in
                            compareStore.isFavorite(product)
                        },
                        isSelected: { product in
                            compareStore.isSelected(product)
                        },
                        canSelect: { product in
                            compareStore.canSelect(product)
                        },
                        metricValueProvider: { product, kind in
                            compareStore.metricValue(for: product, kind: kind)
                        },
                        displayValueProvider: { product, column in
                            compareStore.displayValue(for: product, column: column)
                        },
                        updatedInfoProvider: { product in
                            compareStore.updatedInfo(for: product)
                        },
                        isBestMetric: { product, kind in
                            compareStore.isBest(product, for: kind)
                        },
                        toggleFavorite: { product in
                            compareStore.toggleFavorite(product)
                        },
                        toggleSelection: { product in
                            compareStore.toggleSelection(product)
                        }
                    )
                }
            }
        }
    }

    private var topPanel: some View {
        @Bindable var compareStore = compareStore

        return DashboardPanel(
            title: "Compare Monitor",
            subtitle: "radAR · monitor comparativo de productos públicos del BCRA",
            metadataItems: [
                PanelMetadataItem(title: "Universe", value: "\(compareStore.state.value?.count ?? 0)"),
                PanelMetadataItem(title: "Selected", value: compareStore.selectionSummary)
            ],
            badges: [
                PanelBadge("BCRA", style: .category),
                PanelBadge("PUBLIC DATA", style: .neutral),
                PanelBadge("TERMINAL", style: .neutral)
            ]
        ) {
            CompareMonitorFrame {
                CompareCategorySelector(
                    selectedCategory: $compareStore.selectedCategory
                )
                .padding(.vertical, RadarTheme.Spacing.small)
                .padding(.horizontal, RadarTheme.Spacing.small)
            }

            CompareFiltersView(
                searchQuery: $compareStore.searchQuery,
                sortOption: $compareStore.sortOption,
                showFavoritesOnly: $compareStore.showFavoritesOnly,
                filteredCount: compareStore.filteredProducts.count,
                selectionSummary: compareStore.selectionSummary,
                clearSelection: compareStore.selectedProductIDs.isEmpty ? nil : { compareStore.clearSelection() }
            )
        }
    }
}

@MainActor
private struct ComparePreviewScene: View {
    @State private var store = CompareFixtures.previewStore()

    var body: some View {
        NavigationStack {
            CompareView(compareStore: store)
        }
    }
}

#Preview("Compare") {
    ComparePreviewScene()
}
