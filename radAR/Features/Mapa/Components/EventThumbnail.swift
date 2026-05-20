import SwiftUI

/// Thumbnail rendered on the trailing edge of news cards. Shows a real news
/// image, with a leading-edge gradient that fades into the card background so
/// the picture eases into the text area instead of butting against it.
// TODO: per-event imagery — for now every card uses `congress`.
struct EventThumbnail: View {
    let event: NewsEvent
    var width: CGFloat = 110

    var body: some View {
        ZStack(alignment: .trailing) {
            Image("congress")
                .resizable()
                .scaledToFill()
                .frame(width: width)
                .clipped()

            fade
        }
        .frame(width: width)
        .clipped()
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
