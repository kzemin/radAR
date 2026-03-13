import Foundation

struct FinancialMetric: Hashable {
    let value: Double?
    let format: FinancialMetricFormat

    init(value: Double?, format: FinancialMetricFormat) {
        self.value = value
        self.format = format
    }
}

enum FinancialMetricFormat: Hashable {
    case currency(code: String)
    case percentage
    case number(unit: String? = nil)
}
