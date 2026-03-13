import Foundation

struct FinancialChange: Hashable {
    let value: Double
    let format: FinancialMetricFormat

    init(value: Double, format: FinancialMetricFormat = .percentage) {
        self.value = value
        self.format = format
    }
}
