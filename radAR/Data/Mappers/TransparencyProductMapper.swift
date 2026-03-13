import Foundation

enum TransparencyProductMapper {
    private static let locale = Locale(identifier: "es_AR")

    static func map(_ dto: TransparencyProductDTO) -> FinancialProduct {
        FinancialProduct(
            id: dto.id,
            name: dto.nombre,
            institution: dto.entidad,
            category: dto.categoria,
            currencyCode: dto.moneda,
            monthlyFee: dto.comisionMensual,
            rate: dto.tasaNominalAnual,
            annualCost: dto.costoFinancieroTotal,
            minimumIncome: dto.ingresoMinimo,
            updatedAt: dto.actualizado,
            summary: dto.descripcion,
            highlights: dto.destacados
        )
    }

    static func mapSavingsAccounts(_ dtos: [BCRASavingsAccountDTO]) -> [FinancialProduct] {
        deduplicatedProducts(
            from: dtos.map { dto in
                FinancialProduct(
                    id: "savings-\(dto.codigoEntidad)",
                    name: "Caja de ahorro",
                    institution: dto.descripcionEntidad,
                    category: .savingsAccount,
                    currencyCode: "ARS",
                    monthlyFee: nil,
                    rate: nil,
                    annualCost: nil,
                    minimumIncome: nil,
                    updatedAt: dto.fechaInformacion,
                    summary: savingsSummary(for: dto),
                    highlights: [
                        "Debida diligencia simplificada: \(normalizedYesNo(dto.procesoSimplificadoDebidaDiligencia))",
                        "Fuente pública BCRA"
                    ]
                )
            },
            groupKey: { "\($0.category.rawValue)|\($0.institution)" },
            sort: {
                if $0.updatedAt != $1.updatedAt {
                    return $0.updatedAt > $1.updatedAt
                }

                return $0.institution.localizedCaseInsensitiveCompare($1.institution) == .orderedAscending
            }
        )
    }

    static func mapPackages(_ dtos: [BCRAPackageProductDTO]) -> [FinancialProduct] {
        deduplicatedProducts(
            from: dtos.map { dto in
                FinancialProduct(
                    id: packageIdentifier(for: dto),
                    name: preferredProductName(short: dto.nombreCorto, full: dto.nombreCompleto, fallback: "Paquete de productos"),
                    institution: dto.descripcionEntidad,
                    category: .package,
                    currencyCode: "ARS",
                    monthlyFee: dto.comisionMaximaMantenimiento,
                    rate: nil,
                    annualCost: nil,
                    minimumIncome: dto.ingresoMinimoMensual,
                    updatedAt: dto.fechaInformacion,
                    summary: packageSummary(for: dto),
                    highlights: compactHighlights([
                        dto.segmento.map { "Segmento: \($0)" },
                        dto.beneficiarios,
                        compactListSnippet(dto.productosIntegrantes, prefix: "Incluye")
                    ])
                )
            },
            groupKey: { $0.id },
            sort: {
                if $0.updatedAt != $1.updatedAt {
                    return $0.updatedAt > $1.updatedAt
                }

                return ($0.monthlyFee ?? Double.greatestFiniteMagnitude) < ($1.monthlyFee ?? Double.greatestFiniteMagnitude)
            }
        )
    }

    static func mapTermDeposits(_ dtos: [BCRATermDepositDTO]) -> [FinancialProduct] {
        deduplicatedProducts(
            from: dtos.compactMap { dto in
                let name = preferredProductName(
                    short: dto.nombreCorto,
                    full: dto.nombreCompleto,
                    fallback: "Plazo fijo"
                )

                return FinancialProduct(
                    id: termDepositIdentifier(for: dto),
                    name: name,
                    institution: dto.descripcionEntidad,
                    category: .termDeposit,
                    currencyCode: currencyCode(for: dto.denominacion),
                    monthlyFee: nil,
                    rate: normalizedPercentage(dto.tasaEfectivaAnualMinima),
                    annualCost: nil,
                    minimumIncome: dto.montoMinimoInvertir,
                    updatedAt: dto.fechaInformacion,
                    summary: termDepositSummary(for: dto),
                    highlights: compactHighlights([
                        dto.canalConstitucion.map { "Canal: \($0)" },
                        dto.plazoMinimoInvertirDias.map { "Plazo mínimo: \($0) días" },
                        dto.montoMinimoInvertir.map { "Monto mínimo: \(numberString($0))" }
                    ])
                )
            },
            groupKey: { $0.id },
            sort: {
                if $0.updatedAt != $1.updatedAt {
                    return $0.updatedAt > $1.updatedAt
                }

                return ($0.rate ?? 0) > ($1.rate ?? 0)
            }
        )
    }

