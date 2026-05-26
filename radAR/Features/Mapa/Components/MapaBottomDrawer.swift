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
            // Expanded stops just below the "radAR / ARGENTINA" header — reserve the
            // ticker + brand header at the top so they stay visible.
            let topReserve = MapaTheme.Metrics.drawerTopReserve
            let expandedHeight = max(peekHeight + 120, availableHeight - topReserve)
            let base = store.isDrawerExpanded ? expandedHeight : peekHeight
            let resolved = max(peekHeight, min(expandedHeight, base + dragTranslation))

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
            VStack(spacing: 0) {
                handle
                headerBar
            }
            .contentShape(Rectangle())
            .simultaneousGesture(dragGesture(peek: peek, expanded: expanded))

            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: RadarTheme.Spacing.compact) {
                    ForEach(visibleEvents) { event in
                        EventCard(
                            event: event,
                            isSelected: event.id == store.selectedEventID
                        ) {
                            onTapEvent(event)
                        }
                    }

                    if visibleEvents.isEmpty {
                        emptyState
                    }

                    footer
                }
                .padding(.horizontal, MapaTheme.Metrics.cardPadding)
                .padding(.vertical, RadarTheme.Spacing.section)
                .padding(.bottom, safeBottom)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(MapaTheme.Colors.mapWorldLand)
        .overlay(alignment: .top) {
            Rectangle().fill(MapaTheme.Colors.border).frame(height: 1)
        }
        .animation(RadarTheme.Animation.panel, value: store.isDrawerExpanded)
    }

    /// Full chronological list of provincial events — the drawer is a stable browse
    /// list regardless of peek/expanded state. National events live in the ticker.
    private var visibleEvents: [NewsEvent] {
        store.provincialEvents
    }

    private var handle: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 10)
            .contentShape(Rectangle())
            .onTapGesture {
                store.toggleDrawer()
            }
    }

    private var headerBar: some View {
        HStack(alignment: .center, spacing: RadarTheme.Spacing.row) {
            VStack(alignment: .leading, spacing: RadarTheme.Spacing.micro) {
                Text("Noticias")
                    .textStyle(.drawerTitle)
                    .foregroundStyle(MapaTheme.Colors.textPrimary)
                Text("Últimas 24 horas")
                    .textStyle(.drawerSubtitle)
                    .foregroundStyle(MapaTheme.Colors.textSecondary)
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

    private var footer: some View {
        Text("radAR · 2026")
            .textStyle(.drawerFooter)
            .foregroundStyle(MapaTheme.Colors.textTertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, RadarTheme.Spacing.section)
    }

    private func dragGesture(peek: CGFloat, expanded: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .global)
            .onChanged { value in
                dragTranslation = -value.translation.height
            }
            .onEnded { value in
                let projected = -value.predictedEndTranslation.height
                let base = store.isDrawerExpanded ? expanded : peek
                let predictedHeight = base + projected
                let midpoint = (peek + expanded) / 2
                let shouldExpand = predictedHeight >= midpoint
                withAnimation(RadarTheme.Animation.panel) {
                    store.isDrawerExpanded = shouldExpand
                    dragTranslation = 0
                }
            }
    }
}
