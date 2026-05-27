import CoreLocation
import SwiftUI

struct MapaView: View {
    @State private var store: MapaStore

    init(store: MapaStore) {
        _store = State(initialValue: store)
    }

    var body: some View {
        ZStack {
            MapaTheme.Colors.background
                .ignoresSafeArea()

            map
                .ignoresSafeArea()

            legibilityGradients
                .ignoresSafeArea()
                .allowsHitTesting(false)

            topStack
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            MapaBottomDrawer(store: store) { event in
                store.select(event: event)
                if store.isDrawerExpanded { store.toggleDrawer() }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await store.load() }
        .task {
            // Live market strip: prime on appear and refresh every 5 minutes while
            // the view is on screen. Cancelled automatically on disappear.
            while !Task.isCancelled {
                await store.loadMarket()
                try? await Task.sleep(for: .seconds(300))
            }
        }
        .overlay { statusOverlay }
    }

    @ViewBuilder
    private var statusOverlay: some View {
        if store.loadState == .loading, store.events.isEmpty {
            statusPill {
                ProgressView().tint(MapaTheme.Colors.textSecondary)
                Text("Cargando noticias…")
                    .textStyle(.drawerSubtitle)
                    .foregroundStyle(MapaTheme.Colors.textSecondary)
            }
        } else if case let .failed(message) = store.loadState, store.events.isEmpty {
            statusPill {
                Text(message)
                    .textStyle(.drawerSubtitle)
                    .foregroundStyle(MapaTheme.Colors.textPrimary)
                Button { Task { await store.load() } } label: {
                    Text("Reintentar")
                        .textStyle(.cardTag)
                        .foregroundStyle(MapaTheme.Colors.info)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func statusPill<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 8) { content() }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(MapaTheme.Colors.surface)
            .overlay(Rectangle().stroke(MapaTheme.Colors.border, lineWidth: 1))
            .padding(.bottom, 120)
    }

    // MARK: - Layers

    private var map: some View {
        ArgentinaMapCanvas(
            provinces: store.provinces,
            argentinaExtras: store.argentinaExtras,
            worldCountries: store.worldCountries,
            events: store.events,
            activeProvinces: store.activeProvinces,
            selectedEventID: store.selectedEventID,
            cameraTargetCoordinate: store.cameraTargetCoordinate,
            cameraNonce: store.cameraNonce,
            onSelectEvent: { event in
                store.select(event: event)
            },
            onTapEmpty: {
                store.deselect()
            }
        )
    }

    private var legibilityGradients: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    MapaTheme.Colors.background.opacity(0.96),
                    MapaTheme.Colors.background.opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 180)

            Spacer(minLength: 0)

            LinearGradient(
                colors: [
                    MapaTheme.Colors.background.opacity(0.0),
                    MapaTheme.Colors.background.opacity(0.85),
                    MapaTheme.Colors.background.opacity(0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 260)
        }
    }

    private var topStack: some View {
        VStack(alignment: .leading, spacing: 0) {
            NewsTickerBar(items: tickerItems, onTapNews: selectNews)

            VStack(alignment: .leading, spacing: RadarTheme.Spacing.compact) {
                MapaHeader(subtitle: headerSubtitle)
                    .padding(.horizontal, MapaTheme.Metrics.cardPadding)
                    .padding(.top, RadarTheme.Spacing.compact)

                if let event = store.calloutEvent {
                    MapaPinCallout(event: event) {
                        store.dismissCallout()
                    }
                    .padding(.trailing, 12)
                    .transition(
                        .move(edge: .leading)
                            .combined(with: .opacity)
                    )
                    // Per-event identity: resets the body-expand state between events and
                    // restores the slide/fade transition when switching pins.
                    .id(event.id)
                }
            }
        }
        .animation(RadarTheme.Animation.callout, value: store.calloutEventID)
    }

    private var headerSubtitle: String {
        store.selectedEvent?.province.displayName ?? "Argentina"
    }

    /// National headlines (breaking first) lead the ticker, followed by the live
    /// market strip. Capped so the marquee loops in a reasonable cycle.
    private var tickerItems: [TickerItem] {
        let national = store.nationalEvents
        let ordered = national.filter { $0.severity == .breaking }
            + national.filter { $0.severity != .breaking }
        let news = ordered.prefix(14).map { event in
            TickerItem.news(
                eventID: event.id.uuidString,
                kicker: "Nacional",
                text: event.headline,
                breaking: event.severity == .breaking
            )
        }
        let market = store.quotes.map { quote -> TickerItem in
            switch quote.kind {
            case .riesgoPais:
                .stat(label: quote.label, value: quote.value)
            default:
                .quote(label: quote.label, value: quote.value, change: nil)
            }
        }
        return news + market
    }

    private func selectNews(_ eventID: String) {
        guard let event = store.events.first(where: { $0.id.uuidString == eventID }) else { return }
        store.select(event: event)
    }
}

#Preview("Mapa") {
    MapaView(store: MapaStore())
}
