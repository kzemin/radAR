import Foundation

enum AppTab: Hashable {
    case home
    case compare
    case market
    case settings

    var title: String {
        switch self {
        case .home:
            "Home"
        case .compare:
            "Compare"
        case .market:
            "Market"
        case .settings:
            "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            "house"
        case .compare:
            "rectangle.split.3x1"
        case .market:
            "chart.line.uptrend.xyaxis"
        case .settings:
            "gearshape"
        }
    }
}
