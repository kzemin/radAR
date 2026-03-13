import Foundation

struct BCRASavingsAccountDTO: Decodable {
    let codigoEntidad: Int
    let descripcionEntidad: String
    let fechaInformacion: Date
    let procesoSimplificadoDebidaDiligencia: String?
}

struct BCRAPackageProductDTO: Decodable {
    let comisionMaximaMantenimiento: Double?
    let ingresoMinimoMensual: Double?
    let antiguedadLaboralMinimaMeses: Int?
    let edadMaximaSolicitada: Int?
    let beneficiarios: String?
    let segmento: String?
    let productosIntegrantes: String?
    let codigoEntidad: Int
    let descripcionEntidad: String
    let fechaInformacion: Date
    let nombreCompleto: String?
    let nombreCorto: String?
    let territorioValidez: String?
    let masInformacion: String?
}

struct BCRATermDepositDTO: Decodable {
    let denominacion: String?
    let montoMinimoInvertir: Double?
    let plazoMinimoInvertirDias: Int?
    let canalConstitucion: String?
    let tasaEfectivaAnualMinima: Double?
    let codigoEntidad: Int
    let descripcionEntidad: String
    let fechaInformacion: Date
    let nombreCompleto: String?
    let nombreCorto: String?
    let territorioValidez: String?
    let masInformacion: String?
}

struct BCRAPersonalLoanDTO: Decodable {
    let montoMinimoOtorgable: Double?
    let denominacion: String?
    let montoMaximoOtorgable: Double?
    let plazoMaximoOtorgable: Int?
    let ingresoMinimoMensual: Double?
    let antiguedadLaboralMinimaMeses: Int?
    let edadMaximaSolicitada: Int?
    let relacionCuotaIngreso: Double?
    let beneficiario: String?
    let cargoMaximoCancelacionAnticipada: Double?
    let tasaEfectivaAnualMaxima: Double?
    let tipoTasa: String?
    let costoFinancieroEfectivoTotalMaximo: Double?
    let cuotaInicial: Double?
    let codigoEntidad: Int
    let descripcionEntidad: String
    let fechaInformacion: Date
    let nombreCompleto: String?
    let nombreCorto: String?
    let territorioValidez: String?
    let masInformacion: String?
}

struct BCRACreditCardDTO: Decodable {
    let comisionMaximaAdministracionMantenimiento: Double?
    let comisionMaximaRenovacion: Double?
    let tasaEfectivaAnualMaximaFinanciacion: Double?
    let tasaEfectivaAnualMaximaAdelantoEfectivo: Double?
    let ingresoMinimoMensual: Double?
    let antiguedadLaboralMinimaMeses: Int?
    let edadMaximaSolicitada: Int?
    let segmento: String?
    let codigoEntidad: Int
    let descripcionEntidad: String
    let fechaInformacion: Date
    let nombreCompleto: String?
    let nombreCorto: String?
    let territorioValidez: String?
    let masInformacion: String?
}
