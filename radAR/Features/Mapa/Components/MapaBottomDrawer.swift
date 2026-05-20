import SwiftUI

struct MapaBottomDrawer: View {
    @Bindable var store: MapaStore
    let onTapEvent: (NewsEvent) -> Void

    @State private var dragTranslation: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let safeBottom = proxy.safeAreaInsets.bottom
            let availableHeight = proxy.size.height + safeBottom
            let peekHeight = MapaTheme.Metrics.drawerPeekHeight + safeBottom
            let expandedHeight = max(
                peekHeight + 120,
                availableHeight * MapaTheme.Metrics.drawerExpandedFraction
            )
            let base = store.isDrawerExpanded ? expandedHeight : peekHeight
            let resolved = max(peekHeight, min(expandedHeight, base - dragTranslation))

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                drawerSurface(
                    height: resolved,
                    peek: peekHeight,
                    expanded: expandedHeight,
                    safeBottom: safeBottom
                )
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    private func drawerSurface(
        height: CGFloat,
        peek: CGFloat,
        expanded: CGFloat,
        safeBottom: CGFloat
    ) -> some View {
        VStack(spacing: 0) {
            handle
            headerBar
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: RadarTheme.Spacing.compact) {
                    ForEach(visibleEvents) { event in
                        EventCard(
                            event: event,
                            isSelected: false
                        ) {
                            onTapEvent(event)
                        }
                    }

                    if visibleEvents.isEmpty {
                        emptyState
                    }
                }
                .padding(.horizontal, MapaTheme.Metrics.cardPadding)
                .padding(.top, RadarTheme.Spacing.compact)
                .padding(.bottom, max(safeBottom, RadarTheme.Spacing.section))
            }
            .scrollDisabled(!store.isDrawerExpanded)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(MapaTheme.Colors.mapWorldLand)
        .overlay(alignment: .top) {
            Rectangle().fill(MapaTheme.Colors.border).frame(height: 1)
        }
        .gesture(dragGesture(peek: peek, expanded: expanded))
        .animation(RadarTheme.Animation.panel, value: store.isDrawerExpanded)
    }

    /// Always chronological — the drawer is a stable browse list and does not
    /// reorder or focus around the map's current selection.
    private var visibleEvents: [NewsEvent] {
        store.isDrawerExpanded ? store.events : Array(store.events.prefix(1))
    }

    private var handle: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(MapaTheme.Colors.borderStrong)
                .frame(width: 36, height: 3)
                .padding(.top, 8)
                .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            store.toggleDrawer()
        }
    }

    private var headerBar: some View {
        HStack(alignment: .firstTextBaseline, spacing: RadarTheme.Spacing.row) {
            HStack(spacing: RadarTheme.Spacing.xSmall) {
                Text("Noticias".uppercased())
                    .font(RadarTheme.Typography.panelTitle)
                    .tracking(0.7)
                    .foregroundStyle(MapaTheme.Colors.textPrimary)
            }

            Spacer(minLength: RadarTheme.Spacing.row)

            Button {
                store.toggleDrawer()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: store.isDrawerExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MapaTheme.Colors.info)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, MapaTheme.Metrics.cardPadding)
        .padding(.bottom, RadarTheme.Spacing.small)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: RadarTheme.Spacing.xSmall) {
            Text("Sin eventos en la ventana seleccionada".uppercased())
                .font(RadarTheme.Typography.panelTitle)
                .tracking(0.7)
                .foregroundStyle(MapaTheme.Colors.textPrimary)
            Text("Ampliá el rango para ver más coberturas.")
                .font(RadarTheme.Typography.rowSecondary)
                .foregroundStyle(MapaTheme.Colors.textSecondary)
        }
        .padding(MapaTheme.Metrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(Rectangle().stroke(MapaTheme.Colors.border, lineWidth: 1))
    }

    private func dragGesture(peek: CGFloat, expanded: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .local)
            .onChanged { value in
                if store.isDrawerExpanded {
                    dragTranslation = -value.translation.height
                } else {
                    dragTranslation = -value.translation.height
                }
            }
            .onEnded { value in
                let projected = -(value.predictedEndTranslation.height)
                let base = store.isDrawerExpanded ? expanded : peek
                let predictedHeight = base + projected
                let midpoint = (peek + expanded) / 2
                let shouldExpand = predictedHeight >= midpoint
                dragTranslation = 0
                if shouldExpand != store.isDrawerExpanded {
                    store.isDrawerExpanded = shouldExpand
                }
            }
    }
}