    static func mapPersonalLoans(_ dtos: [BCRAPersonalLoanDTO]) -> [FinancialProduct] {
        deduplicatedProducts(
            from: dtos.map { dto in
                FinancialProduct(
                    id: personalLoanIdentifier(for: dto),
                    name: preferredProductName(short: dto.nombreCorto, full: dto.nombreCompleto, fallback: "Préstamo personal"),
                    institution: dto.descripcionEntidad,
                    category: .personalLoan,
                    currencyCode: currencyCode(for: dto.denominacion),
                    monthlyFee: nil,
                    rate: normalizedPercentage(dto.tasaEfectivaAnualMaxima),
                    annualCost: normalizedPercentage(dto.costoFinancieroEfectivoTotalMaximo),
                    minimumIncome: dto.ingresoMinimoMensual,
                    updatedAt: dto.fechaInformacion,
                    summary: personalLoanSummary(for: dto),
                    highlights: compactHighlights([
                        dto.beneficiario,
                        dto.plazoMaximoOtorgable.map { "Hasta \($0) meses" },
                        dto.montoMaximoOtorgable.map { "Monto máx.: \(numberString($0))" }
                    ])
                )
            },
            groupKey: { $0.id },
            sort: {
                if $0.updatedAt != $1.updatedAt {
                    return $0.updatedAt > $1.updatedAt
                }

                return ($0.annualCost ?? Double.greatestFiniteMagnitude) < ($1.annualCost ?? Double.greatestFiniteMagnitude)
            }
        )
    }

    static func mapCreditCards(_ dtos: [BCRACreditCardDTO]) -> [FinancialProduct] {
        deduplicatedProducts(
            from: dtos.map { dto in
                FinancialProduct(
                    id: creditCardIdentifier(for: dto),
                    name: preferredProductName(short: dto.nombreCorto, full: dto.nombreCompleto, fallback: "Tarjeta de crédito"),
                    institution: dto.descripcionEntidad,
                    category: .creditCard,
                    currencyCode: "ARS",
                    monthlyFee: dto.comisionMaximaAdministracionMantenimiento,
                    rate: normalizedPercentage(dto.tasaEfectivaAnualMaximaFinanciacion),
                    annualCost: normalizedPercentage(dto.tasaEfectivaAnualMaximaAdelantoEfectivo),
                    minimumIncome: dto.ingresoMinimoMensual,
                    updatedAt: dto.fechaInformacion,
                    summary: creditCardSummary(for: dto),
                    highlights: compactHighlights([
                        dto.segmento.map { "Segmento: \($0)" },
                        dto.comisionMaximaRenovacion.map { "Renovación: \(numberString($0))" },
                        dto.masInformacion
                    ])
                )
            },
            groupKey: { $0.id },
            sort: {
                if $0.updatedAt != $1.updatedAt {
                    return $0.updatedAt > $1.updatedAt
                }

                return ($0.monthlyFee ?? Double.greatestFiniteMagnitude) < ($1.monthlyFee ?? Double.greatestFiniteMagnitude)
            }
        )
    }

