import Foundation

enum ProductSortOption: String, CaseIterable, Identifiable {
    case name = "Nombre"
    case institution = "Entidad"
    case monthlyFee = "Comisión"
    case rate = "Tasa"
    case annualCost = "CFT"
    case updated = "Actualizado"

    var id: Self { self }
}
