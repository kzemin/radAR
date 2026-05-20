import SwiftUI

enum RadarTheme {
    enum Colors {
        static let accent = Color(red: 0.973, green: 0.369, blue: 0.133)
        static let accentMuted = Color(red: 1.0, green: 0.91, blue: 0.87)
        static let background = Color(red: 0.988, green: 0.988, blue: 0.988)
        static let backgroundElevated = Color.white
        static let surface = Color.white
        static let surfaceMuted = Color(red: 0.988, green: 0.988, blue: 0.988)
        static let surfaceStrong = Color.white
        static let border = Color.black
        static let separator = Color.black
        static let grid = Color.clear
        static let textPrimary = Color.black
        static let textSecondary = Color.black
        static let textTertiary = Color.black
        static let positive = Color(red: 0.22, green: 0.84, blue: 0.49)
        static let negative = Color(red: 0.95, green: 0.35, blue: 0.33)
        static let warning = accent
        static let info = accent
    }

    enum Spacing {
        static let micro: CGFloat = 2
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 6
        static let compact: CGFloat = 8
        static let row: CGFloat = 8
        static let card: CGFloat = 8
        static let section: CGFloat = 12
        static let screen: CGFloat = 10
    }

    enum Radius {
        static let xSmall: CGFloat = 2
        static let small: CGFloat = 3
        static let control: CGFloat = 3
        static let card: CGFloat = 4
    }

    enum Shadow {
        static let panelOpacity: CGFloat = 0.08
        static let panelRadius: CGFloat = 4
    }

    enum Typography {
        static func sansRegular(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
            .custom("Inter-Regular", size: size, relativeTo: style)
        }

        static func sansMedium(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
            .custom("Inter-Medium", size: size, relativeTo: style)
        }

        static func sansSemibold(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
            .custom("Inter-SemiBold", size: size, relativeTo: style)
        }

        static func sansBold(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
            .custom("Inter-Bold", size: size, relativeTo: style)
        }

        static func monoRegular(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
            .custom("GeistMono-Regular", size: size, relativeTo: style)
        }

        static func monoMedium(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
            .custom("GeistMono-Medium", size: size, relativeTo: style)
        }

        static func monoSemibold(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
            .custom("GeistMono-SemiBold", size: size, relativeTo: style)
        }

        static let panelTitle = monoSemibold(11, relativeTo: .caption)
        static let panelSubtitle = monoMedium(10, relativeTo: .caption)
        static let denseSectionTitle = monoSemibold(12, relativeTo: .caption)
        static let denseSectionSubtitle = monoRegular(10, relativeTo: .caption)
        static let rowLabel = sansSemibold(12, relativeTo: .subheadline)
        static let rowSecondary = sansMedium(11, relativeTo: .caption)
        static let body = sansRegular(13, relativeTo: .body)
        static let bodyStrong = sansSemibold(13, relativeTo: .body)
        static let compactLabel = monoSemibold(11, relativeTo: .caption)
        static let compactTag = monoMedium(10, relativeTo: .caption2)
        static let tableValue = monoSemibold(12, relativeTo: .caption)
        static let value = monoSemibold(16, relativeTo: .headline)
        static let largeValue = monoSemibold(22, relativeTo: .title2)
        static let heroValue = monoSemibold(28, relativeTo: .title)
        static let buttonLabel = monoSemibold(11, relativeTo: .caption)
    }
}
