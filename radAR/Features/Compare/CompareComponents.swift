import SwiftUI

private enum CompareMonitorLayout {
    static func width(for kind: CompareTableColumnKind) -> CGFloat {
        switch kind {
        case .compare:
            return 42
        case .entity:
            return 92
        case .product:
            return 196
        case .monthlyFee:
            return 88
        case .rate:
            return 84
        case .annualCost:
            return 84
        case .minimumRequirement:
            return 96
        case .updated:
            return 84
        case .favorite:
            return 42
        }
    }

    static func totalWidth(for columns: [CompareTableColumn]) -> CGFloat {
        columns.reduce(0) { partial, column in
            partial + width(for: column.kind)
        }
    }
}

struct CompareFiltersView: View {
    @Binding var searchQuery: String
    @Binding var sortOption: ProductSortOption
    @Binding var showFavoritesOnly: Bool
    let filteredCount: Int
    let selectionSummary: String
    let clearSelection: (() -> Void)?

    var body: some View {
        CompareMonitorFrame {
            DenseFilterBar(statusText: "\(filteredCount) filas · \(selectionSummary)") {
                VStack(alignment: .leading, spacing: RadarTheme.Spacing.small) {
                    HStack(spacing: RadarTheme.Spacing.row) {
                        HStack(spacing: RadarTheme.Spacing.small) {
                            Image(systemName: "magnifyingglass")
                                .font(RadarTheme.Typography.compactLabel)
                                .foregroundStyle(RadarTheme.Colors.textSecondary)

                            TextField("Buscar entidad o producto", text: $searchQuery)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(RadarTheme.Typography.rowSecondary)
                                .foregroundStyle(RadarTheme.Colors.textPrimary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RadarTheme.Colors.backgroundElevated)
                        .overlay(
                            Rectangle()
                                .stroke(RadarTheme.Colors.border, lineWidth: 1)
                        )

                        Picker("Orden", selection: $sortOption) {
                            ForEach(ProductSortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 122)
                    }

                    HStack(spacing: RadarTheme.Spacing.row) {
                        Toggle(isOn: $showFavoritesOnly) {
                            Text("Solo favoritos")
                                .font(RadarTheme.Typography.compactLabel)
                                .foregroundStyle(RadarTheme.Colors.textSecondary)
                        }
                        .toggleStyle(.switch)

                        Spacer(minLength: RadarTheme.Spacing.row)

                        if let clearSelection {
                            TerminalButton(
                                title: "Limpiar selección",
                                style: .ghost,
                                action: clearSelection
                            )
                        }
                    }
                }
            }
        }
    }
}

struct CompareCategorySelector: View {
    @Binding var selectedCategory: ProductCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RadarTheme.Spacing.small) {
                ForEach(ProductCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.iconName)
                            Text(category.rawValue.uppercased())
                        }
                        .font(RadarTheme.Typography.compactTag)
                        .tracking(0.4)
                        .foregroundStyle(
                            selectedCategory == category
                                ? RadarTheme.Colors.textPrimary
                                : RadarTheme.Colors.textSecondary
                        )
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            selectedCategory == category
                                ? RadarTheme.Colors.backgroundElevated
                                : RadarTheme.Colors.surface
                        )
                        .overlay(
                            Rectangle()
                                .stroke(
                                    selectedCategory == category
                                        ? RadarTheme.Colors.accent
                                        : RadarTheme.Colors.border,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct CompareMonitorFrame<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        MonitorFrame {
            content
        }
    }
}

struct CompareTableView: View {
    let columns: [CompareTableColumn]
    let products: [FinancialProduct]
    let isFavorite: (FinancialProduct) -> Bool
    let isSelected: (FinancialProduct) -> Bool
    let canSelect: (FinancialProduct) -> Bool
    let metricValueProvider: (FinancialProduct, CompareTableColumnKind) -> FinancialMetric?
    let displayValueProvider: (FinancialProduct, CompareTableColumn) -> String
    let updatedInfoProvider: (FinancialProduct) -> String
    let isBestMetric: (FinancialProduct, CompareTableColumnKind) -> Bool
    let toggleFavorite: (FinancialProduct) -> Void
    let toggleSelection: (FinancialProduct) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            CompareMonitorFrame {
                VStack(spacing: 0) {
                    CompareTableHeader(columns: columns)
                    PanelDivider()

                    ForEach(products) { product in
                        CompareProductRowView(
                            product: product,
                            columns: columns,
                            isFavorite: isFavorite(product),
                            isSelected: isSelected(product),
                            canSelect: canSelect(product),
                            metricValueProvider: { kind in
                                metricValueProvider(product, kind)
                            },
                            displayValueProvider: { column in
                                displayValueProvider(product, column)
                            },
                            updatedInfo: updatedInfoProvider(product),
                            isBestMetric: { kind in
                                isBestMetric(product, kind)
                            },
                            toggleFavorite: {
                                toggleFavorite(product)
                            },
                            toggleSelection: {
                                toggleSelection(product)
                            }
                        )

                        if product.id != products.last?.id {
                            PanelDivider()
                        }
                    }
                }
                .frame(minWidth: CompareMonitorLayout.totalWidth(for: columns), alignment: .leading)
            }
        }
    }
}