    private static func deduplicatedProducts(
        from products: [FinancialProduct],
        groupKey: (FinancialProduct) -> String,
        sort: (FinancialProduct, FinancialProduct) -> Bool
    ) -> [FinancialProduct] {
        Dictionary(grouping: products, by: groupKey)
            .values
            .compactMap { group in
                group.sorted(by: sort).first
            }
            .sorted {
                if $0.institution != $1.institution {
                    return $0.institution.localizedCaseInsensitiveCompare($1.institution) == .orderedAscending
                }

                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    private static func savingsSummary(for dto: BCRASavingsAccountDTO) -> String {
        if normalizedYesNo(dto.procesoSimplificadoDebidaDiligencia) == "Sí" {
            return "La entidad informa apertura con proceso simplificado de debida diligencia."
        }

        return "La entidad informa caja de ahorro sin proceso simplificado de debida diligencia."
    }

    private static func packageSummary(for dto: BCRAPackageProductDTO) -> String {
        let segment = cleaned(dto.segmento)
        let beneficiaries = cleaned(dto.beneficiarios)
        let products = compactListSnippet(dto.productosIntegrantes, prefix: "Incluye")

        return compactSentence([
            segment.map { "Segmento \($0)." },
            beneficiaries.map { "\($0)." },
            products.map { "\($0)." }
        ])
    }

    private static func termDepositSummary(for dto: BCRATermDepositDTO) -> String {
        let channel = cleaned(dto.canalConstitucion) ?? "Canal no informado"
        let minimumDays = dto.plazoMinimoInvertirDias.map { "\($0) días" } ?? "plazo no informado"
        return "\(channel). Plazo mínimo \(minimumDays)."
    }

    private static func personalLoanSummary(for dto: BCRAPersonalLoanDTO) -> String {
        let rateType = cleaned(dto.tipoTasa) ?? "Tasa no informada"
        let maxTerm = dto.plazoMaximoOtorgable.map { "\($0) meses" } ?? "plazo no informado"
        return "\(rateType). Hasta \(maxTerm)."
    }

    private static func creditCardSummary(for dto: BCRACreditCardDTO) -> String {
        let segment = cleaned(dto.segmento) ?? "Segmento no informado"
        return "\(segment). Financiación y adelantos publicados por la entidad ante BCRA."
    }

    private static func packageIdentifier(for dto: BCRAPackageProductDTO) -> String {
        [
            "package",
            "\(dto.codigoEntidad)",
            normalizedKey(preferredProductName(short: dto.nombreCorto, full: dto.nombreCompleto, fallback: "paquete")),
            normalizedKey(cleaned(dto.segmento) ?? "general")
        ].joined(separator: "-")
    }

    private static func termDepositIdentifier(for dto: BCRATermDepositDTO) -> String {
        [
            "term",
            "\(dto.codigoEntidad)",
            normalizedKey(preferredProductName(short: dto.nombreCorto, full: dto.nombreCompleto, fallback: "plazo-fijo")),
            normalizedKey(cleaned(dto.canalConstitucion) ?? "canal")
        ].joined(separator: "-")
    }

    private static func personalLoanIdentifier(for dto: BCRAPersonalLoanDTO) -> String {
        [
            "loan",
            "\(dto.codigoEntidad)",
            normalizedKey(preferredProductName(short: dto.nombreCorto, full: dto.nombreCompleto, fallback: "prestamo"))
        ].joined(separator: "-")
    }

    private static func creditCardIdentifier(for dto: BCRACreditCardDTO) -> String {
        [
            "card",
            "\(dto.codigoEntidad)",
            normalizedKey(preferredProductName(short: dto.nombreCorto, full: dto.nombreCompleto, fallback: "tarjeta"))
        ].joined(separator: "-")
    }

    private static func preferredProductName(
        short: String?,
        full: String?,
        fallback: String
    ) -> String {
        cleaned(short)
            ?? cleaned(full)
            ?? fallback
    }

    private static func cleaned(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "0", trimmed.lowercased() != "null" else {
            return nil
        }

        return trimmed
    }

    private static func compactHighlights(_ values: [String?]) -> [String] {
        Array(
            values.compactMap { cleaned($0) }
                .prefix(3)
        )
    }

    private static func compactListSnippet(_ value: String?, prefix: String) -> String? {
        guard let cleanedValue = cleaned(value) else {
            return nil
        }

        if cleanedValue.count <= 84 {
            return "\(prefix): \(cleanedValue)"
        }

        let index = cleanedValue.index(cleanedValue.startIndex, offsetBy: 84)
        return "\(prefix): \(cleanedValue[..<index])."
    }

    private static func compactSentence(_ values: [String?]) -> String {
        values.compactMap { cleaned($0) }.joined(separator: " ")
    }

    private static func numberString(_ value: Double) -> String {
        value.formatted(
            .number
                .locale(locale)
                .notation(.compactName)
                .precision(.fractionLength(0...1))
        )
    }

    private static func currencyCode(for denomination: String?) -> String {
        guard let denomination = cleaned(denomination)?.folding(options: .diacriticInsensitive, locale: locale).uppercased() else {
            return "ARS"
        }

        if denomination.contains("DOLAR") || denomination.contains("U$S") || denomination.contains("USD") {
            return "USD"
        }

        return "ARS"
    }

    private static func normalizedPercentage(_ value: Double?) -> Double? {
        guard let value else {
            return nil
        }

        return value > 1000 ? value / 100 : value
    }

    private static func normalizedYesNo(_ value: String?) -> String {
        guard let value = cleaned(value)?.uppercased() else {
            return "No informado"
        }

        switch value {
        case "SI", "SÍ":
            return "Sí"
        case "NO":
            return "No"
        default:
            return value.capitalized(with: locale)
        }
    }

    private static func normalizedKey(_ value: String) -> String {
        value
            .folding(options: .diacriticInsensitive, locale: locale)
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}
