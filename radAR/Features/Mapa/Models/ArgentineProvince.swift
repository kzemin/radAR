import CoreLocation
import Foundation

enum ArgentineProvince: String, CaseIterable, Codable, Hashable, Identifiable {
    case buenosAires = "AR-B"
    case caba = "AR-C"
    case catamarca = "AR-K"
    case chaco = "AR-H"
    case chubut = "AR-U"
    case cordoba = "AR-X"
    case corrientes = "AR-W"
    case entreRios = "AR-E"
    case formosa = "AR-P"
    case jujuy = "AR-Y"
    case laPampa = "AR-L"
    case laRioja = "AR-F"
    case mendoza = "AR-M"
    case misiones = "AR-N"
    case neuquen = "AR-Q"
    case rioNegro = "AR-R"
    case salta = "AR-A"
    case sanJuan = "AR-J"
    case sanLuis = "AR-D"
    case santaCruz = "AR-Z"
    case santaFe = "AR-S"
    case santiagoDelEstero = "AR-G"
    case tierraDelFuego = "AR-V"
    case tucuman = "AR-T"

    var id: String { rawValue }

    var code: String { rawValue }

    var displayName: String {
        switch self {
        case .buenosAires: "Buenos Aires"
        case .caba: "Ciudad de Buenos Aires"
        case .catamarca: "Catamarca"
        case .chaco: "Chaco"
        case .chubut: "Chubut"
        case .cordoba: "Córdoba"
        case .corrientes: "Corrientes"
        case .entreRios: "Entre Ríos"
        case .formosa: "Formosa"
        case .jujuy: "Jujuy"
        case .laPampa: "La Pampa"
        case .laRioja: "La Rioja"
        case .mendoza: "Mendoza"
        case .misiones: "Misiones"
        case .neuquen: "Neuquén"
        case .rioNegro: "Río Negro"
        case .salta: "Salta"
        case .sanJuan: "San Juan"
        case .sanLuis: "San Luis"
        case .santaCruz: "Santa Cruz"
        case .santaFe: "Santa Fe"
        case .santiagoDelEstero: "Santiago del Estero"
        case .tierraDelFuego: "Tierra del Fuego"
        case .tucuman: "Tucumán"
        }
    }

    /// Approximate centroid used as the default pin coordinate when an event
    /// doesn't carry a specific location and as the camera target on selection.
    var centroid: CLLocationCoordinate2D {
        switch self {
        case .buenosAires: .init(latitude: -36.5, longitude: -60.0)
        case .caba: .init(latitude: -34.61, longitude: -58.44)
        case .catamarca: .init(latitude: -27.7, longitude: -67.0)
        case .chaco: .init(latitude: -26.4, longitude: -60.5)
        case .chubut: .init(latitude: -43.8, longitude: -68.5)
        case .cordoba: .init(latitude: -32.1, longitude: -64.2)
        case .corrientes: .init(latitude: -28.5, longitude: -57.8)
        case .entreRios: .init(latitude: -32.0, longitude: -59.4)
        case .formosa: .init(latitude: -25.3, longitude: -59.8)
        case .jujuy: .init(latitude: -23.3, longitude: -65.7)
        case .laPampa: .init(latitude: -37.2, longitude: -65.7)
        case .laRioja: .init(latitude: -29.7, longitude: -67.4)
        case .mendoza: .init(latitude: -34.6, longitude: -68.6)
        case .misiones: .init(latitude: -26.9, longitude: -54.7)
        case .neuquen: .init(latitude: -38.7, longitude: -70.2)
        case .rioNegro: .init(latitude: -40.5, longitude: -67.4)
        case .salta: .init(latitude: -24.6, longitude: -65.0)
        case .sanJuan: .init(latitude: -31.0, longitude: -68.9)
        case .sanLuis: .init(latitude: -33.7, longitude: -66.0)
        case .santaCruz: .init(latitude: -48.7, longitude: -70.0)
        case .santaFe: .init(latitude: -30.8, longitude: -60.9)
        case .santiagoDelEstero: .init(latitude: -27.8, longitude: -63.6)
        case .tierraDelFuego: .init(latitude: -54.0, longitude: -67.5)
        case .tucuman: .init(latitude: -26.9, longitude: -65.3)
        }
    }
}
