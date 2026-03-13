import SwiftUI

struct TerminalScreenBackground: View {
    var body: some View {
        GeometryReader { _ in
            ZStack {
                RadarTheme.Colors.surface

                Canvas { context, size in
                    var path = Path()
                    let horizontalStep: CGFloat = 24
                    let verticalStep: CGFloat = 28

                    stride(from: 0, through: size.height, by: horizontalStep).forEach { y in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    }

                    stride(from: 0, through: size.width, by: verticalStep).forEach { x in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }

                    context.stroke(path, with: .color(RadarTheme.Colors.grid), lineWidth: 0.5)
                }

                LinearGradient(
                    colors: [
                        Color.clear,
                        RadarTheme.Colors.surface.opacity(0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
    }
}