struct CompareTableHeader: View {
    let columns: [CompareTableColumn]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(columns) { column in
                Text(column.shortTitle.uppercased())
                    .font(RadarTheme.Typography.compactTag)
                    .tracking(0.6)
                    .foregroundStyle(RadarTheme.Colors.textSecondary)
                    .frame(
                        width: CompareMonitorLayout.width(for: column.kind),
                        alignment: headerAlignment(for: column.kind)
                    )
                    .padding(.vertical, 8)
                    .padding(.horizontal, 6)
            }
        }
        .background(RadarTheme.Colors.backgroundElevated.opacity(0.6))
    }

    private func headerAlignment(for kind: CompareTableColumnKind) -> Alignment {
        switch kind {
        case .product:
            return .leading
        case .compare, .favorite:
            return .center
        case .entity, .updated:
            return .leading
        case .monthlyFee, .rate, .annualCost, .minimumRequirement:
            return .trailing
        }
    }
}

struct CompareProductRowView: View {
    let product: FinancialProduct
    let columns: [CompareTableColumn]
    let isFavorite: Bool
    let isSelected: Bool
    let canSelect: Bool
    let metricValueProvider: (CompareTableColumnKind) -> FinancialMetric?
    let displayValueProvider: (CompareTableColumn) -> String
    let updatedInfo: String
    let isBestMetric: (CompareTableColumnKind) -> Bool
    let toggleFavorite: () -> Void
    let toggleSelection: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(columns) { column in
                cell(for: column)
            }
        }
        .background(
            isSelected
                ? RadarTheme.Colors.accent.opacity(0.08)
                : Color.clear
        )
    }

    @ViewBuilder
    private func cell(for column: CompareTableColumn) -> some View {
        switch column.kind {
        case .compare:
            Button(action: toggleSelection) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(
                        isSelected
                            ? RadarTheme.Colors.accent
                            : (canSelect ? RadarTheme.Colors.textSecondary : RadarTheme.Colors.border)
                    )
                    .frame(width: CompareMonitorLayout.width(for: .compare))
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .disabled(!canSelect)

        case .entity:
            Text(displayValueProvider(column).uppercased())
                .font(RadarTheme.Typography.compactLabel)
                .foregroundStyle(RadarTheme.Colors.textPrimary)
                .lineLimit(2)
                .frame(width: CompareMonitorLayout.width(for: .entity), alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 6)

        case .product:
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(RadarTheme.Typography.rowLabel)
                    .foregroundStyle(RadarTheme.Colors.textPrimary)
                    .lineLimit(1)

                Text(product.summary)
                    .font(RadarTheme.Typography.panelSubtitle)
                    .foregroundStyle(RadarTheme.Colors.textSecondary)
                    .lineLimit(2)
            }
            .frame(width: CompareMonitorLayout.width(for: .product), alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)

        case .updated:
            VStack(alignment: .leading, spacing: 2) {
                Text(displayValueProvider(column))
                    .font(RadarTheme.Typography.compactLabel)
                    .foregroundStyle(RadarTheme.Colors.textPrimary)
                Text(updatedInfo)
                    .font(RadarTheme.Typography.compactTag)
                    .foregroundStyle(RadarTheme.Colors.textTertiary)
                    .lineLimit(1)
            }
            .frame(width: CompareMonitorLayout.width(for: .updated), alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)

        case .favorite:
            Button(action: toggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isFavorite ? RadarTheme.Colors.warning : RadarTheme.Colors.textSecondary)
                    .frame(width: CompareMonitorLayout.width(for: .favorite))
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

        case .monthlyFee, .rate, .annualCost, .minimumRequirement:
            metricCell(kind: column.kind)
        }
    }

    @ViewBuilder
    private func metricCell(kind: CompareTableColumnKind) -> some View {
        if let metric = metricValueProvider(kind) {
            Text(RadarFormatters.metric(metric, compact: true))
                .font(RadarTheme.Typography.tableValue)
                .monospacedDigit()
                .foregroundStyle(isBestMetric(kind) ? RadarTheme.Colors.accent : RadarTheme.Colors.textPrimary)
                .frame(
                    width: CompareMonitorLayout.width(for: kind),
                    alignment: .trailing
                )
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
        } else {
            Text("—")
                .font(RadarTheme.Typography.tableValue)
                .foregroundStyle(RadarTheme.Colors.textTertiary)
                .frame(
                    width: CompareMonitorLayout.width(for: kind),
                    alignment: .trailing
                )
                .padding(.vertical, 8)
                .padding(.horizontal, 6)
        }
    }
}

