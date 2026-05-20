import SwiftUI

struct EventCard: View {
    let event: NewsEvent
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Text(event.province.displayName)
                        .foregroundStyle(MapaTheme.Colors.textSecondary)

                    Text("·")
                        .foregroundStyle(MapaTheme.Colors.textTertiary)

                    Text(RadarFormatters.relativeShort(event.timestamp))
                        .foregroundStyle(MapaTheme.Colors.textTertiary)
                }
                .textStyle(.cardLocation)
                .lineLimit(1)

                Text(event.headline)
                    .textStyle(.cardTitle)
                    .foregroundStyle(MapaTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(MapaTheme.Metrics.cardPadding)
            .padding(.trailing, 96)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MapaTheme.Colors.background)
            .overlay(alignment: .trailing) {
                EventThumbnail(event: event, width: 90)
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .topTrailing) {
                EventCardTags(event: event)
                    .padding(.top, 8)
                    .padding(.trailing, 10)
            }
            .overlay(alignment: .leading) {
                if isSelected {
                    Rectangle()
                        .fill(MapaTheme.Colors.info)
                        .frame(width: 3)
                }
            }
            .overlay(
                Rectangle()
                    .stroke(isSelected ? MapaTheme.Colors.info : MapaTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

/// LIVE + category code rendered as plain mono text, sitting on top of the
/// trailing thumbnail at the card's top-right.
struct EventCardTags: View {
    let event: NewsEvent

    var body: some View {
        HStack(spacing: 8) {
            if event.severity == .breaking {
                Text("Live".uppercased())
                    .textStyle(.cardTag)
                    .foregroundStyle(MapaTheme.Colors.accent)
                    .shadow(color: MapaTheme.Colors.backgroundDeep.opacity(0.6), radius: 2, x: 0, y: 1)
            }

            Text(event.category.code)
                .textStyle(.cardTag)
                .foregroundStyle(MapaTheme.Colors.textPrimary)
                .shadow(color: MapaTheme.Colors.backgroundDeep.opacity(0.6), radius: 2, x: 0, y: 1)
        }
    }
}
