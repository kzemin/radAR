import Foundation

struct TransparencyProductDTO: Decodable {
    let id: String
    let nombre: String
    let entidad: String
    let categoria: ProductCategory
    let moneda: String
    let comisionMensual: Double?
    let tasaNominalAnual: Double?
    let costoFinancieroTotal: Double?
    let ingresoMinimo: Double?
    let actualizado: Date
    let descripcion: String
    let destacados: [String]
}

extension TransparencyProductDTO {
    private static func sampleDate(daysAgo: Int, hour: Int) -> Date {
        let calendar = Calendar.current
        let baseDate = calendar.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: baseDate) ?? baseDate
    }

    static func samples(for category: ProductCategory) -> [TransparencyProductDTO] {
        switch category {
        case .savingsAccount:
            return [
                .init(
                    id: "caja-galicia-move",
                    nombre: "Caja Galicia Move",
                    entidad: "Galicia",
                    categoria: .savingsAccount,
                    moneda: "ARS",
                    comisionMensual: 0,
                    tasaNominalAnual: 0,
                    costoFinancieroTotal: nil,
                    ingresoMinimo: 0,
                    actualizado: sampleDate(daysAgo: 1, hour: 10),
                    descripcion: "Caja de ahorro en pesos con mantenimiento bonificado y operación transaccional básica.",
                    destacados: ["Costo mensual 0", "Tarjeta de débito incluida", "Transferencias inmediatas"]
                ),
                .init(
                    id: "caja-bbva-online",
                    nombre: "Caja BBVA Online",
                    entidad: "BBVA",
                    categoria: .savingsAccount,
                    moneda: "ARS",
                    comisionMensual: 0,
                    tasaNominalAnual: 0,
                    costoFinancieroTotal: nil,
                    ingresoMinimo: 0,
                    actualizado: sampleDate(daysAgo: 2, hour: 12),
                    descripcion: "Caja de ahorro en pesos orientada a uso general con apertura remota y operatoria digital.",
                    destacados: ["Mantenimiento 0", "Canal digital", "Alta remota"]
                ),
                .init(
                    id: "caja-santander-super",
                    nombre: "SuperCuenta Ahorro",
                    entidad: "Santander",
                    categoria: .savingsAccount,
                    moneda: "ARS",
                    comisionMensual: 0,
                    tasaNominalAnual: 0,
                    costoFinancieroTotal: nil,
                    ingresoMinimo: 0,
                    actualizado: sampleDate(daysAgo: 3, hour: 9),
                    descripcion: "Cuenta minorista para pagos, cobros y transferencias en pesos dentro del sistema local.",
                    destacados: ["Débito sin costo", "Transferencias 24/7", "Extracciones por red"]
                )
            ]
        case .package:
            return [
                .init(
                    id: "pack-macro-selecta",
                    nombre: "Selecta",
                    entidad: "Macro",
                    categoria: .package,
                    moneda: "ARS",
                    comisionMensual: 8200,
                    tasaNominalAnual: nil,
                    costoFinancieroTotal: nil,
                    ingresoMinimo: 1_600_000,
                    actualizado: sampleDate(daysAgo: 1, hour: 15),
                    descripcion: "Paquete bancario para clientes sueldo con bonificación sujeta a acreditación de haberes.",
                    destacados: ["Bonificación por haberes", "Tarjeta internacional", "Cuenta sueldo incluida"]
                ),
                .init(
                    id: "pack-hsbc-premier",
                    nombre: "Premier",
                    entidad: "Galicia Más",
                    categoria: .package,
                    moneda: "ARS",
                    comisionMensual: 9900,
                    tasaNominalAnual: nil,
                    costoFinancieroTotal: nil,
                    ingresoMinimo: 2_200_000,
                    actualizado: sampleDate(daysAgo: 4, hour: 11),
                    descripcion: "Paquete de segmento alto con cuentas en múltiples monedas y productos complementarios.",
                    destacados: ["Caja en USD", "Tarjetas adicionales", "Segmento premium"]
                ),
                .init(
                    id: "pack-patagonia-plus",
                    nombre: "Patagonia Plus",
                    entidad: "Banco Patagonia",
                    categoria: .package,
                    moneda: "ARS",
                    comisionMensual: 7300,
                    tasaNominalAnual: nil,
                    costoFinancieroTotal: nil,
                    ingresoMinimo: 1_300_000,
                    actualizado: sampleDate(daysAgo: 2, hour: 16),
                    descripcion: "Paquete de servicios para clientes con acreditación de ingresos y bonificación parcial.",
                    destacados: ["Cuenta corriente incluida", "Débitos automáticos", "Programa de puntos"]
                )
            ]
        case .termDeposit:
            return [
                .init(
                    id: "pf-nacion-30",
                    nombre: "Plazo fijo tradicional 30 días",
                    entidad: "Banco Nación",
                    categoria: .termDeposit,
                    moneda: "ARS",
                    comisionMensual: 0,
                    tasaNominalAnual: 31.5,
                    costoFinancieroTotal: nil,
                    ingresoMinimo: 0,
                    actualizado: sampleDate(daysAgo: 1, hour: 13),
                    descripcion: "Plazo fijo tradicional en pesos con ticket mínimo bajo y acreditación al vencimiento.",
                    destacados: ["Ticket mínimo accesible", "Constitución online", "Renovación opcional"]
                ),
                .init(
                    id: "pf-galicia-online",
                    nombre: "Plazo fijo online",
                    entidad: "Galicia",
                    categoria: .termDeposit,
                    moneda: "ARS",
                    comisionMensual: 0,
                    tasaNominalAnual: 30.25,
                    costoFinancieroTotal: nil,
                    ingresoMinimo: 10_000,
                    actualizado: sampleDate(daysAgo: 0, hour: 17),
                    descripcion: "Plazo fijo minorista con simulación previa y constitución desde canal digital.",
                    destacados: ["Simulación previa", "Constitución inmediata", "Disponible 24/7"]
                ),
                .init(
                    id: "pf-bbva-uv",
                    nombre: "Plazo fijo UVA precancelable",
                    entidad: "BBVA",
                    categoria: .termDeposit,
                    moneda: "ARS",
                    comisionMensual: 0,
                    tasaNominalAnual: 1,
                    costoFinancieroTotal: nil,
                    ingresoMinimo: 1_000,
                    actualizado: sampleDate(daysAgo: 5, hour: 10),
                    descripcion: "Plazo fijo UVA precancelable con cobertura indexada y ventana de salida anticipada.",
                    destacados: ["Cobertura CER", "Precancelable", "Monto mínimo bajo"]
                )
            ]
        case .personalLoan:
            return [
                .init(
                    id: "prestamo-galicia-sueldos",
                    nombre: "Préstamo personal clientes sueldo",
                    entidad: "Galicia",
                    categoria: .personalLoan,
                    moneda: "ARS",
                    comisionMensual: nil,
                    tasaNominalAnual: 67.8,
                    costoFinancieroTotal: 103.4,
                    ingresoMinimo: 900_000,
                    actualizado: sampleDate(daysAgo: 2, hour: 14),
                    descripcion: "Línea personal en pesos para clientes sueldo con acreditación rápida y plazo extendido.",
                    destacados: ["Acreditación rápida", "Hasta 60 cuotas", "Precancelación parcial"]
                ),
                .init(
                    id: "prestamo-macro-simple",
                    nombre: "Préstamo Personal Simple",
                    entidad: "Macro",
                    categoria: .personalLoan,
                    moneda: "ARS",
                    comisionMensual: nil,
                    tasaNominalAnual: 71.2,
                    costoFinancieroTotal: 109.8,
                    ingresoMinimo: 650_000,
                    actualizado: sampleDate(daysAgo: 1, hour: 12),
                    descripcion: "Préstamo personal de tasa fija con monto escalable y cancelación en cuotas en pesos.",
                    destacados: ["Cuotas fijas", "Sin garante", "Gestión digital"]
                ),
                .init(
                    id: "prestamo-patagonia-flex",
                    nombre: "Préstamo Flex",
                    entidad: "Banco Patagonia",
                    categoria: .personalLoan,
                    moneda: "ARS",
                    comisionMensual: nil,
                    tasaNominalAnual: 65.4,
                    costoFinancieroTotal: 97.6,
                    ingresoMinimo: 750_000,
                    actualizado: sampleDate(daysAgo: 3, hour: 18),
                    descripcion: "Línea personal con opción de cancelación anticipada y aprobación según scoring crediticio.",
                    destacados: ["Aprobación rápida", "Cancelación anticipada", "Monto según scoring"]
                )
            ]
        case .creditCard:
            return [
                .init(
                    id: "tc-santander-amex",
                    nombre: "American Express Gold",
                    entidad: "Santander",
                    categoria: .creditCard,
                    moneda: "ARS",
                    comisionMensual: 5900,
                    tasaNominalAnual: 82.4,
                    costoFinancieroTotal: 124.1,
                    ingresoMinimo: 1_100_000,
                    actualizado: sampleDate(daysAgo: 2, hour: 9),
                    descripcion: "Tarjeta de crédito de segmento alto con programa de puntos y financiación rotativa.",
                    destacados: ["Programa de puntos", "Plan V", "Segmento alto"]
                ),
                .init(
                    id: "tc-bbva-latam",
                    nombre: "Visa LATAM Pass",
                    entidad: "BBVA",
                    categoria: .creditCard,
                    moneda: "ARS",
                    comisionMensual: 6400,
                    tasaNominalAnual: 79.5,
                    costoFinancieroTotal: 118.7,
                    ingresoMinimo: 1_000_000,
                    actualizado: sampleDate(daysAgo: 4, hour: 10),
                    descripcion: "Tarjeta orientada a acumulación de millas con foco en consumo financiado y viajes.",
                    destacados: ["Cuotas en viajes", "Millas LATAM Pass", "Seguros incluidos"]
                ),
                .init(
                    id: "tc-nacion-mastercard",
                    nombre: "Mastercard Nativa",
                    entidad: "Banco Nación",
                    categoria: .creditCard,
                    moneda: "ARS",
                    comisionMensual: 3200,
                    tasaNominalAnual: 77.1,
                    costoFinancieroTotal: 113.2,
                    ingresoMinimo: 650_000,
                    actualizado: sampleDate(daysAgo: 1, hour: 11),
                    descripcion: "Tarjeta generalista con costo mensual moderado y beneficios bancarios estándar.",
                    destacados: ["Promos en cuotas", "Costo mensual bajo", "Billetera interoperable"]
                )
            ]
        }
    }
}
