import SwiftUI

/// Thumbnail rendered on the trailing edge of news cards. Shows the event's
/// per-article image when available; falls back to a category symbol on a
/// muted card when there's no URL or the load fails. A leading-edge gradient
/// fades the picture into the card background so it eases into the text area
/// instead of butting against it.
///
/// Uses a `Color.clear` shim sized to the parent's height so the AsyncImage
/// (which `.scaledToFill`s) is clipped to the card's bounds — without this,
/// portrait-aspect images push past the card vertically.
struct EventThumbnail: View {
    let event: NewsEvent
    var width: CGFloat = 110

    var body: some View {
        Color.clear
            .frame(width: width)
            .overlay { content }
            .overlay { fade }
            .clipped()
    }

    @ViewBuilder
    private var content: some View {
        if let url = event.imageURL {
            AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.18))) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                case .empty, .failure:
                    symbolPlaceholder
                @unknown default:
                    symbolPlaceholder
                }
            }
        } else {
            symbolPlaceholder
        }
    }

    private var symbolPlaceholder: some View {
        ZStack {
            Rectangle().fill(MapaTheme.Colors.surface)
            Image(systemName: event.category.symbolName)
                .font(.system(size: width * 0.32, weight: .regular))
                .foregroundStyle(MapaTheme.Colors.textTertiary)
        }
    }

    private var fade: some View {
        LinearGradient(
            stops: [
                .init(color: MapaTheme.Colors.background, location: 0),
                .init(color: MapaTheme.Colors.background.opacity(0.55), location: 0.45),
                .init(color: .clear, location: 1.0)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .allowsHitTesting(false)
    }
}
