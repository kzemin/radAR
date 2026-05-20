import SwiftUI

struct MapaHeader: View {
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("radAR")
                .textStyle(.appTitle)
                .foregroundStyle(MapaTheme.Colors.textPrimary)
                .kerning(-0.4)

            Text(subtitle.uppercased())
                .textStyle(.appSubtitle)
                .foregroundStyle(MapaTheme.Colors.info)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
