import SwiftUI

struct TerminalScreenBackground: View {
    var body: some View {
        GeometryReader { _ in
            RadarTheme.Colors.background
            .ignoresSafeArea()
        }
    }
}