struct ProductComparisonMatrixView: View {
    let snapshot: ProductComparisonSnapshot

    private let metricColumnWidth: CGFloat = 136
    private let productColumnWidth: CGFloat = 178

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            CompareMonitorFrame {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        headerCell(title: "Métrica", subtitle: nil, width: metricColumnWidth)

                        ForEach(snapshot.products) { product in
                            headerCell(
                                title: product.institution,
                                subtitle: product.name,
                                width: productColumnWidth
                            )
                        }
                    }

                    PanelDivider()

                    ForEach(snapshot.rows) { row in
                        HStack(alignment: .top, spacing: 0) {
                            cell(
                                value: row.title,
                                width: metricColumnWidth,
                                highlighted: false,
                                isLabel: true
                            )

                            ForEach(row.values) { value in
                                cell(
                                    value: value.value,
                                    width: productColumnWidth,
                                    highlighted: value.highlighted,
                                    isLabel: false
                                )
                            }
                        }

                        if row.id != snapshot.rows.last?.id {
                            PanelDivider()
                        }
                    }
                }
                .frame(
                    minWidth: metricColumnWidth + (productColumnWidth * CGFloat(snapshot.products.count)),
                    alignment: .leading
                )
            }
        }
    }

    private func headerCell(
        title: String,
        subtitle: String?,
        width: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(RadarTheme.Typography.compactLabel)
                .foregroundStyle(RadarTheme.Colors.textPrimary)
                .lineLimit(1)

            if let subtitle {
                Text(subtitle)
                    .font(RadarTheme.Typography.panelSubtitle)
                    .foregroundStyle(RadarTheme.Colors.textSecondary)
                    .lineLimit(2)
            }
        }
        .frame(width: width, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(RadarTheme.Colors.backgroundElevated.opacity(0.55))
    }

    private func cell(
        value: String,
        width: CGFloat,
        highlighted: Bool,
        isLabel: Bool
    ) -> some View {
        Text(value)
            .font(isLabel ? RadarTheme.Typography.compactLabel : RadarTheme.Typography.panelSubtitle)
            .foregroundStyle(
                highlighted
                    ? RadarTheme.Colors.accent
                    : (isLabel ? RadarTheme.Colors.textPrimary : RadarTheme.Colors.textSecondary)
            )
            .lineLimit(isLabel ? 1 : 3)
            .multilineTextAlignment(.leading)
            .frame(width: width, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(highlighted ? RadarTheme.Colors.accent.opacity(0.08) : .clear)
    }
}

@MainActor
private struct CompareRowPreviewScene: View {
    private let store = CompareFixtures.previewStore()
    private let product = CompareFixtures.products(for: .termDeposit)[0]

    var body: some View {
        CompareMonitorFrame {
            CompareProductRowView(
                product: product,
                columns: store.tableColumns,
                isFavorite: true,
                isSelected: true,
                canSelect: true,
                metricValueProvider: { kind in
                    store.metricValue(for: product, kind: kind)
                },
                displayValueProvider: { column in
                    store.displayValue(for: product, column: column)
                },
                updatedInfo: store.updatedInfo(for: product),
                isBestMetric: { kind in
                    store.isBest(product, for: kind)
                },
                toggleFavorite: {},
                toggleSelection: {}
            )
        }
        .padding()
        .background(TerminalScreenBackground())
    }
}

#Preview("Compare Row") {
    CompareRowPreviewScene()
}

@MainActor
private struct ComparisonMatrixPreviewScene: View {
    private let snapshot = CompareFixtures.previewStore().comparisonSnapshot!

    var body: some View {
        ProductComparisonMatrixView(snapshot: snapshot)
            .padding()
            .background(TerminalScreenBackground())
    }
}

#Preview("Comparison Matrix") {
    ComparisonMatrixPreviewScene()
}
