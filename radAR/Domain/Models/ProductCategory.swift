import Foundation

enum ProductCategory: String, CaseIterable, Codable, Identifiable {
    case savingsAccount = "Cajas de ahorro"
    case package = "Paquetes"
    case termDeposit = "Plazos fijos"
    case personalLoan = "Préstamos personales"
    case creditCard = "Tarjetas de crédito"

    var id: Self { self }

    var iconName: String {
        switch self {
        case .savingsAccount:
            "building.columns"
        case .package:
            "shippingbox"
        case .termDeposit:
            "banknote"
        case .personalLoan:
            "creditcard.and.123"
        case .creditCard:
            "creditcard"
        }
    }
}
